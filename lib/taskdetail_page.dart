import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:teamworkapp/l10n/app_localizations.dart';

import 'constants.dart';
import 'auth_provider.dart';
import 'filedetail_page.dart';

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
  double? aiSuggestedStatus;
  final String baseUrl = AppConstants.apiBaseUrl;
  String? get token => context.read<AuthProvider>().token;

  bool _isEditingStatus = false;

  File? selectedFile;
  final TextEditingController fileNameController = TextEditingController();
  final TextEditingController fileDescController = TextEditingController();
  bool _isLoadingAI = false;

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
          await predictAIProgress(comment: text);
          setState(() {
            _isEditingStatus = true;
          });
          fetchComments();
        }
      } else {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.send_comment_failed)),
          );
        }
      }
    } catch (e) {
      //debugPrint('Error sendComment: $e');
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.send_comment_failed}: $e')),
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
          setState(() {
            aiSuggestedStatus = null;
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
          await predictAIProgress(file: file);
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

  Future<void> predictAIProgress({String? comment, File? file}) async {
    setState(() {
      _isLoadingAI = true;
    });
    try {
      final aiUri = Uri.parse('${AppConstants.urlPython}/predict');
      final aiPayload = {
        'current_status': status?.toInt() ?? 0,
        'comment': comment ?? '',
        'priority': task['priority'] ?? 'Normal',
        'days_to_deadline': task['days_to_deadline'] ?? 0,
        'file_path': file?.path ?? '',
        'file_size_mb': file != null ? (await file.length()) / 1024 / 1024 : 0,
      };

      final aiRes = await http.post(
        aiUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(aiPayload),
      );

      if (aiRes.statusCode == 200) {
        final pred = jsonDecode(aiRes.body)['predicted_status'];
        setState(() {
          aiSuggestedStatus = pred;
          status = pred;
        });
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('AI gợi ý tiến độ: ${pred.toStringAsFixed(1)}%')),
          );
        }
      }
    } catch (e) {
      debugPrint('AI prediction failed: $e');
    }
    setState(() {
      _isLoadingAI = false;
    });
  }


  String formatBytes(int bytes, int decimals) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }
  @override
  Widget build(BuildContext context) {
    final assignees = (task['assignees'] as List?) ?? [];
    final TextEditingController commentController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text(task['title'] ?? AppLocalizations.of(context)!.task_details),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Priority & Deadline
            Text(
              task['title'] ?? AppLocalizations.of(context)!.no_title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              '${AppLocalizations.of(context)!.priority}: ${task['priority'] ?? ''} | '
                  '${AppLocalizations.of(context)!.deadline}: ${task['deadline'] ?? AppLocalizations.of(context)!.no_deadline_selected}',
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
              task['description'] ?? AppLocalizations.of(context)!.no_description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Divider(),

            // Progress / Status
            Text(
              '${AppLocalizations.of(context)!.progress} (${status?.toInt() ?? 0}%)',
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
            if (aiSuggestedStatus != null)
              Text(
                'AI gợi ý: ${aiSuggestedStatus!.toStringAsFixed(1)}%',
                style: TextStyle(color: Colors.blueAccent),
              ),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(_isEditingStatus ? Icons.lock_open : Icons.lock),
                  onPressed: () async {
                    if (_isEditingStatus) {
                      setState(() {
                        _isLoadingAI = true;
                      });

                      await updateStatus(status!);

                      setState(() {
                        _isEditingStatus = false;
                        _isLoadingAI = false;
                      });
                    }
                  },
                ),

                // Hiển thị loading nhỏ khi đang gọi AI
                if (_isLoadingAI)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(),

            // Assignees
            Text(
              AppLocalizations.of(context)!.assignee,
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
              AppLocalizations.of(context)!.comments,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            // Hiển thị danh sách comment
            Column(
              children: comments.isEmpty
                  ? [Text(AppLocalizations.of(context)!.no_comments)]
                  : comments.map((c) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c['user']['name'] ?? 'No Name'),
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
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.comment_placeholder,
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
              AppLocalizations.of(context)!.attachments,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Column(
              children: files.isEmpty
                  ? [Text(AppLocalizations.of(context)!.no_attachments)]
                  : files.map((f) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.insert_drive_file),
                  title: Text(f['name'] ?? 'File Name'),
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
              }).toList(),
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles();

                    if (result != null && result.files.isNotEmpty) {
                      //debugPrint('FilePicker result: $result');
                      selectedFile = File(result.files.first.path!);
                      // Mặc định tên file gốc
                      fileNameController.text = result.files.first.name.split('.').first;
                      setState(() {});
                    }
                  },
                  icon: const Icon(Icons.attach_file),
                  label:Text(AppLocalizations.of(context)!.select_file),
                ),
                if (selectedFile != null) ...[
                  TextField(
                    controller: fileNameController,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.file_name_optional),
                  ),
                  TextField(
                    controller: fileDescController,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.description_optional),
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
                    label: Text(AppLocalizations.of(context)!.upload),
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
