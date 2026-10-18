part of '../main.dart';

class ScanHistoryPage extends StatelessWidget {
  const ScanHistoryPage({super.key});
  @override
  Widget build(BuildContext context) => const _ApiListPage(
        path: '/qr/scans',
        listKey: 'scans',
        title: 'QR Scan History',
        subtitle: 'Recent tracking activity',
        kind: 'scan',
      );
}

// --- _ApiListPage (kept intact for ScanHistoryPage) --------------------------

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
      case 'resource':     return Icons.inventory_2_outlined;
      case 'distribution': return Icons.local_shipping_outlined;
      case 'family':       return Icons.groups_outlined;
      case 'scan':         return Icons.qr_code_2;
      case 'location':     return Icons.location_on_outlined;
      case 'report':       return Icons.description_outlined;
      default:             return Icons.chat_bubble_outline;
    }
  }

  String _title(Map<String, dynamic> row) {
    return (row['family']?['head_name'] ??
            row['head_name'] ??
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
          row['members_count'] == null ? null : '${row['members_count']} household members',
        ],
      'scan' => [
          row['family']?['head_name'],
          row['family']?['head_name'],
          row['scan_type'],
          row['quantity_change'] == null ? null : 'Qty ${row['quantity_change']}',
          row['location']?['name'],
          row['scanner']?['name'] == null ? null : 'By ${row['scanner']['name']}',
          row['receiver'] == null || row['receiver'].toString().trim().isEmpty
              ? null
              : 'Claimed by: ${row['receiver']}',
          _fmtScanDate(row['scanned_at'] ?? row['created_at']),
        ],
      'location' => [row['address'], row['purok'], row['type'], row['status']],
      'report'   => [row['description'], row['created_at'] ?? row['date']],
      _          => [row['body'] ?? row['message'], row['created_at'], row['status']],
    };

    return fields
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .map((value) => value.toString())
        .join(' \u2022 ');
  }

  String _fmtScanDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return DateFormat('MMM d, y h:mm a').format(dt);
    } catch (_) {
      return raw.toString();
    }
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
          onRefresh: () async => setState(() => future = Api.req('GET', widget.path)),
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
                const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator())),
              if (snapshot.hasError)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_off_outlined, size: 36, color: muted),
                        const SizedBox(height: 10),
                        Text('Could not load ${widget.title.toLowerCase()}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(snapshot.error.toString().replaceFirst('Exception: ', ''),
                            textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 12)),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => setState(() => future = Api.req('GET', widget.path)),
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!snapshot.hasError && snapshot.connectionState == ConnectionState.done && rows.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(26),
                    child: Column(
                      children: [
                        Container(
                          width: 54, height: 54,
                          decoration: BoxDecoration(color: const Color(0xffeff6ff), borderRadius: BorderRadius.circular(16)),
                          child: Icon(icon, color: blue, size: 27),
                        ),
                        const SizedBox(height: 12),
                        Text(search.isEmpty ? 'No ${widget.title.toLowerCase()} found' : 'No matching results',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 5),
                        const Text('Pull down to refresh the list.', style: TextStyle(color: muted, fontSize: 12)),
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
                            width: 42, height: 42,
                            decoration: BoxDecoration(color: const Color(0xffeff6ff), borderRadius: BorderRadius.circular(13)),
                            child: Icon(icon, color: blue),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_title(row), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                if (sub.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Text(sub, style: const TextStyle(color: muted, fontSize: 12, height: 1.4)),
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

