import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/expense.dart';
import 'crypto_service.dart';

class LocalDb {
  static Database? _db;
  static Future<Database> get db async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'finanzapp.db');
    _db = await openDatabase(path, version: 1, onCreate: (d, _) async {
      await d.execute('''
        CREATE TABLE expenses(
          id INTEGER PRIMARY KEY AUTOINCREMENT, uuid TEXT UNIQUE NOT NULL,
          title TEXT NOT NULL, amount REAL NOT NULL, category TEXT NOT NULL,
          date TEXT NOT NULL, note TEXT, receipt_path TEXT, user_id TEXT,
          updated_at TEXT NOT NULL
        )
      ''');
      await d.execute('''
        CREATE TABLE categories(
          id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE NOT NULL, color TEXT
        )
      ''');
      await d.execute('''
        CREATE TABLE budgets(
          id INTEGER PRIMARY KEY AUTOINCREMENT, category TEXT, amount REAL NOT NULL,
          period TEXT NOT NULL, user_id TEXT
        )
      ''');
      for (final c in ['Alimentos','Transporte','Hogar','Salud','Entretenimiento','Otros']) {
        await d.insert('categories', {'name': c, 'color': '607D8B'});
      }
      await d.insert('budgets', {'category': null, 'amount': 5000.0, 'period': 'mensual'});
    });
    return _db!;
  }

  static Future<List<Expense>> all() async {
    final rows = await (await db).query('expenses', orderBy: 'date DESC');
    final result = <Expense>[];
    for (final row in rows) {
      final m = Map<String, dynamic>.from(row);
      m['title'] = await CryptoService.decryptText(m['title'] as String);
      m['category'] = await CryptoService.decryptText(m['category'] as String);
      if (m['note'] != null) m['note'] = await CryptoService.decryptText(m['note'] as String);
      if (m['receipt_path'] != null) m['receipt_path'] = await CryptoService.decryptText(m['receipt_path'] as String);
      result.add(Expense.fromMap(m));
    }
    return result;
  }

  static Future<void> save(Expense e) async {
    final d = await db;
    final m = e.toMap();
    m['title'] = await CryptoService.encryptText(e.title);
    m['category'] = await CryptoService.encryptText(e.category);
    m['note'] = e.note == null ? null : await CryptoService.encryptText(e.note!);
    m['receipt_path'] = e.receiptPath == null ? null : await CryptoService.encryptText(e.receiptPath!);
    if (e.id == null) {
      await d.insert('expenses', m, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await d.update('expenses', m, where: 'id = ?', whereArgs: [e.id]);
    }
  }

  static Future<void> delete(int id) async =>
      (await db).delete('expenses', where: 'id = ?', whereArgs: [id]);

  static Future<double> monthlyBudget() async {
    final rows = await (await db).query('budgets', limit: 1);
    return rows.isEmpty ? 5000 : (rows.first['amount'] as num).toDouble();
  }

  static Future<void> setBudget(double amount) async {
    final d = await db;
    final rows = await d.query('budgets', limit: 1);
    if (rows.isEmpty) {
      await d.insert('budgets', {'category': null, 'amount': amount, 'period': 'mensual'});
    } else {
      await d.update('budgets', {'amount': amount}, where: 'id = ?', whereArgs: [rows.first['id']]);
    }
  }
}
