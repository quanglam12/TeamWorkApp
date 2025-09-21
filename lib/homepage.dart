import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'settings_page.dart';
import 'constants.dart';
import 'auth_provider.dart';
import 'groupdetailpage.dart';

import 'l10n/app_localizations.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver{

  bool _loadingGroups = true;
  List<Map<String, dynamic>> _groups = [];

  List<dynamic> _notifications = [];
  List<dynamic> _messages = [];
  int _unreadNotifications = 0;
  int _unreadMessages = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    WidgetsBinding.instance.addObserver(this);
    // Bắt đầu timer
    _startPolling();
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _stopPolling;
    }
  }

  void _startPolling() {
    _timer?.cancel();
    _fetchNotifications();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchNotifications());
  }
  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
  }
  Future<void> _fetchData() async {
    setState(() {
      _loadingGroups = true;
    });

    try {
      final token = context.read<AuthProvider>().token;
      final url = Uri.parse('${AppConstants.apiBaseUrl}/api/groups');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        final groupsData = (jsonData['groups'] as List)
            .map((g) => {
          'id': g['id'],
          'name': g['name'],
          'description': g['description'],
          'avatar': g['avturl'],
          'members': g['members_count'] ?? 0
        })
            .toList();

        setState(() {
          _groups = groupsData;
          _loadingGroups = false;
        });
      } else {
        setState(() {
          _loadingGroups = false;
        });
        debugPrint('Lỗi API: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _loadingGroups = false;
      });
      debugPrint('Lỗi kết nối API: $e');
    }
  }
  Future<void> _fetchNotifications() async {

    try {
      final token = context.read<AuthProvider>().token;
      final url = Uri.parse('${AppConstants.apiBaseUrl}/api/notifications');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> data = json['data']; // Laravel resource trả về data

        // phân loại: tin nhắn vs thông báo khác
        final messages = data.where((n) => n['type'] == 'new_chat_message').toList();
        final notifs = data.where((n) => n['type'] != 'new_chat_message').toList();

        // tính chưa đọc
        final unreadMessages = messages.where((n) => n['is_read'] == false).length;
        final unreadNotifs = notifs.where((n) => n['is_read'] == false).length;

        setState(() {
          _notifications = notifs;
          _messages = messages;
          _unreadNotifications = unreadNotifs;
          _unreadMessages = unreadMessages;
        });
      } else {
        debugPrint('Fetch notifications failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  static Future<bool> markNotificationAsRead(BuildContext context, int notificationId) async {
    final token = context.read<AuthProvider>().token;
    final url = Uri.parse('${AppConstants.apiBaseUrl}/api/notifications/$notificationId/read');

    final res = await http.patch(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return res.statusCode >= 200 && res.statusCode < 300;
  }


  Future<void> _markOneAsRead(Map<String, dynamic> n) async {
    if (n['is_read'] == true) return; // đã đọc rồi

    final success = await markNotificationAsRead(context, n['id']);
    if (success) {
      setState(() {
        // cập nhật object local
        n['is_read'] = true;

        // cập nhật lại counters
        _unreadNotifications = _notifications.where((x) => x['is_read'] == false).length;
        _unreadMessages = _messages.where((x) => x['is_read'] == false).length;
      });
    } else {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.mark_all_as_read)),
        );
      }
    }
  }
  Future<void> _markAllAsRead({String? type}) async {
    final token = context.read<AuthProvider>().token;
    var url = '${AppConstants.apiBaseUrl}/api/notifications/read-all';
    if (type != null) {
      url += '?type=$type';
    }

    final res = await http.patch(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      setState(() {
        switch (type) {
          case 'new_chat_message':
          // chỉ đánh dấu phần tin nhắn
            for (final m in _messages) {
              m['is_read'] = true;
            }
            _unreadMessages = 0;
            break;

          case 'other':
          // chỉ đánh dấu phần thông báo
            for (final n in _notifications) {
              n['is_read'] = true;
            }
            _unreadNotifications = 0;
            break;

          default:
          // đánh dấu tất cả
            for (final m in _messages) {
              m['is_read'] = true;
            }
            for (final n in _notifications) {
              n['is_read'] = true;
            }
            _unreadMessages = 0;
            _unreadNotifications = 0;
            break;
        }
      });
    } else {
      // nếu cần thì show lỗi ở đây
      debugPrint('Mark all as read failed: ${res.statusCode}');
    }
  }

  String formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return '';
    }
    try {
      // Chuyển chuỗi thành đối tượng DateTime
      final dateTime = DateTime.parse(dateTimeString);

      // Tạo đối tượng định dạng
      final formatter = DateFormat('HH:mm-dd/MM/yyyy');

      // Trả về chuỗi đã được định dạng
      return formatter.format(dateTime);
    } catch (e) {
      // Xử lý lỗi nếu chuỗi không hợp lệ
      //debugPrint('Lỗi định dạng: $e');
      return '';
    }
  }

  void _showCreateGroupSheet() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    File? avatarFile;
    bool creating = false;

    // Lấy token tuỳ cách bạn lưu trữ
    final token = context.read<AuthProvider>().token;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          Future<void> pickAvatar() async {
            final picker = ImagePicker();
            final picked = await picker.pickImage(source: ImageSource.gallery);
            if (picked != null) {
              setModalState(() {
                avatarFile = File(picked.path);
              });
            }
          }

          Future<void> submit() async {
            if (nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.group_name_cannot_be_empty,
                  ),
                ),
              );
              return;
            }

            setModalState(() {
              creating = true;
            });

            try {
              final url = Uri.parse('${AppConstants.apiBaseUrl}/api/groups');

              if (avatarFile == null) {
                // gửi json thuần
                final response = await http.post(
                  url,
                  headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'Authorization': 'Bearer $token',
                  },
                  body: jsonEncode({
                    'name': nameController.text,
                    'description': descriptionController.text,
                  }),
                );

                //print('Status: ${response.statusCode}');
                //print('Body: ${response.body}');
                if (response.statusCode == 200 || response.statusCode == 201) {
                  if(context.mounted) {
                    Navigator.pop(context);
                  }
                  _fetchData();
                  if(context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!
                              .group_created_successfully,
                        ),
                      ),
                    );
                  }
                } else {
                  if(context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.errorMessage('${response.statusCode}: ${response.body}')
                        ),
                      ),
                    );
                  }
                }
              } else {
                // upload multipart nếu có avatar
                var request = http.MultipartRequest('POST', url);
                request.headers['Accept'] = 'application/json';
                request.headers['Authorization'] = 'Bearer $token';
                request.fields['name'] = nameController.text;
                request.fields['description'] = descriptionController.text;
                request.files.add(
                  await http.MultipartFile.fromPath('avatar', avatarFile!.path),
                );

                var streamed = await request.send();
                //print('Status code: ${streamed.statusCode}');
                //final respStr = await streamed.stream.bytesToString();
                //print('Body: $respStr');
                if (!mounted) return;

                if (streamed.statusCode == 200 || streamed.statusCode == 201) {
                  if(context.mounted) {
                    Navigator.pop(context);
                  }
                  _fetchData();
                  if(context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!
                              .group_created_successfully,
                        ),
                      ),
                    );
                  }
                } else {
                  final respStr = await streamed.stream.bytesToString();
                  if(context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.errorMessage('${streamed.statusCode}: $respStr')),
                      ),
                    );
                  }
                }
              }
            } finally {
              if (mounted) {
                setModalState(() {
                  creating = false;
                });
              }
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: pickAvatar,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage:
                      avatarFile != null ? FileImage(avatarFile!) : null,
                      child: avatarFile == null
                          ? const Icon(Icons.camera_alt,
                          size: 32, color: Colors.white70)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.group_name,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText:
                      AppLocalizations.of(context)!.description_optional,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: creating ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: creating
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Text(
                        AppLocalizations.of(context)!.create_group,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }


  Widget _buildBadge(IconData icon, int count, VoidCallback onPressed) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return _buildNotificationList(_notifications, AppLocalizations.of(context)!.notification);
      },
    );
  }

  void _showMessages() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return _buildNotificationList(_messages, AppLocalizations.of(context)!.message);
      },
    );
  }

  Widget _buildNotificationList(List<dynamic> items, String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down),
                onPressed: () {
                  Navigator.pop(context); // đóng sheet
                },
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // nút "Đánh dấu tất cả đã đọc"
              IconButton(
                icon: const Icon(Icons.done_all),
                tooltip: AppLocalizations.of(context)!.mark_all_as_read,
                onPressed: () async {
                  await _markAllAsRead(type: title == AppLocalizations.of(context)!.message ? "new_chat_message" : "other");
                  await _fetchNotifications();
                },
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: items.isEmpty
                ? Center(child: Text('${AppLocalizations.of(context)!.no} $title'))
                : ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final n = items[index];

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: Icon(
                    n['type'] == 'new_chat_message' ? Icons.message : Icons.notifications,
                    color: n['is_read'] == true ? Colors.grey : Colors.blue,
                  ),
                  title: Text(n['message'] ?? ''),
                  subtitle: Text(formatDateTime(n['created_at'])),
                  trailing: n['is_read'] == false
                      ? const Icon(Icons.circle, size: 10, color: Colors.blue)
                      : null,
                  onTap: () async {
                    // 1) Đánh dấu đã đọc trước (API + cập nhật local)
                    await _markOneAsRead(n);

                    // 2) Nếu là tin nhắn chat, chuyển vào chat
                    if (n['type'] == 'new_chat_message') {
                      // cố gắng lấy chatId từ data.url hoặc reference_id
                      int? chatId;
                      try {
                        if (n['data'] != null && n['data']['url'] != null) {
                          final url = n['data']['url'] as String;
                          final match = RegExp(r'/api/chats/(\d+)').firstMatch(url);
                          if (match != null) chatId = int.parse(match.group(1)!);
                        }
                        if (chatId == null && n['reference_id'] != null) {
                          chatId = (n['reference_id'] as num).toInt();
                        }
                      } catch (_) {}

                      if (chatId != null) {
                        // TODO: mowr trang chat

                      } else {
                        // Không tìm được chatId, bạn có thể mở rộng xử lý theo app
                        if(context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(
                                AppLocalizations.of(context)!.errorMessage('chatId'))),
                          );
                        }
                      }
                    } else {
                      final targetUrl = n['data']?['url'] as String?;
                      if (targetUrl != null) {
                        //TODO xử lí khác
                      }
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(AppLocalizations.of(context)!.appTitle,
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          _buildBadge(Icons.notifications, _unreadNotifications, _showNotifications),
          _buildBadge(Icons.message, _unreadMessages, _showMessages),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!.group_list,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    _showCreateGroupSheet();
                  },
                  icon: const Icon(Icons.add),
                  label:Text(AppLocalizations.of(context)!.create_new_group),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _loadingGroups
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                // hàm reload dữ liệu của bạn
                onRefresh: () async {
                  // gọi hàm tải lại dữ liệu ở đây
                  await _fetchData();
                  await _fetchNotifications();
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(), // đảm bảo luôn scroll được để hiện refresh indicator
                  itemCount: _groups.length,
                  itemBuilder: (context, index) {
                    final group = _groups[index];
                    final scale = MediaQuery.of(context).textScaler.scale(1.0);
                    final size = (40 * scale.clamp(1.0, 1.5));
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: Container(
                          width: size,
                          height: size,
                          clipBehavior: Clip.hardEdge,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8 * scale),
                          ),
                          child: Image.network(
                            '${AppConstants.apiBaseUrl}/storage/${(group["avatar"] != null && group["avatar"].isNotEmpty) ? group["avatar"] : 'groupsavt/avtdefault.png'}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.red[900],
                                alignment: Alignment.center,
                                child: Text(
                                  AppLocalizations.of(context)!.avatar,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            },
                          ),
                        ),
                        title: Text(group["name"] as String),
                        subtitle: Text(
                            "${group["members"]} ${AppLocalizations.of(context)!.members}"),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          _stopPolling();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupDetailPage(
                                groupId: group["id"],
                              ),
                            ),
                          ).then((_) {
                            _startPolling();
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateGroupSheet();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}