import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'api.dart';

const blue = Color(0xff2563eb);
const ink = Color(0xff0f172a);
const muted = Color(0xff64748b);
const canvas = Color(0xfff6f8fc);

void main() => runApp(const StaffApp());

class StaffApp extends StatelessWidget {
  const StaffApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Disaster Relief',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: blue),
          scaffoldBackgroundColor: canvas,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: ink,
            elevation: 0,
            centerTitle: false,
            surfaceTintColor: Colors.white,
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xffe8edf5)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xffdbe3ef)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xffdbe3ef)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(44, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        home: const LoginPage(),
      );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  bool hidePassword = true;
  String? error;

  Future<void> login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      setState(() => error = 'Enter your email and password.');
      return;
    }
    setState(() { busy = true; error = null; });
    try {
      final result = await Api.req('POST', '/login', auth: false, body: {
        'email': email.text.trim(),
        'password': password.text,
      });
      if (result['user']?['role'] != 'staff') {
        throw Exception('This mobile app is for staff accounts only.');
      }
      await Api.saveToken(result['token'].toString());
      if (mounted) {
        Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const StaffHome()));
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 76, height: 76,
                      decoration: BoxDecoration(color: blue, borderRadius: BorderRadius.circular(22)),
                      child: const Icon(Icons.volunteer_activism, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 24),
                    const Text('Disaster Relief', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: ink)),
                    const SizedBox(height: 6),
                    const Text('Staff portal', style: TextStyle(color: muted, fontSize: 15)),
                    const SizedBox(height: 28),
                    Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      const Text('Welcome back', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 5),
                      const Text('Sign in to manage relief operations.', style: TextStyle(color: muted)),
                      const SizedBox(height: 22),
                      TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Staff email', prefixIcon: Icon(Icons.mail_outline))),
                      const SizedBox(height: 14),
                      TextField(controller: password, obscureText: hidePassword, onSubmitted: (_) => busy ? null : login(), decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => hidePassword = !hidePassword), icon: Icon(hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
                      if (error != null) ...[const SizedBox(height: 12), Text(error!, style: const TextStyle(color: Colors.red))],
                      const SizedBox(height: 18),
                      FilledButton(onPressed: busy ? null : login, child: busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Sign in')),
                    ]))),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class NavItem {
  final String title;
  final IconData icon;
  final Widget page;
  const NavItem(this.title, this.icon, this.page);
}

class StaffHome extends StatefulWidget {
  const StaffHome({super.key});
  @override
  State<StaffHome> createState() => _StaffHomeState();
}

class _StaffHomeState extends State<StaffHome> {
  int index = 0;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late final List<NavItem> items = const [
    NavItem('Dashboard', Icons.grid_view_rounded, StaffDashboard()),
    NavItem('Resources', Icons.inventory_2_outlined, ResourcePage()),
    NavItem('QR Tracking', Icons.qr_code_2_rounded, ScanPage()),
    NavItem('Distribution', Icons.local_shipping_outlined, DistributionPage()),
    NavItem('Locations', Icons.location_on_outlined, LocationPage()),
    NavItem('Reports', Icons.description_outlined, ReportPage()),
    NavItem('Messages', Icons.chat_bubble_outline, MessagePage()),
    NavItem('Families', Icons.groups_outlined, FamilyListPage()),
    NavItem('Scan History', Icons.history_rounded, ScanHistoryPage()),
  ];

  Future<void> logout() async {
    try {
      await Api.req('POST', '/logout');
    } catch (_) {}

    await Api.clearToken();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = items[index];
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: blue,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Center(
                child: Text(
                  'DR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'Disaster Relief',
                    style: TextStyle(color: muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => _showInfo(
              context,
              'Notifications',
              'Notifications will appear here when supported by the API.',
            ),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xffdbeafe),
              child: Text(
                'S',
                style: TextStyle(color: blue, fontWeight: FontWeight.bold),
              ),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                logout();
              } else {
                _showInfo(
                  context,
                  'Staff account',
                  'Signed in with a staff account.',
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'account', child: Text('Account')),
              PopupMenuItem(value: 'logout', child: Text('Log out')),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                color: const Color(0xffeff6ff),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: blue,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Center(
                        child: Text(
                          'DR',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Disaster Relief',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Staff application',
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  children: [
                    for (var i = 0; i < items.length; i++)
                      ListTile(
                        leading: Icon(items[i].icon, color: i == index ? blue : muted),
                        title: Text(
                          items[i].title,
                          style: TextStyle(
                            color: i == index ? blue : ink,
                            fontWeight:
                                i == index ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        selected: i == index,
                        selectedTileColor: const Color(0xffeff6ff),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onTap: () {
                          setState(() => index = i);
                          Navigator.pop(context);
                        },
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Log out',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: logout,
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: index,
        children: [for (final item in items) item.page],
      ),
      bottomNavigationBar: NavigationBar(
        height: 68,
        selectedIndex: index < 4 ? index : 0,
        onDestinationSelected: (value) {
          if (value == 4) {
            scaffoldKey.currentState?.openDrawer();
          } else {
            setState(() => index = value);
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Resources'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          NavigationDestination(icon: Icon(Icons.local_shipping_outlined), label: 'Relief'),
          NavigationDestination(icon: Icon(Icons.menu_rounded), label: 'More'),
        ],
      ),
    );
  }
}

void _showInfo(BuildContext context, String title, String message) => showDialog<void>(context: context, builder: (_) => AlertDialog(title: Text(title), content: Text(message), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))]));

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});
  @override State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  late Future<List<Map<String, dynamic>>> future = _load();
  Future<List<Map<String, dynamic>>> _load() async {
    final paths = ['/resources', '/distributions/history', '/staff/families', '/qr/scans'];
    return Future.wait(paths.map((p) async { try { return await Api.req('GET', p); } catch (_) { return <String, dynamic>{}; } }));
  }
  List<dynamic> _rows(Map<String, dynamic> map, String key) => map[key] is List ? map[key] as List : <dynamic>[];
  @override Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(future: future, builder: (context, snap) {
    final data = snap.data ?? const <Map<String, dynamic>>[];
    final resources = data.isNotEmpty ? _rows(data[0], 'resources') : <dynamic>[];
    final distributions = data.length > 1 ? _rows(data[1], 'distributions') : <dynamic>[];
    final families = data.length > 2 ? _rows(data[2], 'families') : <dynamic>[];
    final scans = data.length > 3 ? _rows(data[3], 'scans') : <dynamic>[];
    final pending = distributions.where((e) => (e as Map)['status']?.toString().toLowerCase() == 'pending').length;
    final completed = distributions.where((e) => (e as Map)['status']?.toString().toLowerCase() == 'completed').length;
    final stock = resources.fold<num>(0, (sum, e) => sum + ((e as Map)['quantity'] is num ? e['quantity'] as num : num.tryParse('${e['quantity']}') ?? 0));
    return RefreshIndicator(onRefresh: () async => setState(() => future = _load()), child: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 28), children: [
      const Text('Overview of relief operations', style: TextStyle(color: muted, fontSize: 13)),
      const SizedBox(height: 16),
      Row(children: [Expanded(child: _QuickAction(icon: Icons.qr_code_scanner, label: 'Scan QR', onTap: () => _showInfo(context, 'QR Tracking', 'Open QR Tracking from the bottom navigation.'))), const SizedBox(width: 10), Expanded(child: _QuickAction(icon: Icons.description_outlined, label: 'Reports', onTap: () => _showInfo(context, 'Reports', 'Open Reports from the More menu.')))]),
      const SizedBox(height: 18),
      if (snap.connectionState == ConnectionState.waiting) const LinearProgressIndicator(),
      GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.42, children: [
        _StatCard(title: 'Total Resources', value: snap.hasData ? '${resources.length}' : '—', icon: Icons.inventory_2_outlined, tint: const Color(0xffeff6ff), color: blue),
        _StatCard(title: 'Total Stock Quantity', value: snap.hasData ? '$stock' : '—', icon: Icons.widgets_outlined, tint: const Color(0xffeef2ff), color: const Color(0xff4f46e5)),
        _StatCard(title: 'Pending', value: snap.hasData ? '$pending' : '—', icon: Icons.schedule_rounded, tint: const Color(0xfffffbeb), color: const Color(0xffd97706)),
        _StatCard(title: 'In Transit / Pending', value: snap.hasData ? '$pending' : '—', icon: Icons.local_shipping_outlined, tint: const Color(0xfff1f5f9), color: const Color(0xff475569)),
        _StatCard(title: 'Completed', value: snap.hasData ? '$completed' : '—', icon: Icons.check_circle_outline, tint: const Color(0xffecfdf5), color: const Color(0xff059669)),
        _StatCard(title: 'Families', value: snap.hasData ? '${families.length}' : '—', icon: Icons.groups_outlined, tint: const Color(0xffeff6ff), color: blue),
        _StatCard(title: 'QR Scans Logged', value: snap.hasData ? '${scans.length}' : '—', icon: Icons.qr_code_2_rounded, tint: const Color(0xfffaf5ff), color: const Color(0xffa855f7)),
        _StatCard(title: 'Households Served', value: snap.hasData ? '$completed' : '—', icon: Icons.volunteer_activism_outlined, tint: const Color(0xfff0fdfa), color: const Color(0xff0d9488)),
      ]),
      const SizedBox(height: 22),
      _SectionCard(title: 'Recent Distributions', action: 'Refresh', onAction: () => setState(() => future = _load()), child: distributions.isEmpty ? const _EmptyState(text: 'No distributions to show yet.') : Column(children: distributions.take(4).map((e) { final m = e as Map; return _MiniRecord(icon: Icons.local_shipping_outlined, title: '${m['family_name'] ?? m['family']?['name'] ?? 'Family distribution'}', subtitle: '${m['status'] ?? 'Status unavailable'} • ${m['distribution_date'] ?? m['scheduled_at'] ?? ''}'); }).toList())),
      const SizedBox(height: 14),
      _SectionCard(title: 'Recent QR Scans', action: 'Refresh', onAction: () => setState(() => future = _load()), child: scans.isEmpty ? const _EmptyState(text: 'No scan records to show yet.') : Column(children: scans.take(4).map((e) { final m = e as Map; return _MiniRecord(icon: Icons.qr_code_2, title: '${m['resource']?['name'] ?? m['resource_name'] ?? 'Resource scan'}', subtitle: '${m['scan_type'] ?? 'Scan'} • ${m['scanned_at'] ?? ''}'); }).toList())),
      const SizedBox(height: 14),
      _SectionCard(title: 'Low Stock Alerts', child: resources.where((e) { final m = e as Map; final q = m['quantity']; final min = m['min_quantity']; return q is num && min is num && q <= min; }).isEmpty ? const _EmptyState(text: 'No low-stock alerts, or stock thresholds are unavailable.') : Column(children: resources.where((e) { final m = e as Map; return m['quantity'] is num && m['min_quantity'] is num && (m['quantity'] as num) <= (m['min_quantity'] as num); }).map((e) { final m = e as Map; return _MiniRecord(icon: Icons.warning_amber_rounded, title: '${m['name'] ?? 'Resource'}', subtitle: 'Remaining stock: ${m['quantity']}'); }).toList())),
    ]));
  });
}

class _QuickAction extends StatelessWidget { final IconData icon; final String label; final VoidCallback onTap; const _QuickAction({required this.icon, required this.label, required this.onTap}); @override Widget build(BuildContext context) => OutlinedButton.icon(onPressed: onTap, icon: Icon(icon, size: 19), label: Text(label, maxLines: 1), style: OutlinedButton.styleFrom(foregroundColor: ink, backgroundColor: Colors.white, side: const BorderSide(color: Color(0xffdbe3ef)), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))); }
class _StatCard extends StatelessWidget { final String title, value; final IconData icon; final Color tint, color; const _StatCard({required this.title, required this.value, required this.icon, required this.tint, required this.color}); @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: color, size: 21)), Text(value, style: const TextStyle(fontSize: 24, height: 1.1, fontWeight: FontWeight.w800, color: ink)), Text(title, style: const TextStyle(fontSize: 11, color: muted), maxLines: 2, overflow: TextOverflow.ellipsis)]))); }
class _SectionCard extends StatelessWidget { final String title; final String? action; final VoidCallback? onAction; final Widget child; const _SectionCard({required this.title, required this.child, this.action, this.onAction}); @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))), if (action != null) TextButton(onPressed: onAction, child: Text(action!))]), const SizedBox(height: 8), child]))); }
class _EmptyState extends StatelessWidget { final String text; const _EmptyState({required this.text}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4), child: Center(child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 13)))); }
class _MiniRecord extends StatelessWidget { final IconData icon; final String title, subtitle; const _MiniRecord({required this.icon, required this.title, required this.subtitle}); @override Widget build(BuildContext context) => ListTile(contentPadding: EdgeInsets.zero, leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xffeff6ff), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: blue, size: 20)), title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: Text(subtitle.trim().isEmpty ? '—' : subtitle, style: const TextStyle(fontSize: 11, color: muted), maxLines: 1, overflow: TextOverflow.ellipsis)); }

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final code = TextEditingController();
  final quantity = TextEditingController(text: '1');
  final notes = TextEditingController();

  String type = 'audit';
  String? error;
  Map<String, dynamic>? resource;
  bool busy = false;
  bool cameraOpen = false;
  bool handled = false;

  Future<void> lookup(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() => error = 'Enter or scan a resource QR code.');
      return;
    }

    setState(() {
      busy = true;
      error = null;
      resource = null;
      code.text = trimmed;
    });

    try {
      final response = await Api.req('POST', '/qr/lookup', body: {'qr_code': trimmed});
      if (mounted) {
        setState(() => resource = response['resource'] as Map<String, dynamic>?);
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> save() async {
    final q = int.tryParse(quantity.text);
    if (q == null || q < 1) {
      setState(() => error = 'Quantity must be a positive whole number.');
      return;
    }

    setState(() {
      busy = true;
      error = null;
    });

    try {
      await Api.req(
        'POST',
        '/qr/scan',
        body: {
          'qr_code': code.text.trim(),
          'scan_type': type,
          'quantity_change': type == 'check_out'
              ? -q
              : (type == 'check_in' ? q : 0),
          'location_id': resource?['location_id'],
          'notes': notes.text.trim(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tracking record saved.')),
        );
        setState(() {
          resource = null;
          code.clear();
          notes.clear();
          quantity.text = '1';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  void dispose() {
    code.dispose();
    quantity.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Scan and track relief resources',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xffeff6ff),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner, color: blue, size: 25),
                      SizedBox(width: 10),
                      Text(
                        'QR Tracking',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (cameraOpen)
                  SizedBox(
                    height: 250,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: MobileScanner(
                        onDetect: (capture) {
                          if (handled || capture.barcodes.isEmpty) {
                            return;
                          }
                          final value = capture.barcodes.first.rawValue;
                          if (value == null || value.isEmpty) {
                            return;
                          }
                          handled = true;
                          cameraOpen = false;
                          setState(() { cameraOpen = false; });
                          lookup(value);
                        },
                      ),
                    ),
                  ),
                TextField(
                  controller: code,
                  decoration: InputDecoration(
                    labelText: 'Resource QR code',
                    prefixIcon: const Icon(Icons.qr_code_2),
                    suffixIcon: IconButton(
                      tooltip: 'Scan with camera',
                      onPressed: () {
                        setState(() {
                          cameraOpen = !cameraOpen;
                          handled = false;
                        });
                      },
                      icon: const Icon(Icons.camera_alt_outlined, color: blue),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: busy ? null : () => lookup(code.text),
                  icon: const Icon(Icons.search),
                  label: const Text('Find resource'),
                ),
                if (busy)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(),
                  ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                if (resource != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  Text(
                    resource!['name']?.toString() ?? 'Resource',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Stock: ${resource!['quantity'] ?? '—'} ${resource!['unit'] ?? ''}',
                  ),
                  Text('Location: ${resource!['location']?['name'] ?? '—'}'),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(
                      labelText: 'Tracking action',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'check_in',
                        child: Text('Check in / add stock'),
                      ),
                      DropdownMenuItem(
                        value: 'check_out',
                        child: Text('Check out / remove stock'),
                      ),
                      DropdownMenuItem(value: 'audit', child: Text('Audit')),
                      DropdownMenuItem(
                        value: 'transfer',
                        child: Text('Transfer (record only)'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => type = value ?? 'audit');
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: quantity,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notes,
                    decoration: const InputDecoration(labelText: 'Notes (optional)'),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: busy ? null : save,
                    child: const Text('Save tracking record'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ResourcePage extends StatelessWidget { const ResourcePage({super.key}); @override Widget build(BuildContext context) => const _ApiListPage(path: '/resources', listKey: 'resources', title: 'Resources', subtitle: 'Relief supply inventory', kind: 'resource'); }
class DistributionPage extends StatelessWidget { const DistributionPage({super.key}); @override Widget build(BuildContext context) => const _ApiListPage(path: '/distributions/history', listKey: 'distributions', title: 'Distribution', subtitle: 'Current relief distribution and history', kind: 'distribution'); }
class FamilyListPage extends StatelessWidget { const FamilyListPage({super.key}); @override Widget build(BuildContext context) => const _ApiListPage(path: '/staff/families', listKey: 'families', title: 'Families', subtitle: 'Households in your assigned Purok', kind: 'family'); }
class ScanHistoryPage extends StatelessWidget { const ScanHistoryPage({super.key}); @override Widget build(BuildContext context) => const _ApiListPage(path: '/qr/scans', listKey: 'scans', title: 'QR Scan History', subtitle: 'Recent tracking activity', kind: 'scan'); }
class LocationPage extends StatelessWidget { const LocationPage({super.key}); @override Widget build(BuildContext context) => const _ApiListPage(path: '/locations', listKey: 'locations', title: 'Locations', subtitle: 'Relief storage and distribution locations', kind: 'location'); }
class ReportPage extends StatelessWidget { const ReportPage({super.key}); @override Widget build(BuildContext context) => const _ApiListPage(path: '/reports', listKey: 'reports', title: 'Reports', subtitle: 'Relief operation reports', kind: 'report'); }
class MessagePage extends StatelessWidget { const MessagePage({super.key}); @override Widget build(BuildContext context) => const _ApiListPage(path: '/messages', listKey: 'messages', title: 'Messages', subtitle: 'Messages and announcements', kind: 'message'); }

class _ApiListPage extends StatefulWidget {
  const _ApiListPage({
    required this.path,
    required this.listKey,
    required this.title,
    required this.subtitle,
    required this.kind,
  });

  final String path;
  final String listKey;
  final String title;
  final String subtitle;
  final String kind;

  @override
  State<_ApiListPage> createState() => _ApiListPageState();
}

class _ApiListPageState extends State<_ApiListPage> {
  late Future<Map<String, dynamic>> future;
  String search = '';

  @override
  void initState() {
    super.initState();
    future = Api.req('GET', widget.path);
  }

  IconData get icon {
    switch (widget.kind) {
      case 'resource':
        return Icons.inventory_2_outlined;
      case 'distribution':
        return Icons.local_shipping_outlined;
      case 'family':
        return Icons.groups_outlined;
      case 'scan':
        return Icons.qr_code_2;
      case 'location':
        return Icons.location_on_outlined;
      case 'report':
        return Icons.description_outlined;
      default:
        return Icons.chat_bubble_outline;
    }
  }

  String _title(Map<String, dynamic> row) {
    return (row['family_name'] ??
            row['family']?['name'] ??
            row['resource']?['name'] ??
            row['name'] ??
            row['title'] ??
            row['head_name'] ??
            row['family_id'] ??
            row['scan_type'] ??
            'Record')
        .toString();
  }

  String _subtitle(Map<String, dynamic> row) {
    final fields = switch (widget.kind) {
      'resource' => [
          row['category'],
          row['quantity'] == null ? null : '${row['quantity']} ${row['unit'] ?? ''}',
          row['location']?['name'] ?? row['location_name'],
          row['status'],
        ],
      'distribution' => [
          row['head_name'] ?? row['family_head']?['name'],
          row['purok']?['name'] ?? row['purok_name'],
          row['resource']?['name'] ?? row['resource_name'],
          row['quantity'] == null ? null : 'Qty ${row['quantity']}',
          row['status'],
          row['distribution_date'] ?? row['scheduled_at'],
        ],
      'family' => [
          row['family_id'],
          row['head_name'] ?? row['family_head'],
          row['purok']?['name'] ?? row['purok_name'],
          row['members_count'] == null
              ? null
              : '${row['members_count']} household members',
        ],
      'scan' => [
          row['scan_type'],
          row['quantity_change'] == null ? null : 'Qty ${row['quantity_change']}',
          row['scanned_at'] ?? row['created_at'],
          row['location']?['name'],
        ],
      'location' => [row['address'], row['purok'], row['type'], row['status']],
      'report' => [row['description'], row['created_at'] ?? row['date']],
      _ => [row['body'] ?? row['message'], row['created_at'], row['status']],
    };

    return fields
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .map((value) => value.toString())
        .join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        final raw = snapshot.data?[widget.listKey] as List? ?? const [];
        final rows = raw.where((item) {
          final row = item as Map<String, dynamic>;
          final haystack = '${_title(row)} ${_subtitle(row)}';
          return haystack.toLowerCase().contains(search.toLowerCase());
        }).toList();

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              future = Api.req('GET', widget.path);
            });
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(widget.subtitle, style: const TextStyle(color: muted, fontSize: 13)),
              const SizedBox(height: 14),
              TextField(
                onChanged: (value) => setState(() => search = value),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search ${widget.title.toLowerCase()}...',
                ),
              ),
              const SizedBox(height: 14),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (snapshot.hasError)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_off_outlined, size: 36, color: muted),
                        const SizedBox(height: 10),
                        Text(
                          'Could not load ${widget.title.toLowerCase()}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          snapshot.error.toString().replaceFirst('Exception: ', ''),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => setState(() {
                            future = Api.req('GET', widget.path);
                          }),
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!snapshot.hasError &&
                  snapshot.connectionState == ConnectionState.done &&
                  rows.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(26),
                    child: Column(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xffeff6ff),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(icon, color: blue, size: 27),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          search.isEmpty ? 'No ${widget.title.toLowerCase()} found' : 'No matching results',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Pull down to refresh the list.',
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ...rows.map((item) {
                final row = item as Map<String, dynamic>;
                final sub = _subtitle(row);
                final status = row['status']?.toString();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(13),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xffeff6ff),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(icon, color: blue),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _title(row),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (sub.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Text(
                                      sub,
                                      style: const TextStyle(
                                        color: muted,
                                        fontSize: 12,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                if (status != null && status.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: _StatusChip(status: status),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, color: Color(0xff94a3b8)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final lowercase = status.toLowerCase();
    final color = lowercase.contains('complete') ||
            lowercase.contains('available') ||
            lowercase.contains('stock')
        ? const Color(0xff059669)
        : lowercase.contains('cancel') || lowercase.contains('low')
            ? const Color(0xffdc2626)
            : const Color(0xff64748b);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
