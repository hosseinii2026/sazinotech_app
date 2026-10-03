import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _loginController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  String? _error;

  Future<void> _submit() async {
    if (_loginController.text.trim().isEmpty) {
      setState(() => _error = 'ایمیل یا موبایل را وارد کنید');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _message = null;
    });

    try {
      final res = await ApiService().get('/forgot_password.php', params: {
        'login': _loginController.text.trim(),
      });

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (res.data['success'] == true) {
        setState(() => _message = res.data['message']);
      } else {
        setState(() => _error = res.data['message'] ?? 'خطا در ارسال درخواست');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'خطا در ارتباط با سرور';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF38BDF8);

    return Scaffold(
      appBar: AppBar(
        title: const Text('فراموشی رمز عبور', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.lock_reset, size: 80, color: color),
              const SizedBox(height: 20),
              const Text('بازیابی رمز عبور',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 40),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text('❌ $_error', style: const TextStyle(color: Colors.red)),
                ),
              if (_message != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Text('✅ $_message', style: const TextStyle(color: Colors.green)),
                ),
              TextField(
                controller: _loginController,
                decoration: InputDecoration(
                  hintText: 'ایمیل یا شماره موبایل',
                  prefixIcon: const Icon(Icons.email),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('ارسال لینک بازیابی', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}