import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense.dart';
import 'local_db.dart';

class SyncService {
  static Future<void> sync() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Inicia sesión para sincronizar.');
    final expenses = await LocalDb.all();
    for (final e in expenses) {
      await client.from('expenses').upsert({
        'uuid': e.uuid, 'user_id': user.id, 'title': e.title,
        'amount': e.amount, 'category': e.category, 'date': e.date,
        'note': e.note, 'updated_at': e.updatedAt,
      }, onConflict: 'uuid');
    }
    final remote = await client.from('expenses').select().eq('user_id', user.id);
    final db = await LocalDb.db;
    for (final row in remote) {
      final e = Expense(
        uuid: row['uuid'], title: row['title'], amount: (row['amount'] as num).toDouble(),
        category: row['category'], date: row['date'], note: row['note'],
        userId: user.id, updatedAt: row['updated_at'],
      );
      await LocalDb.save(e);
    }
  }
}
