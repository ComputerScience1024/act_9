import 'package:flutter/material.dart';
import 'database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper().database; // Ensure database is initialized
  runApp(MaterialApp(
    home: FoldersScreen(),
  ));
}

class FoldersScreen extends StatefulWidget {
  @override
  _FoldersScreenState createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> folders = [];

  final Map<String, String> folderImages = {
    'Hearts': 'assets/Heart.png',
    'Spades': 'assets/Spade.png',
    'Diamonds': 'assets/Diamond.png',
    'Clubs': 'assets/Club.png',
  };

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final db = await dbHelper.database;
    List<Map<String, dynamic>> fetchedFolders = await db.query('folders');

    List<Map<String, dynamic>> folderWithCounts = [];
    for (var folder in fetchedFolders) {
      int count = (await db.rawQuery(
        'SELECT COUNT(*) as count FROM cards WHERE folder_id = ?',
        [folder['id']]
      ))[0]['count'] as int;

      folderWithCounts.add({
        'id': folder['id'],
        'name': folder['name'],
        'count': count,
        'image': folderImages[folder['name']] ?? 'assets/default.png',
      });
    }

    setState(() {
      folders = folderWithCounts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Folders')),
      body: folders.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: folders.length,
              itemBuilder: (context, index) {
                final folder = folders[index];
                return ListTile(
                  leading: Image.asset(folder['image'], width: 50, height: 50),
                  title: Text(folder['name']),
                  subtitle: Text('${folder['count']} cards'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CardsScreen(folderId: folder['id'], folderName: folder['name']),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class CardsScreen extends StatefulWidget {
  final int folderId;
  final String folderName;

  CardsScreen({required this.folderId, required this.folderName});

  @override
  _CardsScreenState createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> cards = [];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final db = await dbHelper.database;
    List<Map<String, dynamic>> fetchedCards = await db.query(
      'cards',
      where: 'folder_id = ?',
      whereArgs: [widget.folderId],
    );

    setState(() {
      cards = fetchedCards;
    });
  }

  void _showAddCardDialog() {
    String cardName = '';
    String cardImageUrl = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Card'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Card Name'),
                onChanged: (value) => cardName = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Image URL'),
                onChanged: (value) => cardImageUrl = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (cardName.isNotEmpty && cardImageUrl.isNotEmpty) {
                  await dbHelper.insertCard(cardName, widget.folderName, cardImageUrl, widget.folderId);
                  _loadCards();
                  Navigator.pop(context);
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditCardDialog(Map<String, dynamic> card) {
    String newName = card['name'];
    String newImageUrl = card['image_url'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Card'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Card Name'),
                onChanged: (value) => newName = value,
                controller: TextEditingController(text: card['name']),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Image URL'),
                onChanged: (value) => newImageUrl = value,
                controller: TextEditingController(text: card['image_url']),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await dbHelper.updateCard(card['id'], newName, widget.folderName, newImageUrl, widget.folderId);
                _loadCards();
                Navigator.pop(context);
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCard(int cardId) async {
    await dbHelper.deleteCard(cardId);
    _loadCards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.folderName} Cards')),
      body: cards.isEmpty
          ? Center(child: Text('No cards available'))
          : GridView.builder(
              padding: EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(card['image_url'], width: 80, height: 80, errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.image_not_supported, size: 80);
                      }),
                      SizedBox(height: 10),
                      Text(card['name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditCardDialog(card),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteCard(card['id']),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: _showAddCardDialog,
      ),
    );
  }
}
