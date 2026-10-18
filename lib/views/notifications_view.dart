part of '../main.dart';

class _NotificationsSheet extends StatefulWidget {
  const _NotificationsSheet();
  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await Api.req('GET', '/announcements');
      final list = result['announcements'] as List? ??
          result['data'] as List? ?? [];
      if (mounted) {
        setState(() {
          _items = list.map((e) => e as Map<String, dynamic>).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (_, ctrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Announcements',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ink)),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_off_outlined, size: 36, color: muted),
                              const SizedBox(height: 10),
                              const Text('Could not load announcements.',
                                  style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
                              const SizedBox(height: 6),
                              const Text('Check your connection and try again.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: muted, fontSize: 12)),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: () { setState(() { _loading = true; _error = null; }); _load(); },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _items.isEmpty
                        ? const Center(
                            child: Text('No announcements yet.',
                                style: TextStyle(color: muted, fontSize: 13)))
                        : ListView.separated(
                            controller: ctrl,
                            padding: const EdgeInsets.all(16),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const Divider(height: 12),
                            itemBuilder: (_, i) {
                              final item = _items[i];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title']?.toString() ?? 'Announcement',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: ink),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['body']?.toString() ?? '',
                                    style: const TextStyle(
                                        fontSize: 13, color: muted, height: 1.45),
                                  ),
                                ],
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final lowercase = status.toLowerCase();
    final color = lowercase.contains('complete') || lowercase.contains('available') || lowercase.contains('stock')
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
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ─── Scan dialog helper ─────────────────────────────────────────────────────

class _ScanInfoRow extends StatelessWidget {
  const _ScanInfoRow({required this.label, required this.value});
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xff64748b))),
          ),
          Expanded(
            child: Text(
              value!,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xff1e293b)),
            ),
          ),
        ],
      ),
    );
  }
}
