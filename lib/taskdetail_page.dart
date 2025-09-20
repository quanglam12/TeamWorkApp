import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:teamworkapp/l10n/app_localizations.dart';

import 'constants.dart';
import 'auth_provider.dart';

class TaskDetailPage extends StatefulWidget {
  final Map<String, dynamic> task;
  final int groupId;

  const TaskDetailPage({super.key, required this.task, required this.groupId});

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  // placeholder state
  late Map<String, dynamic> task;
  List<Map<String, dynamic>> comments = [];
  List<Map<String, dynamic>> files = [];
  double? status;
  final String baseUrl = AppConstants.apiBaseUrl;
  String? get token => context.read<AuthProvider>().token;

  bool _isEditingStatus = false;

  File? selectedFile;
  final TextEditingController fileNameController = TextEditingController();
  final TextEditingController fileDescController = TextEditingController();

  @override
  void initState() {
    super.initState();
    task = widget.task;
    status = (task['status'] ?? 0).toDouble();
    fetchComments();
    fetchFiles();
  }

  // Placeholder functions
  Future<void> fetchComments() async {
    try {

      final res = await http.get(
        Uri.parse('$baseUrl/api/tasks/${task['id']}/comments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == true) {
          setState(() {
            comments = List<Map<String, dynamic>>.from(data['comments']);
          });
        }
      } else {
        debugPrint('Fetch comments failed: ${res.body}');
      }
    } catch (e) {
      debugPrint('Error fetchComments: $e');
    }
  }

  Future<void> sendComment(String text) async {
    try {
      final uri = Uri.parse('$baseUrl/api/tasks/${task['id']}/comments');
      final res = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'text': text}),
      );

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        if (data['status'] == true) {
          setState(() {
            _isEditingStatus = true;
          });
          fetchComments();
        }
      } else {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gửi comment thất bại')),
          );
        }
      }
    } catch (e) {
      //debugPrint('Error sendComment: $e');
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gửi comment thất bại: $e')),
        );
      }
    }
  }

  Future<void> fetchFiles() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/files/task/${task['id']}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == true) {
          setState(() {
            files = List<Map<String, dynamic>>.from(data['files']);
          });
        }
      } else {
        debugPrint('Fetch files failed: ${res.body}');
      }
    } catch (e) {
      debugPrint('Error fetchFiles: $e');
    }
  }

  Future<void> updateStatus(double newStatus) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/api/tasks/${task['id']}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': newStatus.toInt()}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == true) {
          debugPrint(data);
          setState(() {
            status = newStatus;
          });
        }
      } else {
        debugPrint('Update status failed: ${res.body}');
      }
    } catch (e) {
      debugPrint('Error updateStatus: $e');
    }
  }

  Future<void> uploadFile(File file, {String? description, String? name}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/files/upload');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['group_id'] = widget.groupId.toString()
        ..fields['task_id'] = task['id'].toString();
      if (description != null) request.fields['description'] = description;
      if (name != null) request.fields['name'] = name;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == true) {
          // cập nhật danh sách file
          setState(() {
            _isEditingStatus = true;
            selectedFile = null;
            fileNameController.clear();
            fileDescController.clear();
          });
          fetchFiles();
        }
      } else {
        debugPrint('Upload file failed: ${res.body}');
      }
    } catch (e) {
      debugPrint('Error uploadFile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignees = (task['assignees'] as List?) ?? [];
    final TextEditingController commentController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text(task['title'] ?? 'Chi tiết công việc'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Priority & Deadline
            Text(
              task['title'] ?? 'Không tiêu đề',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Ưu tiên: ${task['priority'] ?? ''} | '
                  'Hạn: ${task['deadline'] ?? 'Chưa có'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(),

            // Description
            Text(
              AppLocalizations.of(context)!.description,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              task['description'] ?? 'Không có mô tả',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Divider(),

            // Progress / Status
            Text(
              'Tiến độ (${status?.toInt() ?? 0}%)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: status ?? 0,
              min: 0,
              max: 100,
              divisions: 20,
              label: '${status?.toInt() ?? 0}%',
              onChanged: _isEditingStatus
                  ? (v) {
                setState(() => status = v);
              }
                  : null,
            ),
            IconButton(
              icon: Icon(_isEditingStatus ? Icons.lock_open : Icons.lock),
              onPressed: () {
                if (_isEditingStatus) {
                  updateStatus(status!);
                  setState(() {
                    _isEditingStatus = false;
                  });
                }
              },
            ),
            const Divider(),

            // Assignees
            Text(
              'Người thực hiện',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: assignees.map<Widget>((a) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: (a['avturl'] != null)
                          ? NetworkImage('${AppConstants.apiBaseUrl}/storage/${a['avturl']}')
                          : const AssetImage('assets/images/avtUdefault.png')
                      as ImageProvider,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a['name'] ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              }).toList(),
            ),
            const Divider(),

            // Comments
            Text(
              'Bình luận',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            // Hiển thị danh sách comment
            Column(
              children: comments.isEmpty
                  ? [const Text('Chưa có bình luận')]
                  : comments.map((c) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c['user']['name'] ?? 'Ẩn danh'),
                  subtitle: Text(c['text'] ?? ''),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            // Form gửi comment mới (UI placeholder)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      hintText: 'Nhập bình luận...',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => sendComment(commentController.text),
                ),
              ],
            ),
            const Divider(),

            // Files
            Text(
              'Tệp đính kèm',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Column(
              children: files.isEmpty
                  ? [const Text('Chưa có tệp đính kèm')]
                  : files.map((f) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.insert_drive_file),
                  title: Text(f['name'] ?? 'Tên file'),
                  subtitle: Text('${f['size'] ?? ''} bytes'),
                  onTap: () {
                    // TODO: mở file
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles();

                    if (result != null && result.files.isNotEmpty) {
                      debugPrint('FilePicker result: $result');
                      selectedFile = File(result.files.first.path!);
                      // Mặc định tên file gốc
                      fileNameController.text = result.files.first.name.split('.').first;
                      setState(() {});
                    }
                  },
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Chọn tệp'),
                ),
                if (selectedFile != null) ...[
                  TextField(
                    controller: fileNameController,
                    decoration: const InputDecoration(labelText: 'Tên file (tùy chọn)'),
                  ),
                  TextField(
                    controller: fileDescController,
                    decoration: const InputDecoration(labelText: 'Mô tả (tùy chọn)'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (selectedFile == null) return;
                      await uploadFile(
                        selectedFile!,
                        name: fileNameController.text.trim(),
                        description: fileDescController.text.trim(),
                      );
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Tải lên'),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}
