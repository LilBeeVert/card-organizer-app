import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // DATABASE GETTER
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('card_organizer.db');
    return _database!;
  }

  // INIT DATABASE
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // CREATE TABLES
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE folders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        folder_name TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cards(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_name TEXT NOT NULL,
        suit TEXT NOT NULL,
        image_url TEXT,
        folder_id INTEGER NOT NULL,
        FOREIGN KEY (folder_id) REFERENCES folders(id)
          ON DELETE CASCADE
      )
    ''');

    await _prepopulateFolders(db);
    await _prepopulateCards(db);
  }

  // PREPOPULATE FOLDERS
  Future<void> _prepopulateFolders(Database db) async {
    const folders = ['Hearts', 'Diamonds', 'Clubs', 'Spades'];

    for (String suit in folders) {
      await db.insert('folders', {
        'folder_name': suit,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  // PREPOPULATE CARDS
  Future<void> _prepopulateCards(Database db) async {
    const suits = ['Hearts', 'Diamonds', 'Clubs', 'Spades'];
    const cardNames = [
      'Ace',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      'Jack',
      'Queen',
      'King'
    ];

    for (int i = 0; i < suits.length; i++) {
      for (String card in cardNames) {
        await db.insert('cards', {
          'card_name': card,
          'suit': suits[i],
          'image_url':
              'https://deckofcardsapi.com/static/img/${_generateCardCode(card, suits[i])}.png',
          'folder_id': i + 1,
        });
      }
    }
  }

  // HELPER: Generate Card Code
  String _generateCardCode(String card, String suit) {
    String suitLetter;

    switch (suit) {
      case 'Hearts':
        suitLetter = 'H';
        break;
      case 'Diamonds':
        suitLetter = 'D';
        break;
      case 'Clubs':
        suitLetter = 'C';
        break;
      case 'Spades':
        suitLetter = 'S';
        break;
      default:
        suitLetter = 'S';
    }

    String value;

    switch (card) {
      case 'Ace':
        value = 'A';
        break;
      case 'Jack':
        value = 'J';
        break;
      case 'Queen':
        value = 'Q';
        break;
      case 'King':
        value = 'K';
        break;
      default:
        value = card;
    }

    return '$value$suitLetter';
  }
}
