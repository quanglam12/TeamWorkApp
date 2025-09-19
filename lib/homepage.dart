import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

class _HomePageState extends State<HomePage> {

  bool _loadingGroups = true;
  List<Map<String, dynamic>> _groups = [];

  int _unreadNotifications = 0;
  int _unreadMessages = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
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


  void _showNotifications() {
    final notifications = [
      "Thông báo 1: Nội dung thông báo mẫu",
      "Thông báo 2: Nội dung thông báo mẫu",
      "Thông báo 3: Nội dung thông báo mẫu",
    ];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.notification),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: notifications.length,
            itemBuilder: (context, index) => ListTile(
              leading: const Icon(Icons.notifications),
              title: Text(notifications[index]),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    ).then((_) {
      // sau khi xem thông báo thì reset badge
      setState(() => _unreadNotifications = 0);
    });
  }

  void _showMessages() {
    final messages = [
      {"from": "Nguyễn A", "content": "Xin chào, đây là tin nhắn 1"},
      {"from": "Trần B", "content": "Tin nhắn 2 mẫu"},
      {"from": "Lê C", "content": "Tin nhắn 3 mẫu"},
    ];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.message),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(msg["from"]!),
                subtitle: Text(msg["content"]!),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    ).then((_) {
      // reset badge tin nhắn
      setState(() => _unreadMessages = 0);
    });
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
                          "Lỗi ${response.statusCode}: ${response.body}",
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
                        content: Text("Lỗi ${streamed.statusCode}: $respStr"),
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


  Widget _buildBadge(IconData icon, int count, VoidCallback onTap) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onTap,
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
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                '$count',
                style: const TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
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
                  : ListView.builder(
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
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          },
                        ),
                      ),
                      title: Text(group["name"] as String),
                      subtitle: Text("${group["members"]} ${AppLocalizations.of(context)!.members}"),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GroupDetailPage(groupId: group["id"],),
                          ),
                        );

                      },
                    ),
                  );
                },
              ),
            ),
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