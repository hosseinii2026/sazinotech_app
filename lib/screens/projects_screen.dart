import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';
import '../services/api_service.dart';
import 'project_detail_screen.dart';
import 'add_project_screen.dart';
import '../utils/date_helper.dart';

class ProjectsScreen extends StatefulWidget {
  final String role;
  const ProjectsScreen({super.key, required this.role});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<Project> _projects = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _statusFilter = '';
  String _sortBy = 'id';
  String _sortOrder = 'DESC';
  final _searchController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final isAdmin = widget.role == 'admin';
      final path = isAdmin ? '/admin/projects.php' : '/projects.php';
      final params = <String, dynamic>{
        'sort_by': _sortBy,
        'sort_order': _sortOrder,
      };
      if (_searchQuery.isNotEmpty) params['search'] = _searchQuery;
      if (_statusFilter.isNotEmpty) params['status'] = _statusFilter;
      if (_budgetMinController.text.isNotEmpty) params['budget_min'] = _budgetMinController.text;
      if (_budgetMaxController.text.isNotEmpty) params['budget_max'] = _budgetMaxController.text;

      final res = await ApiService().get(path, params: params);

      if (res.data['success'] == true) {
        final List<dynamic> data = res.data['projects'] ?? [];
        setState(() {
          _projects = data.map((e) => Project.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'خطا در دریافت پروژه‌ها';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'خطا در ارتباط با سرور';
        _isLoading = false;
      });
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('فیلترها',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _statusFilter.isEmpty ? null : _statusFilter,
              decoration: InputDecoration(
                labelText: 'وضعیت',
                filled: true,
                fillColor: const Color(0xFF050810),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              dropdownColor: const Color(0xFF0F172A),
              items: const [
                DropdownMenuItem(value: '', child: Text('همه')),
                DropdownMenuItem(value: 'ready', child: Text('در انتظار تایید')),
                DropdownMenuItem(value: 'active', child: Text('در حال انجام')),
                DropdownMenuItem(value: 'done', child: Text('تحویل شده')),
                DropdownMenuItem(value: 'rejected', child: Text('رد شده')),
                DropdownMenuItem(value: 'suggested', child: Text('پیشنهاد اصلاحی')),
                DropdownMenuItem(value: 'cancelled', child: Text('لغو شده')),
              ],
              onChanged: (value) => setState(() => _statusFilter = value ?? ''),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _budgetMinController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'بودجه از',
                      filled: true,
                      fillColor: const Color(0xFF050810),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _budgetMaxController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'بودجه تا',
                      filled: true,
                      fillColor: const Color(0xFF050810),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _sortBy,
              decoration: InputDecoration(
                labelText: 'مرتب‌سازی بر اساس',
                filled: true,
                fillColor: const Color(0xFF050810),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              dropdownColor: const Color(0xFF0F172A),
              items: const [
                DropdownMenuItem(value: 'id', child: Text('جدیدترین')),
                DropdownMenuItem(value: 'title', child: Text('عنوان')),
                DropdownMenuItem(value: 'budget', child: Text('بودجه')),
                DropdownMenuItem(value: 'created_at', child: Text('تاریخ')),
              ],
              onChanged: (value) => setState(() => _sortBy = value ?? 'id'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _statusFilter = '';
                        _budgetMinController.clear();
                        _budgetMaxController.clear();
                        _sortBy = 'id';
                      });
                    },
                    child: const Text('پاک کردن'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _loadProjects();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8)),
                    child: const Text('اعمال'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
        title: Text(isAdmin ? 'مدیریت پروژه‌ها' : 'پروژه‌های من',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onPressed: _showFilterSheet,
            ),
        ],
      ),
      body: Column(
        children: [
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                onSubmitted: (value) {
                  setState(() => _searchQuery = value);
                  _loadProjects();
                },
                decoration: InputDecoration(
                  hintText: 'جستجو...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('❌ $_error', style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: _loadProjects, child: const Text('تلاش مجدد')),
                          ],
                        ),
                      )
                    : _projects.isEmpty
                        ? const Center(
                            child: Text('پروژه‌ای یافت نشد',
                                style: TextStyle(color: Colors.grey, fontSize: 16)))
                        : RefreshIndicator(
                            onRefresh: _loadProjects,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _projects.length,
                              itemBuilder: (context, index) =>
                                  _buildProjectCard(context, _projects[index], color, isAdmin),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: !isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddProjectScreen())),
              backgroundColor: color,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('پروژه جدید', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  Widget _buildProjectCard(BuildContext context, Project project, Color color, bool isAdmin) {
    return Dismissible(
      key: Key(project.id.toString()),
      direction: isAdmin ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('حذف پروژه'),
            content: const Text('آیا مطمئن هستید؟'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
            ],
          ),
        );
      },
      onDismissed: (direction) => _deleteProject(project.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Color(project.statusColor),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(project.title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      if (isAdmin && project.customerName.isNotEmpty)
                        Text('مشتری: ${project.customerName}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Color(project.statusColor).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(project.statusText,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Color(project.statusColor),
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Text(DateHelper.toJalali(project.createdAt),
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ProjectDetailScreen(project: project, role: widget.role))),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: color.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: Text('جزئیات', style: TextStyle(color: color)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteProject(int projectId) async {
    final prefs = await SharedPreferences.getInstance();
    final adminId = prefs.getInt('user_id') ?? 0;
    await ApiService().get('/admin/delete_project.php', params: {
      'project_id': projectId,
      'admin_id': adminId,
    });
    _loadProjects();
  }
}