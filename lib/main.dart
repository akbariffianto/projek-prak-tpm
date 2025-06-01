// Path: lib/main.dart
import 'package:flutter/material.dart';
import 'services/hive_service.dart';
import 'pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Disney Character Review App',
      theme: ThemeData(
        // Tema warna yang lebih menarik
        primarySwatch: Colors.deepPurple, // Warna dasar yang kuat
        colorScheme: const ColorScheme.light(
          primary: Colors.deepPurple, // Warna utama
          secondary: Colors.amber, // Warna aksen cerah
          background: Colors.white,
          surface: Colors.white,
          error: Colors.red,
          onPrimary: Colors.white,
          onSecondary: Colors.black, // Kontras dengan warna aksen
          onBackground: Colors.black,
          onSurface: Colors.black,
          onError: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple, // Warna AppBar default
          foregroundColor: Colors.white, // Warna teks dan ikon AppBar
          elevation: 4, // Sedikit shadow
          centerTitle: true, // Judul AppBar di tengah
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8), // Margin default untuk Card
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            backgroundColor: Colors.deepPurple, // Default warna tombol
            foregroundColor: Colors.white, // Default warna teks tombol
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor:
                Colors.deepPurple, // Warna TextButton sesuai primary
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none, // Default tanpa border
          ),
          filled: true,
          fillColor: Colors.grey.shade100, // Warna fill untuk TextField
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintStyle: TextStyle(color: Colors.grey.shade600),
          labelStyle: TextStyle(color: Colors.grey.shade800),
        ),
      ),
      home: const SplashPage(),
    );
  }
}
