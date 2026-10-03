import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/date_helper.dart';

class AdminLogsScreen extends StatefulWidget {
  const AdminLogsScreen({super.key});

  @override
  State<AdminLogsScreen> createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends State<AdminLogsScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final res = await ApiService().get('/admin/logs.php');
      if (res.data['success'] == true) {
        setState(() {
          _logs = List<Map<String, dynamic>>.from(res.data['logs'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لاگ فعالیت‌ها', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
          : _logs.isEmpty
              ? const Center(
                  child: Text('هنوز لاگی ثبت نشده است', style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _loadLogs,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.history, color: Color(0xFF8B5CF6), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  log['admin_name'] ?? 'ادمین',
                                  style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${log['action']} روی ${log['target_type']} #${log['target_id']}',
                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                            if (log['old_value'] != null && log['old_value'].toString().isNotEmpty)
                              Text(
                                'از: ${log['old_value']} → به: ${log['new_value']}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              DateHelper.toJalaliWithTime(log['created_at']),
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}