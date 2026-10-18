part of '../main.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _user;
  bool _editing = false;
  bool _busy = false;
  String? _error;
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final result = await Api.req('GET', '/me');
      final user = result['user'] as Map<String, dynamic>?;
      if (mounted && user != null) {
        setState(() {
          _user = user;
          _nameCtrl.text  = user['name']?.toString() ?? '';
          _emailCtrl.text = user['email']?.toString() ?? '';
          _phoneCtrl.text = user['phone']?.toString() ?? '';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _save() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isNotEmpty && !RegExp(r'^09\d{9}$').hasMatch(phone)) {
      setState(() => _error = 'Phone must start with 09 and be 11 digits.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final result = await Api.patch('/profile', body: {
        'name':  _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': phone.isEmpty ? null : phone,
      });
      if (mounted) {
        setState(() {
          _user = result['user'] as Map<String, dynamic>? ?? _user;
          _editing = false;
          _busy = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated.')));
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _busy = false; });
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      setState(() => _busy = true);
      final result = await Api.uploadFile('/profile/avatar', 'avatar', picked.path);
      if (mounted) {
        final avatarUrl = result['avatar_url']?.toString();
        setState(() {
          if (_user != null && avatarUrl != null) _user!['avatar'] = avatarUrl;
          _busy = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final locationName = (user?['location'] is Map) ? user!['location']['name']?.toString() ?? '' : '';
    final purokName    = (user?['purok'] is Map)    ? user!['purok']['name']?.toString() ?? ''    : '';
    final avatarUrl    = user?['avatar']?.toString();
    final staffId      = user?['id']?.toString() ?? '';
    final initials     = (user?['name']?.toString() ?? 'S').substring(0, 1).toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          TextButton(
            onPressed: () => setState(() { _editing = !_editing; _error = null; }),
            child: Text(_editing ? 'Cancel' : 'Edit', style: const TextStyle(color: blue)),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Avatar
                Center(
                  child: GestureDetector(
                    onTap: _editing ? _pickAvatar : null,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: const Color(0xffdbeafe),
                          backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
                          child: (avatarUrl == null || avatarUrl.isEmpty)
                              ? Text(initials, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: blue))
                              : null,
                        ),
                        if (_editing)
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              width: 28, height: 28,
                              decoration: const BoxDecoration(color: blue, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(child: Text(user['name']?.toString() ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink))),
                if (staffId.isNotEmpty)
                  Center(child: Text('STAFF-$staffId', style: const TextStyle(fontSize: 13, color: muted))),
                const SizedBox(height: 20),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xfffff1f2), borderRadius: BorderRadius.circular(10)),
                    child: Text(_error!, style: const TextStyle(color: Color(0xffdc2626), fontSize: 13)),
                  ),
                  const SizedBox(height: 12),
                ],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Account Information', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 14),
                        if (_editing) ...[
                          const _FieldLabel('Name'),
                          const SizedBox(height: 6),
                          TextField(controller: _nameCtrl),
                          const SizedBox(height: 14),
                          const _FieldLabel('Email'),
                          const SizedBox(height: 6),
                          TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 14),
                          const _FieldLabel('Phone (start with 09, 11 digits)'),
                          const SizedBox(height: 6),
                          TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, maxLength: 11,
                              decoration: const InputDecoration(counterText: '')),
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: _busy ? null : _save,
                            child: _busy
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Save changes'),
                          ),
                        ] else ...[
                          _DetailRow('Name', user['name']?.toString()),
                          _DetailRow('Email', user['email']?.toString()),
                          _DetailRow('Phone', user['phone']?.toString()),
                          _DetailRow('Role', user['role']?.toString()),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Assignment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 14),
                        _DetailRow('Barangay / Location', locationName.isNotEmpty ? locationName : 'Not assigned'),
                        _DetailRow('Purok', purokName.isNotEmpty ? purokName : 'Not assigned'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// --- Scan History Page (uses _ApiListPage � kept intact) ---------------------

