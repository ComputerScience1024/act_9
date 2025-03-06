import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'card_organizer.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create Folders table
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create Cards table
    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        suit TEXT NOT NULL,
        image_url TEXT NOT NULL,
        folder_id INTEGER,
        FOREIGN KEY (folder_id) REFERENCES folders (id) ON DELETE CASCADE
      )
    ''');

    // Insert default folders
    await db.insert('folders', {'name': 'Hearts'});
    await db.insert('folders', {'name': 'Spades'});
    await db.insert('folders', {'name': 'Diamonds'});
    await db.insert('folders', {'name': 'Clubs'});

    // Prepopulate cards
    await _populateCards(db);
  }

  Future<void> _populateCards(Database db) async {
    List<String> suits = ['Hearts', 'Spades', 'Diamonds', 'Clubs'];
    List<String> cardNames = [
      'Ace', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King'
    ];

    for (String suit in suits) {
      // Get the folder ID for the current suit
      List<Map<String, dynamic>> folder =
          await db.query('folders', where: 'name = ?', whereArgs: [suit]);
      int folderId = folder.first['id'];

      for (String name in cardNames) {
        String imageUrl = 'assets/cards/${name.toLowerCase()}_of_${suit.toLowerCase()}.png';
        await db.insert('cards', {
          'name': name,
          'suit': suit,
          'image_url': imageUrl,
          'folder_id': folderId,
        });
      }
    }
  }
}
