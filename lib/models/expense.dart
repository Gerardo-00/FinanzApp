class Expense {
  final int? id;
  final String uuid;
  final String title;
  final double amount;
  final String category;
  final String date;
  final String? note;
  final String? receiptPath;
  final String? userId;
  final String updatedAt;

  const Expense({
    this.id, required this.uuid, required this.title, required this.amount,
    required this.category, required this.date, this.note, this.receiptPath,
    this.userId, required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'uuid': uuid, 'title': title, 'amount': amount,
    'category': category, 'date': date, 'note': note,
    'receipt_path': receiptPath, 'user_id': userId, 'updated_at': updatedAt,
  };

  factory Expense.fromMap(Map<String, dynamic> m) => Expense(
    id: m['id'] as int?, uuid: m['uuid'] as String,
    title: m['title'] as String, amount: (m['amount'] as num).toDouble(),
    category: m['category'] as String, date: m['date'] as String,
    note: m['note'] as String?, receiptPath: m['receipt_path'] as String?,
    userId: m['user_id'] as String?, updatedAt: m['updated_at'] as String,
  );
}
