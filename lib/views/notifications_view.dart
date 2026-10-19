part of '../main.dart';

class _AnnouncementsSheet extends StatefulWidget {
  const _AnnouncementsSheet();
  @override
  State<_AnnouncementsSheet> createState() => _AnnouncementsSheetState();
}

class _AnnouncementsSheetState extends State<_AnnouncementsSheet> {
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
      final list =
          result['announcements'] as List? ?? result['data'] as List? ?? [];
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

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      builder: (_, ctrl) => SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: canvas,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xffdbeafe),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.campaign_rounded,
                          color: blue, size: 23),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Announcements',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: ink)),
                          SizedBox(height: 2),
                          Text('Updates for your barangay',
                              style: TextStyle(color: muted, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close announcements',
                      icon: const Icon(Icons.close_rounded),
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
                                  const Icon(Icons.cloud_off_outlined,
                                      size: 36, color: muted),
                                  const SizedBox(height: 10),
                                  const Text('Could not load announcements.',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: ink)),
                                  const SizedBox(height: 6),
                                  Text(_error!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: muted, fontSize: 12)),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: _refresh,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Try again'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _items.isEmpty
                            ? RefreshIndicator(
                                onRefresh: _refresh,
                                child: ListView(
                                  controller: ctrl,
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(24),
                                  children: const [
                                    SizedBox(height: 42),
                                    Icon(Icons.campaign_outlined,
                                        color: Color(0xff94a3b8), size: 46),
                                    SizedBox(height: 12),
                                    Text('No announcements yet.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: ink,
                                            fontWeight: FontWeight.w700)),
                                    SizedBox(height: 5),
                                    Text(
                                        'New updates will appear here when shared.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: muted, fontSize: 12)),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _refresh,
                                child: ListView.separated(
                                  controller: ctrl,
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _items.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (_, i) {
                                    final item = _items[i];
                                    final createdAt = DateTime.tryParse(
                                            item['created_at']?.toString() ??
                                                '')
                                        ?.toLocal();
                                    final timestamp = createdAt == null
                                        ? ''
                                        : DateFormat('MMM d, y • h:mm a')
                                            .format(createdAt);
                                    return Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(15),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: 34,
                                                  height: 34,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xffeff6ff),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            11),
                                                  ),
                                                  child: const Icon(
                                                      Icons.campaign_outlined,
                                                      color: blue,
                                                      size: 19),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    item['title']?.toString() ??
                                                        'Announcement',
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: ink),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              item['body']?.toString() ?? '',
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color: ink,
                                                  height: 1.5),
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                const Icon(
                                                    Icons.schedule_rounded,
                                                    color: muted,
                                                    size: 14),
                                                const SizedBox(width: 5),
                                                Expanded(
                                                  child: Text(timestamp,
                                                      style: const TextStyle(
                                                          color: muted,
                                                          fontSize: 11)),
                                                ),
                                                Text(
                                                  item['sender']?['name']
                                                          ?.toString() ??
                                                      'Administrator',
                                                  style: const TextStyle(
                                                      color: blue,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ),
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
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
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
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: Color(0xff64748b))),
          ),
          Expanded(
            child: Text(
              value!,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff1e293b)),
            ),
          ),
        ],
      ),
    );
  }
}
