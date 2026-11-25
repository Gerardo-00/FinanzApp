import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'models/expense.dart';
import 'services/local_db.dart';
import 'services/sync_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final url = SupabaseConfig.url;
  final key = SupabaseConfig.anonKey;
  if (url.isNotEmpty && key.isNotEmpty) {
    await Supabase.initialize(url: url, anonKey: key);
  }
  await NotificationService.init();
  runApp(const FinanzApp());
}

class FinanzApp extends StatelessWidget {
  const FinanzApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'FinanzApp', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF167D62)),
      useMaterial3: true, scaffoldBackgroundColor: const Color(0xFFF5F7F6)),
    home: SupabaseConfig.url.isEmpty ? const SetupScreen() :
      (Supabase.instance.client.auth.currentSession == null ? const AuthScreen() : const HomeScreen()),
  );
}

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Padding(
    padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.account_balance_wallet, size: 64, color: Colors.green),
      const Text('Configura Supabase', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      const Text('Ejecuta la app con SUPABASE_URL y SUPABASE_ANON_KEY mediante --dart-define. Consulta README.md.'),
    ]))));
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override State<AuthScreen> createState() => _AuthScreenState();
}
class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController(), password = TextEditingController();
  bool register = false, loading = false;
  String? error;
  Future<void> submit() async {
    if (!email.text.contains('@') || password.text.length < 6) {
      setState(() => error = 'Ingresa un correo válido y contraseña de 6 caracteres mínimo.'); return;
    }
    setState(() { loading = true; error = null; });
    try {
      final auth = Supabase.instance.client.auth;
      if (register) {
        await auth.signUp(email: email.text.trim(), password: password.text);
      } else {
        await auth.signInWithPassword(email: email.text.trim(), password: password.text);
      }
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (e) { setState(() => error = 'No se pudo autenticar. Verifica tus datos y conexión.'); }
    finally { if (mounted) setState(() => loading = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: SingleChildScrollView(
    padding: const EdgeInsets.all(24), child: Column(children: [
      const Icon(Icons.account_balance_wallet, size: 64, color: Color(0xFF167D62)),
      const Text('FinanzApp', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
      const SizedBox(height: 24),
      TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Correo', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder())),
      if (error != null) Padding(padding: const EdgeInsets.all(8), child: Text(error!, style: const TextStyle(color: Colors.red))),
      const SizedBox(height: 12),
      FilledButton(onPressed: loading ? null : submit, child: loading ? const CircularProgressIndicator() : Text(register ? 'Crear cuenta' : 'Iniciar sesión')),
      TextButton(onPressed: () => setState(() => register = !register), child: Text(register ? 'Ya tengo cuenta' : 'Crear cuenta')),
    ]))));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  List<Expense> expenses = [];
  bool loading = true, syncing = false;
  String? error;
  final money = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
  @override void initState() { super.initState(); load(); }
  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try { expenses = await LocalDb.all(); }
    catch (_) { error = 'No se pudieron cargar los gastos locales.'; }
    if (mounted) setState(() => loading = false);
  }
  double get total => expenses.fold(0, (s, e) => s + e.amount);
  Future<void> remove(Expense e) async {
    if (e.id != null) await LocalDb.delete(e.id!);
    await load();
  }
  Future<void> sync() async {
    setState(() => syncing = true);
    try { await SyncService.sync(); await load(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sincronización completada'))); }
    catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al sincronizar. Revisa tu sesión y conexión.'))); }
    finally { if (mounted) setState(() => syncing = false); }
  }
  @override Widget build(BuildContext context) {
    final budgetFuture = LocalDb.monthlyBudget();
    return Scaffold(appBar: AppBar(title: const Text('FinanzApp'), actions: [
      IconButton(onPressed: syncing ? null : sync, icon: syncing ? const SizedBox(width:20,height:20,child:CircularProgressIndicator()) : const Icon(Icons.sync)),
      IconButton(onPressed: () async { await Supabase.instance.client.auth.signOut(); if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen())); }, icon: const Icon(Icons.logout)),
    ]),
    floatingActionButton: FloatingActionButton.extended(onPressed: () async {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseForm()));
      await load();
    }, icon: const Icon(Icons.add), label: const Text('Agregar gasto')),
    body: loading ? const Center(child: CircularProgressIndicator()) : error != null ? Center(child: Text(error!)) :
    RefreshIndicator(onRefresh: load, child: ListView(padding: const EdgeInsets.all(16), children: [
      Card(color: const Color(0xFF167D62), child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Gastos registrados', style: TextStyle(color: Colors.white70)),
        Text(money.format(total), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
        Text('${expenses.length} movimientos', style: const TextStyle(color: Colors.white70)),
      ]))),
      const SizedBox(height: 12),
      FutureBuilder<double>(future: budgetFuture, builder: (context, snap) {
        final budget = snap.data ?? 5000;
        final ratio = budget <= 0 ? 0.0 : (total / budget).clamp(0.0, 1.0);
        if (total >= budget * .8) NotificationService.budgetWarning(total, budget);
        return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Presupuesto mensual'), Text(money.format(budget))]),
          const SizedBox(height: 10), LinearProgressIndicator(value: ratio),
          Text('${(ratio * 100).toStringAsFixed(0)}% utilizado'),
          TextButton(onPressed: () async {
            final c = TextEditingController(text: budget.toStringAsFixed(0));
            final value = await showDialog<double>(context: context, builder: (ctx) => AlertDialog(
              title: const Text('Nuevo presupuesto'), content: TextField(controller: c, keyboardType: TextInputType.number, decoration: const InputDecoration(prefixText: '\$')),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                FilledButton(onPressed: () => Navigator.pop(ctx, double.tryParse(c.text)), child: const Text('Guardar'))]));
            if (value != null && value > 0) { await LocalDb.setBudget(value); if (mounted) setState(() {}); }
          }, child: const Text('Editar presupuesto'))
        ])));
      }),
      const SizedBox(height: 12),
      if (expenses.isNotEmpty) SizedBox(height: 190, child: Card(child: Padding(padding: const EdgeInsets.all(12), child: ExpenseChart(expenses: expenses)))),
      const SizedBox(height: 12), const Text('Movimientos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      if (expenses.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Todavía no hay gastos. Agrega tu primer movimiento.'))),
      ...expenses.map((e) => Card(child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
        title: Text(e.title), subtitle: Text('${e.category} • ${e.date}'),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(money.format(e.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
          PopupMenuButton<String>(onSelected: (v) async {
            if (v == 'edit') { await Navigator.push(context, MaterialPageRoute(builder: (_) => ExpenseForm(expense: e))); await load(); }
            if (v == 'delete') { await remove(e); }
          }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Editar')), PopupMenuItem(value: 'delete', child: Text('Eliminar'))])
        ]),
      ))),
      const SizedBox(height: 80),
    ])));
  }
}

class ExpenseChart extends StatelessWidget {
  final List<Expense> expenses;
  const ExpenseChart({super.key, required this.expenses});
  @override Widget build(BuildContext context) {
    final values = <String,double>{};
    for (final e in expenses) { values[e.category] = (values[e.category] ?? 0) + e.amount; }
    final items = values.entries.toList();
    if (items.isEmpty) return const Center(child: Text('Sin datos para graficar'));
    return BarChart(BarChartData(
      titlesData: FlTitlesData(show: true, topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
          final i = v.toInt(); return i >= 0 && i < items.length ? Padding(padding: const EdgeInsets.only(top: 4), child: Text(items[i].key, style: const TextStyle(fontSize: 9))) : const SizedBox();
        }))),
      barGroups: [for (var i=0;i<items.length;i++) BarChartGroupData(x:i, barRods:[BarChartRodData(toY:items[i].value, width:18, borderRadius: BorderRadius.circular(3))])],
      gridData: const FlGridData(show: false), borderData: FlBorderData(show: false),
    ));
  }
}

class ExpenseForm extends StatefulWidget {
  final Expense? expense;
  const ExpenseForm({super.key, this.expense});
  @override State<ExpenseForm> createState() => _ExpenseFormState();
}
class _ExpenseFormState extends State<ExpenseForm> {
  final title = TextEditingController(), amount = TextEditingController(), note = TextEditingController();
  final picker = ImagePicker();
  String category = 'Alimentos', date = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String? receipt;
  bool saving = false;
  final categories = ['Alimentos','Transporte','Hogar','Salud','Entretenimiento','Otros'];
  @override void initState() { super.initState(); final e=widget.expense; if(e!=null) {
    title.text=e.title; amount.text=e.amount.toString(); note.text=e.note ?? '';
    category=e.category; date=e.date; receipt=e.receiptPath;
  }}
  Future<void> photo() async {
    final x = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (x != null) setState(() => receipt = x.path);
  }
  Future<void> save() async {
    final t=title.text.trim(), a=double.tryParse(amount.text.replaceAll(',', '.'));
    if(t.isEmpty || a==null || a<=0 || a>100000000) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escribe una descripción y un importe válido mayor que cero.'))); return;
    }
    setState(()=>saving=true);
    try {
      final old=widget.expense;
      final user=Supabase.instance.client.auth.currentUser;
      final e=Expense(id:old?.id, uuid:old?.uuid ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title:t, amount:a, category:category, date:date, note:note.text.trim().isEmpty?null:note.text.trim(),
        receiptPath:receipt, userId:user?.id, updatedAt:DateTime.now().toUtc().toIso8601String());
      await LocalDb.save(e);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('No se pudo guardar el gasto.'))); }
    finally { if(mounted) setState(()=>saving=false); }
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.expense==null?'Nuevo gasto':'Editar gasto')),
    body:ListView(padding:const EdgeInsets.all(20),children:[
      TextField(controller:title, decoration:const InputDecoration(labelText:'Descripción',border:OutlineInputBorder())),
      const SizedBox(height:12),
      TextField(controller:amount, keyboardType:const TextInputType.numberWithOptions(decimal:true), decoration:const InputDecoration(labelText:'Importe (MXN)',prefixText:'\$ ',border:OutlineInputBorder())),
      const SizedBox(height:12),
      DropdownButtonFormField<String>(value:category, decoration:const InputDecoration(labelText:'Categoría',border:OutlineInputBorder()), items:categories.map((c)=>DropdownMenuItem(value:c,child:Text(c))).toList(), onChanged:(v){if(v!=null)setState(()=>category=v);}),
      const SizedBox(height:12),
      TextField(controller:note, maxLines:2, decoration:const InputDecoration(labelText:'Nota (opcional)',border:OutlineInputBorder())),
      const SizedBox(height:12),
      OutlinedButton.icon(onPressed:photo, icon:const Icon(Icons.camera_alt), label:const Text('Fotografiar ticket')),
      if(receipt!=null) Padding(padding:const EdgeInsets.all(8), child: Text('Ticket: ${receipt!.split(Platform.pathSeparator).last}')),
      const SizedBox(height:20),
      FilledButton(onPressed:saving?null:save, child:saving?const CircularProgressIndicator():const Text('Guardar gasto')),
    ]));
}
