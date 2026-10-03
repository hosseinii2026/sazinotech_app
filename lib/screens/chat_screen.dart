import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../utils/date_helper.dart';

class ChatScreen extends StatefulWidget {
  final String role;
  final String contactName;
  final int contactId;

  const ChatScreen({
    super.key,
    required this.role,
    required this.contactName,
    this.contactId = 1,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  int _userId = 0;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('user_id') ?? 0;
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final res = await ApiService().get('/messages.php', params: {
        'action': 'list',
        'user_id': _userId,
        'contact_id': widget.contactId,
      });

      if (res.data['success'] == true) {
        final List<dynamic> data = res.data['messages'] ?? [];
        setState(() {
          _messages = data.map((e) => Map<String, dynamic>.from(e)).toList();
          _isLoading = false;
        });
        _scrollToBottom();
        await ApiService().get('/mark_read.php', params: {
          'user_id': _userId,
          'contact_id': widget.contactId,
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final text = _messageController.text.trim();
    _messageController.clear();

    try {
      await ApiService().get('/messages.php', params: {
        'action': 'send',
        'sender_id': _userId,
        'receiver_id': widget.contactId,
        'message': text,
      });

      setState(() {
        _messages.add({
          'sender_id': _userId,
          'receiver_id': widget.contactId,
          'message': text,
          'created_at': DateTime.now().toIso8601String(),
        });
      });
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطا در ارسال پیام')),
      );
    }
  }

  Future<void> _pickFile(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      XFile? file = await picker.pickImage(source: source);
      if (file == null) return;
      await _uploadAndSend(File(file.path));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطا در انتخاب فایل')),
      );
    }
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.single.path == null) return;
      await _uploadAndSend(File(result.files.single.path!));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطا در انتخاب فایل')),
      );
    }
  }

  Future<void> _uploadAndSend(File file) async {
    setState(() => _isUploading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final res = await ApiService().uploadFile('/upload.php', file, token);

      if (res.data['success'] == true) {
        final fileUrl = res.data['file_url'];
        final fileType = res.data['file_type'];

        await ApiService().get('/send_message_file.php', params: {
          'sender_id': _userId,
          'receiver_id': widget.contactId,
          'message': '',
          'file_url': fileUrl,
          'file_type': fileType,
        });

        setState(() {
          _messages.add({
            'sender_id': _userId,
            'receiver_id': widget.contactId,
            'message': '',
            'file_url': fileUrl,
            'file_type': fileType,
            'created_at': DateTime.now().toIso8601String(),
          });
        });
        _scrollToBottom();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطا در آپلود فایل')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo, color: Color(0xFF38BDF8)),
              title: const Text('گالری', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickFile(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF38BDF8)),
              title: const Text('دوربین', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickFile(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file, color: Color(0xFF38BDF8)),
              title: const Text('فایل', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickDocument();
              },
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
        title: Text(widget.contactName, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              showSearch(context: context, delegate: MessageSearchDelegate(_messages));
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
                : _messages.isEmpty
                    ? const Center(
                        child: Text('هنوز پیامی ارسال نشده است',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg['sender_id'] == _userId;
                          return _buildMessageBubble(msg, isMe, color);
                        },
                      ),
          ),
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: LinearProgressIndicator(color: Color(0xFF38BDF8)),
            ),
          _buildInputBar(color),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe, Color color) {
    final fileUrl = msg['file_url'];
    final fileType = msg['file_type'];
    final isRead = msg['is_read'] == 1;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? color.withOpacity(0.8) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
          border: isMe ? null : Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fileUrl != null && fileUrl.isNotEmpty) _buildFilePreview(fileUrl, fileType),
            if (msg['message'] != null && msg['message'].toString().isNotEmpty)
              Text(
                msg['message'],
                style: TextStyle(color: isMe ? Colors.white : Colors.white70, fontSize: 14),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateHelper.toJalaliWithTime(msg['created_at']),
                  style: TextStyle(color: isMe ? Colors.white54 : Colors.grey, fontSize: 10),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: isRead ? Colors.blue : Colors.white54,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview(String fileUrl, String? fileType) {
    if (fileType == 'jpg' || fileType == 'jpeg' || fileType == 'png' || fileType == 'gif') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          fileUrl,
          width: 200,
          height: 150,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.attach_file, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text('فایل ضمیمه', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInputBar(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.grey),
            onPressed: _showAttachmentOptions,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'پیام خود را بنویسید...',
                filled: true,
                fillColor: const Color(0xFF050810),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: color,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

class MessageSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> messages;
  MessageSearchDelegate(this.messages);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = messages
        .where((m) => (m['message'] ?? '').toString().toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(results[index]['message'] ?? ''),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = messages
        .where((m) => (m['message'] ?? '').toString().toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(results[index]['message'] ?? ''),
      ),
    );
  }
}