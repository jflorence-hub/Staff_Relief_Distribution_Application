part of '../main.dart';

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xff1d4ed8), Color(0xff2563eb), Color(0xff1e40af)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff2563eb).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Shield background
              Positioned(
                top: 6,
                child: Icon(
                  Icons.shield_outlined,
                  color: Colors.white.withValues(alpha: 0.25),
                  size: 70,
                ),
              ),
              // Main relief worker icon
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.medical_services_outlined,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 4),
                      Icon(Icons.assignment_outlined,
                          color: Colors.white.withValues(alpha: 0.9), size: 20),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Icon(Icons.person_outlined,
                      color: Colors.white, size: 26),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Staff Disaster Relief',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: ink,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(height: 1, width: 24, color: const Color(0xff2563eb)),
            const SizedBox(width: 8),
            const Text(
              'APPLICATION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xff2563eb),
                letterSpacing: 2.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(height: 1, width: 24, color: const Color(0xff2563eb)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(color: blue),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'STAFF',
            style: TextStyle(
              color: blue,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Together for a safer and stronger community.',
          style: TextStyle(color: muted, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// --- Login Page --------------------------------------------------------------

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _hidePassword = true;
  bool _rememberMe = false;
  String? _error;

  Future<void> _login() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthController().login(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StaffHome()),
        );
      }
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: _AppLogo()),
                    const SizedBox(height: 28),
                    const Text('Disaster Relief Resource Management',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: ink)),
                    const SizedBox(height: 6),
                    const Text('Sign in to continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: muted, fontSize: 14)),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _FieldLabel('Email'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              onSubmitted: (_) => _busy ? null : _login(),
                            ),
                            const SizedBox(height: 14),
                            const _FieldLabel('Password'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _password,
                              obscureText: _hidePassword,
                              onSubmitted: (_) => _busy ? null : _login(),
                              decoration: InputDecoration(
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                      () => _hidePassword = !_hidePassword),
                                  icon: Icon(_hidePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (v) =>
                                      setState(() => _rememberMe = v ?? false),
                                  activeColor: blue,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                                const SizedBox(width: 6),
                                const Text('Remember me',
                                    style: TextStyle(fontSize: 13, color: ink)),
                              ],
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 10),
                              Text(_error!,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 13)),
                            ],
                            const SizedBox(height: 14),
                            FilledButton(
                              onPressed: _busy ? null : _login,
                              child: _busy
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Text('Sign in'),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const ForgotPasswordPage())),
                                child: const Text('Forgot password?',
                                    style: TextStyle(
                                        color: blue,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                            Wrap(
                              spacing: 4,
                              runSpacing: 2,
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text("Don't have an account?",
                                    style:
                                        TextStyle(color: muted, fontSize: 13)),
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const RegisterPage())),
                                  child: const Text('Register',
                                      style: TextStyle(
                                          color: blue,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                        'Demo admin login: admin@disasterrelief.test / password',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: muted, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

// --- Register Page -----------------------------------------------------------

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _birthdate = TextEditingController();
  final _homeAddress = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _hidePassword = true;
  bool _hideConfirm = true;
  bool _busy = false;
  String? _error;

  // All locations returned by /puroks (active only)
  List<Map<String, dynamic>> _locations = [];
  // Puroks filtered to the selected location (or all if none selected)
  List<Map<String, dynamic>> _filteredPuroks = [];

  String? _selectedLocationId;
  Set<String> _selectedPurokIds = {}; // preferred puroks (multi-select)
  bool _noPreference = false; // "No preference / any available"

  bool _locationsLoading = false;
  bool _puroksLoading = false;
  bool _loadFailed = false;
  DateTime? _selectedBirthdate;

  // Password strength: 0 = none, 1 = weak, 2 = medium, 3 = strong
  int _pwStrength = 0;

  @override
  void initState() {
    super.initState();
    _password.addListener(_updatePasswordStrength);
    _loadLocations();
  }

  // --- Helpers --------------------------------------------------------------

  void _updatePasswordStrength() {
    final pw = _password.text;
    if (pw.isEmpty) {
      setState(() => _pwStrength = 0);
      return;
    }
    final strength = pw.length < 8
        ? 1
        : pw.length < 12
            ? 2
            : 3;
    if (mounted) setState(() => _pwStrength = strength);
  }

  DateTime get _latestEligibleBirthdate {
    final today = DateTime.now();
    return DateTime(today.year - 18, today.month, today.day);
  }

  Future<void> _pickBirthdate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedBirthdate ?? _latestEligibleBirthdate,
      firstDate: DateTime(1900),
      lastDate: _latestEligibleBirthdate,
    );
    if (selected == null) return;
    setState(() {
      _selectedBirthdate = selected;
      _birthdate.text = DateFormat('yyyy-MM-dd').format(selected);
    });
  }

  /// Load active locations from /puroks. Called once on init.
  Future<void> _loadLocations() async {
    setState(() {
      _locationsLoading = true;
      _loadFailed = false;
    });
    try {
      final response = await Api.req('GET', '/puroks', auth: false);
      final locationList =
          (response['locations'] as List? ?? []).cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() {
          _locations = locationList;
          _locationsLoading = false;
        });
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _locationsLoading = false;
          _loadFailed = true;
        });
    }
  }

  /// Called whenever the selected location changes.
  /// Re-fetches puroks filtered by that location.
  Future<void> _onLocationChanged(String? locationId) async {
    setState(() {
      _selectedLocationId = locationId;
      _selectedPurokIds = {};
      _noPreference = false;
      _filteredPuroks = [];
      _puroksLoading = locationId != null;
    });
    if (locationId == null) return;

    try {
      final response = await Api.req(
        'GET',
        '/puroks?location_id=$locationId',
        auth: false,
      );
      final purokList =
          (response['puroks'] as List).cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() {
          _filteredPuroks = purokList;
          _puroksLoading = false;
        });
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _puroksLoading = false;
          _loadFailed = true;
        });
    }
  }

  // --- Validation + submit -------------------------------------------------

  Future<void> _register() async {
    if (_fullName.text.trim().isEmpty || _email.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in all required fields.');
      return;
    }
    final phone = _phone.text.trim();
    if (phone.isNotEmpty && !RegExp(r'^09\d{9}$').hasMatch(phone)) {
      setState(
          () => _error = 'Phone number must start with 09 and be 11 digits.');
      return;
    }
    if (_selectedLocationId == null) {
      setState(() => _error = 'Please select a location.');
      return;
    }
    if (_selectedBirthdate == null ||
        _selectedBirthdate!.isAfter(_latestEligibleBirthdate)) {
      setState(() => _error = 'Staff must be at least 18 years old.');
      return;
    }
    // purok is now optional — applicant expresses preferences, admin assigns at approval
    if (_password.text.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }
    if (_password.text != _confirmPassword.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Api.req('POST', '/register', auth: false, body: {
        'name': _fullName.text.trim(),
        'email': _email.text.trim(),
        'phone': phone.isEmpty ? null : phone,
        'birthdate': _birthdate.text,
        'home_address':
            _homeAddress.text.trim().isEmpty ? null : _homeAddress.text.trim(),
        'purok_id': null, // assigned by admin at approval
        'preferred_purok_ids': _noPreference || _selectedPurokIds.isEmpty
            ? null
            : _selectedPurokIds.map(int.parse).toList(),
        'location_id': int.parse(_selectedLocationId!),
        'password': _password.text,
        'password_confirmation': _confirmPassword.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Registration request submitted. You will receive an email once approved.')),
        );
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
      }
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _password.removeListener(_updatePasswordStrength);
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _birthdate.dispose();
    _homeAddress.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  // --- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: _AppLogo()),
                    const SizedBox(height: 24),
                    const Text('Request Staff Access',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: ink)),
                    const SizedBox(height: 6),
                    const Text('Your request will be reviewed by an admin',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: muted, fontSize: 14)),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // -- Personal info ----------------------------
                            const _FieldLabel('Full name'),
                            const SizedBox(height: 6),
                            TextField(controller: _fullName),
                            const SizedBox(height: 14),
                            const _FieldLabel('Email'),
                            const SizedBox(height: 6),
                            TextField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress),
                            const SizedBox(height: 14),
                            const _FieldLabel('Phone (optional)'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              maxLength: 11,
                              decoration:
                                  const InputDecoration(counterText: ''),
                            ),
                            const SizedBox(height: 14),
                            const _FieldLabel('Birth date (18+)'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _birthdate,
                              readOnly: true,
                              onTap: _pickBirthdate,
                              decoration: const InputDecoration(
                                hintText: 'Select your date of birth',
                                suffixIcon: Icon(Icons.calendar_today_outlined),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const _FieldLabel('Home address'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _homeAddress,
                              maxLines: 2,
                              textCapitalization: TextCapitalization.words,
                            ),

                            // -- Location dropdown ------------------------
                            const SizedBox(height: 14),
                            const _FieldLabel('Barangay'),
                            const SizedBox(height: 4),
                            const Text(
                              'Only locations currently accepting staff applications are shown.',
                              style: TextStyle(fontSize: 11, color: muted),
                            ),
                            const SizedBox(height: 6),
                            if (_locationsLoading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                    child: SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))),
                              )
                            else if (_loadFailed)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                      'Could not load data. Check your connection.',
                                      style: TextStyle(
                                          color: Colors.red, fontSize: 13)),
                                  const SizedBox(height: 6),
                                  TextButton.icon(
                                    onPressed: _loadLocations,
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('Retry'),
                                    style: TextButton.styleFrom(
                                        visualDensity: VisualDensity.compact),
                                  ),
                                ],
                              )
                            else
                              DropdownButtonFormField<String>(
                                value: _selectedLocationId,
                                hint: const Text('Select Location'),
                                items: _locations
                                    .map((l) => DropdownMenuItem<String>(
                                          value: l['id'].toString(),
                                          child: Text(l['name'].toString()),
                                        ))
                                    .toList(),
                                onChanged: _onLocationChanged,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
                                ),
                              ),

                            // -- Purok preference -----------------------
                            const SizedBox(height: 14),
                            const _FieldLabel('Purok (optional)'),
                            const SizedBox(height: 4),
                            const Text(
                              'Choose one preferred purok. The admin will confirm your assignment.',
                              style: TextStyle(color: muted, fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            if (_puroksLoading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                    child: SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))),
                              )
                            else if (_selectedLocationId == null)
                              const Text(
                                'Select a location first to see available puroks.',
                                style: TextStyle(color: muted, fontSize: 13),
                              )
                            else ...[
                              DropdownButtonFormField<String>(
                                value: _noPreference
                                    ? 'none'
                                    : _selectedPurokIds.isEmpty
                                        ? null
                                        : _selectedPurokIds.first,
                                hint: const Text('Select Purok'),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: 'none',
                                    child:
                                        Text('No preference / any available'),
                                  ),
                                  ..._filteredPuroks.map((p) {
                                    final occupied = p['is_occupied'] == true;
                                    return DropdownMenuItem<String>(
                                      value: p['id'].toString(),
                                      enabled: !occupied,
                                      child: Text(
                                        occupied
                                            ? '${p['name']} (Occupied)'
                                            : p['name'].toString(),
                                      ),
                                    );
                                  }),
                                ],
                                onChanged: (value) => setState(() {
                                  _noPreference = value == 'none';
                                  _selectedPurokIds =
                                      value == null || value == 'none'
                                          ? {}
                                          : {value};
                                }),
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
                                ),
                              ),
                            ],

                            // -- Password ---------------------------------
                            const SizedBox(height: 14),
                            const _FieldLabel('Password'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _password,
                              obscureText: _hidePassword,
                              decoration: InputDecoration(
                                hintText: 'At least 8 characters',
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                      () => _hidePassword = !_hidePassword),
                                  icon: Icon(_hidePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                ),
                              ),
                            ),
                            // Password strength bar
                            if (_pwStrength > 0) ...[
                              const SizedBox(height: 8),
                              _PasswordStrengthBar(strength: _pwStrength),
                            ],
                            const SizedBox(height: 14),
                            const _FieldLabel('Confirm password'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _confirmPassword,
                              obscureText: _hideConfirm,
                              decoration: InputDecoration(
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                      () => _hideConfirm = !_hideConfirm),
                                  icon: Icon(_hideConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                ),
                              ),
                            ),

                            // -- Error + submit ---------------------------
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(_error!,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 13)),
                            ],
                            const SizedBox(height: 18),
                            FilledButton(
                              onPressed: _busy ? null : _register,
                              child: _busy
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Text('Submit Request'),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Already have an account? ',
                                    style:
                                        TextStyle(color: muted, fontSize: 13)),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: const Text('Sign in',
                                      style: TextStyle(
                                          color: blue,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _email = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _sendOtp() async {
    if (_email.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your email address.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Api.req('POST', '/password/forgot',
          auth: false, body: {'email': _email.text.trim()});
      if (mounted) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => VerifyOtpPage(email: _email.text.trim())));
      }
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Recover your password',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: ink)),
                        const SizedBox(height: 6),
                        const Text(
                            'Verify your email before creating a new password.',
                            style: TextStyle(color: muted, fontSize: 13)),
                        const SizedBox(height: 22),
                        const _FieldLabel('Gmail address'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration:
                              const InputDecoration(hintText: 'you@gmail.com'),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(_error!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 13)),
                        ],
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: _busy ? null : _sendOtp,
                          child: _busy
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Send OTP'),
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Back to login',
                                style: TextStyle(
                                    color: blue, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

// --- Verify OTP Page ---------------------------------------------------------

class VerifyOtpPage extends StatefulWidget {
  const VerifyOtpPage({super.key, required this.email});
  final String email;
  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final _otp = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _verifyOtp() async {
    if (_otp.text.trim().isEmpty) {
      setState(() => _error = 'Please enter the OTP.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Api.req('POST', '/password/verify-otp', auth: false, body: {
        'email': widget.email,
        'otp': _otp.text.trim(),
      });
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => ResetPasswordPage(email: widget.email)),
        );
      }
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _error = null);
    try {
      await Api.req('POST', '/password/forgot',
          auth: false, body: {'email': widget.email});
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP resent to your email.')));
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Recover your password',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: ink)),
                        const SizedBox(height: 6),
                        const Text(
                            'Verify your email before creating a new password.',
                            style: TextStyle(color: muted, fontSize: 13)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xffecfdf5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'A 6-digit OTP was sent to your email. It expires in 10 minutes.',
                            style: TextStyle(
                                color: Color(0xff059669), fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const _FieldLabel('6-digit OTP'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _otp,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(
                              hintText: 'Enter OTP', counterText: ''),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(_error!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 13)),
                        ],
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: _busy ? null : _verifyOtp,
                          child: _busy
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Verify OTP'),
                        ),
                        const SizedBox(height: 10),
                        Center(
                            child: TextButton(
                                onPressed: _resendOtp,
                                child: const Text('Resend OTP',
                                    style: TextStyle(
                                        color: blue,
                                        fontWeight: FontWeight.w600)))),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginPage()),
                                (_) => false),
                            child: const Text('Back to login',
                                style: TextStyle(
                                    color: blue, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

// --- Reset Password Page -----------------------------------------------------

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, required this.email});
  final String email;
  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _busy = false;
  bool _hideNew = true;
  bool _hideConfirm = true;
  String? _error;

  Future<void> _reset() async {
    if (_newPassword.text.isEmpty || _confirmPassword.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (_newPassword.text.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }
    if (_newPassword.text != _confirmPassword.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Api.req('POST', '/password/reset', auth: false, body: {
        'email': widget.email,
        'new_password': _newPassword.text,
        'new_password_confirmation': _confirmPassword.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Password reset successfully. Please sign in.')));
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
      }
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Set new password',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: ink)),
                        const SizedBox(height: 6),
                        const Text('Create a strong password for your account.',
                            style: TextStyle(color: muted, fontSize: 13)),
                        const SizedBox(height: 22),
                        const _FieldLabel('New password'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _newPassword,
                          obscureText: _hideNew,
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _hideNew = !_hideNew),
                              icon: Icon(_hideNew
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const _FieldLabel('Confirm new password'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _confirmPassword,
                          obscureText: _hideConfirm,
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _hideConfirm = !_hideConfirm),
                              icon: Icon(_hideConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(_error!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 13)),
                        ],
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: _busy ? null : _reset,
                          child: _busy
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Reset password'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

// --- Shared helpers -----------------------------------------------------------

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: ink));
}

/// A simple three-segment bar showing password strength.
/// strength: 1 = weak (red), 2 = medium (amber), 3 = strong (green)
class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({required this.strength});
  final int strength;

  @override
  Widget build(BuildContext context) {
    const colors = [
      Colors.transparent,
      Color(0xffdc2626), // weak  � red
      Color(0xfff59e0b), // medium � amber
      Color(0xff059669), // strong � green
    ];
    const labels = ['', 'Weak', 'Medium', 'Strong'];
    final color = colors[strength.clamp(0, 3)];
    final label = labels[strength.clamp(0, 3)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(
              3,
              (i) => Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                      height: 5,
                      decoration: BoxDecoration(
                        color: i < strength ? color : const Color(0xffe2e8f0),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  )),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
