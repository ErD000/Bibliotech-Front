import 'dart:convert';
import 'package:bibliotech2/cloud_book_screen.dart';
import 'package:bibliotech2/profile_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './SettingsScreen.dart';
import 'BookListHelpers.dart'; // Import helper functions and widgets
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf; // Préfixe 'sf' pour Syncfusion PDF
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import './book_utils.dart';
import './manual_add_book_screen.dart';
import './stat_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'profile_screen.dart';

class BookListScreen extends StatefulWidget {
  final VoidCallback toggleTheme;

  const BookListScreen({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  _BookListScreenState createState() => _BookListScreenState();
}

bool isMenuVisible = false;

class _BookListScreenState extends State<BookListScreen> {
  List<Map<String, dynamic>> books = []; // Liste dynamique des livres
  String currentFilter = 'Voir tout';

  @override
  void initState() {
    super.initState();
    _initializeBooks();
  }

  // Fonction pour initialiser les livres
  Future<void> _initializeBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token'); // Récupérer le token enregistré

    if (token != null) {
      final userUuid = extractUserUuidFromToken(
          token); // Extraire l'UUID de l'utilisateur à partir du token
      if (userUuid != null) {
        await _loadUserBooks(
            userUuid); // Charger les livres en fonction de l'UUID
        await _loadBooksFromUserDirectory(
            userUuid); // Charger les livres depuis le répertoire local
      }
    }
  }

  // Fonction de filtrage des livres
  List<Map<String, dynamic>> _filteredBooks() {
    switch (currentFilter) {
      case 'À lire':
        return books.where((book) => book['isToRead'] == true).toList();
      case 'Lu':
        return books.where((book) => book['isRead'] == true).toList();
      case 'Progression':
        return books.where((book) =>
        book['progress'] != null && book['progress'] > 0).toList();
      default:
        return books; // Voir tout
    }
  }

  // Fonction de rafraîchissement des livres
  Future<void> _refreshBooks() async {
    setState(() {
      books.clear(); // Efface les livres existants avant de les recharger
    });
    await _initializeBooks(); // Recharge les livres depuis le stockage
  }

  // Charger les livres depuis SharedPreferences
  Future<void> _loadUserBooks(String userUuid) async {
    final prefs = await SharedPreferences.getInstance();

    final booksData = prefs.getString('books_$userUuid');
    if (booksData != null) {
      final List<dynamic> decodedBooks = jsonDecode(booksData);
      setState(() {
        books = decodedBooks.map((book) {
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
      });
      print('[INFO] Livres et statuts restaurés depuis le stockage local.');
    } else {
      print('[INFO] Aucun livre trouvé pour cet utilisateur.');
    }
  }

  // Charger les livres depuis le répertoire local
  Future<void> _loadBooksFromUserDirectory(String userUuid) async {
    final directory = await getApplicationDocumentsDirectory();
    final userDirectory = Directory('${directory.path}/BookShelf/$userUuid');

    if (userDirectory.existsSync()) {
      final List<FileSystemEntity> files = userDirectory.listSync();
      setState(() {
        for (var file in files) {
          if (file is File &&
              (file.path.endsWith('.pdf') || file.path.endsWith('.epub'))) {
            final fileName = file.uri.pathSegments.last;
            books.add({
              'name': fileName,
              'path': file.path,
              'pagesRead': 0,
              'totalPages': 0,
              'progress': 0.0,
              'isRead': false,
              'isToRead': false,
            });
          }
        }
      });
      print('[INFO] Livres chargés depuis le répertoire local : ${userDirectory
          .path}');
    } else {
      print('[INFO] Répertoire utilisateur non trouvé.');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 4,
        title: buildAppBarTitle(),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          // Bouton pour recharger les livres
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Rafraîchir les livres',
            onPressed: _refreshBooks,
          ),
          IconButton(
            icon: Icon(Icons.account_box),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // En-tête du menu à tiroirs
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.black,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Text(
                    'Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'BIBLIOTECH v1.0',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            // Éléments du menu ProfileScreen

            ListTile(
              leading: Icon(Icons.library_books, color: Colors.red),
              title: Text('Ma bibliothèque'),
              onTap: () {
                print("Accéder à Ma bibliothèque");
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.cloud, color: Colors.blue),
              title: Text('Mes livres en ligne'),
              onTap: () {
                print("Accéder à Mes livres en ligne");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CloudBookScreen(toggleTheme: widget.toggleTheme),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.add_box, color: Colors.green),
              title: Text('Mes livres en ajout manuel'),
              onTap: () {
                print("Accéder à Mes livres en ajout manuel");
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ManualBookScreen(toggleTheme: widget.toggleTheme),
                    ));
              },
            ),
            ListTile(
              leading: Icon(Icons.bar_chart, color: Colors.orange),
              title: Text('Mes statistiques'),
              onTap: () {
                print("Accéder à Mes statistiques");
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          StatsScreen(),
                    ));
              },
            ),
            ListTile(
              leading: Icon(Icons.star, color: Colors.black),
              title: Text('Leaderboard'),
              onTap: () {
                print("Accéder au Leaderboard");
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProfilePage(),
                    ));
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSectionTitle('Suivi de lecture'),
                SizedBox(height: 20),
                buildFloatingButtonRow(context, (selectedFilter) {
                  setState(() {
                    currentFilter =
                        selectedFilter; // Met à jour le filtre actif
                  });
                }),
                SizedBox(height: 30),
                buildSectionTitle('Liste des livres'),
                SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredBooks().length,
                    itemBuilder: (context, index) {
                      return buildBookCard(
                          context, _filteredBooks(), index, setState);
                    },
                  ),
                ),
              ],
            ),

            // Floating Action Button et menu animé
            Positioned(
              bottom: 24, // Espacement ajusté
              right: 24,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  // Menu animé
                  AnimatedScale(
                    duration: Duration(milliseconds: 200),
                    scale: isMenuVisible ? 1.0 : 0.0,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              await _addBook();
                              setState(() {
                                isMenuVisible = false; // Ferme le menu
                              });
                            },
                            icon: Icon(
                                Icons.upload_file, color: Colors.deepPurple),
                            label: Text("Téléverser un fichier"),
                          ),
                          Divider(height: 1, color: Colors.grey.shade300),
                          TextButton.icon(
                            onPressed: () async {
                              setState(() {
                                isMenuVisible = false; // Ferme le menu
                              });
                              await _addBookManually();
                            },
                            icon: Icon(Icons.add_box_outlined,
                                color: Colors.deepPurple),
                            label: Text("Ajouter manuellement"),
                          ),
                        ],
                      ),
                    ),
                  ),
                  FloatingActionButton(
                    backgroundColor: Colors.blue,
                    child: Icon(
                      isMenuVisible ? Icons.close : Icons.add,
                      size: 35,
                    ),
                    onPressed: () {
                      setState(() {
                        isMenuVisible =
                        !isMenuVisible; // Bascule l'état du menu
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Ajout manuel d'un livre
  Future<void> _addBookManually() async {
    final filePickerResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'epub'],
    );

    if (filePickerResult != null && filePickerResult.files.isNotEmpty) {
      final filePath = filePickerResult.files.single.path;
      if (filePath != null) {
        // Ici vous pouvez ajouter le fichier manuellement comme vous le souhaitez
        print('Fichier sélectionné : $filePath');
        final fileName = filePickerResult.files.single.name;
        final totalPages = 0; // Vous pouvez calculer ou obtenir le nombre total de pages ici
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        final userUuid = extractUserUuidFromToken(token ?? "");
        if (userUuid != null) {
          await _saveBookLocally(filePath, fileName, userUuid, totalPages);
        }
      }
    }
  }

  // Ajout d'un livre via téléversement
  Future<void> _addBook() async {
    // Sélectionner un fichier
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'epub'],
    );

    if (result != null) {
      // Récupération du chemin du fichier sélectionné
      String filePath = result.files.single.path!;
      String fileName = result.files.single.name;
      int totalPages = 0;

      try {
        final file = File(filePath);
        final bytes = await file.readAsBytes();
        final fileHash = sha1.convert(bytes).toString(); // Hash du fichier

        // Récupérer le token pour l'utilisateur
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token == null) throw Exception('Token not available.');

        // Tentative d'upload du fichier vers le serveur
        final uri = Uri.parse('http://10.0.6.2:3000/api/add_book');
        final request = http.MultipartRequest('POST', uri);
        request.fields['token'] = token;
        request.fields['fileHash'] = fileHash;
        request.files.add(await http.MultipartFile.fromPath('file', filePath));

        final response = await request.send();
        if (response.statusCode == 200) {
          final responseBody = await response.stream.bytesToString();
          final responseData = jsonDecode(responseBody);

          if (responseData['success'] == true) {
            // Si l'upload est réussi, sauvegarde locale et mise à jour de l'interface
            final userUuid = extractUserUuidFromToken(token);
            if (userUuid != null) {
              await _saveBookLocally(filePath, fileName, userUuid, totalPages);
              setState(() {
                currentFilter = 'Voir tout';
              });
              print('Livre téléchargé et sauvegardé avec succès.');
              Fluttertoast.showToast(
                msg: "Livre ajouté avec succès en local ! Uploadé dans le cloud avec succès !",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: Colors.green,
                textColor: Colors.white,
                fontSize: 16.0,
              );
            }
          } else {
            print('Erreur serveur: ${responseData['message']}');
          }
        } else if (response.statusCode == 400) {
          // Si le fichier existe déjà, ajoutez-le à l'interface sans téléverser
          print('Erreur 400: Le livre existe déjà sur le serveur.');
          Fluttertoast.showToast(
            msg: "Le livre existe déjà sur le serveur. Veuillez le télécharger à partir de votre espace cloud !",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
          );

          final directory = await getApplicationDocumentsDirectory();
          final userUuid = extractUserUuidFromToken(token);
          final userDirectory = Directory(
              '${directory.path}/BookShelf/$userUuid');

          final localFile = File('${userDirectory.path}/$fileName');
          if (await localFile.exists()) {
            setState(() {
              books.add({
                'name': fileName,
                'path': localFile.path,
                'pagesRead': 0,
                'totalPages': totalPages,
                'progress': 0.0,
                'isRead': false,
                'isToRead': false,
              });
            });
            print(
                '[INFO] Livre ajouté à l\'interface depuis le stockage local.');
          }
        } else {
          print('Erreur lors de l\'upload: ${response.statusCode}');
        }
      } catch (e) {
        print('Erreur: $e');
      }
    } else {
      print('Aucun fichier sélectionné.');
    }
  }

// Fonction de sauvegarde locale du livre
  Future<void> _saveBookLocally(String filePath, String fileName,
      String userUuid, int totalPages) async {
    final directory = await getApplicationDocumentsDirectory();
    final userDirectory = Directory('${directory.path}/BookShelf/$userUuid');

    // Créer le répertoire si nécessaire
    if (!userDirectory.existsSync()) {
      await userDirectory.create(recursive: true);
    }

    // Copier le fichier dans le répertoire de l'utilisateur
    final newFilePath = '${userDirectory.path}/$fileName';
    final file = File(filePath);
    await file.copy(newFilePath); // Copier le fichier dans le dossier local

    // Ajouter le livre à la liste des livres
    setState(() {
      books.add({
        'name': fileName,
        'path': newFilePath,
        'pagesRead': 0,
        'totalPages': totalPages,
        'progress': 0.0,
        'isRead': false,
        'isToRead': false,
      });
    });

    print('[INFO] Livre enregistré localement : $newFilePath');
  }
}
