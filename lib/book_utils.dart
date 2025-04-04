import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Extrait le user_uuid à partir du token JWT
String? extractUserUuidFromToken(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    final payload = utf8.decode(base64.decode(base64.normalize(parts[1])));
    final data = jsonDecode(payload);
    return data['user_uuid'] as String?;
  } catch (e) {
    print('[ERREUR] Impossible d\'extraire le user_uuid : $e');
    return null;
  }
}

/// Charge les livres de l'utilisateur à partir du stockage local
Future<List<Map<String, dynamic>>> loadUserBooks(String token) async {
  try {
    final userUuid = extractUserUuidFromToken(token);
    if (userUuid == null) {
      print('[ERREUR] Impossible de récupérer les livres, user_uuid introuvable.');
      return [];
    }

    final directory = await getApplicationDocumentsDirectory();
    final userDirectory = Directory('${directory.path}/BookShelf/$userUuid');
    print('USER DIRECTORY : ');
    print(userDirectory);
    if (!userDirectory.existsSync()) {
      print('[INFO] Aucun répertoire trouvé pour cet utilisateur.');
      return [];
    }

    final books = userDirectory
        .listSync()
        .whereType<File>()
        .map((file) {
      return {
        'name': file.uri.pathSegments.last,
        'path': file.path,
        'pagesRead': 0,
        'totalPages': 0,
        'progress': 0.0,
      };
    })
        .toList();

    return books;
  } catch (e) {
    print('[ERREUR] Échec du chargement des livres : $e');
    return [];
  }
}

Future<void> saveBooksStateToStorage(List<Map<String, dynamic>> books) async {
  final prefs = await SharedPreferences.getInstance();

  // Sauvegarder les livres en tant que JSON
  final token = prefs.getString('token');
  if (token == null) {
    print('[ERREUR] Token manquant, sauvegarde impossible.');
    return;
  }

  final userUuid = extractUserUuidFromToken(token);
  if (userUuid == null) {
    print('[ERREUR] User UUID manquant, sauvegarde impossible.');
    return;
  }

  final booksData = books.map((book) {
    return {
      'name': book['name'],
      'path': book['path'],
      'pagesRead': book['pagesRead'],
      'totalPages': book['totalPages'],
      'progress': book['progress'],
      'isRead': book['isRead'] ?? false,
      'isToRead': book['isToRead'] ?? false,
    };
  }).toList();

  await prefs.setString('books_$userUuid', jsonEncode(booksData));
  print('[INFO] État des livres sauvegardé.');
}
/// Save manually added books to SharedPreferences
Future<void> saveManualBooks(List<Map<String, dynamic>> books, String userUuid) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final booksData = books.map((book) {
      return {
        'title': book['title'],
        'coverImage': book['coverImage']?.path, // Save path to image file
        'addedDate': book['addedDate'].toIso8601String(),
        'pagesRead': book['pagesRead'],
        'totalPages': book['totalPages'],
        'note': book['note'],
        'status': book['status'],
      };
    }).toList();

    await prefs.setString('manualBooks_$userUuid', jsonEncode(booksData));
    print('[INFO] Manual books saved successfully.');
  } catch (e) {
    print('[ERROR] Failed to save manual books: $e');
  }
}

/// Load manually added books from SharedPreferences
Future<List<Map<String, dynamic>>> loadManualBooks(String userUuid) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final storedBooks = prefs.getString('manualBooks_$userUuid') ?? '[]'; // Use default if null
    final bookList = List<Map<String, dynamic>>.from(jsonDecode(storedBooks));

    return bookList.map((book) {
      return {
        ...book,
        'coverImage': book['coverImage'] != null ? File(book['coverImage']) : null,
        'addedDate': DateTime.parse(book['addedDate']),
      };
    }).toList();
  } catch (e) {
    print('[ERROR] Failed to load manual books: $e');
    return [];
  }
}

Future<void> _deleteBookFile(String filePath) async {
  try {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete(); // Delete the file from the local directory
      print('[INFO] Fichier supprimé de la mémoire locale : $filePath');
    } else {
      print('[ERREUR] Fichier non trouvé : $filePath');
    }
  } catch (e) {
    print('[ERREUR] Impossible de supprimer le fichier : $e');
  }
}