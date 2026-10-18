part of '../main.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});
  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  List<Map<String, dynamic>> _locations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        Api.req('GET', '/locations'),
        Api.req('GET', '/me'),
      ]);
      final raw = results[0]['locations'] as List? ?? [];
      final user = results[1]['user'] as Map<String, dynamic>?;
      if (mounted) {
        setState(() {
          final myLocId = user?['location_id']?.toString();
          final all = raw.map((e) => e as Map<String, dynamic>).toList();
          _locations = myLocId != null && myLocId.isNotEmpty
              ? all.where((l) => l['id']?.toString() == myLocId).toList()
              : all;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Color _statusColor(String? s) {
    final v = s?.toLowerCase() ?? '';
    if (v == 'active') return const Color(0xff059669);
    if (v == 'inactive' || v == 'closed') return const Color(0xffdc2626);
    return muted;
  }

  String _formatLocationType(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'distribution_center': return 'Distribution Center';
      case 'warehouse':           return 'Warehouse';
      case 'staging_area':        return 'Staging Area';
      case 'evacuation_center':   return 'Evacuation Center';
      case 'relief_center':       return 'Relief Center';
      default:                    return raw ?? '';
    }
  }

  void _showDetail(Map<String, dynamic> l) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xffe2e8f0), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(l['name']?.toString() ?? 'Location', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ink)),
            const SizedBox(height: 12),
            _DetailRow('Type',                      _formatLocationType(l['type']?.toString())),
            _DetailRow('Address',                   l['address']?.toString()),
            _DetailRow('City / Barangay',           l['city']?.toString()),
            _DetailRow('Families',                  l['families_count']?.toString()),
            _DetailRow('Resources Stocked',
                (l['resources_count'] != null || l['resources_sum_quantity'] != null)
                    ? '${l['resources_count'] ?? 0} items \u2022 ${l['resources_sum_quantity'] ?? 0} units'
                    : null),
            _DetailRow('Deliveries Completed',      l['completed_distributions_count']?.toString()),
            _DetailRow('Household Members Served',  l['household_member_served']?.toString()),
            _DetailRow('Barangay Captain',          l['contact_person']?.toString()),
            _DetailRow('Captain Contact',           l['contact_phone']?.toString()),
            _DetailRow('Email',                     l['email']?.toString()),
            _DetailRow('Total Resource Stock',         l['resources_sum_quantity']?.toString()),
            _DetailRow('Status',                    l['status']?.toString()),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_loading) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
        if (_error != null) Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: Colors.red))),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _locations.isEmpty && !_loading
                ? const Center(child: Text('No locations assigned.', style: TextStyle(color: muted)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _locations.length,
                    itemBuilder: (_, i) {
                      final l = _locations[i];
                      final status = l['status']?.toString() ?? '';
                      final statusColor = _statusColor(status);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () => _showDetail(l),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(color: const Color(0xffeff6ff), borderRadius: BorderRadius.circular(13)),
                                    child: const Icon(Icons.location_on_outlined, color: blue),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(l['name']?.toString() ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                        if ((l['type']?.toString() ?? '').isNotEmpty) Text('${_formatLocationType(l['type']?.toString())} \u2022 ${l['city'] ?? ''}', style: const TextStyle(fontSize: 12, color: muted)),
                                        if (status.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                              child: Text(status, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: Color(0xff94a3b8)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

// --- Report Page --------------------------------------------------------------

