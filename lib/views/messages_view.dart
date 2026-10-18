part of '../main.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});
  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _me;
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _timer;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadMe().then((_) => _loadMessages());
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _loadMessages());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMe() async {
    try {
      final result = await Api.req('GET', '/me');
      if (mounted) setState(() => _me = result['user'] as Map<String, dynamic>?);
    } catch (_) {}
  }

  Future<void> _loadMessages() async {
    try {
      final result = await Api.req('GET', '/messages');
      final list = result['messages'] as List? ?? [];
      if (mounted) {
        setState(() => _messages = list.map((e) => e as Map<String, dynamic>).toList());
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollCtrl.hasClients) {
            _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await Api.req('POST', '/messages', body: {'message': text});
      _msgCtrl.clear();
      await _loadMessages();
    } catch (_) {} finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ampm';
    } catch (_) { return ''; }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final day = DateTime(dt.year, dt.month, dt.day);
      if (day == today) return 'Today';
      if (day == yesterday) return 'Yesterday';
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) { return ''; }
  }

  List<Map<String, dynamic>> _groupByDate() {
    final groups = <Map<String, dynamic>>[];
    String lastLabel = '';
    for (final msg in _messages) {
      final label = _formatDate(msg['created_at']?.toString());
      if (label != lastLabel) {
        groups.add({'type': 'date', 'label': label});
        lastLabel = label;
      }
      groups.add({'type': 'msg', 'data': msg});
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final myId = _me?['id'];
    final grouped = _groupByDate();

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xffe8edf5))),
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: const Color(0xffdbeafe), borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.groups_outlined, color: blue, size: 20),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  Text('Direct chat with administration', style: TextStyle(color: muted, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        // Messages list
        Expanded(
          child: _messages.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 40, color: muted),
                      SizedBox(height: 8),
                      Text('No messages yet. Write to admin below.', style: TextStyle(color: muted, fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: grouped.length,
                  itemBuilder: (context, i) {
                    final item = grouped[i];
                    if (item['type'] == 'date') {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xfff1f5f9), borderRadius: BorderRadius.circular(20)),
                                child: Text(item['label']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: muted)),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                      );
                    }
                    final msg = item['data'] as Map<String, dynamic>;
                    final isSelf = msg['sender_id']?.toString() == myId?.toString();
                    final senderName = msg['sender']?['name']?.toString();
                    final text = msg['message']?.toString() ?? '';
                    final time = _formatTime(msg['created_at']?.toString());

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Column(
                        crossAxisAlignment: isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          if (!isSelf && senderName != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 2),
                              child: Text(senderName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: muted)),
                            ),
                          Row(
                            mainAxisAlignment: isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelf ? blue : Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(18),
                                      topRight: const Radius.circular(18),
                                      bottomLeft: Radius.circular(isSelf ? 18 : 4),
                                      bottomRight: Radius.circular(isSelf ? 4 : 18),
                                    ),
                                    border: isSelf ? null : Border.all(color: const Color(0xffe2e8f0)),
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
                                  ),
                                  child: Text(text, style: TextStyle(color: isSelf ? Colors.white : ink, fontSize: 14)),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                            child: Text(time, style: const TextStyle(fontSize: 10, color: muted)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        // Compose
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xffe8edf5))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: 'Write a message to admin\u2026',
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send_rounded, color: blue),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xffeff6ff),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- Resource Page ------------------------------------------------------------

