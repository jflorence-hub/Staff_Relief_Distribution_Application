part of '../main.dart';

class DistributionPage extends StatefulWidget {
  const DistributionPage({super.key});
  @override
  State<DistributionPage> createState() => _DistributionPageState();
}

class _DistributionPageState extends State<DistributionPage> {
  List<Map<String, dynamic>> _distributions = [];
  List<Map<String, dynamic>> _schedules = [];
  Map<String, dynamic>? _selectedSchedule;
  String _statusFilter = 'pending';
  String _search = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await Api.req('GET', '/distributions/history');
      final raw = result['distributions'] as List? ?? [];
      final schedRaw = result['schedules'] as List? ?? [];
      if (mounted) {
        setState(() {
          _distributions = raw.map((e) => e as Map<String, dynamic>).toList();
          _schedules = schedRaw.map((e) => e as Map<String, dynamic>).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _distributions;
    if (_selectedSchedule != null) {
      list = list.where((d) {
        final date = d['distribution_date']?.toString().substring(0, 10);
        final resName = d['resource']?['name']?.toString();
        final locName = d['location']?['name']?.toString();
        return date == _selectedSchedule!['date'] &&
            resName == _selectedSchedule!['resource_name'] &&
            locName == _selectedSchedule!['location_name'];
      }).toList();
    }
    // Status/exclusion filter
    switch (_statusFilter) {
      case 'pending':
        list = list
            .where((d) =>
                (d['status']?.toString() ?? '') == 'pending' &&
                (d['excluded'] as bool? ?? false) == false)
            .toList();
        break;
      case 'completed':
        list = list
            .where((d) => (d['status']?.toString() ?? '') == 'completed')
            .toList();
        break;
      case 'excluded':
        list = list
            .where((d) => (d['excluded'] as bool? ?? false) == true)
            .toList();
        break;
      default: // 'all'
        break;
    }
    if (_search.isEmpty) return list;
    return list.where((d) {
      final hay =
          '${d['family']?['head_name'] ?? d['head_name'] ?? ''} ${d['family_id'] ?? ''} ${d['status'] ?? ''}'
              .toLowerCase();
      return hay.contains(_search.toLowerCase());
    }).toList();
  }

  int _countFiltered(String filter) {
    var list = _distributions;
    if (_selectedSchedule != null) {
      list = list.where((d) {
        final date = d['distribution_date']?.toString().substring(0, 10);
        final resourceName = d['resource']?['name']?.toString() ?? '';
        final locationName = d['location']?['name']?.toString() ?? '';
        return date == _selectedSchedule!['date'] &&
            resourceName == _selectedSchedule!['resource_name'] &&
            locationName == _selectedSchedule!['location_name'];
      }).toList();
    }
    switch (filter) {
      case 'pending':
        return list
            .where((d) =>
                (d['status']?.toString() ?? '') == 'pending' &&
                (d['excluded'] as bool? ?? false) == false)
            .length;
      case 'completed':
        return list
            .where((d) => (d['status']?.toString() ?? '') == 'completed')
            .length;
      case 'excluded':
        return list
            .where((d) => (d['excluded'] as bool? ?? false) == true)
            .length;
      default:
        return list.length;
    }
  }

  Color _statusColor(String? s) {
    final v = s?.toLowerCase() ?? '';
    if (v == 'completed') return const Color(0xff059669);
    if (v == 'cancelled' || v == 'canceled') return const Color(0xffdc2626);
    if (v == 'pending') return const Color(0xfff59e0b);
    return muted;
  }

  String _formatFamilyId(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    return raw;
  }

  String _formatDistDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final m = dt.minute.toString().padLeft(2, '0');
      final ap = dt.hour >= 12 ? 'PM' : 'AM';
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year} $h:$m $ap';
    } catch (_) {
      return raw;
    }
  }

  void _showDetail(Map<String, dynamic> d) {
    final family = d['family'] as Map? ?? {};
    final purok = family['purok']?['name'] ?? d['purok']?['name'] ?? '';
    final loc = family['location']?['name'] ?? d['location']?['name'] ?? '';
    final resource = d['resource'] as Map? ?? {};
    final isCompleted =
        (d['status']?.toString() ?? '').toLowerCase() == 'completed';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.95,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: const Color(0xffe2e8f0),
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Distribution Details',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: ink)),
            const SizedBox(height: 12),
            _DetailRow(
                'Relief Code', d['qr_code']?.toString() ?? d['id']?.toString()),
            _DetailRow(
                'Family ID',
                _formatFamilyId(family['family_id']?.toString() ??
                    d['family_id']?.toString())),
            _DetailRow('Head of Family',
                family['head_name']?.toString() ?? d['head_name']?.toString()),
            _DetailRow('Family Head',
                family['head_name']?.toString() ?? d['head_name']?.toString()),
            _DetailRow('Location', loc.isNotEmpty ? '$purok, $loc' : purok),
            _DetailRow('Relief',
                resource['name']?.toString() ?? d['resource_name']?.toString()),
            _DetailRow('Additional Items', d['additional_items']?.toString()),
            _DetailRow('Qty', d['quantity']?.toString()),
            _DetailRow('Scanned By', d['scanned_by']?.toString()),
            _DetailRow('Status', d['status']?.toString()),
            if (d['excluded'] as bool? ?? false) _DetailRow('Excluded', 'Yes'),
            if ((d['exclusion_reason']?.toString() ?? '').isNotEmpty)
              _DetailRow('Exclusion Reason', d['exclusion_reason'].toString()),
            if (isCompleted)
              _DetailRow('Receiver',
                  d['recipient_name']?.toString() ?? d['receiver']?.toString()),
            _DetailRow('Disaster', d['disaster']?.toString()),
            _DetailRow('Reason', d['reason']?.toString()),
            _DetailRow(
                'Date',
                _formatDistDate(d['distribution_date']?.toString() ??
                    d['scheduled_at']?.toString())),
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
        if (_schedules.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: DropdownButtonFormField<Map<String, dynamic>?>(
              initialValue: _selectedSchedule,
              decoration: const InputDecoration(
                  labelText: 'Schedule',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('All schedules')),
                ..._schedules.map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(
                        '${s['date'] ?? ''} \u2022 ${s['resource_name'] ?? ''}',
                        maxLines: 2,
                        softWrap: true,
                      ),
                    )),
              ],
              onChanged: (v) => setState(() => _selectedSchedule = v),
            ),
          ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              for (final tab in [
                'all',
                'pending',
                'completed',
                'excluded'
              ]) ...[
                _FilterTab(
                  label: tab == 'all'
                      ? 'All'
                      : tab == 'pending'
                          ? 'Pending'
                          : tab == 'completed'
                              ? 'Completed'
                              : 'Excluded',
                  count: _countFiltered(tab),
                  isActive: _statusFilter == tab,
                  color: tab == 'pending'
                      ? const Color(0xfff59e0b)
                      : tab == 'completed'
                          ? const Color(0xff059669)
                          : tab == 'excluded'
                              ? const Color(0xffdc2626)
                              : const Color(0xff2563eb),
                  onTap: () => setState(() => _statusFilter = tab),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search distributions...'),
          ),
        ),
        if (_loading) const Center(child: CircularProgressIndicator()),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined,
                        size: 36, color: muted),
                    const SizedBox(height: 8),
                    Text(_error!,
                        style: const TextStyle(color: muted, fontSize: 13),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: filtered.isEmpty && !_loading
                ? const Center(
                    child: Text('No distributions found.',
                        style: TextStyle(color: muted)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final d = filtered[i];
                      final family = d['family'] as Map? ?? {};
                      final name = family['head_name']?.toString() ??
                          d['head_name']?.toString() ??
                          d['recipient_name']?.toString() ??
                          'Distribution';
                      final resource = d['resource'] as Map? ?? {};
                      final resName = resource['name']?.toString() ??
                          d['resource_name']?.toString() ??
                          '';
                      final status = d['status']?.toString() ?? '';
                      final date = _formatDistDate(
                          d['distribution_date']?.toString() ??
                              d['scheduled_at']?.toString());
                      final statusColor = _statusColor(status);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () => _showDetail(d),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                        color: const Color(0xfff0fdfa),
                                        borderRadius:
                                            BorderRadius.circular(13)),
                                    child: const Icon(
                                        Icons.local_shipping_outlined,
                                        color: Color(0xff0d9488)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(name,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700)),
                                        if (resName.isNotEmpty)
                                          Text(resName,
                                              style: const TextStyle(
                                                  fontSize: 12, color: muted)),
                                        if (date.isNotEmpty)
                                          Text(date,
                                              style: const TextStyle(
                                                  fontSize: 11, color: muted)),
                                        if (status.isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                  color: statusColor.withValues(
                                                      alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8)),
                                              child: Text(status,
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: statusColor,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                            ),
                                          ),
                                        if (d['excluded'] as bool? ??
                                            false) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xffdc2626)
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Text('Excluded',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xffdc2626),
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ),
                                          if ((d['exclusion_reason']
                                                      ?.toString() ??
                                                  '')
                                              .isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 2),
                                              child: Text(
                                                d['exclusion_reason']
                                                    .toString(),
                                                style: const TextStyle(
                                                    fontSize: 11, color: muted),
                                              ),
                                            ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right,
                                      color: Color(0xff94a3b8)),
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

// --- Distribution Filter Tab Widget ------------------------------------------

class _FilterTab extends StatelessWidget {
  final String label;
  final int count;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.count,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : const Color(0xffe2e8f0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : const Color(0xff64748b),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.3)
                    : color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Location Page ------------------------------------------------------------
