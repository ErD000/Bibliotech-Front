import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PDFViewerPage extends StatefulWidget {
  final String filePath;
  final void Function(int? current, int? total) onPageChanged; // Accepter des valeurs nullable

  PDFViewerPage({required this.filePath, required this.onPageChanged});

  @override
  _PDFViewerPageState createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  late PDFViewController _controller;
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Viewer'),
      ),
      body: PDFView(
        filePath: widget.filePath,
        onPageChanged: (int? current, int? total) {  // Modifier les types des paramètres
          setState(() {
            _currentPage = current ?? 0;  // Gérer le cas où `current` peut être nul
            widget.onPageChanged(current, total); // Passer les deux paramètres
          });
        },
      ),
    );
  }
}