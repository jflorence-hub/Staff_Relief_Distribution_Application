part of '../main.dart';

class ResourcePage extends StatefulWidget {
  const ResourcePage({super.key});
  @override
  State<ResourcePage> createState() => _ResourcePageState();
}

class _ResourcePageState extends State<ResourcePage> {
  List<Map<String, dynamic>> _resources = [];
  Map<String, dynamic>? _meUser;
  String _search = '';
  String? _selectedCategory;
  String? _selectedDisaster;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        Api.req('GET', '/resources'),
        Api.req('GET', '/me'),
      ]);
      final raw = results[0]['resources'] as List? ?? [];
      final user = results[1]['user'] as Map<String, dynamic>?;
      if (mounted) {
        setState(() {
          _resources = raw.map((e) => e as Map<String, dynamic>).toList();
          _meUser = user;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final myLocId = _meUser?['location_id']?.toString();
    return _resources.where((r) {
      final locId = r['location_id']?.toString() ?? r['location']?['id']?.toString();
      if (myLocId != null && myLocId.isNotEmpty && locId != null && locId != myLocId) return false;
      if (_selectedCategory != null && r['category']?.toString() != _selectedCategory) return false;
      if (_selectedDisaster != null && r['disaster']?.toString() != _selectedDisaster) return false;
      if (_search.isNotEmpty) {
        final hay = '${r['name']} ${r['category']} ${r['location']?['name']}'.toLowerCase();
        if (!hay.contains(_search.toLowerCase())) return false;
      }
      return true;
    }).toList();
  }

  List<String> get _categories {
    final cats = _resources.map((r) => r['category']?.toString() ?? '').where((c) => c.isNotEmpty).toSet().toList();
    cats.sort();
    return cats;
  }

  List<String> get _disasters {
    final d = _resources.map((r) => r['disaster']?.toString() ?? '').where((c) => c.isNotEmpty).toSet().toList();
    d.sort();
    return d;
  }

  Color _statusColor(String? status) {
    final s = status?.toLowerCase() ?? '';
    if (s.contains('available') || s.contains('in_stock') || s.contains('active')) return const Color(0xff059669);
    if (s.contains('low') || s.contains('critical')) return const Color(0xffdc2626);
    return muted;
  }

  String _formatResourceStatus(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'in_stock':      return 'In Stock';
      case 'low_stock':     return 'Low Stock';
      case 'out_of_stock':  return 'Out of Stock';
      default:              return raw ?? '';
    }
  }

  void _showDetail(Map<String, dynamic> r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xffe2e8f0), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(r['name']?.toString() ?? 'Resource', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ink)),
            const SizedBox(height: 12),
            _DetailRow('Category', r['category']?.toString()),
            _DetailRow('Quantity', '${r['quantity'] ?? ''} ${r['unit'] ?? ''}'),
            _DetailRow('Status', _formatResourceStatus(r['status']?.toString())),
            _DetailRow('Location', r['location']?['name']?.toString()),
            _DetailRow('Disaster', r['disaster']?.toString()),
            _DetailRow('Description', r['description']?.toString()),
            _DetailRow('Min Threshold', r['minimum_threshold']?.toString()),
            if ((r['qr_code']?.toString() ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('QR Code', style: TextStyle(fontSize: 12, color: muted)),
              const SizedBox(height: 4),
              SelectableText(r['qr_code'].toString(), style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search resources...'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All')),
                        ..._categories.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))),
                      ],
                      onChanged: (v) => setState(() => _selectedCategory = v),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedDisaster,
                      decoration: const InputDecoration(labelText: 'Disaster', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All')),
                        ..._disasters.map((d) => DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis))),
                      ],
                      onChanged: (v) => setState(() => _selectedDisaster = v),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_loading) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
        if (_error != null) Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: Colors.red))),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: filtered.isEmpty && !_loading
                ? const Center(child: Text('No resources found.', style: TextStyle(color: muted)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final r = filtered[i];
                      final status = r['status']?.toString() ?? '';
                      final statusColor = _statusColor(status);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () => _showDetail(r),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(color: const Color(0xffeff6ff), borderRadius: BorderRadius.circular(13)),
                                    child: const Icon(Icons.inventory_2_outlined, color: blue),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(r['name']?.toString() ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if ((r['category']?.toString() ?? '').isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(color: const Color(0xffeff6ff), borderRadius: BorderRadius.circular(8)),
                                                child: Text(r['category'].toString(), style: const TextStyle(fontSize: 11, color: blue)),
                                              ),
                                            const SizedBox(width: 6),
                                            Text('${r['quantity'] ?? ''} ${r['unit'] ?? ''}', style: const TextStyle(fontSize: 12, color: muted)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        if ((r['location']?['name']?.toString() ?? '').isNotEmpty)
                                          Text(r['location']['name'].toString(), style: const TextStyle(fontSize: 11, color: muted)),
                                        if (status.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                              child: Text(_formatResourceStatus(status), style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String? value;
  @override
  Widget build(BuildContext context) {
    if (value == null || value!.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 12, color: muted))),
          Expanded(child: Text(value!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ink))),
        ],
      ),
    );
  }
}

// --- Distribution Page --------------------------------------------------------

