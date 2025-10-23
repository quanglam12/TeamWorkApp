import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import 'auth_provider.dart';
import 'constants.dart';
import 'package:flutter_markdown/flutter_markdown.dart';


class GroupStatsScreen extends StatefulWidget {
  final Map<String, dynamic>? groupData;

  const GroupStatsScreen({super.key, required this.groupData});

  @override
  State<GroupStatsScreen> createState() => _GroupStatsScreenState();
}

class _GroupStatsScreenState extends State<GroupStatsScreen> {
  bool isLoading = true;
  List<dynamic> tasks = [];

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    final token = context.read<AuthProvider>().token;
    final groupId = widget.groupData?['id'];

    final url = Uri.parse(
      '${AppConstants.apiBaseUrl}/api/tasks?group_id=$groupId',
    );

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == true) {
        setState(() {
          tasks = data['tasks'] ?? [];
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  String summarizeLogs(Map<String, dynamic> logsData) {
    final buffer = StringBuffer();
    final userStats = <String, Map<String, int>>{};

    logsData.forEach((taskId, data) {
      final task = data['task'] ?? {};
      final logs = List<Map<String, dynamic>>.from(data['logs'] ?? []);

      final title = task['title'] ?? 'Không có tiêu đề';
      final desc = task['description'] ?? '';
      final status = task['status'] ?? 0;
      final priority = task['priority'] ?? 'unknown';
      final deadline = task['deadline'] ?? 'Không có hạn';

      // Đếm loại hành động
      int updateCount = 0;
      int commentCount = 0;
      final users = <String>{};

      for (final log in logs) {
        final action = log['action'] ?? '';
        final userName = log['user']?['name'] ?? 'Ẩn danh';
        users.add(userName);

        if (action == 'updated_status') updateCount++;
        if (action == 'comment_added') commentCount++;

        // Ghi nhận thống kê tổng hợp cho từng user
        userStats.putIfAbsent(userName, () => {
          'updates': 0,
          'comments': 0,
          'tasks': 0,
        });
        if (action == 'updated_status') {
          userStats[userName]!['updates'] =
            (userStats[userName]!['updates'] ?? 0) + 1;
        }
        if (action == 'comment_added') {
          userStats[userName]!['comments'] =
            (userStats[userName]!['comments'] ?? 0) + 1;
        }
      }

      // Ghi nhận số task người dùng tham gia
      for (final u in users) {
        userStats[u]!['tasks'] = (userStats[u]!['tasks'] ?? 0) + 1;
      }

      // Gộp nội dung tóm tắt từng task
      buffer.writeln('---');
      buffer.writeln('Task: $title');
      buffer.writeln('Mô tả: $desc');
      buffer.writeln('Ưu tiên: $priority');
      buffer.writeln('Hạn: $deadline');
      buffer.writeln('Tiến độ: $status%');
      buffer.writeln('Thành viên: ${users.join(", ")}');
      buffer.writeln('Cập nhật: $updateCount lần, Bình luận: $commentCount lần');
    });

    // Tổng hợp cuối cùng cho từng người dùng
    buffer.writeln('\nTổng hợp hoạt động:');
    userStats.forEach((user, stats) {
      buffer.writeln(
          '- $user: ${stats['tasks']} task, ${stats['updates']} cập nhật, ${stats['comments']} bình luận');
    });

    return buffer.toString();
  }



  Future<void> _evaluateWithAI() async {
    BuildContext? dialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final token = context.read<AuthProvider>().token;
      final taskIds = tasks.map((t) => t['id']).toList();
      // --- Gọi API Laravel lấy logs ---
      final url = Uri.parse('${AppConstants.apiBaseUrl}/api/task-logs/by-tasks');
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'task_ids': taskIds,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Không thể lấy dữ liệu task logs (HTTP ${response.statusCode})");
      }

      final logsData = jsonDecode(response.body);
      final summary = summarizeLogs(logsData);
      print(summary);
      // --- Chuẩn bị prompt ---
      final prompt = '''
Bạn là chuyên gia đánh giá hiệu suất làm việc nhóm.
Dựa vào tóm tắt dữ liệu bên dưới, hãy:
1. Đánh giá tiến độ chung của nhóm
2. Nhận xét mức độ chủ động của từng thành viên
3. Đề xuất cải thiện (cụ thể nhưng ngắn gọn)

Dữ liệu:
$summary
''';

      // --- Gọi Groq API ---
      final aiResponse = await http.post(
        Uri.parse(AppConstants.groqApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${dotenv.env['GROQ_API_KEY']}',
        },
        body: jsonEncode({
          "model": "llama-3.1-8b-instant",
          "input": prompt,
        }),
      ).timeout(const Duration(minutes: 2));

      if(context.mounted) {
        if (dialogContext != null && Navigator.canPop(dialogContext!)) {
          Navigator.pop(dialogContext!);
        }
      }
      if (aiResponse.statusCode == 200) {
        final result = jsonDecode(aiResponse.body);
        // --- Xử lý dữ liệu phản hồi từ Groq / LocalAI ---
        final outputList = result['output'] as List?;
        String aiText = 'Không có phản hồi';

        if (outputList != null && outputList.isNotEmpty) {
          final messagePart = outputList.firstWhere(
                (item) => item['type'] == 'message',
            orElse: () => null,
          );
          if (messagePart != null) {
            final contentList = messagePart['content'] as List?;
            if (contentList != null && contentList.isNotEmpty) {
              aiText = contentList
                  .firstWhere(
                    (c) => c['type'] == 'output_text',
                orElse: () => null,
              )?['text'] ??
                  'Không có phản hồi';
            }
            print(result);
          }
        }

        // --- Hiển thị hộp thoại theo theme ---
        if (mounted) {
          final theme = Theme.of(context);
          final textTheme = theme.textTheme;

          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.analytics_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text("Đánh giá của AI", style: textTheme.titleMedium),
                ],
              ),
              content: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  // Hiển thị Markdown (đậm, danh sách, v.v.)
                  child: MarkdownBody(
                    data: aiText,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                      p: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                      strong: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      listBullet: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton.icon(
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text("Sao chép"),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: aiText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Đã sao chép nội dung")),
                    );
                  },
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Đóng"),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception("AI trả về lỗi: ${aiResponse.body}");
      }
    } catch (e) {
      if(context.mounted) {
        if (dialogContext != null && Navigator.canPop(dialogContext!)) {
          Navigator.pop(dialogContext!);
        }
        if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e")),
        );
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // --- Thống kê ---
    final totalTasks = tasks.length;
    final notStarted = tasks.where((t) => t['status'] == 0).length;
    final inProgress = tasks.where((t) => t['status']! > 0 && t['status']! < 100).length;
    final completed = tasks.where((t) => t['status'] == 100).length;

    // tiến độ trung bình
    final avgProgress = totalTasks > 0
        ? tasks.map((t) => t['status'] as int).reduce((a, b) => a + b) / totalTasks
        : 0;

    // thống kê theo priority
    final high = tasks.where((t) => t['priority'] == 'high').length;
    final medium = tasks.where((t) => t['priority'] == 'medium').length;
    final low = tasks.where((t) => t['priority'] == 'low').length;

    return Scaffold(
      appBar: AppBar(
        title: Text("Thống kê - ${widget.groupData?['name']}"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Thông tin nhóm ---
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (widget.groupData?['avturl'] != null && widget.groupData!['avturl'].isNotEmpty)
                        ? NetworkImage("${AppConstants.apiBaseUrl}/storage/${widget.groupData!['avturl']}")
                        : null,
                    child: (widget.groupData?['avturl'] == null || widget.groupData!['avturl'].isEmpty)
                        ? Image.asset(
                      'assets/images/avtGdefault.png',
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                title: Text(widget.groupData?['name'] ?? ''),
                subtitle: Text("Thành viên: ${widget.groupData?['members_count']}"),
              ),
            ),

            const SizedBox(height: 20),

            // --- Biểu đồ tiến độ ---
            Text("Tiến độ công việc (Trung bình: ${avgProgress.toStringAsFixed(1)}%)",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 200, child: _ProgressPieChart()),

            const SizedBox(height: 20),

            // --- Thống kê trạng thái ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBox("Tổng", totalTasks, Colors.blue),
                _buildStatBox("Chưa bắt đầu", notStarted, Colors.grey),
                _buildStatBox("Đang làm", inProgress, Colors.orange),
                _buildStatBox("Hoàn thành", completed, Colors.green),
              ],
            ),

            const SizedBox(height: 20),

            // --- Thống kê priority ---
            Text("Theo mức độ ưu tiên", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBox("Cao", high, Colors.red),
                _buildStatBox("Trung bình", medium, Colors.yellow[700]!),
                _buildStatBox("Thấp", low, Colors.green),
              ],
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.smart_toy_outlined),
              label: const Text("Đánh giá bằng AI"),
              onPressed: _evaluateWithAI,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, int value, Color color) {
    return Column(
      children: [
        Text(value.toString(),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label),
      ],
    );
  }
}

// Widget demo biểu đồ tròn (có thể tinh chỉnh theo tasks thực tế)
class _ProgressPieChart extends StatelessWidget {
  const _ProgressPieChart();

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(value: 40, color: Colors.green, title: "HT"),
          PieChartSectionData(value: 30, color: Colors.orange, title: "ĐL"),
          PieChartSectionData(value: 30, color: Colors.grey, title: "CBĐ"),
        ],
      ),
    );
  }
}
