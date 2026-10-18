part of '../main.dart';

class _FamilyRegisterSheet extends StatefulWidget {
  final List<Map<String, dynamic>> puroks;
  final List<Map<String, dynamic>> locations;
  final dynamic staffPurokId;
  final dynamic staffLocationId;
  final VoidCallback onRegistered;
  const _FamilyRegisterSheet({
    required this.puroks,
    required this.locations,
    required this.staffPurokId,
    required this.staffLocationId,
    required this.onRegistered,
  });
  @override
  State<_FamilyRegisterSheet> createState() => _FamilyRegisterSheetState();
}

class _FamilyRegisterSheetState extends State<_FamilyRegisterSheet> {
  final _headNameCtrl   = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _phoneCtrl      = TextEditingController();
  final _pinCtrl        = TextEditingController();
  final _confirmPinCtrl = TextEditingController();
  final List<TextEditingController> _memberCtrls = [TextEditingController()];
  bool _hidePin = true;
  bool _hideConfirm = true;
  bool _busy = false;
  String? _error;
  String? _selectedPurokId;
  String? _selectedLocationId;

  @override
  void initState() {
    super.initState();
    // Pre-select staff's assigned purok and location
    _selectedPurokId    = widget.staffPurokId?.toString();
    _selectedLocationId = widget.staffLocationId?.toString();
  }

  @override
  void dispose() {
    for (final c in [_headNameCtrl, _emailCtrl, _phoneCtrl,
        _pinCtrl, _confirmPinCtrl, ..._memberCtrls]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    // Validate required fields
    if (_headNameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in all required fields.');
      return;
    }
    final phone = _phoneCtrl.text.trim();
    if (phone.isNotEmpty && !RegExp(r'^09\d{9}$').hasMatch(phone)) {
      setState(() => _error = 'Phone must be 11 digits starting with 09.');
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(_pinCtrl.text)) {
      setState(() => _error = 'PIN must be exactly 6 digits.');
      return;
    }
    if (_pinCtrl.text != _confirmPinCtrl.text) {
      setState(() => _error = 'PINs do not match.');
      return;
    }
    if (_selectedPurokId == null) {
      setState(() => _error = 'Please select a purok.');
      return;
    }
    if (_selectedLocationId == null) {
      setState(() => _error = 'Please select a location.');
      return;
    }
    for (int i = 0; i < _memberCtrls.length; i++) {
      if (_memberCtrls[i].text.trim().isEmpty) {
        setState(() => _error = 'Member ${i + 1} name is required.');
        return;
      }
    }

    setState(() { _busy = true; _error = null; });
    try {
      await Api.req('POST', '/staff/families/register', body: {
        'head_name':        _headNameCtrl.text.trim(),
        'email':            _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'phone':            phone.isEmpty ? null : phone,
        'household_member': _memberCtrls.length,
        'member_names':     _memberCtrls.map((c) => c.text.trim()).toList(),
        'purok_id':         int.parse(_selectedPurokId!),
        'location_id':      int.parse(_selectedLocationId!),
        'pin':              _pinCtrl.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Family registered successfully.')),
        );
        widget.onRegistered();
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xffe2e8f0), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Expanded(child: Text('Add Family', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ink))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.all(20),
              children: [
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xfffff1f2), borderRadius: BorderRadius.circular(10)),
                    child: Text(_error!, style: const TextStyle(color: Color(0xffdc2626), fontSize: 13)),
                  ),
                  const SizedBox(height: 12),
                ],
                _buildField('Head of Family *', _headNameCtrl),
                _buildField('Phone (optional, 09XXXXXXXXX)', _phoneCtrl, keyboard: TextInputType.phone, maxLen: 11),
                _buildField('Email (optional, for PIN recovery)', _emailCtrl, keyboard: TextInputType.emailAddress),
                const SizedBox(height: 4),
                // Household Members
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Household Members (${_memberCtrls.length})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ink)),
                    TextButton.icon(
                      onPressed: () => setState(() => _memberCtrls.add(TextEditingController())),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    ),
                  ],
                ),
                ...List.generate(_memberCtrls.length, (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(width: 24, child: Text('${i + 1}.', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, color: muted))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _memberCtrls[i],
                          decoration: InputDecoration(
                            labelText: 'Member ${i + 1} full name',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      if (_memberCtrls.length > 1)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.red),
                          onPressed: () {
                            setState(() { _memberCtrls[i].dispose(); _memberCtrls.removeAt(i); });
                          },
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                )),
                const SizedBox(height: 8),
                // Purok
                DropdownButtonFormField<String>(
                  initialValue: _selectedPurokId,
                  decoration: const InputDecoration(labelText: 'Purok *'),
                  items: widget.puroks.where((p) =>
                    p['id'].toString() == widget.staffPurokId?.toString() &&
                    p['location_id'].toString() == widget.staffLocationId?.toString()
                  ).map((p) => DropdownMenuItem<String>(
                    value: p['id'].toString(),
                    child: Text(p['name'].toString()),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedPurokId = v),
                ),
                const SizedBox(height: 12),
                // Location
                DropdownButtonFormField<String>(
                  initialValue: _selectedLocationId,
                  decoration: const InputDecoration(labelText: 'Location / Barangay *'),
                  items: widget.locations.where((l) =>
                    l['id'].toString() == widget.staffLocationId?.toString()
                  ).map((l) => DropdownMenuItem<String>(
                    value: l['id'].toString(),
                    child: Text(l['name'].toString()),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedLocationId = v),
                ),
                const SizedBox(height: 12),
                // PIN
                TextField(
                  controller: _pinCtrl,
                  obscureText: _hidePin,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Family PIN (6 digits) *',
                    counterText: '',
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _hidePin = !_hidePin),
                      icon: Icon(_hidePin ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmPinCtrl,
                  obscureText: _hideConfirm,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Confirm PIN *',
                    counterText: '',
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
                      icon: Icon(_hideConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Register Family'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {TextInputType? keyboard, int? maxLen}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: ctrl,
          keyboardType: keyboard,
          maxLength: maxLen,
          buildCounter: maxLen != null ? (_, {required currentLength, required isFocused, maxLength}) => null : null,
          decoration: InputDecoration(labelText: label),
        ),
      );
}

// --- Family Detail Sheet ------------------------------------------------------

class _FamilyDetailSheet extends StatefulWidget {
  final Map<String, dynamic> family;
  const _FamilyDetailSheet({required this.family});

  @override
  State<_FamilyDetailSheet> createState() => _FamilyDetailSheetState();
}

class _FamilyDetailSheetState extends State<_FamilyDetailSheet> {
  List<Map<String, dynamic>>? _members;
  bool _loadingMembers = true;
  String? _membersError;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final id = widget.family['id'];
    if (id == null) {
      setState(() { _loadingMembers = false; _membersError = 'No family ID.'; });
      return;
    }
    try {
      final result = await Api.req('GET', '/families/$id/members');
      final list = (result['members'] as List? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList();
      if (mounted) {
        setState(() { _members = list; _loadingMembers = false; });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _membersError = 'Could not load members.';
          _loadingMembers = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.family;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.95,
      builder: (_, ctrl) => ListView(
        controller: ctrl,
        padding: const EdgeInsets.all(20),
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xffe2e8f0), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(f['head_name']?.toString() ?? 'Family', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ink)),
          const SizedBox(height: 12),
          _DetailRow('Head of Family', f['head_name']?.toString()),
          _DetailRow('Phone', f['phone']?.toString()),
          _DetailRow('Household Members', f['household_member']?.toString() ?? f['members_count']?.toString()),
          _DetailRow('Purok', (f['purok'] is Map) ? f['purok']['name']?.toString() : f['purok']?.toString()),
          _DetailRow('Location', (f['location'] is Map) ? f['location']['name']?.toString() : f['location']?.toString()),
          _DetailRow('Status', f['status']?.toString()),
          _DetailRow('Family ID', f['family_id']?.toString()),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text('Household Members', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 10),
          if (_loadingMembers)
            const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
          else if (_membersError != null)
            Text(_membersError!, style: const TextStyle(color: Colors.red, fontSize: 13))
          else if (_members == null || _members!.isEmpty)
            const Text('No member names recorded.', style: TextStyle(color: muted, fontSize: 13))
          else
            ...(_members!.map((m) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(color: const Color(0xffeff6ff), borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text('${m['number']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: blue))),
                  ),
                  const SizedBox(width: 10),
                  Text(m['name']?.toString() ?? 'Member #${m['number']}', style: const TextStyle(fontSize: 13, color: ink)),
                ],
              ),
            ))),
        ],
      ),
    );
  }
}

// --- Family List Page ---------------------------------------------------------

class FamilyListPage extends StatefulWidget {
  const FamilyListPage({super.key});
  @override
  State<FamilyListPage> createState() => _FamilyListPageState();
}

class _FamilyListPageState extends State<FamilyListPage> {
  List<Map<String, dynamic>> _families = [];
  List<Map<String, dynamic>> _puroks = [];
  List<Map<String, dynamic>> _locations = [];
  Map<String, dynamic>? _meUser;
  String _search = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        Api.req('GET', '/staff/families'),
        Api.req('GET', '/puroks', auth: false),
        Api.req('GET', '/me'),
      ]);
      final raw = results[0]['families'] as List? ?? [];
      final puroksRaw = results[1]['puroks'] as List? ?? [];
      final locRaw = results[1]['locations'] as List? ?? [];
      final user = results[2]['user'] as Map<String, dynamic>?;
      if (mounted) {
        setState(() {
          _families = raw.map((e) => e as Map<String, dynamic>).toList();
          _puroks = puroksRaw.map((e) => e as Map<String, dynamic>).toList();
          _locations = locRaw.map((e) => e as Map<String, dynamic>).toList();
          _meUser = user;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _families;
    return _families.where((f) {
      final hay = '${f['head_name']} ${f['family_id']} ${f['phone']}'.toLowerCase();
      return hay.contains(_search.toLowerCase());
    }).toList();
  }

  void _showDetail(Map<String, dynamic> f) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FamilyDetailSheet(family: f),
    );
  }

  void _openRegisterForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FamilyRegisterSheet(
        puroks: _puroks,
        locations: _locations,
        staffPurokId: _meUser?['purok_id'],
        staffLocationId: _meUser?['location_id'],
        onRegistered: () { Navigator.pop(context); _load(); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search families...'),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _openRegisterForm,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Family'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        if (_loading) const Center(child: CircularProgressIndicator()),
        if (_error != null) Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: Colors.red))),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: filtered.isEmpty && !_loading
                ? const Center(child: Text('No families found.', style: TextStyle(color: muted)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final f = filtered[i];
                      final purok = (f['purok'] is Map) ? f['purok']['name']?.toString() ?? '' : f['purok']?.toString() ?? '';
                      final members = f['household_member']?.toString() ?? f['members_count']?.toString() ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () => _showDetail(f),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(color: const Color(0xffeff6ff), borderRadius: BorderRadius.circular(13)),
                                    child: const Icon(Icons.groups_outlined, color: blue),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(f['head_name']?.toString() ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                        if ((f['head_name']?.toString() ?? '').isNotEmpty)
                                          Text(f['head_name'].toString(), style: const TextStyle(fontSize: 12, color: muted)),
                                        Row(children: [
                                          if (purok.isNotEmpty) Text(purok, style: const TextStyle(fontSize: 11, color: muted)),
                                          if (purok.isNotEmpty && members.isNotEmpty) const Text(' \u2022 ', style: TextStyle(color: muted, fontSize: 11)),
                                          if (members.isNotEmpty) Text('$members members', style: const TextStyle(fontSize: 11, color: muted)),
                                        ]),
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

// --- Profile Page -------------------------------------------------------------

