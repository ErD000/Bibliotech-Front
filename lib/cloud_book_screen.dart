import 'dart:io';  // Ajout de cette importation
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart'; // Pour gérer le téléchargement du fichier
import 'package:path_provider/path_provider.dart'; // Pour accéder au dossier "Téléchargements"
import './book_utils.dart'; // Assurez-vous d'importer book_utils.dart ici
import 'book_list_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CloudBookScreen extends StatefulWidget {
  final Function toggleTheme;

  CloudBookScreen({required this.toggleTheme});

  @override
  _CloudBookScreenState createState() => _CloudBookScreenState();
}

class _CloudBookScreenState extends State<CloudBookScreen> {
  late Future<List<Map<String, dynamic>>> _booksFuture;
  List<Map<String, dynamic>> books = []; // Déclarer books ici pour stocker les livres

  // Fetch the list of books with a GET request
  Future<List<Map<String, dynamic>>> fetchBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception("Token manquant ou invalide.");
    }

    final String url = "http://10.0.6.2:3000/api/get_library";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'token': token,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse is Map<String, dynamic> &&
            jsonResponse['success'] == true) {
          final List<dynamic> library = jsonResponse['library'] ?? [];
          return List<Map<String, dynamic>>.from(library);
        } else {
          throw Exception(
              jsonResponse['message'] ?? 'Échec de la récupération des livres');
        }
      } else {
        throw Exception("Erreur réseau : ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Une erreur est survenue : $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _booksFuture = fetchBooks();
  }

  // Sauvegarder le livre localement dans le répertoire de l'utilisateur
  Future<void> _saveBookLocally(
      String filePath,
      String fileName,
      String userUuid,
      int totalPages,
      ) async {
    final directory = await getApplicationDocumentsDirectory();
    final userDirectory = Directory('${directory.path}/BookShelf/$userUuid');

    // Créer le répertoire utilisateur s'il n'existe pas
    if (!userDirectory.existsSync()) {
      userDirectory.createSync(recursive: true);
      print('[INFO] Répertoire utilisateur créé : ${userDirectory.path}');
    }

    // Définir le chemin local du fichier
    final localFile = File('${userDirectory.path}/$fileName');
    await File(filePath).copy(localFile.path); // Copier le fichier téléchargé dans le répertoire local
    print('[INFO] Fichier copié localement : ${localFile.path}');

    // Mettre à jour l'état avec le livre localement sauvegardé
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
  }

  // Méthode pour télécharger un livre et le sauvegarder localement
  Future<void> downloadBook(String fileUuid, String fileName) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      print("Token manquant ou invalide.");
      return;
    }

    final String url = "http://10.0.6.2:3000/api/download_book";

    try {
      // Obtenir l'UUID de l'utilisateur à partir du token
      final userUuid = extractUserUuidFromToken(token);
      if (userUuid == null) {
        print("UUID de l'utilisateur introuvable.");
        return;
      }

      // Créer une instance de Dio pour le téléchargement
      Dio dio = Dio();
      final downloadDirectory = await getApplicationDocumentsDirectory();
      final downloadPath = '${downloadDirectory.path}/$fileName';

      // Télécharger le fichier
      await dio.download(url, downloadPath, options: Options(headers: {
        'token': token,
        'book_uuid': fileUuid,
        'Content-Type': 'application/json',
      }));

      print("Fichier téléchargé avec succès dans : $downloadPath");

      //TODO
      Fluttertoast.showToast(
        msg: "Livre téléchargé avec succès ! Veuillez rafraîchir la page.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      // Sauvegarder le fichier localement dans le répertoire spécifique à l'utilisateur
      // (en utilisant _saveBookLocally)
      await _saveBookLocally(downloadPath, fileName, userUuid, 100); // Assurez-vous d'ajuster `totalPages`

    } catch (e) {
      print("Erreur lors du téléchargement : $e");
    }
  }
  Future<void> deleteBook(String bookUuid) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      print("Token manquant ou invalide.");
      return;
    }

    final String url = "http://10.0.6.2:3000/api/delete_book";

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': token,
          'book_uuid': bookUuid,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          // Supprimez le livre localement après la confirmation de l'API
          setState(() {
            books.removeWhere((book) => book['fileUUID'] == bookUuid);
          });
          print('Livre supprimé avec succès.');
        } else {
          print('Erreur côté serveur : ${jsonResponse['message']}');
        }
      } else {
        print('Erreur réseau : ${response.statusCode}');
      }
    } catch (e) {
      print("Erreur lors de la suppression : $e");
    }
  }

  // Construire une carte pour chaque livre
  Widget buildBookCard(Map<String, dynamic> book) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(
                book['fileFormat'] == '.pdf' ? Icons.picture_as_pdf : Icons.book,
                color: Colors.deepPurple,
              ),
              title: Text(
                book['fileName'] ?? 'Nom du fichier indisponible',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Dernière ouverture : ${book['lastOpen']?.toString().split('T')[0] ?? 'Non ouvert'}',
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Bouton de téléchargement
                TextButton.icon(
                  onPressed: () {
                    final fileUuid = book['fileUUID'];
                    final fileName = book['fileName'];
                    if (fileUuid != null) {
                      downloadBook(fileUuid, fileName);
                    } else {
                      print("Identifiant de fichier manquant.");
                    }
                  },
                  icon: Icon(Icons.download, color: Colors.green),
                  label: Text("Télécharger"),
                ),
                SizedBox(width: 8),
                // Bouton de suppression (pas encore implémenté)
                TextButton.icon(
                  onPressed: () {
                    final fileUuid = book['fileUUID'];
                    if (fileUuid != null) {
                      deleteBook(fileUuid); // Appel de la fonction deleteBook
                    } else {
                      print("UUID de fichier manquant.");
                    }
                  },
                  icon: Icon(Icons.delete, color: Colors.red),
                  label: Text("Supprimer"),
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
          'Mes livres en Cloud',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>( // Récupérer la liste des livres
        future: _booksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur : ${snapshot.error}',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'Aucun livre disponible.',
                style: TextStyle(fontSize: 18),
              ),
            );
          } else {
            final books = snapshot.data!; // Utilisation des livres récupérés
            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: books.length,
              itemBuilder: (context, index) {
                return buildBookCard(books[index]);
              },
            );
          }
        },
      ),
    );
  }
}
