part of '../main.dart';

class NavItem {
  final String title;
  final IconData icon;
  final Widget page;
  const NavItem(this.title, this.icon, this.page);
}

// --- Staff Home ---------------------------------------------------------------

class StaffHome extends StatefulWidget {
  const StaffHome({super.key});
  @override
  State<StaffHome> createState() => _StaffHomeState();
}

class _StaffHomeState extends State<StaffHome> {
  int index = 0;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _announcementTimer;

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

  @override
  void initState() {
    super.initState();
    _announcementTimer = Timer.periodic(const Duration(seconds: 60), (_) => _checkAnnouncements());
  }

  @override
  void dispose() {
    _announcementTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAnnouncements() async {
    if (!mounted) return;
    try {
      final result = await Api.req('GET', '/announcements');
      final list = result['announcements'] as List? ?? result['data'] as List? ?? [];
      if (list.isEmpty || !mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final lastId = prefs.getInt('last_staff_announcement_id') ?? 0;
      final newItems = list.where((a) {
        final id = (a as Map)['id'];
        return id is int ? id > lastId : (int.tryParse(id.toString()) ?? 0) > lastId;
      }).toList();
      if (newItems.isEmpty || !mounted) return;
      final latest = newItems.last as Map;
      final newMaxId = list.fold<int>(0, (m, a) {
        final id = (a as Map)['id'];
        final i = id is int ? id : (int.tryParse(id.toString()) ?? 0);
        return i > m ? i : m;
      });
      await prefs.setInt('last_staff_announcement_id', newMaxId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(latest['title']?.toString() ?? 'New announcement'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(latest['title']?.toString() ?? 'Announcement'),
                  content: Text(latest['body']?.toString() ?? ''),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                ),
              );
            },
          ),
        ));
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await Api.req('POST', '/logout');
    } catch (_) {}
    await Api.clearToken();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
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
              decoration: BoxDecoration(color: blue, borderRadius: BorderRadius.circular(11)),
              child: const Center(child: Text('DR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(selected.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const Text('Disaster Relief', style: TextStyle(color: muted, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (_) => const _NotificationsSheet(),
            ),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xffdbeafe),
              child: Text('S', style: TextStyle(color: blue, fontWeight: FontWeight.bold)),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                logout();
              } else if (value == 'profile') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
              } else {
                _showInfo(context, 'Staff account', 'Signed in with a staff account.');
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'profile', child: Text('Profile')),
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
                      decoration: BoxDecoration(color: blue, borderRadius: BorderRadius.circular(13)),
                      child: const Center(child: Text('DR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Disaster Relief', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        SizedBox(height: 3),
                        Text('Staff application', style: TextStyle(color: muted, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline, color: muted),
                      title: const Text('Profile', style: TextStyle(color: ink, fontWeight: FontWeight.w500)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
                      },
                    ),
                    const Divider(height: 12),
                    for (var i = 0; i < items.length; i++)
                      ListTile(
                        leading: Icon(items[i].icon, color: i == index ? blue : muted),
                        title: Text(items[i].title,
                            style: TextStyle(
                                color: i == index ? blue : ink,
                                fontWeight: i == index ? FontWeight.w700 : FontWeight.w500)),
                        selected: i == index,
                        selectedTileColor: const Color(0xffeff6ff),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                title: const Text('Log out', style: TextStyle(color: Colors.red)),
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
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Resources'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          NavigationDestination(icon: Icon(Icons.local_shipping_outlined), label: 'Relief'),
        ],
      ),
    );
  }
}

void _showInfo(BuildContext context, String title, String message) => showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))]));

// --- Staff Dashboard ----------------------------------------------------------

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});
  @override State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  late Future<List<Map<String, dynamic>>> future = _load();

  Future<List<Map<String, dynamic>>> _load() async {
    final paths = ['/me', '/resources', '/distributions/history', '/staff/families', '/qr/scans'];
    return Future.wait(paths.map((p) async {
      try { return await Api.req('GET', p); } catch (_) { return <String, dynamic>{}; }
    }));
  }

  List<dynamic> _rows(Map<String, dynamic> map, String key) =>
      map[key] is List ? map[key] as List : <dynamic>[];

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snap) {
          final data          = snap.data ?? const <Map<String, dynamic>>[];
          final me            = data.isNotEmpty   ? data[0]                         : <String, dynamic>{};
          final resources     = data.length > 1   ? _rows(data[1], 'resources')     : <dynamic>[];
          final distributions = data.length > 2   ? _rows(data[2], 'distributions') : <dynamic>[];
          final families      = data.length > 3   ? _rows(data[3], 'families')      : <dynamic>[];
          final scans         = data.length > 4   ? _rows(data[4], 'scans')         : <dynamic>[];

          final user         = me['user'] is Map ? me['user'] as Map<String, dynamic> : <String, dynamic>{};
          final locationName = user['location']?['name']?.toString();
          final purokName    = user['purok']?['name']?.toString();
          final staffName    = user['name']?.toString();

          final pending = distributions.where((e) =>
              (e as Map)['status']?.toString().toLowerCase() == 'pending').length;
          final completed = distributions.where((e) =>
              (e as Map)['status']?.toString().toLowerCase() == 'completed').length;
          final cancelled = distributions.where((e) =>
              (e as Map)['status']?.toString().toLowerCase() == 'cancelled').length;
          final stock = resources.fold<num>(0, (sum, e) {
            final q = (e as Map)['quantity'];
            return sum + (q is num ? q : (num.tryParse(q.toString()) ?? 0));
          });
          final householdsServed = families.where((f) {
            final dist = (f as Map)['latest_distribution'];
            return dist is Map &&
                dist['status']?.toString().toLowerCase() == 'completed';
          }).length;

          return RefreshIndicator(
            onRefresh: () async => setState(() => future = _load()),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              children: [
                const Text('Overview of relief operations', style: TextStyle(color: muted, fontSize: 13)),
                const SizedBox(height: 16),

                // My Assignment card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(color: const Color(0xffeff6ff), borderRadius: BorderRadius.circular(11)),
                              child: const Icon(Icons.badge_outlined, color: blue, size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Text('My Assignment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ink)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 14),
                        _AssignmentRow(
                          icon: Icons.location_on_outlined,
                          label: 'Assigned Location',
                          value: snap.hasData ? (locationName ?? 'Not assigned') : '\u2014',
                        ),
                        const SizedBox(height: 10),
                        _AssignmentRow(
                          icon: Icons.map_outlined,
                          label: 'Assigned Purok',
                          value: snap.hasData ? (purokName ?? 'Not assigned') : '\u2014',
                        ),
                        const SizedBox(height: 10),
                        _AssignmentRow(
                          icon: Icons.person_outline,
                          label: 'Purok Handler',
                          value: snap.hasData ? (staffName ?? 'Unknown') : '\u2014',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                if (snap.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(),

                // Stat grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.42,
                  children: [
                    _StatCard(title: 'Total Resources',      value: snap.hasData ? '${resources.length}'    : '\u2014', icon: Icons.inventory_2_outlined,       tint: const Color(0xffeff6ff), color: blue),
                    _StatCard(title: 'Total Stock Quantity',  value: snap.hasData ? '$stock'                 : '\u2014', icon: Icons.widgets_outlined,            tint: const Color(0xffeef2ff), color: const Color(0xff4f46e5)),
                    _StatCard(title: 'Pending',               value: snap.hasData ? '$pending'           : '\u2014', icon: Icons.local_shipping_outlined,     tint: const Color(0xfff1f5f9), color: const Color(0xff475569)),
                    _StatCard(title: 'Completed',             value: snap.hasData ? '$completed'             : '\u2014', icon: Icons.check_circle_outline,        tint: const Color(0xffecfdf5), color: const Color(0xff059669)),
                    _StatCard(title: 'Cancelled',             value: snap.hasData ? '$cancelled'             : '\u2014', icon: Icons.cancel_outlined,             tint: const Color(0xfffff1f2), color: const Color(0xffdc2626)),
                    _StatCard(title: 'Families',              value: snap.hasData ? '${families.length}'     : '\u2014', icon: Icons.groups_outlined,             tint: const Color(0xffeff6ff), color: blue),
                    _StatCard(title: 'QR Scans Logged',       value: snap.hasData ? '${scans.length}'        : '\u2014', icon: Icons.qr_code_2_rounded,           tint: const Color(0xfffaf5ff), color: const Color(0xffa855f7)),
                    _StatCard(title: 'Households Served',     value: snap.hasData ? '$householdsServed'  : '\u2014', icon: Icons.volunteer_activism_outlined, tint: const Color(0xfff0fdfa), color: const Color(0xff0d9488)),
                  ],
                ),
                const SizedBox(height: 22),

                const SizedBox(height: 4),
                const Text(
                  'Current Relief Distribution',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ink),
                ),
                const SizedBox(height: 6),
                _SectionCard(
                  title: 'Recent Distributions',
                  action: 'View All',
                  onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DistributionPage())),
                  child: distributions.isEmpty
                      ? const _EmptyState(text: 'No distributions to show yet.')
                      : Column(children: distributions.take(4).map((e) {
                          final m = e as Map;
                          return _MiniRecord(
                            icon: Icons.local_shipping_outlined,
                            title: '${m['head_name'] ?? m['family']?['head_name'] ?? 'Family distribution'}',
                            subtitle: '${m['status'] ?? 'Status unavailable'} \u2022 ${m['distribution_date'] ?? m['scheduled_at'] ?? ''}',
                          );
                        }).toList()),
                ),
                const SizedBox(height: 14),

                _SectionCard(
                  title: 'Recent QR Scans',
                  action: 'View All',
                  onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanHistoryPage())),
                  child: scans.isEmpty
                      ? const _EmptyState(text: 'No scan records to show yet.')
                      : Column(children: scans.take(4).map((e) {
                          final m = e as Map;
                          return _MiniRecord(
                            icon: Icons.qr_code_2,
                            title: '${m['resource']?['name'] ?? m['resource_name'] ?? 'Resource scan'}',
                            subtitle: '${m['scan_type'] ?? 'Scan'} \u2022 ${m['scanned_at'] ?? ''}',
                          );
                        }).toList()),
                ),
                const SizedBox(height: 14),

                _SectionCard(
                  title: 'Low Stock Alerts',
                  child: resources.where((e) {
                    final m = e as Map;
                    final q = m['quantity']; final min = m['minimum_threshold'] ?? m['min_quantity'];
                    return q is num && min is num && q <= min;
                  }).isEmpty
                      ? const _EmptyState(text: 'No low-stock alerts, or stock thresholds are unavailable.')
                      : Column(children: resources.where((e) {
                          final m = e as Map;
                          final q = m['quantity']; final min = m['minimum_threshold'] ?? m['min_quantity'];
                          return q is num && min is num && q <= min;
                        }).map((e) {
                          final m = e as Map;
                          return _MiniRecord(
                            icon: Icons.warning_amber_rounded,
                            title: '${m['name'] ?? 'Resource'}',
                            subtitle: 'Remaining stock: ${m['quantity']}',
                          );
                        }).toList()),
                ),
              ],
            ),
          );
        },
      );
}

// Assignment row helper
class _AssignmentRow extends StatelessWidget {
  const _AssignmentRow({required this.icon, required this.label, required this.value});
  final IconData icon; final String label; final String value;
  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: muted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: muted)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ink)),
              ],
            ),
          ),
        ],
      );
}

class _StatCard extends StatelessWidget {
  final String title, value; final IconData icon; final Color tint, color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.tint, required this.color});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: color, size: 21)), Text(value, style: const TextStyle(fontSize: 24, height: 1.1, fontWeight: FontWeight.w800, color: ink)), Text(title, style: const TextStyle(fontSize: 11, color: muted), maxLines: 2, overflow: TextOverflow.ellipsis)])));
}

class _SectionCard extends StatelessWidget {
  final String title; final String? action; final VoidCallback? onAction; final Widget child;
  const _SectionCard({required this.title, required this.child, this.action, this.onAction});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))), if (action != null) TextButton(onPressed: onAction, child: Text(action!))]), const SizedBox(height: 8), child])));
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4), child: Center(child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 13))));
}

class _MiniRecord extends StatelessWidget {
  final IconData icon; final String title, subtitle;
  const _MiniRecord({required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => ListTile(contentPadding: EdgeInsets.zero, leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xffeff6ff), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: blue, size: 20)), title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: Text(subtitle.trim().isEmpty ? '\u2014' : subtitle, style: const TextStyle(fontSize: 11, color: muted), maxLines: 1, overflow: TextOverflow.ellipsis));
}

// --- Scan Page (QR Tracking) --------------------------------------------------

