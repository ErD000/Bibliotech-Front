import 'package:flutter/material.dart';
import './PDFViewer.dart';
import './book_utils.dart';
import 'dart:io';
import 'package:intl/intl.dart';

// Modern SaaS-style theme colors
const Color primaryColor = Color(0xFF2563EB); // Blue 600
const Color secondaryColor = Color(0xFF1E293B); // Slate 800
const Color accentColor = Color(0xFFF97316); // Orange 500
const Color lightBgColor = Color(0xFFF8FAFC); // Light background
const Color cardBgColor = Color(0xFFFFFFFF);

Widget buildAppBarTitle() {
  return Row(
    children: [
      Icon(Icons.menu_book_rounded, color: Colors.white, size: 30),
      const SizedBox(width: 12),
      const Text(
        'BiblioTech Pro',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
      ),
    ],
  );
}

Widget buildSectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: secondaryColor,
      ),
    ),
  );
}

Widget buildFloatingButtonRow(BuildContext context, Function(String) onFilterChange) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Wrap(
        key: ValueKey(DateTime.now().millisecondsSinceEpoch),
        spacing: 12,
        children: [
          _filterChip('📚 À lire', 'À lire', Colors.orangeAccent, onFilterChange),
          _filterChip('✅ Lu', 'Lu', Colors.green, onFilterChange),
          _filterChip('📊 Progression', 'Progression', Colors.blue, onFilterChange),
          _filterChip('👁️ Voir tout', 'Voir tout', Colors.purple, onFilterChange),
        ],
      ),
    ),
  );
}

Widget _filterChip(String label, String filter, Color color, Function(String) onFilterChange) {
  return Hero(
    tag: filter,
    child: ActionChip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      shape: const StadiumBorder(),
      elevation: 3,
      onPressed: () => onFilterChange(filter),
    ),
  );
}

Widget buildBookCard(BuildContext context, List<Map<String, dynamic>> books,
    int index, StateSetter setState) {
  final book = books[index];
  final isRead = book['isRead'] ?? false;
  final isToRead = book['isToRead'] ?? false;
  final progress = book['progress'] ?? 0.0;
  final dateAdded = book['dateAdded'] != null
      ? DateFormat('dd/MM/yyyy').format(DateTime.parse(book['dateAdded']))
      : 'Date inconnue';

  String badge = 'Nouveau';
  Color badgeColor = Colors.indigo;

  if (isRead) {
    badge = 'Terminé';
    badgeColor = Colors.green.shade600;
  } else if (progress > 0) {
    badge = 'En cours';
    badgeColor = Colors.blue.shade600;
  }

  return AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
    margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
    decoration: BoxDecoration(
      color: cardBgColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 10,
          offset: Offset(0, 4),
        )
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  book['name'],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Chip(
                label: Text(badge, style: const TextStyle(color: Colors.white)),
                backgroundColor: badgeColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            color: primaryColor,
            minHeight: 6,
          ),
          const SizedBox(height: 6),
          Text(
            '${book['pagesRead'] ?? 0} pages lues sur ${book['totalPages'] ?? 100}',
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text('📅 Ajouté le $dateAdded',
              style: const TextStyle(fontSize: 12, color: Colors.black45)),
          const SizedBox(height: 12),
          buildBookActions(context, books, index, setState),
        ],
      ),
    ),
  );
}

Widget buildBookActions(BuildContext context, List<Map<String, dynamic>> books,
    int index, StateSetter setState) {
  final book = books[index];

  return Column(
    children: [
      Row(
        children: [
          _pillButton('À lire', Colors.orange, () async {
            setState(() {
              book['isToRead'] = true;
              book['isRead'] = false;
            });
            await saveBooksStateToStorage(books);
          }),
          const SizedBox(width: 8),
          _pillButton('Lu', Colors.green, () async {
            setState(() {
              book['isRead'] = true;
              book['isToRead'] = false;
            });
            await saveBooksStateToStorage(books);
          }),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          _pillButton('Reprendre', accentColor, () {
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 400),
                pageBuilder: (_, __, ___) => PDFViewerPage(
                  filePath: book['path'],
                  onPageChanged: (current, total) {
                    setState(() {
                      book['pagesRead'] = current ?? 0;
                      book['progress'] = total != null && total > 0
                          ? (current ?? 0) / total
                          : 0.0;
                    });
                  },
                ),
                transitionsBuilder: (_, anim, __, child) => FadeTransition(
                  opacity: anim,
                  child: child,
                ),
              ),
            );
          }),
          const SizedBox(width: 8),
          _pillButton('🗑 Supprimer', Colors.redAccent, () async {
            final file = File(book['path']);
            if (await file.exists()) await file.delete();

            setState(() {
              books.removeAt(index);
            });

            await saveBooksStateToStorage(books);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('📁 Livre supprimé avec succès')),
            );
          }),
        ],
      ),
    ],
  );
}

Widget _pillButton(String label, Color color, VoidCallback onPressed) {
  return Expanded(
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: 2,
        ),
        child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.white)),
      ),
    ),
  );
}