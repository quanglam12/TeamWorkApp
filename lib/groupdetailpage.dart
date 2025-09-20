import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:teamworkapp/l10n/app_localizations.dart';

import 'constants.dart';
import 'auth_provider.dart';
import 'taskdetail_page.dart';
import 'filedetail_page.dart';

class GroupDetailPage extends StatefulWidget {
  final int groupId;

  const GroupDetailPage({super.key, required this.groupId});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}
Map<String, dynamic>? groupData;
class _GroupDetailPageState extends State<GroupDetailPage>
    with SingleTickerProviderStateMixin {

  bool isLoading = true;



  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchGroupDetail();
  }

  Future<void> _fetchGroupDetail() async {
    try {
      final token = context.read<AuthProvider>().token;
      final url = Uri.parse(
          '${AppConstants.apiBaseUrl}/api/groups/${widget.groupId}');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        setState(() {
          groupData = body['group'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }
  Future<void> _showEditGroupSheet(BuildContext context) async {
    final nameController =
    TextEditingController(text: groupData?['name'] ?? '');
    final descController =
    TextEditingController(text: groupData?['description'] ?? '');
    // avatar hiện tại
    String avatarUrl =
        '${AppConstants.apiBaseUrl}/storage/${groupData?['avturl'] ?? 'groupsavt/avtdefault.png'}';
    File? newAvatar;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateSheet) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Chỉnh sửa nhóm', style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        setStateSheet(() {
                        newAvatar = File(picked.path);
                        });
                       }
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: newAvatar != null
                          ? FileImage(newAvatar!)
                          : NetworkImage(avatarUrl) as ImageProvider,
                      child: const Align(
                        alignment: Alignment.bottomRight,
                        child: Icon(Icons.camera_alt, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên nhóm',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả nhóm',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final token = context.read<AuthProvider>().token;
                      final uri = Uri.parse(
                          '${AppConstants.apiBaseUrl}/api/groups/${widget.groupId}');
                      final request = http.MultipartRequest('POST', uri);
                      request.headers['Authorization'] = 'Bearer $token';
                      request.fields['name'] = nameController.text.trim();
                      request.fields['description'] =
                          descController.text.trim();
                      request.fields['_method'] = 'PUT'; // Laravel update

                      if (newAvatar != null) {
                        request.files.add(await http.MultipartFile.fromPath(
                          'avatar', // key file trên backend
                          newAvatar!.path,
                        ));
                      }

                      final streamed = await request.send();
                      final resp = await http.Response.fromStream(streamed);

                      if (resp.statusCode == 200) {
                        if(context.mounted) {
                          Navigator.pop(ctx);
                        }
                        _fetchGroupDetail();
                      } else {
                        // xử lý lỗi
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Lưu thay đổi'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );

  }
  Future<void> updateMemberRole({
    required BuildContext context,
    required int groupId,
    required int userId,
    required String role,
  }) async {
    final token = context.read<AuthProvider>().token;

    final url = Uri.parse(
        '${AppConstants.apiBaseUrl}/api/groups/$groupId/members/$userId');

    final response = await http.put(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'role': role}),
    );

    if (response.statusCode == 200) {
      final res = jsonDecode(response.body);
      if (res['status'] == true) {
        // Cập nhật thành công
        if(context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật vai trò thành công')),
          );
        }
      } else {
        if(context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Có lỗi xảy ra')),
          );
        }
      }
    } else {
      if(context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi ${response.statusCode}')),
        );
      }
    }
  }
  Future<void> showGroupMembersDialog(
      BuildContext context,
      List<dynamic> members,
      bool isAdmin,
      ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: Text(isAdmin ? 'Quản lý thành viên' : 'Danh sách thành viên'),
                actions: [
                  if (isAdmin)
                    IconButton(
                      icon: const Icon(Icons.person_add),
                      onPressed: () {
                        showAddMembersDialog(context, groupData?['id']);
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              body: ListView.builder(
                controller: scrollController,
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final m = members[index];
                  final user = m['user'];
                  final avatarUrl =
                      '${AppConstants.apiBaseUrl}/storage/${user['avturl'] ?? 'avatars/default.png'}';

                  return ListTile(
                    leading: CircleAvatar(backgroundImage: NetworkImage(avatarUrl)),
                    title: Text(user['name'] ?? ''),
                    subtitle: Text(m['role'] ?? ''),
                    trailing: isAdmin && m['role'] != 'admin'
                        ? PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'remove') {
                          removeMember(
                            context: context,
                            groupId: widget.groupId,
                            userId: groupData?['user']?['id'],
                            userName: groupData?['user']?['name'] ?? '',
                          );
                        } else if (value == 'changeRole') {
                          _showChangeRoleDialog(context, m);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'changeRole',
                          child: Text('Thay đổi vai trò'),
                        ),
                        const PopupMenuItem(
                          value: 'remove',
                          child: Text('Gỡ thành viên'),
                        ),
                      ],
                      icon: const Icon(Icons.more_vert),
                    )
                        : null,
                    onTap: () {
                      // TODO: Mở profile thành viên
                    },
                  );

                },
              ),
            );
          },
        );
      },
    );
  }
  void showAddMembersDialog(BuildContext context, int groupId) {
    final formKey = GlobalKey<FormState>();
    final List<Map<String, dynamic>> members = [
      {'email': '', 'role': 'member'}
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        final screenWidth = MediaQuery.of(ctx).size.width;
        final dialogWidth = screenWidth * 0.9;
        final maxDialogWidth = 650.0;

        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            // giới hạn chiều rộng dialog
            insetPadding: const EdgeInsets.symmetric(horizontal: 8),
            contentPadding: EdgeInsets.zero,
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            title: const Text('Thêm thành viên'),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: dialogWidth > maxDialogWidth
                    ? maxDialogWidth
                    : dialogWidth,
                // hạn chế chiều cao để cuộn được
                maxHeight: MediaQuery.of(ctx).size.height * 0.8,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      ...members.asMap().entries.map((entry) {
                        final index = entry.key;
                        final member = entry.value;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                TextFormField(
                                  initialValue: member['email'],
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Email bắt buộc';
                                    }
                                    if (!RegExp(r'\S+@\S+\.\S+')
                                        .hasMatch(value)) {
                                      return 'Email không hợp lệ';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    member['email'] = value;
                                  },
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    // dropdown bé hơn email một chút
                                    Flexible(
                                      flex: 2, // nhỏ hơn
                                      child: DropdownButtonFormField<String>(
                                        value: member['role'],
                                        decoration: const InputDecoration(
                                          labelText: 'Vai trò',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: const [
                                          DropdownMenuItem(
                                              value: 'member',
                                              child: Text('Member')),
                                          DropdownMenuItem(
                                              value: 'manager',
                                              child: Text('Manager')),
                                          DropdownMenuItem(
                                              value: 'admin',
                                              child: Text('Admin')),
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            member['role'] = value!;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle,
                                          color: Colors.red),
                                      tooltip: 'Xoá thành viên này',
                                      onPressed: () {
                                        setState(() {
                                          members.removeAt(index);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            members.add({'email': '', 'role': 'member'});
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm thành viên mới'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  await addMembers(context, groupId, members);
                  if (context.mounted) Navigator.pop(ctx);
                },
                child: const Text('Thêm'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> addMembers(
      BuildContext context, int groupId, List<Map<String, dynamic>> members) async {
    final token = context.read<AuthProvider>().token;

    final url = Uri.parse('${AppConstants.apiBaseUrl}/api/groups/$groupId/members');

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'members': members}),
    );

    if (!context.mounted) return;

    if (response.statusCode == 200) {
      final res = jsonDecode(response.body);
      final results = res['results'] as Map<String, dynamic>;

      // Hiển thị kết quả từng email
      results.forEach((email, result) {
        if (result['status'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$email: thêm thành công')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$email: ${result['message']}')),
          );
        }
      });

      _fetchGroupDetail();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi ${response.statusCode}')),
      );
    }
  }
  Future<void> removeMember({
    required BuildContext context,
    required int groupId,
    required int userId,
    required String userName,
  }) async {
    final token = context
        .read<AuthProvider>()
        .token;
    // Xác nhận trước khi xoá
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xoá'),
        content: Text('Bạn có chắc chắn muốn xoá thành viên "$userName" khỏi nhóm không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );

    // Nếu bấm Hủy thì confirm == false
    if (confirm != true) return;

    // Gọi API xoá
    final url = Uri.parse(
        '${AppConstants.apiBaseUrl}/api/groups/$groupId/members/$userId');

    final response = await http.delete(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final res = jsonDecode(response.body);
      if (res['status'] == true) {
        if(context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xoá thành viên thành công')),
          );
        }
        _fetchGroupDetail();
      } else {
        if(context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Có lỗi xảy ra')),
          );
        }
      }
    } else {
      if(context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi ${response.statusCode} khi xoá')),
        );
      }
    }
  }

  void _showChangeRoleDialog(BuildContext context, dynamic member) {
    String? selectedRole = member['role'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Thay đổi vai trò cho ${member['user']['name']}'),
          content: DropdownButtonFormField<String>(
            value: selectedRole,
            onChanged: (value) {
              selectedRole = value;
            },
            items: const [
              DropdownMenuItem(value: 'member', child: Text('Thành viên')),
              DropdownMenuItem(value: 'manager', child: Text('Quản lí')),
              DropdownMenuItem(value: 'admin', child: Text('Quản trị')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final groupId = groupData?['id'];
                final userId = member['user']['id'];

                if (selectedRole != null) {
                  await updateMemberRole(
                    context: context,
                    groupId: groupId,
                    userId: userId,
                    role: selectedRole!,
                  );
                }
                if(context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }
  Future<void> showDeleteGroupDialog(BuildContext context, int groupId, VoidCallback? onDeleted) async {
    final controller = TextEditingController();

    // Tạo chuỗi random 6 ký tự
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    final confirmationCode = String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Xác nhận xoá nhóm', style: TextStyle(color: Colors.red)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Bạn có chắc chắn xoá nhóm? Tất cả dữ liệu sẽ mất.'),
              const SizedBox(height: 12),
              Text(
                'Nhập đúng mã xác nhận bên dưới để xoá nhóm:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                confirmationCode,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Nhập mã xác nhận',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                if (controller.text != confirmationCode) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mã xác nhận không đúng')),
                  );
                  return;
                }

                // Gọi API xoá nhóm
                final token = context.read<AuthProvider>().token;
                final url = Uri.parse('${AppConstants.apiBaseUrl}/api/groups/$groupId');

                final response = await http.delete(
                  url,
                  headers: {
                    'Accept': 'application/json',
                    'Authorization': 'Bearer $token',
                  },
                );

                if (!context.mounted) return;

                if (response.statusCode == 200) {
                  final res = jsonDecode(response.body);
                  if (res['status'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nhóm đã được xoá thành công')),
                    );
                    Navigator.pop(ctx);
                    if (onDeleted != null) onDeleted();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res['message'] ?? 'Có lỗi xảy ra')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi ${response.statusCode}')),
                  );
                }
              },
              child: const Text('Xoá nhóm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> showLeaveGroupDialog(BuildContext context, int groupId, VoidCallback? onLeaved) async {
    final controller = TextEditingController();

    // Tạo một số ngẫu nhiên từ 0 đến 9
    final rnd = Random();
    final confirmationCode = rnd.nextInt(10).toString();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Xác nhận rời nhóm', style: TextStyle(color: Colors.red)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Bạn có chắc chắn muốn rời nhóm?'),
              const SizedBox(height: 12),
              Text(
                'Nhập đúng mã xác nhận bên dưới để rời nhóm:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                confirmationCode,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nhập mã xác nhận',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                if (controller.text != confirmationCode) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mã xác nhận không đúng')),
                  );
                  return;
                }

                // Gọi API rời nhóm
                final token = context.read<AuthProvider>().token;
                final url = Uri.parse('${AppConstants.apiBaseUrl}/api/groups/$groupId/leave');

                final response = await http.delete(
                  url,
                  headers: {
                    'Accept': 'application/json',
                    'Authorization': 'Bearer $token',
                  },
                );

                if (!context.mounted) return;

                if (response.statusCode == 200) {
                  final res = jsonDecode(response.body);
                  if (res['status'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bạn đã rời nhóm thành công')),
                    );
                    Navigator.pop(ctx);
                    if (onLeaved != null) onLeaved();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res['message'] ?? 'Có lỗi xảy ra')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi ${response.statusCode}')),
                  );
                }
              },
              child: const Text('Rời nhóm'),
            ),
          ],
        );
      },
    );
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().userId;
    final data = groupData ?? {};
    final isAdmin = (data['members'] as List<dynamic>).any(
              (member) => member['user_id'] == currentUserId && member['role'] == 'admin',
        );
    final isOwner = data['createdBy']?['id'] == currentUserId;
    final name = data['name'] ?? AppLocalizations.of(context)!.loading;
    final description = data['description'] ?? '';
    final avatarUrl =
        '${AppConstants.apiBaseUrl}/storage/${data['avturl'] ?? 'groupsavt/avtdefault.png'}';
    final membersCount = data['members_count'] ?? 0;
    final createdBy = data['createdBy']?['name'] ?? '';

    List<PopupMenuEntry<String>> buildMenuItems(bool isAdmin, bool isOwner) {
      if(isOwner){
        return [
          PopupMenuItem(
            value: 'edit',
            child: Text(AppLocalizations.of(context)!.editGroup),
          ),
          PopupMenuItem(
            value: 'members',
            child: Text(AppLocalizations.of(context)!.manageMembers),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'pin',
            child: Text(AppLocalizations.of(context)!.pinGroup),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Text(AppLocalizations.of(context)!.deleteGroup),
          ),
        ];
      } else if (isAdmin) {
        return [
          PopupMenuItem(
            value: 'edit',
            child: Text(AppLocalizations.of(context)!.editGroup),
          ),
          PopupMenuItem(
            value: 'members',
            child: Text(AppLocalizations.of(context)!.manageMembers),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'pin',
              child: Text(AppLocalizations.of(context)!.pinGroup),
          ),
          PopupMenuItem(
            value: 'leave',
            child: Text(AppLocalizations.of(context)!.leaveGroup),
          ),
        ];
      } else {
        return [
          PopupMenuItem(
            value: 'members',
            child: Text(AppLocalizations.of(context)!.memberList),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'pin',
            child: Text(AppLocalizations.of(context)!.pinGroup),
          ),
          PopupMenuItem(
            value: 'leave',
            child: Text(AppLocalizations.of(context)!.leaveGroup),
          ),
        ];
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _showEditGroupSheet(context);
                  break;
                case 'members':
                  showGroupMembersDialog(
                    context,
                    data['members'] ?? [],
                    isAdmin,
                  );
                  break;
                case 'pin':
                // TODO: xử lý ghim nhóm
                  break;
                case 'delete':
                  showDeleteGroupDialog(context, groupData?['id'], () {
                    Navigator.pop(context);
                  });
                  break;
                case 'leave':
                  showLeaveGroupDialog(context, groupData?['id'], (){
                    Navigator.pop(context);
                  });
                  break;
              }
            },
            itemBuilder: (context) => buildMenuItems(isAdmin, isOwner),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Group Info Section
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    avatarUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium, // font theo theme
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '$membersCount ',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: '${AppLocalizations.of(context)!.members} • ${AppLocalizations.of(context)!.createdBy} '),
                            TextSpan(
                              text: '$createdBy',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                  ),
                )
              ],
            ),
          ),


          // Tabs
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: AppLocalizations.of(context)!.message),
              Tab(text: AppLocalizations.of(context)!.task),
              Tab(text: AppLocalizations.of(context)!.files),
              Tab(text: AppLocalizations.of(context)!.information),
            ],
          ),

          // Nội dung theo tab
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChatTab(),
                _buildTasksTab(),
                _buildFilesTab(),
                _buildInfoTab(data),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return const Center(child: Text('Danh sách Chat...'));
  }

  Widget _buildTasksTab() {
    return TasksTab(
      groupId: groupData?['id']
    );
  }


  Widget _buildFilesTab() {
    return FilesTab(groupId: groupData?['id']);
  }



  Widget _buildInfoTab(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề
          Text(
            data['name'],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 8),

          // Mô tả nhóm
          Text(
            'Mô tả: ${data['description']}',
            style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 8),

          // Người tạo
          Text(
            'Được tạo bởi: ${data['createdBy']['name']}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),

          // Thống kê thành viên
          Text(
            'Tổng số thành viên: ${data['members_count']}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Danh sách thành viên
          const Text(
            'Danh sách thành viên:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: data['members'].length,
              itemBuilder: (context, index) {
                final member = data['members'][index];
                final String memberName = member['user']['name'];
                final String role = member['role'];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(
                      memberName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Vai trò: ${role.replaceFirst(role[0], role[0].toUpperCase())}',
                    ),
                    leading: CircleAvatar(
                    radius: 10,
                    backgroundImage: member['user']['avturl'] != null
                        ? NetworkImage('${AppConstants.apiBaseUrl}/storage/${member['user']['avturl']}')
                        : const AssetImage('assets/images/avtUdefault.png')
                    as ImageProvider,
                  ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


class TasksTab extends StatefulWidget {
  final int groupId;

  const TasksTab({super.key, required this.groupId});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  late Future<List<Map<String, dynamic>>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _tasksFuture = fetchTasks();
  }

  Future<List<Map<String, dynamic>>> fetchTasks() async {
    final token = context.read<AuthProvider>().token;
    final url = Uri.parse(
        '${AppConstants.apiBaseUrl}/api/tasks?group_id=${widget.groupId}');
    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List tasks = (body['tasks'] ?? []) as List;
      return tasks.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load tasks');
    }
  }

  Future<void> _showCreateTaskDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedPriority = 'medium';
    DateTime? selectedDeadline;

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text('Tạo công việc mới'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Tiêu đề'),
                  ),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Mô tả'),
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    items: const [
                      DropdownMenuItem(value: 'high', child: Text('Cao')),
                      DropdownMenuItem(
                          value: 'medium', child: Text('Trung bình')),
                      DropdownMenuItem(value: 'low', child: Text('Thấp')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setStateDialog(() {
                          selectedPriority = val;
                        });
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Ưu tiên'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedDeadline == null
                              ? 'Chưa chọn hạn chót'
                              : 'Hạn chót: ${selectedDeadline!.day}/${selectedDeadline!.month}/${selectedDeadline!.year} ${selectedDeadline!.hour.toString().padLeft(2, '0')}:${selectedDeadline!.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final now = DateTime.now();
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: now,
                            firstDate: now,
                            lastDate: DateTime(now.year + 5),
                          );
                          if (pickedDate != null) {
                            if (!context.mounted) return;
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            DateTime combined = pickedDate;
                            if (pickedTime != null) {
                              combined = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            }
                            setStateDialog(() {
                              selectedDeadline = combined;
                            });
                          }
                        },
                        child: const Text('Chọn hạn chót'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await createTask(
                    titleController.text,
                    descController.text,
                    selectedPriority,
                    selectedDeadline,
                  );
                  if (mounted) {
                    setState(() {
                      _tasksFuture = fetchTasks();
                    });
                  }
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Tạo'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> createTask(
      String title,
      String description,
      String priority,
      DateTime? deadline,
      ) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/api/tasks');

    final body = {
      'title': title,
      'description': description,
      'priority': priority,
      'group_id': widget.groupId.toString(),
      'status': '0',
      'deadline': deadline != null ? deadline.toIso8601String() : '',
    };

    final token = context.read<AuthProvider>().token;
    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Không tạo được task: ${response.body}');
    }
  }

  /// Cập nhật thông tin task
  Future<Map<String, dynamic>> updateTask({
    required int taskId,
    required String title,
    required String description,
    required String priority,
    required String deadline,
  }) async {
    final token = context.read<AuthProvider>().token;
    final url = Uri.parse('${AppConstants.apiBaseUrl}/api/tasks/$taskId');
    final response = await http.put(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {
        'title': title,
        'description': description,
        'priority': priority,
        'deadline': deadline,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Cập nhật task thất bại: ${response.body}');
    }
  }

  /// Gán thêm thành viên cho task (danh sách user_ids)
  Future<Map<String, dynamic>> addAssignees({
    required int taskId,
    required List<int> userIds,
  }) async {
    final token = context.read<AuthProvider>().token;
    final url = Uri.parse('${AppConstants.apiBaseUrl}/api/tasks/$taskId/assignees');
    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_ids': userIds,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gán user thất bại: ${response.body}');
    }
  }

  /// Xoá thành viên khỏi task
  Future<Map<String, dynamic>> removeAssignee({
    required int taskId,
    required int userId,
  }) async {
    final token = context.read<AuthProvider>().token;
    final url = Uri.parse('${AppConstants.apiBaseUrl}/api/tasks/$taskId/assignees/$userId');
    final response = await http.delete(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Xoá user thất bại: ${response.body}');
    }
  }

  Future<void> _showEditTaskDialog(BuildContext context, Map<String, dynamic> task) async {
    final titleController = TextEditingController(text: task['title'] ?? '');
    final descController = TextEditingController(text: task['description'] ?? '');
    String priority = task['priority'] ?? 'medium';
    DateTime? deadline = task['deadline'] != null
        ? DateTime.tryParse(task['deadline'])
        : null;

    // nếu task có assignees
    final currentAssignees =
        (task['assignees'] as List?)?.map((a) => a['id'] as int).toSet() ?? {};
    final selectedUserIds = {...currentAssignees};

    // lấy members từ groupData ở state hiện tại (vì bạn đang trong 1 file)
    final allMembers = (groupData?['members'] as List)
        .map((m) => {
      'user_id': m['user_id'],
      'name': m['user']['name'],
      'avturl': m['user']['avturl'],
    })
        .toList();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Chỉnh sửa Task'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Tiêu đề'),
                  ),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Mô tả'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: priority,
                    decoration: const InputDecoration(labelText: 'Độ ưu tiên'),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Thấp')),
                      DropdownMenuItem(value: 'medium', child: Text('Trung bình')),
                      DropdownMenuItem(value: 'high', child: Text('Cao')),
                    ],
                    onChanged: (val) => setState(() => priority = val!),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Hạn'),
                    subtitle: Text(deadline != null
                        ? '${deadline!.day.toString().padLeft(2, '0')}/'
                        '${deadline!.month.toString().padLeft(2, '0')}/'
                        '${deadline!.year} '
                        '${deadline!.hour.toString().padLeft(2, '0')}:'
                        '${deadline!.minute.toString().padLeft(2, '0')}'
                        : 'Chưa chọn'),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        // 1. Chọn ngày
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: deadline ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 1)),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          // 2. Chọn giờ/phút
                          if(!context.mounted) return;
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: deadline != null
                                ? TimeOfDay.fromDateTime(deadline!)
                                : TimeOfDay.now(),
                          );
                          if (pickedTime != null) {
                            final combined = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                            setState(() => deadline = combined);
                          } else {
                            // nếu không chọn time thì chỉ lưu ngày
                            final combined = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                            );
                            setState(() => deadline = combined);
                          }
                        }
                      },
                    ),
                  )
                  ,
                  const SizedBox(height: 12),
                  const Text('Thành viên thực hiện'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: allMembers.map((m) {
                      final uid = m['user_id'] as int;
                      final selected = selectedUserIds.contains(uid);
                      return FilterChip(
                        avatar: CircleAvatar(
                          radius: 10,
                          backgroundImage: m['avturl'] != null
                              ? NetworkImage('${AppConstants.apiBaseUrl}/storage/${m['avturl']}')
                              : const AssetImage('assets/images/avtUdefault.png')
                          as ImageProvider,
                        ),
                        label: Text(m['name'] ?? ''),
                        selected: selected,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              selectedUserIds.add(uid);
                            } else {
                              selectedUserIds.remove(uid);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // gọi api update task
                  await updateTask(
                    taskId: task['id'],
                    title: titleController.text,
                    description: descController.text,
                    priority: priority,
                    deadline: deadline?.toIso8601String() ?? '',
                  );

                  // tính user thêm/xóa
                  final added = selectedUserIds.difference(currentAssignees);
                  final removed = currentAssignees.difference(selectedUserIds);

                  if (added.isNotEmpty) {
                    await addAssignees(
                      taskId: task['id'],
                      userIds: added.toList(),
                    );
                  }
                  for (final uid in removed) {
                    await removeAssignee(taskId: task['id'], userId: uid);
                  }

                  if (context.mounted) {
                    Navigator.pop(ctx, true); // đóng dialog và báo cập nhật
                    _tasksFuture;
                  }
                },
                child: const Text('Lưu'),
              ),
            ],
          );
        });
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final canCreateTask = ['owner','admin','manager'].contains( ((groupData?['members'] as List?)?.firstWhere( (m) => m['user_id'] == context.read<AuthProvider>().userId, orElse: () => null )?['role'] as String?)?.toLowerCase() );
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: null,
        title: const Text('Danh sách Tasks'),
        actions: [
          if (canCreateTask)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showCreateTaskDialog,
              tooltip: 'Tạo task mới',
            ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final tasks = snapshot.data ?? [];

          if (tasks.isEmpty) {
            return const Center(child: Text('Không có công việc nào.'));
          }

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final permissions = task['permissions'] ?? {};

              return Card(
                margin:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(task['title'] ?? 'Không tiêu đề'),
                  // thay subtitle bằng Column để hiển thị cả text trạng thái lẫn avatar
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trạng thái: ${task['status'] ?? 0}% • Ưu tiên: ${task['priority'] ?? ''}',
                      ),
                      const SizedBox(height: 4),
                      // hàng avatar người thực hiện
                      Builder(builder: (context) {
                        final assignees = (task['assignees'] as List?) ?? [];
                        // lấy tối đa 3 người đầu
                        final displayCount = 3;
                        final displayed = assignees.take(displayCount).toList();
                        final remaining = assignees.length - displayed.length;

                        return Row(
                          children: [
                            ...displayed.map((a) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: CircleAvatar(
                                  radius: 12, // avatar nhỏ nhỏ
                                  backgroundImage: a['avturl'] != null
                                      ? NetworkImage('${AppConstants.apiBaseUrl}/storage/${a['avturl']}')
                                      : const AssetImage('assets/images/avtUdefault.png') as ImageProvider,
                                  child: a['avturl'] == null
                                      ? Text(
                                    (a['name'] ?? '?')[0].toUpperCase(),
                                    style: const TextStyle(fontSize: 10),
                                  )
                                      : null,
                                ),
                              );
                            }),
                            if (remaining > 0)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text('+$remaining',
                                    style: Theme.of(context).textTheme.bodySmall),
                              ),
                          ],
                        );
                      }),
                    ],
                  ),
                  trailing: permissions['can_edit'] == true
                      ? IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      _showEditTaskDialog(context,task);
                    },
                  )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailPage(task: task, groupId: groupData?['id']),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class FilesTab extends StatefulWidget {
  final int? groupId;
  const FilesTab({super.key, required this.groupId});

  @override
  State<FilesTab> createState() => _FilesTabState();
}

class _FilesTabState extends State<FilesTab> {
  List<Map<String, dynamic>> files = [];
  bool isLoading = false;
  File? selectedFile;
  final TextEditingController fileNameController = TextEditingController();
  final TextEditingController fileDescController = TextEditingController();

  String get token => context.read<AuthProvider>().token ?? '';
  String get baseUrl => AppConstants.apiBaseUrl;

  @override
  void initState() {
    super.initState();
    fetchFiles();
  }

  Future<void> fetchFiles() async {
    if (widget.groupId == null) return;
    setState(() => isLoading = true);
    try {
      final uri = Uri.parse('$baseUrl/api/files/group/${widget.groupId}');
      final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == true) {
          setState(() {
            files = List<Map<String, dynamic>>.from(data['files'] ?? []);
          });
        }
      } else {
        debugPrint('Fetch files failed: ${res.body}');
      }
    } catch (e) {
      debugPrint('Error fetchFiles: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> uploadFile(File file, {String? name, String? description}) async {
    if (widget.groupId == null) return;
    try {
      final uri = Uri.parse('$baseUrl/api/files/upload');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['group_id'] = widget.groupId.toString();
      if (description != null) request.fields['description'] = description;
      if (name != null) request.fields['name'] = name;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == true) {
          fetchFiles();
          if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File đã được tải lên')),
            );
          }
          setState(() {
            selectedFile = null;
            fileNameController.clear();
            fileDescController.clear();
          });
        }
      } else {
        debugPrint('Upload file failed: ${res.body}');
      }
    } catch (e) {
      debugPrint('Error uploadFile: $e');
    }
  }

  void showUploadDialog() {
    selectedFile = null;
    fileNameController.clear();
    fileDescController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setStateDialog) {
            // Lấy tên và extension
            final fileName = selectedFile?.path.split('/').last;
            final extension = fileName != null && fileName.contains('.')
                ? fileName.split('.').last.toLowerCase()
                : null;

            // Chọn icon dựa theo extension
            IconData fileIcon;
            if (extension == 'pdf') {
              fileIcon = Icons.picture_as_pdf;
            } else if (extension == 'doc' || extension == 'docx') {
              fileIcon = Icons.description;
            } else if (extension == 'png' || extension == 'jpg' || extension == 'jpeg') {
              fileIcon = Icons.image;
            } else {
              fileIcon = Icons.insert_drive_file;
            }

            return AlertDialog(
              title: const Text('Tải file lên'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles();
                        if (result != null && result.files.isNotEmpty) {
                          selectedFile = File(result.files.first.path!);
                          fileNameController.text =
                              result.files.first.name.split('.').first; // tên không có ext
                          setStateDialog(() {});
                        }
                      },
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Chọn tệp'),
                    ),

                    // Hiển thị file đã chọn
                    if (selectedFile != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(fileIcon, size: 32),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              fileName ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: fileNameController,
                        decoration: const InputDecoration(labelText: 'Tên file (tùy chọn)'),
                      ),
                      TextField(
                        controller: fileDescController,
                        decoration: const InputDecoration(labelText: 'Mô tả (tùy chọn)'),
                      ),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: selectedFile == null
                      ? null
                      : () async {
                    Navigator.pop(context);
                    await uploadFile(
                      selectedFile!,
                      name: fileNameController.text.trim(),
                      description: fileDescController.text.trim(),
                    );
                  },
                  child: const Text('Tải lên'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Thanh trên cùng giống AppBar
        Material(
          elevation: 2,
          color: Theme.of(context).colorScheme.surface,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.upload_file),
                  tooltip: 'Tải file lên',
                  onPressed: showUploadDialog,
                ),
                const SizedBox(width: 8),
                Text(
                  'Danh sách file',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                // chỗ này có thể thêm các nút khác sau này
              ],
            ),
          ),
        ),

        // Danh sách file
        Expanded(
          child: files.isEmpty
              ? const Center(child: Text('Chưa có tệp đính kèm'))
              : ListView.builder(
            itemCount: files.length,
            itemBuilder: (_, index) {
              final f = files[index];
              return ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: Text(f['name'] ?? 'Tên file'),
                subtitle: Text('${f['size'] ?? ''} bytes'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FileDetailPage(fileUrl: '${AppConstants.apiBaseUrl}/storage/${f['path']}', name: f['name'],), // đường dẫn đầy đủ
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
