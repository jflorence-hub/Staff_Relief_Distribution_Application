part of '../main.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});
  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final _qrCtrl       = TextEditingController();
  final _familyCtrl   = TextEditingController();
  final _headCtrl     = TextEditingController();
  final _purokCtrl    = TextEditingController();
  final _reliefCtrl   = TextEditingController();
  final _qtyCtrl      = TextEditingController(text: '1');
  final _locationCtrl = TextEditingController();
  final _dateCtrl     = TextEditingController();
  final _timeCtrl     = TextEditingController();
  final _manualCodeCtrl = TextEditingController();

  String? _familyId;
  String? _locationId;
  String  _scanType    = 'completed';
  String  _scanDate    = '';
  String  _scanTime    = '';
  bool    _formVisible = false;
  bool    _cameraOpen  = false;
  bool    _handled     = false;
  bool    _busy        = false;
  String? _error;
  String? _resourceId;
  final _receiverCtrl = TextEditingController();

  List<Map<String, dynamic>> _families  = [];
  List<Map<String, dynamic>> _familyMembers = [];
  String? _claimedByName;
  bool _loadingMembers = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _qrCtrl.dispose(); _familyCtrl.dispose(); _headCtrl.dispose();
    _purokCtrl.dispose(); _reliefCtrl.dispose(); _qtyCtrl.dispose();
    _locationCtrl.dispose(); _dateCtrl.dispose(); _timeCtrl.dispose();
    _manualCodeCtrl.dispose(); _receiverCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        Api.req('GET', '/staff/families').catchError((_) => <String, dynamic>{}),
        Api.req('GET', '/me').catchError((_) => <String, dynamic>{}),
      ]);
      if (!mounted) return;
      final familiesRaw = results[0]['families'] as List? ?? [];
      final user = (results[1]['user'] is Map)
          ? results[1]['user'] as Map<String, dynamic>
          : <String, dynamic>{};
      final locId   = user['location_id']?.toString() ?? '';
      final locName = user['location']?['name']?.toString() ?? '';
      setState(() {
        _families  = familiesRaw.map((e) => e as Map<String, dynamic>).toList();
        _locationId = locId;
      });
      if (locName.isNotEmpty) _locationCtrl.text = locName;
    } catch (_) {}
  }

  Future<void> _loadFamilyMembers(String familyId) async {
    setState(() { _loadingMembers = true; _familyMembers = []; _claimedByName = null; });
    try {
      final result = await Api.req('GET', '/families/$familyId/members');
      final list = (result['members'] as List? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList();
      if (mounted) setState(() { _familyMembers = list; _loadingMembers = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingMembers = false);
    }
  }

  void _onQrDecoded(String raw) async {
    final value = raw.trim();
    if (value.isEmpty) return;

    // 1. Local lookup
    final match = _families.firstWhere(
      (f) => f['family_id']?.toString() == value,
      orElse: () => <String, dynamic>{},
    );

    if (match.isNotEmpty) {
      _populateForm(match, scannedQr: value);
      return;
    }

    // 2. API fallback
    try {
      final result = await Api.req('POST', '/distributions/lookup-by-qr', body: {'qr_code': value});
      if (result['found'] == true) {
        final family = result['family'] as Map<String, dynamic>? ?? {};
        if (family.isNotEmpty) {
          _populateForm(family, scannedQr: value);
          return;
        }
      }
    } catch (_) {}

    // 3. Not found
    setState(() {
      _error       = 'No family found for QR code "$value".';
      _formVisible = false;
    });
  }

  void _populateForm(Map<String, dynamic> fam, {String scannedQr = ''}) {
    final dist     = fam['latest_distribution'];
    final resource = dist is Map ? dist['resource'] : null;
    final now      = DateTime.now();
    final date = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
    final timeSend    = DateFormat('HH:mm').format(now);
    final timeDisplay = DateFormat('hh:mm a').format(now);
    final purok = (fam['purok'] is Map)
        ? (fam['purok']['name']?.toString() ?? '')
        : (fam['purok']?.toString() ?? '');
    final qty = (dist is Map && dist['quantity'] != null) ? dist['quantity'].toString() : '1';

    // Resolve resource_id from latest_distribution
    String? resId;
    if (dist is Map) {
      final rid = dist['resource']?['id'] ?? dist['resource_id'];
      resId = rid?.toString();
    }

    setState(() {
      _familyId    = fam['id']?.toString();
      _scanDate    = date;
      _scanTime    = timeSend;
      _formVisible = true;
      _error       = null;
      _resourceId  = resId;
      _qtyCtrl.text = qty;
      _claimedByName = null;
    });
    _qrCtrl.text        = scannedQr;
    _familyCtrl.text    = '${fam['head_name'] ?? ''} (${fam['family_id'] ?? ''})';
    _headCtrl.text      = fam['head_name']?.toString() ?? '';
    _purokCtrl.text     = purok;
    _reliefCtrl.text    = resource is Map ? (resource['name']?.toString() ?? '') : '';
    _receiverCtrl.text  = fam['head_name']?.toString() ?? '';
    _dateCtrl.text      = date;
    _timeCtrl.text      = timeDisplay;
    if (_familyId != null) _loadFamilyMembers(_familyId!);
  }

  Future<void> _save() async {
    final q = int.tryParse(_qtyCtrl.text);
    if (q == null || q < 1) {
      setState(() => _error = 'Quantity must be a positive whole number.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      await Api.req('POST', '/qr/scan', body: {
        'qr_code':         _qrCtrl.text.trim(),
        'family_id':       int.tryParse(_familyId ?? ''),
        'scan_type':       _scanType,
        'receiver':        _claimedByName ?? (_receiverCtrl.text.trim().isEmpty ? null : _receiverCtrl.text.trim()),
        'resource_id':     int.tryParse(_resourceId ?? ''),
        'quantity_change': q,
        'location_id':     int.tryParse(_locationId ?? ''),
        'scan_date':       _scanDate,
        'scan_time':       _scanTime,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tracking record saved successfully.')));
        _resetForm();
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 409) {
        final familyName = e.data['head_name']?.toString() ?? 'This family';
        final claimedAt  = e.data['claimed_at']?.toString() ?? 'an earlier time';
        final claimedBy  = e.data['claimed_by']?.toString() ?? 'unknown';
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xffdc2626), size: 24),
              const SizedBox(width: 8),
              const Text('Already Claimed', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xffdc2626))),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$familyName has already received their relief goods.', style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 10),
                _ScanInfoRow(label: 'Claimed on', value: claimedAt),
                _ScanInfoRow(label: 'Claimed by', value: claimedBy),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xffdc2626)),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        _resetForm();
      } else if (e.statusCode == 403) {
        final reason = e.data['exclusion_reason']?.toString() ?? 'No reason provided.';
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(children: [
              const Icon(Icons.block_outlined, color: Color(0xfff59e0b), size: 24),
              const SizedBox(width: 8),
              const Text('Family Excluded', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xfff59e0b))),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('This family has been excluded from the current distribution schedule.', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 10),
                _ScanInfoRow(label: 'Reason', value: reason),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        _resetForm();
      } else {
        setState(() => _error = e.message);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _resetForm() {
    setState(() {
      _formVisible = false; _familyId = null;
      _scanType = 'completed'; _error = null; _handled = false;
      _resourceId = null;
      _familyMembers = [];
      _claimedByName = null;
    });
    for (final c in [_qrCtrl, _familyCtrl, _headCtrl, _purokCtrl, _reliefCtrl, _receiverCtrl]) { c.clear(); }
    _qtyCtrl.text = '1';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Scan a family QR code to record relief distribution', style: TextStyle(color: muted)),
                  const SizedBox(height: 12),

                  // Camera viewfinder
                  if (_cameraOpen)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        height: screenHeight * 0.35,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: MobileScanner(
                            onDetect: (capture) {
                              if (_handled || capture.barcodes.isEmpty) return;
                              final value = capture.barcodes.first.rawValue;
                              if (value == null || value.isEmpty) return;
                              _handled = true;
                              setState(() => _cameraOpen = false);
                              _onQrDecoded(value);
                            },
                          ),
                        ),
                      ),
                    ),

                  // Camera toggle
                  OutlinedButton.icon(
                    onPressed: () => setState(() { _cameraOpen = !_cameraOpen; _handled = false; }),
                    icon: Icon(_cameraOpen ? Icons.camera_alt : Icons.camera_alt_outlined, size: 18),
                    label: Text(_cameraOpen ? 'Stop camera' : 'Start camera'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: blue,
                      side: const BorderSide(color: blue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Manual code input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualCodeCtrl,
                          decoration: const InputDecoration(labelText: 'Family Distribution Code'),
                          onSubmitted: (v) { final code = v.trim(); if (code.isNotEmpty) _onQrDecoded(code); },
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          final code = _manualCodeCtrl.text.trim();
                          if (code.isNotEmpty) _onQrDecoded(code);
                        },
                        child: const Text('Look up'),
                      ),
                    ],
                  ),

                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ),

                  if (!_formVisible && _error == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 18, bottom: 6),
                      child: Column(
                        children: [
                          Icon(Icons.qr_code_2_rounded, size: 48, color: muted.withValues(alpha: 0.4)),
                          const SizedBox(height: 8),
                          const Text('Scan a family QR code or enter a code above to begin',
                              style: TextStyle(color: muted, fontSize: 13), textAlign: TextAlign.center),
                        ],
                      ),
                    ),

                  // Auto-filled form
                  if (_formVisible) ...[
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    _ReadField(label: 'Family', controller: _familyCtrl, icon: Icons.groups_outlined),
                    const SizedBox(height: 12),
                    _ReadField(label: 'Family Head', controller: _headCtrl, icon: Icons.person_outlined),
                    const SizedBox(height: 12),
                    _ReadField(label: 'Purok', controller: _purokCtrl, icon: Icons.map_outlined),
                    const SizedBox(height: 12),
                    _ReadField(label: 'Relief / Resource', controller: _reliefCtrl, icon: Icons.inventory_2_outlined),
                    const SizedBox(height: 12),
                    if (_loadingMembers)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(children: [
                          SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 10),
                          Text('Loading members�',
                              style: TextStyle(color: muted, fontSize: 13)),
                        ]),
                      )
                    else if (_familyMembers.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: _claimedByName,
                        decoration: const InputDecoration(
                          labelText: 'Claimed by',
                          prefixIcon:
                              Icon(Icons.person_outline, size: 18),
                        ),
                        hint: const Text('Select family member'),
                        items: _familyMembers
                            .map((m) => DropdownMenuItem<String>(
                                  value: m['name']?.toString() ??
                                      'Member #${m['number']}',
                                  child: Text(m['name']?.toString() ??
                                      'Member #${m['number']}'),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _claimedByName = v),
                      )
                    else
                      _ReadField(
                          label: 'Claimed by',
                          controller: _receiverCtrl,
                          icon: Icons.person_outline),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantity', prefixIcon: Icon(Icons.numbers_outlined)),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _scanType,
                      decoration: const InputDecoration(labelText: 'Scan Status'),
                      items: const [
                        DropdownMenuItem(value: 'completed', child: Text('Completed')),
                        DropdownMenuItem(value: 'pending',   child: Text('Pending')),
                        DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                      ],
                      onChanged: (v) => setState(() => _scanType = v ?? 'completed'),
                    ),
                    const SizedBox(height: 12),
                    _ReadField(label: 'Location', controller: _locationCtrl, icon: Icons.location_on_outlined),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _dateCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Date', prefixIcon: Icon(Icons.calendar_today_outlined)),
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(context: context, initialDate: now, firstDate: DateTime(2020), lastDate: DateTime(2100));
                        if (picked != null && mounted) {
                          final d = '${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}';
                          setState(() => _scanDate = d);
                          _dateCtrl.text = d;
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _timeCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Time', prefixIcon: Icon(Icons.access_time_outlined)),
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (picked != null && mounted) {
                          final dt = DateTime(2000, 1, 1, picked.hour, picked.minute);
                          setState(() => _scanTime = DateFormat('HH:mm').format(dt));
                          _timeCtrl.text = DateFormat('hh:mm a').format(dt);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    if (_busy) const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _busy ? null : _resetForm,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: muted,
                              side: const BorderSide(color: Color(0xffdbe3ef)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: _busy ? null : _save,
                            child: const Text('Save tracking record'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadField extends StatelessWidget {
  const _ReadField({required this.label, required this.controller, this.icon});
  final String label;
  final TextEditingController controller;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        readOnly: true,
        style: const TextStyle(fontWeight: FontWeight.w600, color: ink),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, size: 18) : null,
          filled: true,
          fillColor: const Color(0xfff8fafc),
        ),
      );
}

// --- Message Page (Chat Bubbles) ----------------------------------------------

