import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore();
  await store.load();
  runApp(SkillAcademyApp(store: store));
}

class SkillAcademyApp extends StatelessWidget {
  const SkillAcademyApp({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skill Academy School Management System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2457C5),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF7F8FC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E9F2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2457C5), width: 1.5),
          ),
        ),
      ),
      home: AppShell(store: store),
    );
  }
}

class AppStore extends ChangeNotifier {
  static const _keys = [
    'students',
    'teachers',
    'attendance',
    'fees',
    'exams',
    'notices',
  ];

  final Map<String, List<Map<String, String>>> _data = {
    for (final key in _keys) key: <Map<String, String>>[],
  };

  List<Map<String, String>> items(String key) =>
      List.unmodifiable(_data[key] ?? []);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _keys) {
      final raw = prefs.getString('skill_academy_$key');
      if (raw == null || raw.isEmpty) continue;
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _data[key] = decoded
            .map((item) => Map<String, String>.from(item as Map))
            .toList();
      } catch (_) {
        _data[key] = <Map<String, String>>[];
      }
    }
  }

  Future<void> add(String key, Map<String, String> item) async {
    final record = Map<String, String>.from(item);
    record['id'] = DateTime.now().microsecondsSinceEpoch.toString();
    (_data[key] ??= []).insert(0, record);
    await _save(key);
    notifyListeners();
  }

  Future<void> update(
    String key,
    String id,
    Map<String, String> values,
  ) async {
    final list = _data[key] ?? [];
    final index = list.indexWhere((item) => item['id'] == id);
    if (index < 0) return;
    list[index] = {...list[index], ...values};
    await _save(key);
    notifyListeners();
  }

  Future<void> delete(String key, String id) async {
    _data[key]?.removeWhere((item) => item['id'] == id);
    await _save(key);
    notifyListeners();
  }

  Future<void> _save(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'skill_academy_$key',
      jsonEncode(_data[key] ?? []),
    );
  }
}

class FieldSpec {
  const FieldSpec(
    this.key,
    this.label, {
    this.required = false,
    this.multiline = false,
    this.keyboardType = TextInputType.text,
    this.hint,
  });

  final String key;
  final String label;
  final bool required;
  final bool multiline;
  final TextInputType keyboardType;
  final String? hint;
}

class ModuleConfig {
  const ModuleConfig({
    required this.key,
    required this.title,
    required this.singular,
    required this.icon,
    required this.primaryKey,
    required this.secondaryKeys,
    required this.fields,
  });

  final String key;
  final String title;
  final String singular;
  final IconData icon;
  final String primaryKey;
  final List<String> secondaryKeys;
  final List<FieldSpec> fields;
}

final modules = <ModuleConfig>[
  const ModuleConfig(
    key: 'students',
    title: 'Students',
    singular: 'Student',
    icon: Icons.school_outlined,
    primaryKey: 'name',
    secondaryKeys: ['student_id', 'class_name', 'section', 'roll'],
    fields: [
      FieldSpec('student_id', 'Student ID', required: true),
      FieldSpec('name', 'Full name', required: true),
      FieldSpec('class_name', 'Class', required: true),
      FieldSpec('section', 'Section'),
      FieldSpec('roll', 'Roll number'),
      FieldSpec('guardian', 'Guardian name'),
      FieldSpec('phone', 'Guardian phone', keyboardType: TextInputType.phone),
      FieldSpec('admission_date', 'Admission date', hint: 'YYYY-MM-DD'),
    ],
  ),
  const ModuleConfig(
    key: 'teachers',
    title: 'Teachers',
    singular: 'Teacher',
    icon: Icons.person_outline,
    primaryKey: 'name',
    secondaryKeys: ['designation', 'subject', 'phone'],
    fields: [
      FieldSpec('name', 'Full name', required: true),
      FieldSpec('designation', 'Designation'),
      FieldSpec('subject', 'Subject'),
      FieldSpec('phone', 'Phone number', keyboardType: TextInputType.phone),
      FieldSpec('email', 'Email', keyboardType: TextInputType.emailAddress),
    ],
  ),
  const ModuleConfig(
    key: 'attendance',
    title: 'Attendance',
    singular: 'Attendance record',
    icon: Icons.fact_check_outlined,
    primaryKey: 'student_name',
    secondaryKeys: ['class_name', 'date', 'status'],
    fields: [
      FieldSpec('student_name', 'Student name', required: true),
      FieldSpec('class_name', 'Class'),
      FieldSpec('date', 'Date', required: true, hint: 'YYYY-MM-DD'),
      FieldSpec('status', 'Status', required: true, hint: 'Present / Absent / Late'),
      FieldSpec('note', 'Note'),
    ],
  ),
  const ModuleConfig(
    key: 'fees',
    title: 'Fees',
    singular: 'Fee payment',
    icon: Icons.payments_outlined,
    primaryKey: 'student_name',
    secondaryKeys: ['month', 'amount', 'method', 'paid_date'],
    fields: [
      FieldSpec('student_name', 'Student name', required: true),
      FieldSpec('month', 'Fee month', required: true, hint: 'e.g. November 2026'),
      FieldSpec('amount', 'Amount (BDT)', required: true, keyboardType: TextInputType.number),
      FieldSpec('method', 'Payment method', hint: 'Cash / bKash / Bank'),
      FieldSpec('paid_date', 'Payment date', hint: 'YYYY-MM-DD'),
      FieldSpec('note', 'Note'),
    ],
  ),
  const ModuleConfig(
    key: 'exams',
    title: 'Examinations',
    singular: 'Exam',
    icon: Icons.assignment_outlined,
    primaryKey: 'title',
    secondaryKeys: ['class_name', 'exam_date', 'total_marks'],
    fields: [
      FieldSpec('title', 'Exam title', required: true),
      FieldSpec('class_name', 'Class', required: true),
      FieldSpec('exam_date', 'Exam date', hint: 'YYYY-MM-DD'),
      FieldSpec('total_marks', 'Total marks', keyboardType: TextInputType.number),
      FieldSpec('note', 'Note'),
    ],
  ),
  const ModuleConfig(
    key: 'notices',
    title: 'Notices',
    singular: 'Notice',
    icon: Icons.campaign_outlined,
    primaryKey: 'title',
    secondaryKeys: ['date', 'body'],
    fields: [
      FieldSpec('title', 'Notice title', required: true),
      FieldSpec('date', 'Publish date', hint: 'YYYY-MM-DD'),
      FieldSpec('body', 'Notice details', multiline: true),
    ],
  ),
];

class NavItem {
  const NavItem(this.label, this.icon);
  final String label;
  final IconData icon;
}

const navItems = <NavItem>[
  NavItem('Dashboard', Icons.dashboard_outlined),
  NavItem('Students', Icons.school_outlined),
  NavItem('Teachers', Icons.person_outline),
  NavItem('Attendance', Icons.fact_check_outlined),
  NavItem('Fees', Icons.payments_outlined),
  NavItem('Examinations', Icons.assignment_outlined),
  NavItem('Notices', Icons.campaign_outlined),
  NavItem('Reports', Icons.bar_chart_outlined),
  NavItem('Settings', Icons.settings_outlined),
];

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.store});
  final AppStore store;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedIndex = 0;

  String get pageTitle => navItems[selectedIndex].label;

  void selectPage(int index) {
    setState(() => selectedIndex = index);
    Navigator.of(context).maybePop();
  }

  Widget _page() {
    if (selectedIndex == 0) return DashboardPage(store: widget.store);
    if (selectedIndex >= 1 && selectedIndex <= 6) {
      return ModulePage(
        store: widget.store,
        config: modules[selectedIndex - 1],
      );
    }
    if (selectedIndex == 7) return ReportsPage(store: widget.store);
    return const SettingsPage();
  }

  Widget _drawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const _BrandHeader(),
            Expanded(
              child: ListView.builder(
                itemCount: navItems.length,
                itemBuilder: (context, index) => _NavTile(
                  item: navItems[index],
                  selected: selectedIndex == index,
                  onTap: () => selectPage(index),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Skill Academy • School Management',
                style: TextStyle(color: Colors.black54, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              pageTitle,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: const Text(
                    'MR',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          drawer: wide ? null : _drawer(),
          body: wide
              ? Row(
                  children: [
                    Container(
                      width: 245,
                      color: Colors.white,
                      child: SafeArea(
                        child: Column(
                          children: [
                            const _BrandHeader(),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: navItems.length,
                                itemBuilder: (context, index) => _NavTile(
                                  item: navItems[index],
                                  selected: selectedIndex == index,
                                  onTap: () => setState(() => selectedIndex = index),
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Founder: Md. Masud Rana',
                                style: TextStyle(color: Colors.black54, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE8ECF4)),
                    Expanded(child: _page()),
                  ],
                )
              : _page(),
        );
      },
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF173B8F), Color(0xFF3674E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white24,
            child: Icon(Icons.auto_awesome, color: Colors.white),
          ),
          SizedBox(height: 12),
          Text(
            'SKILL ACADEMY',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              fontSize: 17,
            ),
          ),
          SizedBox(height: 3),
          Text(
            'School Management System',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Theme.of(context).colorScheme.primary : Colors.black54;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selected: selected,
        selectedTileColor: const Color(0xFFEAF0FF),
        leading: Icon(item.icon, color: color),
        title: Text(
          item.label,
          style: TextStyle(
            color: selected ? color : const Color(0xFF3F4654),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final students = store.items('students');
        final teachers = store.items('teachers');
        final attendance = store.items('attendance');
        final fees = store.items('fees');
        final notices = store.items('notices');
        final paid = fees.fold<double>(
          0,
          (sum, item) => sum + (double.tryParse(item['amount'] ?? '') ?? 0),
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF183D91), Color(0xFF3977E8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to Skill Academy',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'Manage your institution from one simple dashboard.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 15),
                    Text(
                      'Founder: Md. Masud Rana',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeading(title: 'Overview', subtitle: 'Your institution at a glance'),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth < 520
                      ? (constraints.maxWidth - 12) / 2
                      : 220.0;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(width: width, child: MetricCard(title: 'Total Students', value: '${students.length}', icon: Icons.school_outlined, color: const Color(0xFF2457C5))),
                      SizedBox(width: width, child: MetricCard(title: 'Total Teachers', value: '${teachers.length}', icon: Icons.people_outline, color: const Color(0xFF138A67))),
                      SizedBox(width: width, child: MetricCard(title: 'Attendance Records', value: '${attendance.length}', icon: Icons.fact_check_outlined, color: const Color(0xFFB66A13))),
                      SizedBox(width: width, child: MetricCard(title: 'Fees Collected', value: '৳${paid.toStringAsFixed(0)}', icon: Icons.payments_outlined, color: const Color(0xFF7B4ACB))),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              const SectionHeading(title: 'Recent Notices', subtitle: 'Latest announcements'),
              const SizedBox(height: 10),
              if (notices.isEmpty)
                const EmptyState(message: 'No notices yet. Add your first notice from the Notices menu.')
              else
                ...notices.take(4).map((notice) => Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.campaign_outlined)),
                        title: Text(notice['title'] ?? 'Untitled notice', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${notice['date'] ?? ''}  ${notice['body'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                    )),
            ],
          ),
        );
      },
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class ModulePage extends StatefulWidget {
  const ModulePage({super.key, required this.store, required this.config});
  final AppStore store;
  final ModuleConfig config;

  @override
  State<ModulePage> createState() => _ModulePageState();
}

class _ModulePageState extends State<ModulePage> {
  String query = '';

  Future<void> _openForm({Map<String, String>? existing}) async {
    final formKey = GlobalKey<FormState>();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final controllers = <String, TextEditingController>{
      for (final field in widget.config.fields)
        field.key: TextEditingController(
          text: existing?[field.key] ??
              ((field.key == 'date' || field.key == 'paid_date' || field.key == 'admission_date' || field.key == 'exam_date') ? today : ''),
        ),
    };

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null ? 'Add ${widget.config.singular}' : 'Edit ${widget.config.singular}'),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: widget.config.fields.map((field) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: controllers[field.key],
                      keyboardType: field.keyboardType,
                      minLines: field.multiline ? 3 : 1,
                      maxLines: field.multiline ? 5 : 1,
                      decoration: InputDecoration(
                        labelText: field.label,
                        hintText: field.hint,
                      ),
                      validator: field.required
                          ? (value) => (value == null || value.trim().isEmpty) ? 'This field is required' : null
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(
                dialogContext,
                {
                  for (final field in widget.config.fields)
                    field.key: controllers[field.key]!.text.trim(),
                },
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    for (final controller in controllers.values) {
      controller.dispose();
    }

    if (result == null) return;
    if (existing == null) {
      await widget.store.add(widget.config.key, result);
    } else {
      await widget.store.update(widget.config.key, existing['id']!, result);
    }
  }

  Future<void> _delete(Map<String, String> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete record?'),
        content: const Text('This record will be removed from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.store.delete(widget.config.key, item['id']!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final allItems = widget.store.items(widget.config.key);
        final filtered = allItems.where((item) {
          final text = item.values.join(' ').toLowerCase();
          return text.contains(query.toLowerCase());
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${allItems.length} ${widget.config.title.toLowerCase()} record(s)',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text('Add ${widget.config.singular}'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                onChanged: (value) => setState(() => query = value),
                decoration: const InputDecoration(
                  hintText: 'Search records...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: filtered.isEmpty
                    ? EmptyState(
                        message: allItems.isEmpty
                            ? 'No ${widget.config.title.toLowerCase()} added yet. Use the button above to add your first record.'
                            : 'No matching records found.',
                        icon: widget.config.icon,
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final subtitle = widget.config.secondaryKeys
                              .map((key) => item[key])
                              .where((value) => value != null && value.trim().isNotEmpty)
                              .join('  •  ');
                          return Card(
                            elevation: 0,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: Icon(widget.config.icon, color: Theme.of(context).colorScheme.primary),
                              ),
                              title: Text(
                                item[widget.config.primaryKey]?.isNotEmpty == true
                                    ? item[widget.config.primaryKey]!
                                    : 'Untitled',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(subtitle.isEmpty ? 'No additional details' : subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') _openForm(existing: item);
                                  if (value == 'delete') _delete(item);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final fees = store.items('fees');
        final attendance = store.items('attendance');
        final total = fees.fold<double>(
          0,
          (sum, item) => sum + (double.tryParse(item['amount'] ?? '') ?? 0),
        );
        final present = attendance.where((item) => (item['status'] ?? '').toLowerCase() == 'present').length;
        final absent = attendance.where((item) => (item['status'] ?? '').toLowerCase() == 'absent').length;

        return ListView(
          padding: const EdgeInsets.all(22),
          children: [
            const SectionHeading(title: 'Reports', subtitle: 'A quick summary of saved records'),
            const SizedBox(height: 16),
            _ReportRow(label: 'Total students', value: '${store.items('students').length}'),
            _ReportRow(label: 'Total teachers', value: '${store.items('teachers').length}'),
            _ReportRow(label: 'Attendance entries', value: '${attendance.length}'),
            _ReportRow(label: 'Marked present', value: '$present'),
            _ReportRow(label: 'Marked absent', value: '$absent'),
            _ReportRow(label: 'Fee payments recorded', value: '${fees.length}'),
            _ReportRow(label: 'Total fees collected', value: '৳${total.toStringAsFixed(2)}'),
            const SizedBox(height: 14),
            const Text(
              'Note: These reports are calculated from records saved on this device. Cloud synchronization and downloadable reports can be added in the next version.',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        );
      },
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: ListTile(
        title: Text(label),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const SectionHeading(title: 'Institution settings', subtitle: 'Basic information about this demo application'),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          child: Column(
            children: const [
              ListTile(
                leading: Icon(Icons.apartment_outlined),
                title: Text('Institution name'),
                subtitle: Text('Skill Academy'),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.person_outline),
                title: Text('Founder'),
                subtitle: Text('Md. Masud Rana'),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.devices_outlined),
                title: Text('Platform'),
                subtitle: Text('Android and Web (Flutter)'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Card(
          elevation: 0,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Data storage: This starter version stores records locally on the current device/browser. It does not yet include secure staff login, cloud backup, online synchronization, or role permissions. Do not use real student personal data until those protections are configured.',
              style: TextStyle(height: 1.5, color: Colors.black87),
            ),
          ),
        ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: Colors.black26),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
