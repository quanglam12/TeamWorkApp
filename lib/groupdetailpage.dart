import 'dart:async';
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
import 'group_dashboard.dart';

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
                  Text(AppLocalizations.of(context)!.editGroup, style: Theme.of(ctx).textTheme.titleLarge),
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
                    label: Text(AppLocalizations.of(context)!.save_changes),
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
            SnackBar(content: Text(AppLocalizations.of(context)!.update_role_success)),
          );
        }
      } else {
        if(context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'])),
          );
        }
      }
    } else {
      if(context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorMessage(response.statusCode.toString()))),
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
                title: Text(isAdmin ? AppLocalizations.of(context)!.manageMembers : AppLocalizations.of(context)!.memberList),
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
                  final String? avtUrl = user['avturl'];

                  ImageProvider<Object> avatarImage;
                  if (avtUrl != null && avtUrl.isNotEmpty) {
                    final String avatarUrl = '${AppConstants.apiBaseUrl}/storage/$avtUrl';
                    avatarImage = NetworkImage(avatarUrl);
                  } else {
                    avatarImage = const AssetImage('assets/images/avtUdefault.png');
                  }

                  return ListTile(
                    leading: CircleAvatar(backgroundImage: avatarImage),
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
                        PopupMenuItem(
                          value: 'changeRole',
                          child: Text(AppLocalizations.of(context)!.change_role),
                        ),
                        PopupMenuItem(
                          value: 'remove',
                          child: Text(AppLocalizations.of(context)!.remove_member),
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
            title: Text(AppLocalizations.of(context)!.add_member),
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
                                      return AppLocalizations.of(context)!.emailRequired;
                                    }
                                    if (!RegExp(r'\S+@\S+\.\S+')
                                        .hasMatch(value)) {
                                      return AppLocalizations.of(context)!.invalidEmail;
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
                                        initialValue: member['role'],
                                        decoration: InputDecoration(
                                          labelText: AppLocalizations.of(context)!.role,
                                          border: OutlineInputBorder(),
                                        ),
                                        items:[
                                          DropdownMenuItem(
                                              value: 'member',
                                              child: Text(AppLocalizations.of(context)!.role_member)),
                                          DropdownMenuItem(
                                              value: 'manager',
                                              child: Text(AppLocalizations.of(context)!.role_manager)),
                                          DropdownMenuItem(
                                              value: 'admin',
                                              child: Text(AppLocalizations.of(context)!.role_admin)),
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
                                      tooltip: AppLocalizations.of(context)!.delete_this_member,
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
                        label: Text(AppLocalizations.of(context)!.add_new_member),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  await addMembers(context, groupId, members);
                  if (context.mounted) Navigator.pop(ctx);
                },
                child: Text(AppLocalizations.of(context)!.add),
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
            SnackBar(content: Text('${AppLocalizations.of(context)!.add_success}: $email')),
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
        SnackBar(content: Text(AppLocalizations.of(context)!.errorMessage(response.statusCode.toString()))),
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
        title:Text(AppLocalizations.of(context)!.confirm_delete),
        content: Text(AppLocalizations.of(context)!.confirm_delete_member_message(userName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.delete),
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
            SnackBar(content: Text(AppLocalizations.of(context)!.delete_member_success)),
          );
        }
        _fetchGroupDetail();
      } else {
        if(context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'])),
          );
        }
      }
    } else {
      if(context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorMessage(response.statusCode.toString()))),
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
          title: Text(AppLocalizations.of(context)!.change_role_for_member(member['user']['name'])),
          content: DropdownButtonFormField<String>(
            initialValue: selectedRole,
            onChanged: (value) {
              selectedRole = value;
            },
            items: [
              DropdownMenuItem(value: 'member', child: Text(AppLocalizations.of(context)!.role_member)),
              DropdownMenuItem(value: 'manager', child: Text(AppLocalizations.of(context)!.role_manager)),
              DropdownMenuItem(value: 'admin', child: Text(AppLocalizations.of(context)!.role_admin)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
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
              child:Text(AppLocalizations.of(context)!.save),
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
          title: Text(AppLocalizations.of(context)!.confirm_delete_group, style: TextStyle(color: Colors.red)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.confirm_delete_group_message),
              SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.enter_confirmation_code_to_delete,
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
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.enter_confirmation_code,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                if (controller.text != confirmationCode) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.invalid_confirmation_code)),
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
                      SnackBar(content: Text(AppLocalizations.of(context)!.group_deleted_successfully)),
                    );
                    Navigator.pop(ctx);
                    if (onDeleted != null) onDeleted();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res['message'])),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.errorMessage(response.statusCode.toString()))),
                  );
                }
              },
              child: Text(AppLocalizations.of(context)!.delete_group),
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
          title: Text(AppLocalizations.of(context)!.confirm_leave_group, style: TextStyle(color: Colors.red)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.confirm_leave_group_message),
              SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.enter_confirmation_code,
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
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.enter_confirmation_code,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                if (controller.text != confirmationCode) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.invalid_confirmation_code)),
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
                      SnackBar(content: Text(AppLocalizations.of(context)!.leave_group_success)),
                    );
                    Navigator.pop(ctx);
                    if (onLeaved != null) onLeaved();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res['message'])),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.errorMessage(response.statusCode.toString()))),
                  );
                }
              },
              child: Text(AppLocalizations.of(context)!.leave_group),
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
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final currentUserId = context.read<AuthProvider>().userId;
    final data = groupData ?? {};
    final isAdmin = data['createdBy']?['id'] == currentUserId || (data['members'] as List<dynamic>).any(
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
          PopupMenuItem(
            value: 'dashboard',
            child: Text(AppLocalizations.of(context)!.dashboard),
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
          PopupMenuItem(
            value: 'dashboard',
            child: Text(AppLocalizations.of(context)!.dashboard),
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
                case 'dashboard':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupStatsScreen(groupData: groupData),
                    ),
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
      body: Column(
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
    return ChatTab(chatId: groupData?['chat_id']);
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
            '${AppLocalizations.of(context)!.description}: ${data['description']}',
            style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 8),

          // Người tạo
          Text(
            '${AppLocalizations.of(context)!.createdBy}: ${data['createdBy']['name']}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),

          // Thống kê thành viên
          Text(
            '${AppLocalizations.of(context)!.total_members}: ${data['members_count']}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Danh sách thành viên
          Text(
            '${AppLocalizations.of(context)!.member_list}:',
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
                      '${AppLocalizations.of(context)!.role}: ${role.replaceFirst(role[0], role[0].toUpperCase())}',
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
            title: Text(AppLocalizations.of(context)!.create_new_task),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.title),
                  ),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.description),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPriority,
                    items: [
                      DropdownMenuItem(value: 'high', child: Text(AppLocalizations.of(context)!.priority_high)),
                      DropdownMenuItem(
                          value: 'medium', child: Text(AppLocalizations.of(context)!.priority_medium)),
                      DropdownMenuItem(value: 'low', child: Text(AppLocalizations.of(context)!.priority_low)),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setStateDialog(() {
                          selectedPriority = val;
                        });
                      }
                    },
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.priority),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedDeadline == null
                              ? AppLocalizations.of(context)!.no_deadline_selected
                              : '${AppLocalizations.of(context)!.deadline}: ${selectedDeadline!.day}/${selectedDeadline!.month}/${selectedDeadline!.year} ${selectedDeadline!.hour.toString().padLeft(2, '0')}:${selectedDeadline!.minute.toString().padLeft(2, '0')}',
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
                        child: Text(AppLocalizations.of(context)!.select_deadline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)!.cancel),
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
                child: Text(AppLocalizations.of(context)!.create),
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
      throw Exception("Can't create task: ${response.body}");
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
        throw Exception(response.body);
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
            title: Text(AppLocalizations.of(context)!.edit_task),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.title),
                  ),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.description),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: priority,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.priority),
                    items: [
                      DropdownMenuItem(value: 'low', child: Text(AppLocalizations.of(context)!.priority_low)),
                      DropdownMenuItem(value: 'medium', child: Text(AppLocalizations.of(context)!.priority_medium)),
                      DropdownMenuItem(value: 'high', child: Text(AppLocalizations.of(context)!.priority_high)),
                    ],
                    onChanged: (val) => setState(() => priority = val!),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppLocalizations.of(context)!.deadline),
                    subtitle: Text(deadline != null
                        ? '${deadline!.day.toString().padLeft(2, '0')}/'
                        '${deadline!.month.toString().padLeft(2, '0')}/'
                        '${deadline!.year} '
                        '${deadline!.hour.toString().padLeft(2, '0')}:'
                        '${deadline!.minute.toString().padLeft(2, '0')}'
                        : AppLocalizations.of(context)!.no_deadline_selected),
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
                  Text(AppLocalizations.of(context)!.task_assignee),
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
                child: Text(AppLocalizations.of(context)!.cancel),
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
                child: Text(AppLocalizations.of(context)!.save),
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
        title: Text(AppLocalizations.of(context)!.task_list),
        actions: [
          if (canCreateTask)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showCreateTaskDialog,
              tooltip: AppLocalizations.of(context)!.create_new_task_action,
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
            return Center(child: Text(AppLocalizations.of(context)!.errorMessage(snapshot.error.toString())));
          }

          final tasks = snapshot.data ?? [];

          if (tasks.isEmpty) {
            return Center(child: Text(AppLocalizations.of(context)!.no_tasks_found));
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
                  title: Text(task['title'] ?? AppLocalizations.of(context)!.no_title),
                  // thay subtitle bằng Column để hiển thị cả text trạng thái lẫn avatar
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppLocalizations.of(context)!.status}: ${task['status'] ?? 0}% • ${AppLocalizations.of(context)!.priority}: ${task['priority'] ?? ''}',
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
              SnackBar(content: Text(AppLocalizations.of(context)!.file_uploaded)),
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
              title: Text(AppLocalizations.of(context)!.upload_file),
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
                      label: Text(AppLocalizations.of(context)!.select_file),
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
                        decoration: InputDecoration(labelText: AppLocalizations.of(context)!.file_name_optional),
                      ),
                      TextField(
                        controller: fileDescController,
                        decoration: InputDecoration(labelText: AppLocalizations.of(context)!.description_optional),
                      ),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.cancel),
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
                  child: Text(AppLocalizations.of(context)!.upload),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String formatBytes(int bytes, int decimals) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
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
                  tooltip: AppLocalizations.of(context)!.upload_file,
                  onPressed: showUploadDialog,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.file_list,
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
              ? Center(child: Text(AppLocalizations.of(context)!.no_attachments))
              : ListView.builder(
            itemCount: files.length,
            itemBuilder: (_, index) {
              final f = files[index];
              return ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: Text(f['name'] ?? 'File name'),
                subtitle: Text(formatBytes(f['size'] ?? 0, 2)),
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
class ChatTab extends StatefulWidget {
  final int chatId;
  const ChatTab({super.key, required this.chatId});

  @override
  ChatTabState createState() => ChatTabState();
}

class ChatTabState extends State<ChatTab> with WidgetsBindingObserver{
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _messages = [];
  final TextEditingController _controller = TextEditingController();
  Timer? _timer;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  bool _ismessolder = false;
  int? _nextBeforeId;

  final int _pageSize = 20;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchMessages();
    _scrollController.addListener(_onScroll);
    // polling 3s/lần (tạm thời)
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchMessages(older: _ismessolder));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _controller.clear();
    _scrollController.dispose();
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling();
    } else {
      _stopPolling();
    }
  }

  void _startPolling() {
    _timer?.cancel(); // Đảm bảo không có timer nào đang chạy
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchMessages(older: _ismessolder));
  }

  void _stopPolling() {
    _timer?.cancel();
  }
  Future<void> _fetchMessages({bool older = false}) async {
    if (older && (_isFetchingMore || !_hasMore)) return;

    setState(() {
      if (older) _isFetchingMore = true;
    });

    final token = context.read<AuthProvider>().token;
    final params = older && _nextBeforeId != null
        ? '?limit=$_pageSize&before_id=$_nextBeforeId'
        : '?limit=$_pageSize';

    final res = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/api/chats/${widget.chatId}/messages$params'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['status'] == true) {
        final newMessages = List<Map<String, dynamic>>.from(data['messages']);
        final meta = data['meta'] ?? {};

        if (older) {
          // giữ offset trước khi prepend
          final oldMaxExtent = _scrollController.position.maxScrollExtent;
          setState(() {
            _messages.insertAll(0, newMessages);
            _hasMore = meta['has_more'] ?? false;
            _nextBeforeId = meta['next_before'];
          });

          // sau khi render xong thì nhảy lại vị trí cũ
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final newMaxExtent = _scrollController.position.maxScrollExtent;
            final delta = newMaxExtent - oldMaxExtent;
            _scrollController.jumpTo(_scrollController.position.pixels + delta);
          });
        } else {
          // load lần đầu
          setState(() {
            _messages = newMessages;
            _hasMore = meta['has_more'] ?? false;
            _nextBeforeId = meta['next_before'];
          });

          // cuộn xuống đáy ngay sau frame render
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
            }
          });
        }
      }
    }

    if (older) {
      setState(() {
        _isFetchingMore = false;
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isFetchingMore || !_hasMore) return;

    // Kích hoạt khi người dùng cuộn gần đến đỉnh của danh sách
    if (_scrollController.position.pixels <=
        _scrollController.position.minScrollExtent + 100) {
      _ismessolder = true;
      _fetchMessages(older: true);
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    _controller.clear();
    if (text.isEmpty) return;

    final token = context.read<AuthProvider>().token;
    final res = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}/api/chats/${widget.chatId}/messages'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({'text': text}),
    );

    if (res.statusCode == 201) {
      _fetchMessages(older: _ismessolder);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().userId;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8),
            itemCount: _messages.length + 1,
            itemBuilder: (context, index) {
              // 1. Đưa logic kiểm tra loader lên đầu, với index = 0
              if (index == 0) {
                if (_isFetchingMore) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (!_hasMore) {
                  return const Center(child: Text("Hết tin nhắn cũ")); // Có thể hiện thông báo
                } else {
                  return const SizedBox.shrink(); // Ẩn đi nếu không làm gì
                }
              }

              // 2. Lấy tin nhắn với index đã được điều chỉnh (index - 1)
              // Vì vị trí 0 đã dành cho loader
              final msg = _messages[index - 1];
              final isMine = msg['sender_id'] == currentUserId;

              return Align(
                alignment:
                isMine ? Alignment.centerRight : Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: isMine
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg['sender']['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      textScaler: TextScaler.linear(0.8),
                    ),
                    Row(
                      mainAxisAlignment: isMine
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        if (!isMine)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: CircleAvatar(
                              backgroundImage:
                              (msg['sender']['avturl'] != null)
                                  ? NetworkImage(
                                  '${AppConstants.apiBaseUrl}/storage/${msg['sender']['avturl']}')
                                  : const AssetImage(
                                  'assets/images/avtUdefault.png')
                              as ImageProvider,
                              radius: 16,
                            ),
                          ),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isMine
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            msg['text'],
                            style: TextStyle(
                              color: isMine
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                )
              ],
            ),
          ),
        )
      ],
    );
  }
}