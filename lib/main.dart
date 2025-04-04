import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import './SettingsScreen.dart';
import './PDFViewer.dart';
import './book_list_screen.dart';
import './LoginScreen.dart';
import './RegisterScreen.dart';

void main() {
  runApp(MyBookApp());
}

class MyBookApp extends StatefulWidget {
  @override
  _MyBookAppState createState() => _MyBookAppState();
}

class _MyBookAppState extends State<MyBookApp> {
  // Gestion du thème
  ThemeData _themeData = ThemeData.light();

  void _toggleTheme() {
    setState(() {
      _themeData = _themeData.brightness == Brightness.dark
          ? ThemeData.light()
          : ThemeData.dark();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BookShelf',
      theme: _themeData,
      home: BookListScreen(toggleTheme: () {  }, //LoginScreen

      ),
      routes: {
        '/bookList': (context) => BookListScreen(toggleTheme: _toggleTheme),
        '/login': (context) => LoginScreen(),

        //'/settings': (context) => SettingsScreen(toggleTheme: _toggleTheme),
      },
    );
  }
}
