import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "card_organizer.db";
  static const _databaseVersion = 1;

  static const tableFolders = 'folders';
  static const tableCards = 'cards';

  static const columnId = 'id';
  static const columnName = 'name';
  static const columnSuit = 'suit';
  static const columnImageUrl = 'image_url';
  static const columnFolderId = 'folder_id';
  static const columnCreatedAt = 'created_at';

  late Database _db;

  /// Initializes the database
  Future<void> init() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    _db = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  /// Creates tables and constraints
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableFolders (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnName TEXT UNIQUE NOT NULL,
        $columnCreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableCards (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnName TEXT NOT NULL,
        $columnSuit TEXT NOT NULL,
        $columnImageUrl TEXT NOT NULL,
        $columnFolderId INTEGER NOT NULL,
        FOREIGN KEY ($columnFolderId) REFERENCES $tableFolders ($columnId) ON DELETE CASCADE
      )
    ''');

    await _createTriggers(db);
    await _insertDefaultData(db);
  }

  /// Creates triggers to enforce folder limits
  Future<void> _createTriggers(Database db) async {
    // Prevent adding more than 6 cards to a folder
    await db.execute('''
      CREATE TRIGGER enforce_folder_limit
      BEFORE INSERT ON $tableCards
      WHEN (SELECT COUNT(*) FROM $tableCards WHERE $columnFolderId = NEW.$columnFolderId) >= 6
      BEGIN
        SELECT RAISE(ABORT, 'Folder can only hold 6 cards');
      END;
    ''');

    // Prevent deleting cards if the folder has fewer than 3 cards
    await db.execute('''
      CREATE TRIGGER prevent_folder_deletion
      BEFORE DELETE ON $tableCards
      WHEN (SELECT COUNT(*) FROM $tableCards WHERE $columnFolderId = OLD.$columnFolderId) <= 3
      BEGIN
        SELECT RAISE(ABORT, 'You need at least 3 cards in this folder');
      END;
    ''');
  }

  /// Inserts default folders and prepopulates cards
  Future<void> _insertDefaultData(Database db) async {
    List<String> suits = ['Hearts', 'Spades', 'Diamonds', 'Clubs'];
    List<String> cardNames = [
      'Ace', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King'
    ];

    for (String suit in suits) {
      int folderId = await db.insert(tableFolders, {columnName: suit});

      for (String name in cardNames) {
        String imageUrl = 'assets/cards/${name.toLowerCase()}_of_${suit.toLowerCase()}.png';
        await db.insert(tableCards, {
          columnName: name,
          columnSuit: suit,
          columnImageUrl: imageUrl,
          columnFolderId: folderId,
        });
      }
    }
  }

  /// Fetches all folders
  Future<List<Map<String, dynamic>>> getFolders() async {
    return await _db.query(tableFolders);
  }

  /// Fetches all cards in a specific folder
  Future<List<Map<String, dynamic>>> getCardsByFolder(int folderId) async {
    return await _db.query(tableCards, where: '$columnFolderId = ?', whereArgs: [folderId]);
  }

  /// Inserts a new card (enforces folder limit)
  Future<void> insertCard(String name, String suit, String imageUrl, int folderId) async {
    try {
      await _db.insert(tableCards, {
        columnName: name,
        columnSuit: suit,
        columnImageUrl: imageUrl,
        columnFolderId: folderId,
      });
    } catch (e) {
      throw Exception("Error adding card: ${e.toString()}");
    }
  }

  /// Deletes a card
  Future<void> deleteCard(int cardId) async {
    await _db.delete(tableCards, where: '$columnId = ?', whereArgs: [cardId]);
  }

  /// Closes the database connection
  Future<void> closeDatabase() async {
    _db.close();
  }
}
