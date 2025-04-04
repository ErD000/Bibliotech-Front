import 'package:flutter/material.dart';
import './PDFViewer.dart';
import './book_utils.dart';
import 'dart:io'; // Ajoutez ceci pour utiliser la classe File

// Builds the title widget for the app bar
Widget buildAppBarTitle() {
  return Row(
    children: [
      Icon(Icons.menu_book, color: Colors.white, size: 28),
      SizedBox(width: 10),
      Text(
        'BookShelf',
        style: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ],
  );
}

// Builds section titles
Widget buildSectionTitle(String title) {
  return Text(
    title,
    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  );
}

// Builds the row of floating buttons
Widget buildFloatingButtonRow(BuildContext context, Function(String) onFilterChange) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      buildFloatingButton('À lire', Icons.bookmark, Colors.orangeAccent, () {
        onFilterChange('À lire'); // Notifie le changement de filtre
      }),
      buildFloatingButton('Lu', Icons.check_circle, Colors.green, () {
        onFilterChange('Lu');
      }),
      buildFloatingButton('Progression', Icons.analytics, Colors.blue, () {
        onFilterChange('Progression');
      }),
      buildFloatingButton('Voir tout', Icons.visibility, Colors.red, () {
        onFilterChange('Voir tout');
      }),
    ],
  );
}


// Builds a single floating button
Widget buildFloatingButton(String label, IconData icon, Color color,
    VoidCallback onPressed) {
  return Column(
    children: [
      FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: color,
        child: Icon(icon),
      ),
      SizedBox(height: 10),
      Text(label),
    ],
  );
}

// Builds the book card
Widget buildBookCard(BuildContext context, List<Map<String, dynamic>> books,
    int index, StateSetter setState) {
  bool isRead = books[index]['isRead'] ?? false;
  bool isToRead = books[index]['isToRead'] ?? false;
  Color backgroundColor = isToRead
      ? Colors.orange[50]!
      : isRead
      ? Colors.green[50]!
      : Colors.white;

  return Card(
    color: backgroundColor,
    margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  books[index]['name'],
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          LinearProgressIndicator(
            value: books[index]['progress'] ?? 0.0,
            backgroundColor: Colors.grey[300],
            color: Colors.blue,
          ),
          SizedBox(height: 5),
          Text(
            '${books[index]['pagesRead'] ?? 0} pages lues sur ${books[index]['totalPages'] ?? 100}',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          SizedBox(height: 10),
          buildBookActions(context, books, index, setState),
        ],
      ),
    ),
  );
}

// Builds action buttons for the book card
Widget buildBookActions(BuildContext context, List<Map<String, dynamic>> books,
    int index, StateSetter setState) {
  return Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          buildActionButton('À lire', Colors.orange, () async {
            setState(() {
              books[index]['isToRead'] = true;
              books[index]['isRead'] = false;
            });
            await saveBooksStateToStorage(books); // Sauvegarde persistante
          }),
          buildActionButton('Lu', Colors.green, () async {
            setState(() {
              books[index]['isRead'] = true;
              books[index]['isToRead'] = false;
            });
            await saveBooksStateToStorage(books); // Sauvegarde persistante
          }),
        ],
      ),
      SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          buildActionButton('Ouvrir PDF', Colors.blue, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PDFViewerPage(
                  filePath: books[index]['path'],
                  onPageChanged: (current, total) {
                    setState(() {
                      books[index]['pagesRead'] = current ?? 0;
                    });
                  },
                ),
              ),
            );
          }),
          buildActionButton('Supprimer', Colors.red, () async {
            String bookPath = books[index]['path']; // Récupérer le chemin du fichier PDF

            // Supprimer le fichier du stockage local
            final file = File(bookPath);
            if (await file.exists()) {
              await file.delete(); // Supprime le fichier
              print('[INFO] Livre supprimé du stockage : $bookPath');
            }

            // Supprimer le livre de la liste en mémoire
            setState(() {
              if (index >= 0 && index < books.length) {
                books.removeAt(index);
              }
            });

            // Sauvegarder l'état mis à jour dans le stockage persistant (SharedPreferences ou autre)
            await saveBooksStateToStorage(books); // Sauvegarde persistante

            // Optionnel : Ajoutez un message ou une notification pour informer l'utilisateur
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Livre supprimé avec succès')),
            );
          }),
        ],
      ),
    ],
  );
}



// Builds a single action button
Widget buildActionButton(String label, Color color, VoidCallback onPressed) {
  return Expanded(
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color),
      onPressed: onPressed,
      child: Text(label, style: TextStyle(fontSize: 16, color: Colors.white)),
    ),
  );
}
