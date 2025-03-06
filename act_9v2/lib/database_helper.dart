import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "card_organizer.db";
  static const _databaseVersion = 2; // Incremented for schema updates

  static final DatabaseHelper instance = DatabaseHelper._internal();
  factory DatabaseHelper() => instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _createTriggers(db);
    await _insertDefaultData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createTriggers(db);
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        suit TEXT NOT NULL,
        image_url TEXT NOT NULL,
        folder_id INTEGER NOT NULL,
        FOREIGN KEY (folder_id) REFERENCES folders (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createTriggers(Database db) async {
    // Prevent adding more than 6 cards to a folder
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS enforce_folder_limit
      BEFORE INSERT ON cards
      WHEN (SELECT COUNT(*) FROM cards WHERE folder_id = NEW.folder_id) >= 6
      BEGIN
        SELECT RAISE(ABORT, 'Folder can only hold 6 cards');
      END;
    ''');

    // Prevent deleting cards if the folder has fewer than 3 cards
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS prevent_folder_deletion
      BEFORE DELETE ON cards
      WHEN (SELECT COUNT(*) FROM cards WHERE folder_id = OLD.folder_id) <= 3
      BEGIN
        SELECT RAISE(ABORT, 'You need at least 3 cards in this folder');
      END;
    ''');
  }

  Future<void> _insertDefaultData(Database db) async {
    List<String> suits = ['Hearts', 'Spades', 'Diamonds', 'Clubs'];
    for (String suit in suits) {
      await db.insert('folders', {'name': suit}, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    List<Map<String, String>> cards = [
      {'name': 'Ace', 'suit': 'Diamonds', 'image_url': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/21/01_of_diamonds_A.svg/154px-01_of_diamonds_A.svg.png'},
      {'name': '10', 'suit': 'Diamonds', 'image_url': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ae/10_of_diamonds_-_David_Bellot.svg/154px-10_of_diamonds_-_David_Bellot.svg.png'},
      {'name': '5', 'suit': 'Diamonds', 'image_url': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2e/05_of_diamonds.svg/154px-05_of_diamonds.svg.png'},
      {'name': 'Queen', 'suit': 'Diamonds', 'image_url': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/00/Queen_of_diamonds_fr.svg/154px-Queen_of_diamonds_fr.svg.png'},

      {'name': 'Ace', 'suit': 'Hearts', 'image_url': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fc/01_of_hearts_A.svg/144px-01_of_hearts_A.svg.png'},
      {'name': 'King', 'suit': 'Hearts', 'image_url': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/King_of_hearts_fr.svg/144px-King_of_hearts_fr.svg.png'},
      {'name': '4', 'suit': 'Hearts', 'image_url': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/26/04_of_hearts.svg/144px-04_of_hearts.svg.png'},
      {'name': '9', 'suit': 'Hearts', 'image_url': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e7/09_of_hearts.svg/144px-09_of_hearts.svg.png'},

      {'name': '8', 'suit': 'Clubs', 'image_url': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/88/08_of_clubs.svg/185px-08_of_clubs.svg.png'},
      {'name': 'Jack', 'suit': 'Clubs', 'image_url': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/df/Jack_of_clubs_fr.svg/185px-Jack_of_clubs_fr.svg.png'},
      {'name': '5', 'suit': 'Clubs', 'image_url': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ac/05_of_clubs.svg/185px-05_of_clubs.svg.png'},
      {'name': '6', 'suit': 'Clubs', 'image_url': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/be/06_of_clubs.svg/185px-06_of_clubs.svg.png'},

      {'name': 'Ace', 'suit': 'Spades', 'image_url': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/01_of_spades_A.svg/185px-01_of_spades_A.svg.png'},
      {'name': 'Queen', 'suit': 'Spades', 'image_url': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/06/Queen_of_spades_fr.svg/185px-Queen_of_spades_fr.svg.png'},
      {'name': '3', 'suit': 'Spades', 'image_url': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/62/03_of_spades.svg/185px-03_of_spades.svg.png'},
      {'name': '4', 'suit': 'Spades', 'image_url': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7a/04_of_spades.svg/185px-04_of_spades.svg.png'},
    ];

    for (var card in cards) {
      List<Map<String, dynamic>> folder = await db.query('folders', where: 'name = ?', whereArgs: [card['suit']]);
      if (folder.isNotEmpty) {
        int folderId = folder.first['id'];
        await db.insert('cards', {
          'name': card['name'],
          'suit': card['suit'],
          'image_url': card['image_url'],
          'folder_id': folderId,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
  }
}
