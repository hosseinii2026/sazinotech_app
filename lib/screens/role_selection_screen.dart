import 'package:flutter/material.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF050810)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 100,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.business, size: 100, color: Color(0xFF38BDF8));
                  },
                ),
                const SizedBox(height: 20),
                const Text('سازینوتک',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                const SizedBox(height: 60),
                _buildRoleButton(
                  context,
                  '👤 ورود مشتری',
                  'ورود به پنل مشتری',
                  const Color(0xFF38BDF8),
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen(role: 'customer'))),
                ),
                const SizedBox(height: 20),
                _buildRoleButton(
                  context,
                  '👑 ورود ادمین',
                  'ورود به پنل مدیریت',
                  const Color(0xFF8B5CF6),
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen(role: 'admin'))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(BuildContext context, String title, String subtitle, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
          ],
        ),
      ),
    );
  }
}