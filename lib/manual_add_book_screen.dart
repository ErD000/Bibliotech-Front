import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'book_utils.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ManualBookScreen extends StatefulWidget {
  final Function toggleTheme;

  ManualBookScreen({required this.toggleTheme});
//testcomment
  @override
  _ManualBookScreenState createState() => _ManualBookScreenState();
}

class _ManualBookScreenState extends State<ManualBookScreen> {
  final List<Map<String, dynamic>> _manualBooks = [];
  late String? _token;

  @override
  void initState() {
    super.initState();
    _initializeManualBooks();
  }

  String? _extractUserUuidFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = utf8.decode(base64.decode(base64.normalize(parts[1])));
      final data = jsonDecode(payload);
      return data['user_uuid'] as String?;
    } catch (e) {
      print('[ERROR] Failed to extract user UUID: $e');
      return null;
    }
  }

  // Calcul des totaux après chargement des livres
  Future<void> _initializeManualBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      final userUuid = _extractUserUuidFromToken(token);
      if (userUuid != null) {
        final books = await loadManualBooks(userUuid);
        setState(() {
          _manualBooks.addAll(books);
          // Met à jour les totaux après chargement des livres
          _updateTotalPages();
        });
      }
    } else {
      print('[ERROR] Token not found.');
    }
  }

  Future<void> _saveBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      final userUuid = _extractUserUuidFromToken(token);
      if (userUuid != null) {
        await saveManualBooks(_manualBooks, userUuid);
      } else {
        print('[ERROR] User UUID not found, cannot save books.');
      }
    } else {
      print('[ERROR] Token not found, cannot save books.');
    }
  }

  // Nouvelle méthode pour enregistrer les pages lues dans SharedPreferences
  Future<void> _savePagesRead(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final book = _manualBooks[index];
    final key = 'pagesRead_${book['title']}';
    await prefs.setInt(key, book['pagesRead']);

    // Met à jour le total des pages lues dans SharedPreferences
    final totalPagesRead = _calculateTotalPagesRead();
    await prefs.setInt('totalPagesRead', totalPagesRead);
  }

  // Méthode pour calculer le total des pages lues
  int _calculateTotalPagesRead() {
    return _manualBooks.fold(0, (sum, book) => sum + (book['pagesRead'] as int));
  }

  // Méthode pour calculer le total des pages des livres
  int _calculateTotalBookPages() {
    final totalBookPages = _manualBooks.fold(0, (sum, book) => sum + (book['totalPages'] as int));
    return totalBookPages;
  }

  // Nouvelle méthode pour mettre à jour les totaux
  void _updateTotalPages() async {
    final totalPagesRead = _calculateTotalPagesRead();
    final totalBookPages = _calculateTotalBookPages();

    final prefs = await SharedPreferences.getInstance();

    // Enregistrer les totaux dans SharedPreferences
    await prefs.setInt('totalPagesRead', totalPagesRead);
    await prefs.setInt('totalBookPages', totalBookPages);

    setState(() {
      // Recalculer et mettre à jour l'affichage des totaux dans l'interface utilisateur
      print('Total pages read: $totalPagesRead, Total book pages: $totalBookPages');
    });
  }

  // Lors de l'ajout d'un livre, recalculer les totaux et mettre à jour SharedPreferences
  Future<void> _addManualBook() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final coverImage = File(pickedFile.path);
      final totalPagesController = TextEditingController();
      final titleController = TextEditingController();

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Ajouter un nouveau livre', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Titre du livre',
                  labelStyle: TextStyle(fontSize: 18),
                ),
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 10),
              TextField(
                controller: totalPagesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nombre de pages',
                  labelStyle: TextStyle(fontSize: 18),
                ),
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler', style: TextStyle(color: Colors.redAccent)),
            ),
            TextButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    totalPagesController.text.isNotEmpty &&
                    int.tryParse(totalPagesController.text) != null) {
                  setState(() {
                    _manualBooks.add({
                      'title': titleController.text,
                      'coverImage': coverImage,
                      'addedDate': DateTime.now(),
                      'pagesRead': 0,
                      'totalPages': int.parse(totalPagesController.text),
                      'note': '',
                      'status': 'À lire',
                    });
                    _updateTotalPages(); // Recalculer les totaux après ajout
                  });

                  _saveBooks();
                } else {
                  print('[ERROR] Invalid input for totalPages');
                }
                Navigator.pop(context);
              },
              child: Text('Ajouter', style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      );
    }
  }

  // Méthode de suppression mise à jour
  void _deleteBook(int index) {
    setState(() {
      _manualBooks.removeAt(index);
      _updateTotalPages(); // Recalculer les totaux après suppression
    });
    Fluttertoast.showToast(
      msg: "Le livre à bien été supprimé !",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
    _saveBooks();
  }

  // Lors de la modification d'un livre, recalculer les totaux
  void _editBook(int index) {
    final book = _manualBooks[index];
    final noteController = TextEditingController(text: book['note']);
    final pagesReadController = TextEditingController(text: book['pagesRead'].toString());

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Edit Book', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(
                controller: pagesReadController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Pages Read'),
                onChanged: (value) {
                  setState(() {
                    book['pagesRead'] = int.tryParse(value) ?? 0;
                  });
                  _savePagesRead(index); // Enregistrer les pages lues
                  _updateTotalPages(); // Recalculer les totaux
                },
              ),
              TextField(
                controller: noteController,
                maxLength: 50,
                decoration: InputDecoration(labelText: 'Note'),
                onChanged: (value) {
                  book['note'] = value;
                },
              ),
              DropdownButton<String>(
                value: book['status'],
                items: ['À lire', 'Lu']
                    .map((status) => DropdownMenuItem<String>(value: status, child: Text(status)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    book['status'] = value!;
                  });
                },
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                  _saveBooks();
                  _updateTotalPages(); // Recalculer les totaux après modification
                  Navigator.pop(context);
                },
                child: Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildManualBookCard(Map<String, dynamic> book, int index) {
    return Card(
      elevation: 8,
      margin: EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                book['coverImage'] != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    book['coverImage'],
                    width: 80,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                )
                    : Icon(Icons.book, size: 80, color: Colors.deepPurple),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book['title'],
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      Text(
                        'Ajouté le : ${book['addedDate'].toString().split(' ')[0]}',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pages lues: ${book['pagesRead']}/${book['totalPages']}'),
                Text('Statut: ${book['status']}'),
              ],
            ),
            if (book['note'] != null && book['note']!.isNotEmpty) SizedBox(height: 8),
            Text('Note: ${book['note']}', style: TextStyle(fontStyle: FontStyle.italic)),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _editBook(index),
                  child: Text('Editer', style: TextStyle(color: Colors.blue)),
                ),
                TextButton(
                  onPressed: () => _deleteBook(index),
                  child: Text('Supprimer', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Mes Livres Physiques',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [


          // Affichage des livres
          Expanded(
            child: _manualBooks.isEmpty
                ? Center(child: Text('Pas de livres ici.', style: TextStyle(fontSize: 18)))
                : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _manualBooks.length,
              itemBuilder: (context, index) => _buildManualBookCard(_manualBooks[index], index),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addManualBook,
        backgroundColor: Colors.redAccent,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
