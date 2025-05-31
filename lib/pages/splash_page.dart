// Path: lib/pages/splash_page.dart
import 'package:flutter/material.dart';
import '../services/hive_service.dart';
import 'login_page.dart';
import 'home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final userId = await HiveService().getUserSession();
    if (userId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary, // Latar belakang sesuai primary color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Kamu bisa tambahkan logo atau ikon di sini
            Icon(
              Icons.stars, // Contoh ikon
              size: 100,
              color: Theme.of(context).colorScheme.secondary, // Warna aksen
            ),
            const SizedBox(height: 20),
            Text(
              'Disney Character Hub',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary, // Warna teks yang kontras
              ),
            ),
            const SizedBox(height: 30),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary), // Warna progress indicator
            ),
          ],
        ),
      ),
    );
  }
}