import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';
import '../services/api_service.dart';
import '../utils/date_helper.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;
  final String role;

  const ProjectDetailScreen({super.key, required this.project, required this.role});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late Project project;
  bool _isUpdating = false;
  int _adminId = 0;

  final List<String> _rejectReasons = [
    'بودجه کافی نیست',
    'زمان‌بندی مناسب نیست',
    'شرایط فنی فراهم نیست',
    'پروژه خارج از حوزه کاری است',
    'سایر',
  ];

  @override
  void initState() {
    super.initState();
    project = widget.project;
    _loadAdminId();
  }

  Future<void> _loadAdminId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _adminId = prefs.getInt('user_id') ?? 0);
  }

  Future<void> _updateProject(String status, String note,
      {String? rejectReason, String? suggestedPrice}) async {
    setState(() => _isUpdating = true);

    try {
      final params = <String, dynamic>{
        'project_id': project.id,
        'admin_id': _adminId,
        'status': status,
        'admin_note': note,
      };
      if (rejectReason != null) params['reject_reason'] = rejectReason;
      if (suggestedPrice != null) params['suggested_price'] = suggestedPrice;

      final res = await ApiService().get('/admin/change-status.php', params: params);

      if (!mounted) return;
      setState(() => _isUpdating = false);

      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('وضعیت پروژه به‌روزرسانی شد')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطا در به‌روزرسانی')),
      );
    }
  }

  void _showNoteDialog(String status, String dialogTitle,
      {bool showRejectReason = false, bool showPrice = false}) {
    final controller = TextEditingController();
    final priceController = TextEditingController();
    String? selectedReason;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          title: Text(dialogTitle, style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showRejectReason)
                  DropdownButtonFormField<String>(
                    value: selectedReason,
                    decoration: InputDecoration(
                      labelText: 'دلیل رد',
                      filled: true,
                      fillColor: const Color(0xFF050810),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    dropdownColor: const Color(0xFF0F172A),
                    items: _rejectReasons
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (value) => setDialogState(() => selectedReason = value),
                  ),
                if (showPrice) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'قیمت پیشنهادی (تومان)',
                      filled: true,
                      fillColor: const Color(0xFF050810),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'یادداشت خود را بنویسید...',
                    filled: true,
                    fillColor: const Color(0xFF050810),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
            TextButton(
              onPressed: () {
                _updateProject(
                  status,
                  controller.text,
                  rejectReason: selectedReason,
                  suggestedPrice: priceController.text,
                );
                Navigator.pop(context);
              },
              child: const Text('ذخیره'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.role == 'admin';
    final color = isAdmin ? const Color(0xFF8B5CF6) : const Color(0xFF38BDF8);

    return Scaffold(
      appBar: AppBar(
        title: const Text('جزئیات پروژه', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isUpdating
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Color(project.statusColor).withOpacity(0.8),
                        Color(project.statusColor).withOpacity(0.4),
                      ]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(project.title,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 8),
                        if (isAdmin && project.customerName.isNotEmpty)
                          Text('مشتری: ${project.customerName}',
                              style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildInfoRow('وضعیت', project.statusText, Color(project.statusColor)),
                  const SizedBox(height: 12),
                  _buildInfoRow('نوع پروژه', project.type.isEmpty ? 'نامشخص' : project.type, Colors.grey),
                  const SizedBox(height: 12),
                  _buildInfoRow('بودجه', project.budget.isEmpty ? 'نامشخص' : '${project.budget} تومان', Colors.grey),
                  if (project.deadline.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow('تاریخ تحویل', project.deadline, Colors.grey),
                  ],
                  const SizedBox(height: 12),
                  _buildInfoRow('تاریخ ثبت', DateHelper.toJalali(project.createdAt), Colors.grey),
                  if (project.suggestedPrice.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow('قیمت پیشنهادی', '${project.suggestedPrice} تومان', Colors.green),
                  ],
                  if (isAdmin && project.customerPhone.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow('موبایل مشتری', project.customerPhone, Colors.blue),
                  ],
                  const SizedBox(height: 24),
                  const Text('توضیحات',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      project.description.isEmpty ? 'توضیحی ثبت نشده است.' : project.description,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('یادداشت ادمین',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      project.adminNote.isEmpty ? 'هنوز یادداشتی ثبت نشده است.' : project.adminNote,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  if (project.rejectReason.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('دلیل رد',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(project.rejectReason, style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                  const SizedBox(height: 32),
                  if (isAdmin) ...[
                    const Text('اقدامات ادمین',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showNoteDialog('active', 'تایید پروژه'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: const Text('تایید', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showNoteDialog('rejected', 'رد پروژه', showRejectReason: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.close, color: Colors.white),
                            label: const Text('رد', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showNoteDialog('suggested', 'پیشنهاد اصلاحی', showPrice: true),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.purple),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.attach_money, color: Colors.purple),
                        label: const Text('پیشنهاد قیمت', style: TextStyle(color: Colors.purple)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showNoteDialog('active', 'شروع کار'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orange),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.play_arrow, color: Colors.orange),
                        label: const Text('شروع کار', style: TextStyle(color: Colors.orange)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showNoteDialog('ready', 'آماده تحویل'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.blue),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.hourglass_bottom, color: Colors.blue),
                        label: const Text('آماده تحویل', style: TextStyle(color: Colors.blue)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showNoteDialog('done', 'تحویل نهایی'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.green),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.done_all, color: Colors.green),
                        label: const Text('تحویل شده', style: TextStyle(color: Colors.green)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showNoteDialog('cancelled', 'لغو پروژه'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.cancel, color: Colors.grey),
                        label: const Text('لغو شده', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                  ],
                  if (!isAdmin && project.status == 'suggested') ...[
                    const Text('پاسخ به پیشنهاد ادمین',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _respondSuggestion('accept'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: const Text('قبول', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _respondSuggestion('reject'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.close, color: Colors.white),
                            label: const Text('رد', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Future<void> _respondSuggestion(String response) async {
    setState(() => _isUpdating = true);
    try {
      final res = await ApiService().get('/respond_suggestion.php', params: {
        'project_id': project.id,
        'response': response,
      });

      if (!mounted) return;
      setState(() => _isUpdating = false);

      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('پاسخ شما ثبت شد')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isUpdating = false);
    }
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Flexible(
            child: Text(value,
                style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 14),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}