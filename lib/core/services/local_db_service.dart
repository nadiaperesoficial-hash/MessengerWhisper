import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'whisper_messages.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          create table messages (
            id text primary key,
            chat_id text not null,
            sender_id text not null,
            content text,
            type text,
            media_url text,
            created_at text not null,
            read_at text
          )
        ''');
        await db.execute('create index idx_chat_id on messages(chat_id)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('alter table messages add column read_at text');
        }
      },
    );
  }

  Future<void> insertMessage(Map<String, dynamic> message) async {
    final db = await _database;
    await db.insert(
      'messages',
      {
        'id': message['id'],
        'chat_id': message['chat_id'],
        'sender_id': message['sender_id'],
        'content': message['content'],
        'type': message['type'],
        'media_url': message['media_url'],
        'created_at': message['created_at'],
        'read_at': message['read_at'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> markMessageRead(String messageId, String readAt) async {
    final db = await _database;
    await db.update(
      'messages',
      {'read_at': readAt},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<List<Map<String, dynamic>>> fetchMessages(String chatId) async {
    final db = await _database;
    return db.query(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'created_at ASC',
    );
  }

  Future<void> deleteChatHistory(String chatId) async {
    final db = await _database;
    await db.delete('messages', where: 'chat_id = ?', whereArgs: [chatId]);
  }
}
