part of '../main.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _resourcesByCategory  = [];
  List<Map<String, dynamic>> _distributionsByMonth = [];
  List<Map<String, dynamic>> _lowStock             = [];
  List<Map<String, dynamic>> _scansByType          = [];
  List<Map<String, dynamic>> _resourcesByLocation  = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await Api.req('GET', '/reports');
      final s = result['summary'] as Map<String, dynamic>? ?? result;
      if (mounted) {
        setState(() {
          _summary = s;
          _resourcesByCategory  = (result['resources_by_category']  as List? ?? [])
              .map((e) => e as Map<String, dynamic>).toList();
          _distributionsByMonth = (result['distributions_by_month'] as List? ?? [])
              .map((e) => e as Map<String, dynamic>).toList();
          _lowStock             = (result['low_stock'] as List? ?? [])
              .map((e) => e as Map<String, dynamic>).toList();
          _scansByType          = (result['qr_scans_by_type'] as List? ?? [])
              .map((e) => e as Map<String, dynamic>).toList();
          _resourcesByLocation  = (result['resources_by_location'] as List? ?? [])
              .map((e) => e as Map<String, dynamic>).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  int _val(String key) {
    final v = _summary[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '0') ?? 0;
  }

  String _formatScanTypeLabel(String raw) {
    switch (raw.toLowerCase()) {
      case 'completed': return 'Completed';
      case 'pending':   return 'Pending';
      case 'cancelled': return 'Cancelled';
      case 'released':  return 'Released';
      case 'returned':  return 'Returned';
      case 'verified':  return 'Verified';
      default:          return raw.replaceAll('_', ' ').toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) { return const Center(child: CircularProgressIndicator()); }
    if (_error != null) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 40, color: muted),
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(color: muted, fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: _load, child: const Text('Try again')),
        ],
      ));
    }

    final stats = [
      {'label': 'Total Resources',     'value': _val('total_resources'),          'icon': Icons.inventory_2_outlined,        'color': blue,                    'tint': const Color(0xffeff6ff)},
      {'label': 'Total Families',      'value': _val('total_families'),           'icon': Icons.groups_outlined,             'color': const Color(0xff4f46e5), 'tint': const Color(0xffeef2ff)},
      {'label': 'Completed',           'value': _val('completed_distributions'),  'icon': Icons.check_circle_outline,        'color': const Color(0xff059669), 'tint': const Color(0xffecfdf5)},
      {'label': 'Pending',             'value': _val('pending_distributions'),    'icon': Icons.hourglass_empty_outlined,    'color': const Color(0xfff59e0b), 'tint': const Color(0xfffffbeb)},
      {'label': 'Cancelled',           'value': _val('cancelled_distributions'),  'icon': Icons.cancel_outlined,             'color': const Color(0xffdc2626), 'tint': const Color(0xfffff1f2)},
      {'label': 'Households Served',   'value': _val('household_member_served'),  'icon': Icons.volunteer_activism_outlined, 'color': const Color(0xff0d9488), 'tint': const Color(0xfff0fdfa)},
      {'label': 'QR Scans',            'value': _val('total_scans'),              'icon': Icons.qr_code_2_rounded,           'color': const Color(0xffa855f7), 'tint': const Color(0xfffaf5ff)},
      {'label': 'Low Stock Items',     'value': _val('low_stock_count'),          'icon': Icons.warning_amber_rounded,       'color': const Color(0xffdc2626), 'tint': const Color(0xfffff1f2)},
    ];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Relief Operation Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ink)),
          const SizedBox(height: 4),
          const Text('Summary statistics for your assigned location', style: TextStyle(color: muted, fontSize: 13)),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: stats.map((s) => Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: s['tint'] as Color, borderRadius: BorderRadius.circular(11)),
                      child: Icon(s['icon'] as IconData, color: s['color'] as Color, size: 20),
                    ),
                    Text('${s['value']}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: ink, height: 1.1)),
                    Text(s['label'] as String, style: const TextStyle(fontSize: 11, color: muted), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 20),

          // Resources by Category
          if (_resourcesByCategory.isNotEmpty) ...[
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Resources by Category', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ..._resourcesByCategory.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Expanded(child: Text(c['category']?.toString() ?? 'Uncategorized', style: const TextStyle(fontSize: 13, color: ink))),
                    Text('${c['count']} items \u2022 ${c['quantity']} units', style: const TextStyle(fontSize: 12, color: muted)),
                  ]),
                )),
              ]),
            )),
            const SizedBox(height: 14),
          ],

          // Distributions by Month
          if (_distributionsByMonth.isNotEmpty) ...[
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Distributions by Month', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ..._distributionsByMonth.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Expanded(child: Text(m['month']?.toString() ?? '', style: const TextStyle(fontSize: 13, color: ink))),
                    Text('${m['count']} distributions \u2022 ${m['household_member']} served', style: const TextStyle(fontSize: 12, color: muted)),
                  ]),
                )),
              ]),
            )),
            const SizedBox(height: 14),
          ],

          // QR Scans by Type
          if (_scansByType.isNotEmpty) ...[
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('QR Scans by Type', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ..._scansByType.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Expanded(child: Text(_formatScanTypeLabel(s['scan_type']?.toString() ?? ''), style: const TextStyle(fontSize: 13, color: ink))),
                    Text('${s['count']} scans', style: const TextStyle(fontSize: 12, color: muted)),
                  ]),
                )),
              ]),
            )),
            const SizedBox(height: 14),
          ],

          // Resources by Location
          if (_resourcesByLocation.isNotEmpty) ...[
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Resources by Location', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ..._resourcesByLocation.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Expanded(child: Text(l['location']?.toString() ?? 'Unknown', style: const TextStyle(fontSize: 13, color: ink))),
                    Text('${l['resources_count']} items \u2022 ${l['total_quantity']} units', style: const TextStyle(fontSize: 12, color: muted)),
                  ]),
                )),
              ]),
            )),
            const SizedBox(height: 14),
          ],


          // Low Stock Watchlist
          if (_lowStock.isNotEmpty) ...[
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Low Stock Watchlist', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xffdc2626))),
                const SizedBox(height: 12),
                ..._lowStock.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xffdc2626), size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item['name']?.toString() ?? '', style: const TextStyle(fontSize: 13, color: ink))),
                    Text('${item['quantity']} / ${item['minimum_threshold']} ${item['unit'] ?? ''}',
                        style: const TextStyle(fontSize: 12, color: Color(0xffdc2626), fontWeight: FontWeight.w600)),
                  ]),
                )),
              ]),
            )),
            const SizedBox(height: 14),
          ],

          // Export Report button
          FilledButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Export report \u2014 coming soon.')),
            ),
            icon: const Icon(Icons.download_outlined),
            label: const Text('Export Report'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xff4f46e5),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// --- Family Register Sheet (staff manually registers a family) ---------------

