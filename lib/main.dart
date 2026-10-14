import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';

const blue = Color(0xff2563eb);
const ink = Color(0xff0f172a);
const muted = Color(0xff64748b);
const canvas = Color(0xfff6f8fc);

void main() => runApp(const StaffApp());

class StaffApp extends StatelessWidget {
  const StaffApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Disaster Relief',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: blue),
          scaffoldBackgroundColor: canvas,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: ink,
            elevation: 0,
            centerTitle: false,
            surfaceTintColor: Colors.white,
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xffe8edf5)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xffdbe3ef)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xffdbe3ef)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(44, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        home: const LoginPage(),
      );
}

// ─── Shared logo widget ──────────────────────────────────────────────────────

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
                  const Icon(Icons.person_outlined, color: Colors.white, size: 26),
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

// ─── Login Page ──────────────────────────────────────────────────────────────

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
    setState(() { _busy = true; _error = null; });
    try {
      final result = await Api.req('POST', '/login', auth: false, body: {
        'email': _email.text.trim(),
        'password': _password.text,
      });
      if (result['user']?['role'] != 'staff') {
        throw Exception('This mobile app is for staff accounts only.');
      }
      await Api.saveToken(result['token'].toString());
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StaffHome()),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
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
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink)),
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
                                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
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
                                  onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                  activeColor: blue,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                                const SizedBox(width: 6),
                                const Text('Remember me', style: TextStyle(fontSize: 13, color: ink)),
                              ],
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 10),
                              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                            ],
                            const SizedBox(height: 14),
                            FilledButton(
                              onPressed: _busy ? null : _login,
                              child: _busy
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Sign in'),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordPage())),
                                child: const Text('Forgot password?', style: TextStyle(color: blue, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Don't have an account? ", style: TextStyle(color: muted, fontSize: 13)),
                                GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                                  child: const Text('Register', style: TextStyle(color: blue, fontWeight: FontWeight.w700, fontSize: 13)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Demo admin login: admin@disasterrelief.test / password',
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

// ─── Register Page ───────────────────────────────────────────────────────────

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _hidePassword = true;
  bool _hideConfirm = true;
  bool _busy = false;
  String? _error;
  List<Map<String, dynamic>> _puroks = [];
  List<Map<String, dynamic>> _locations = [];
  String? _selectedPurokId;
  String? _selectedLocationId;
  bool _puroksLoading = false;
  bool _puroksLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadPuroks();
  }

  Future<void> _loadPuroks() async {
    setState(() { _puroksLoading = true; _puroksLoadFailed = false; });
    try {
      final response = await Api.req('GET', '/puroks', auth: false);
      final purokList = (response['puroks'] as List).cast<Map<String, dynamic>>();
      final locationList = (response['locations'] as List? ?? []).cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() {
          _puroks = purokList;
          _locations = locationList;
          _puroksLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() { _puroksLoading = false; _puroksLoadFailed = true; });
      }
    }
  }

  Future<void> _register() async {
    if (_fullName.text.trim().isEmpty || _email.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in all required fields.');
      return;
    }
    // Phone validation
    final phone = _phone.text.trim();
    if (phone.isNotEmpty && !RegExp(r'^09\d{9}$').hasMatch(phone)) {
      setState(() => _error = 'Phone number must start with 09 and be 11 digits.');
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
    if (_password.text.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }
    if (_password.text != _confirmPassword.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      await Api.req('POST', '/register', auth: false, body: {
        'name': _fullName.text.trim(),
        'email': _email.text.trim(),
        'phone': phone.isEmpty ? null : phone,
        'purok_id': int.parse(_selectedPurokId!),
        'location_id': int.parse(_selectedLocationId!),
        'password': _password.text,
        'password_confirmation': _confirmPassword.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration request submitted. You will receive an email once approved.')),
        );
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _fullName.dispose(); _email.dispose(); _phone.dispose();
    _password.dispose(); _confirmPassword.dispose();
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
                    const SizedBox(height: 24),
                    const Text('Request Staff Access', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: ink)),
                    const SizedBox(height: 6),
                    const Text('Your request will be reviewed by an admin', textAlign: TextAlign.center,
                        style: TextStyle(color: muted, fontSize: 14)),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _FieldLabel('Full name'),
                            const SizedBox(height: 6),
                            TextField(controller: _fullName),
                            const SizedBox(height: 14),
                            const _FieldLabel('Email'),
                            const SizedBox(height: 6),
                            TextField(controller: _email, keyboardType: TextInputType.emailAddress),
                            const SizedBox(height: 14),
                            const _FieldLabel('Phone (optional, must start with 09)'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              maxLength: 11,
                              decoration: const InputDecoration(counterText: ''),
                            ),
                            const SizedBox(height: 14),
                            const _FieldLabel('Location / Barangay'),
                            const SizedBox(height: 6),
                            if (_puroksLoading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                              )
                            else if (_puroksLoadFailed)
                              const SizedBox.shrink()
                            else
                              DropdownButtonFormField<String>(
                                initialValue: _selectedLocationId,
                                hint: const Text('Select Location'),
                                items: _locations.map((l) => DropdownMenuItem<String>(
                                  value: l['id'].toString(),
                                  child: Text(l['name'].toString()),
                                )).toList(),
                                onChanged: (v) => setState(() => _selectedLocationId = v),
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                ),
                              ),
                            const SizedBox(height: 14),
                            const _FieldLabel('Assigned Purok'),
                            const SizedBox(height: 6),
                            if (_puroksLoading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                              )
                            else if (_puroksLoadFailed)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text('Could not load puroks. Check your connection.',
                                      style: TextStyle(color: Colors.red, fontSize: 13)),
                                  const SizedBox(height: 6),
                                  TextButton.icon(
                                    onPressed: _loadPuroks,
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('Retry'),
                                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                  ),
                                ],
                              )
                            else
                              DropdownButtonFormField<String>(
                                initialValue: _selectedPurokId,
                                hint: const Text('Select Purok'),
                                items: _puroks.map((p) => DropdownMenuItem<String>(
                                  value: p['id'].toString(),
                                  child: Text(p['name'].toString()),
                                )).toList(),
                                onChanged: (v) => setState(() => _selectedPurokId = v),
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                ),
                              ),
                            const SizedBox(height: 14),
                            const _FieldLabel('Password (min 8 characters)'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _password,
                              obscureText: _hidePassword,
                              decoration: InputDecoration(
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
                                  icon: Icon(_hidePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const _FieldLabel('Confirm password'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _confirmPassword,
                              obscureText: _hideConfirm,
                              decoration: InputDecoration(
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
                                  icon: Icon(_hideConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                ),
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                            ],
                            const SizedBox(height: 18),
                            FilledButton(
                              onPressed: _busy ? null : _register,
                              child: _busy
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Submit Request'),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Already have an account? ', style: TextStyle(color: muted, fontSize: 13)),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: const Text('Sign in', style: TextStyle(color: blue, fontWeight: FontWeight.w700, fontSize: 13)),
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

// ─── Forgot Password Page ────────────────────────────────────────────────────

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
    setState(() { _busy = true; _error = null; });
    try {
      await Api.req('POST', '/password/forgot', auth: false, body: {'email': _email.text.trim()});
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => VerifyOtpPage(email: _email.text.trim())));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() { _email.dispose(); super.dispose(); }

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
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink)),
                        const SizedBox(height: 6),
                        const Text('Verify your email before creating a new password.',
                            style: TextStyle(color: muted, fontSize: 13)),
                        const SizedBox(height: 22),
                        const _FieldLabel('Gmail address'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(hintText: 'you@gmail.com'),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                        ],
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: _busy ? null : _sendOtp,
                          child: _busy
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Send OTP'),
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Back to login', style: TextStyle(color: blue, fontWeight: FontWeight.w600)),
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

// ─── Verify OTP Page ─────────────────────────────────────────────────────────

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
    setState(() { _busy = true; _error = null; });
    try {
      await Api.req('POST', '/password/verify-otp', auth: false, body: {
        'email': widget.email,
        'otp': _otp.text.trim(),
      });
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ResetPasswordPage(email: widget.email)),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _error = null);
    try {
      await Api.req('POST', '/password/forgot', auth: false, body: {'email': widget.email});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP resent to your email.')));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  void dispose() { _otp.dispose(); super.dispose(); }

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
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink)),
                        const SizedBox(height: 6),
                        const Text('Verify your email before creating a new password.',
                            style: TextStyle(color: muted, fontSize: 13)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xffecfdf5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'A 6-digit OTP was sent to your email. It expires in 10 minutes.',
                            style: TextStyle(color: Color(0xff059669), fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const _FieldLabel('6-digit OTP'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _otp,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(hintText: 'Enter OTP', counterText: ''),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                        ],
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: _busy ? null : _verifyOtp,
                          child: _busy
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Verify OTP'),
                        ),
                        const SizedBox(height: 10),
                        Center(child: TextButton(onPressed: _resendOtp, child: const Text('Resend OTP', style: TextStyle(color: blue, fontWeight: FontWeight.w600)))),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false),
                            child: const Text('Back to login', style: TextStyle(color: blue, fontWeight: FontWeight.w600)),
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

// ─── Reset Password Page ─────────────────────────────────────────────────────

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
    setState(() { _busy = true; _error = null; });
    try {
      await Api.req('POST', '/password/reset', auth: false, body: {
        'email': widget.email,
        'new_password': _newPassword.text,
        'new_password_confirmation': _confirmPassword.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset successfully. Please sign in.')));
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() { _newPassword.dispose(); _confirmPassword.dispose(); super.dispose(); }

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
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink)),
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
                              onPressed: () => setState(() => _hideNew = !_hideNew),
                              icon: Icon(_hideNew ? Icons.visibility_outlined : Icons.visibility_off_outlined),
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
                              onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
                              icon: Icon(_hideConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                        ],
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: _busy ? null : _reset,
                          child: _busy
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ink));
}

class NavItem {
  final String title;
  final IconData icon;
  final Widget page;
  const NavItem(this.title, this.icon, this.page);
}

// ─── Staff Home ───────────────────────────────────────────────────────────────

class StaffHome extends StatefulWidget {
  const StaffHome({super.key});
  @override
  State<StaffHome> createState() => _StaffHomeState();
}

class _StaffHomeState extends State<StaffHome> {
  int index = 0;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _announcementTimer;

  late final List<NavItem> items = const [
    NavItem('Dashboard', Icons.grid_view_rounded, StaffDashboard()),
    NavItem('Resources', Icons.inventory_2_outlined, ResourcePage()),
    NavItem('QR Tracking', Icons.qr_code_2_rounded, ScanPage()),
    NavItem('Distribution', Icons.local_shipping_outlined, DistributionPage()),
    NavItem('Locations', Icons.location_on_outlined, LocationPage()),
    NavItem('Reports', Icons.description_outlined, ReportPage()),
    NavItem('Messages', Icons.chat_bubble_outline, MessagePage()),
    NavItem('Families', Icons.groups_outlined, FamilyListPage()),
    NavItem('Scan History', Icons.history_rounded, ScanHistoryPage()),
  ];

  @override
  void initState() {
    super.initState();
    _announcementTimer = Timer.periodic(const Duration(seconds: 60), (_) => _checkAnnouncements());
  }

  @override
  void dispose() {
    _announcementTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAnnouncements() async {
    if (!mounted) return;
    try {
      final result = await Api.req('GET', '/announcements');
      final list = result['announcements'] as List? ?? result['data'] as List? ?? [];
      if (list.isEmpty || !mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final lastId = prefs.getInt('last_staff_announcement_id') ?? 0;
      final newItems = list.where((a) {
        final id = (a as Map)['id'];
        return id is int ? id > lastId : (int.tryParse(id.toString()) ?? 0) > lastId;
      }).toList();
      if (newItems.isEmpty || !mounted) return;
      final latest = newItems.last as Map;
      final newMaxId = list.fold<int>(0, (m, a) {
        final id = (a as Map)['id'];
        final i = id is int ? id : (int.tryParse(id.toString()) ?? 0);
        return i > m ? i : m;
      });
      await prefs.setInt('last_staff_announcement_id', newMaxId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(latest['title']?.toString() ?? 'New announcement'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(latest['title']?.toString() ?? 'Announcement'),
                  content: Text(latest['body']?.toString() ?? ''),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                ),
              );
            },
          ),
        ));
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await Api.req('POST', '/logout');
    } catch (_) {}
    await Api.clearToken();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = items[index];
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: blue, borderRadius: BorderRadius.circular(11)),
              child: const Center(child: Text('DR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(selected.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const Text('Disaster Relief', style: TextStyle(color: muted, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (_) => const _NotificationsSheet(),
            ),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xffdbeafe),
              child: Text('S', style: TextStyle(color: blue, fontWeight: FontWeight.bold)),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                logout();
              } else if (value == 'profile') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
              } else {
                _showInfo(context, 'Staff account', 'Signed in with a staff account.');
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'profile', child: Text('Profile')),
              PopupMenuItem(value: 'logout', child: Text('Log out')),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                color: const Color(0xffeff6ff),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: blue, borderRadius: BorderRadius.circular(13)),
                      child: const Center(child: Text('DR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Disaster Relief', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        SizedBox(height: 3),
                        Text('Staff application', style: TextStyle(color: muted, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline, color: muted),
                      title: const Text('Profile', style: TextStyle(color: ink, fontWeight: FontWeight.w500)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
                      },
                    ),
                    const Divider(height: 12),
                    for (var i = 0; i < items.length; i++)
                      ListTile(
                        leading: Icon(items[i].icon, color: i == index ? blue : muted),
                        title: Text(items[i].title,
                            style: TextStyle(
                                color: i == index ? blue : ink,
                                fontWeight: i == index ? FontWeight.w700 : FontWeight.w500)),
                        selected: i == index,
                        selectedTileColor: const Color(0xffeff6ff),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onTap: () {
                          setState(() => index = i);
                          Navigator.pop(context);
                        },
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Log out', style: TextStyle(color: Colors.red)),
                onTap: logout,
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: index,
        children: [for (final item in items) item.page],
      ),
      bottomNavigationBar: NavigationBar(
        height: 68,
        selectedIndex: index < 4 ? index : 0,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Resources'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          NavigationDestination(icon: Icon(Icons.local_shipping_outlined), label: 'Relief'),
        ],
      ),
    );
  }
}

void _showInfo(BuildContext context, String title, String message) => showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))]));

// ─── Staff Dashboard ──────────────────────────────────────────────────────────

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});
  @override State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  late Future<List<Map<String, dynamic>>> future = _load();

  Future<List<Map<String, dynamic>>> _load() async {
    final paths = ['/me', '/resources', '/distributions/history', '/staff/families', '/qr/scans'];
    return Future.wait(paths.map((p) async {
      try { return await Api.req('GET', p); } catch (_) { return <String, dynamic>{}; }
    }));
  }

  List<dynamic> _rows(Map<String, dynamic> map, String key) =>
      map[key] is List ? map[key] as List : <dynamic>[];

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snap) {
          final data          = snap.data ?? const <Map<String, dynamic>>[];
          final me            = data.isNotEmpty   ? data[0]                         : <String, dynamic>{};
          final resources     = data.length > 1   ? _rows(data[1], 'resources')     : <dynamic>[];
          final distributions = data.length > 2   ? _rows(data[2], 'distributions') : <dynamic>[];
          final families      = data.length > 3   ? _rows(data[3], 'families')      : <dynamic>[];
          final scans         = data.length > 4   ? _rows(data[4], 'scans')         : <dynamic>[];

          final user         = me['user'] is Map ? me['user'] as Map<String, dynamic> : <String, dynamic>{};
          final locationName = user['location']?['name']?.toString();
          final purokName    = user['purok']?['name']?.toString();
          final staffName    = user['name']?.toString();

          final pending = distributions.where((e) =>
              (e as Map)['status']?.toString().toLowerCase() == 'pending').length;
          final completed = distributions.where((e) =>
              (e as Map)['status']?.toString().toLowerCase() == 'completed').length;
          final cancelled = distributions.where((e) =>
              (e as Map)['status']?.toString().toLowerCase() == 'cancelled').length;
          final stock = resources.fold<num>(0, (sum, e) {
            final q = (e as Map)['quantity'];
            return sum + (q is num ? q : (num.tryParse(q.toString()) ?? 0));
          });
          final householdsServed = families.where((f) {
            final dist = (f as Map)['latest_distribution'];
            return dist is Map &&
                dist['status']?.toString().toLowerCase() == 'completed';
          }).length;

          return RefreshIndicator(
            onRefresh: () async => setState(() => future = _load()),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              children: [
                const Text('Overview of relief operations', style: TextStyle(color: muted, fontSize: 13)),
                const SizedBox(height: 16),

                // My Assignment card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(color: const Color(0xffeff6ff), borderRadius: BorderRadius.circular(11)),
                              child: const Icon(Icons.badge_outlined, color: blue, size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Text('My Assignment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ink)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 14),
                        _AssignmentRow(
                          icon: Icons.location_on_outlined,
                          label: 'Assigned Location',
                          value: snap.hasData ? (locationName ?? 'Not assigned') : '\u2014',
                        ),
                        const SizedBox(height: 10),
                        _AssignmentRow(
                          icon: Icons.map_outlined,
                          label: 'Assigned Purok',
                          value: snap.hasData ? (purokName ?? 'Not assigned') : '\u2014',
                        ),
                        const SizedBox(height: 10),
                        _AssignmentRow(
                          icon: Icons.person_outline,
                          label: 'Purok Handler',
                          value: snap.hasData ? (staffName ?? 'Unknown') : '\u2014',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                if (snap.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(),

                // Stat grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.42,
                  children: [
                    _StatCard(title: 'Total Resources',      value: snap.hasData ? '${resources.length}'    : '\u2014', icon: Icons.inventory_2_outlined,       tint: const Color(0xffeff6ff), color: blue),
                    _StatCard(title: 'Total Stock Quantity',  value: snap.hasData ? '$stock'                 : '\u2014', icon: Icons.widgets_outlined,            tint: const Color(0xffeef2ff), color: const Color(0xff4f46e5)),
                    _StatCard(title: 'Pending',               value: snap.hasData ? '$pending'           : '\u2014', icon: Icons.local_shipping_outlined,     tint: const Color(0xfff1f5f9), color: const Color(0xff475569)),
                    _StatCard(title: 'Completed',             value: snap.hasData ? '$completed'             : '\u2014', icon: Icons.check_circle_outline,        tint: const Color(0xffecfdf5), color: const Color(0xff059669)),
                    _StatCard(title: 'Cancelled',             value: snap.hasData ? '$cancelled'             : '\u2014', icon: Icons.cancel_outlined,             tint: const Color(0xfffff1f2), color: const Color(0xffdc2626)),
                    _StatCard(title: 'Families',              value: snap.hasData ? '${families.length}'     : '\u2014', icon: Icons.groups_outlined,             tint: const Color(0xffeff6ff), color: blue),
                    _StatCard(title: 'QR Scans Logged',       value: snap.hasData ? '${scans.length}'        : '\u2014', icon: Icons.qr_code_2_rounded,           tint: const Color(0xfffaf5ff), color: const Color(0xffa855f7)),
                    _StatCard(title: 'Households Served',     value: snap.hasData ? '$householdsServed'  : '\u2014', icon: Icons.volunteer_activism_outlined, tint: const Color(0xfff0fdfa), color: const Color(0xff0d9488)),
                  ],
                ),
                const SizedBox(height: 22),

                const SizedBox(height: 4),
                const Text(
                  'Current Relief Distribution',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ink),
                ),
                const SizedBox(height: 6),
                _SectionCard(
                  title: 'Recent Distributions',
                  action: 'View All',
                  onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DistributionPage())),
                  child: distributions.isEmpty
                      ? const _EmptyState(text: 'No distributions to show yet.')
                      : Column(children: distributions.take(4).map((e) {
                          final m = e as Map;
                          return _MiniRecord(
                            icon: Icons.local_shipping_outlined,
                            title: '${m['family_name'] ?? m['family']?['name'] ?? 'Family distribution'}',
                            subtitle: '${m['status'] ?? 'Status unavailable'} \u2022 ${m['distribution_date'] ?? m['scheduled_at'] ?? ''}',
                          );
                        }).toList()),
                ),
                const SizedBox(height: 14),

                _SectionCard(
                  title: 'Recent QR Scans',
                  action: 'View All',
                  onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanHistoryPage())),
                  child: scans.isEmpty
                      ? const _EmptyState(text: 'No scan records to show yet.')
                      : Column(children: scans.take(4).map((e) {
                          final m = e as Map;
                          return _MiniRecord(
                            icon: Icons.qr_code_2,
                            title: '${m['resource']?['name'] ?? m['resource_name'] ?? 'Resource scan'}',
                            subtitle: '${m['scan_type'] ?? 'Scan'} \u2022 ${m['scanned_at'] ?? ''}',
                          );
                        }).toList()),
                ),
                const SizedBox(height: 14),

                _SectionCard(
                  title: 'Low Stock Alerts',
                  child: resources.where((e) {
                    final m = e as Map;
                    final q = m['quantity']; final min = m['minimum_threshold'] ?? m['min_quantity'];
                    return q is num && min is num && q <= min;
                  }).isEmpty
                      ? const _EmptyState(text: 'No low-stock alerts, or stock thresholds are unavailable.')
                      : Column(children: resources.where((e) {
                          final m = e as Map;
                          final q = m['quantity']; final min = m['minimum_threshold'] ?? m['min_quantity'];
                          return q is num && min is num && q <= min;
                        }).map((e) {
                          final m = e as Map;
                          return _MiniRecord(
                            icon: Icons.warning_amber_rounded,
                            title: '${m['name'] ?? 'Resource'}',
                            subtitle: 'Remaining stock: ${m['quantity']}',
                          );
                        }).toList()),
                ),
              ],
            ),
          );
        },
      );
}

// Assignment row helper
class _AssignmentRow extends StatelessWidget {
  const _AssignmentRow({required this.icon, required this.label, required this.value});
  final IconData icon; final String label; final String value;
  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: muted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: muted)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ink)),
              ],
            ),
          ),
        ],
      );
}

class _StatCard extends StatelessWidget {
  final String title, value; final IconData icon; final Color tint, color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.tint, required this.color});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: color, size: 21)), Text(value, style: const TextStyle(fontSize: 24, height: 1.1, fontWeight: FontWeight.w800, color: ink)), Text(title, style: const TextStyle(fontSize: 11, color: muted), maxLines: 2, overflow: TextOverflow.ellipsis)])));
}

class _SectionCard extends StatelessWidget {
  final String title; final String? action; final VoidCallback? onAction; final Widget child;
  const _SectionCard({required this.title, required this.child, this.action, this.onAction});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))), if (action != null) TextButton(onPressed: onAction, child: Text(action!))]), const SizedBox(height: 8), child])));
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4), child: Center(child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 13))));
}

class _MiniRecord extends StatelessWidget {
  final IconData icon; final String title, subtitle;
  const _MiniRecord({required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => ListTile(contentPadding: EdgeInsets.zero, leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xffeff6ff), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: blue, size: 20)), title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: Text(subtitle.trim().isEmpty ? '\u2014' : subtitle, style: const TextStyle(fontSize: 11, color: muted), maxLines: 1, overflow: TextOverflow.ellipsis));
}

// ─── Scan Page (QR Tracking) ──────────────────────────────────────────────────

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
    });
    _qrCtrl.text        = scannedQr;
    _familyCtrl.text    = '${fam['family_name'] ?? ''} (${fam['family_id'] ?? ''})';
    _headCtrl.text      = fam['head_name']?.toString() ?? '';
    _purokCtrl.text     = purok;
    _reliefCtrl.text    = resource is Map ? (resource['name']?.toString() ?? '') : '';
    _receiverCtrl.text  = fam['head_name']?.toString() ?? '';
    _dateCtrl.text      = date;
    _timeCtrl.text      = timeDisplay;
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
        'receiver':        _receiverCtrl.text.trim().isEmpty ? null : _receiverCtrl.text.trim(),
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
                    _ReadField(label: 'Receiver', controller: _receiverCtrl, icon: Icons.person_outline),
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

// ─── Message Page (Chat Bubbles) ──────────────────────────────────────────────

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

// ─── Resource Page ────────────────────────────────────────────────────────────

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

// ─── Distribution Page ────────────────────────────────────────────────────────

class DistributionPage extends StatefulWidget {
  const DistributionPage({super.key});
  @override
  State<DistributionPage> createState() => _DistributionPageState();
}

class _DistributionPageState extends State<DistributionPage> {
  List<Map<String, dynamic>> _distributions = [];
  List<Map<String, dynamic>> _schedules = [];
  Map<String, dynamic>? _selectedSchedule;
  String _search = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
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
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _distributions;
    if (_selectedSchedule != null) {
      list = list.where((d) {
        final date    = d['distribution_date']?.toString().substring(0, 10);
        final resName = d['resource']?['name']?.toString();
        final locName = d['location']?['name']?.toString();
        return date == _selectedSchedule!['date'] &&
               resName == _selectedSchedule!['resource_name'] &&
               locName == _selectedSchedule!['location_name'];
      }).toList();
    }
    if (_search.isEmpty) return list;
    return list.where((d) {
      final hay = '${d['family']?['family_name'] ?? d['family_name'] ?? ''} ${d['family_id'] ?? ''} ${d['status'] ?? ''}'.toLowerCase();
      return hay.contains(_search.toLowerCase());
    }).toList();
  }

  int _countStatus(String status) => _filtered
      .where((d) => (d['status']?.toString() ?? '') == status)
      .length;

  Color _statusColor(String? s) {
    final v = s?.toLowerCase() ?? '';
    if (v == 'completed') return const Color(0xff059669);
    if (v == 'cancelled' || v == 'canceled') return const Color(0xffdc2626);
    if (v == 'pending') return const Color(0xfff59e0b);
    return muted;
  }

  String _formatFamilyId(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isNotEmpty) return 'FAM-${digits.padLeft(4, '0')}';
    return raw;
  }

  String _formatDistDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final h  = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final m  = dt.minute.toString().padLeft(2, '0');
      final ap = dt.hour >= 12 ? 'PM' : 'AM';
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year} $h:$m $ap';
    } catch (_) { return raw; }
  }

  void _showDetail(Map<String, dynamic> d) {
    final family = d['family'] as Map? ?? {};
    final purok  = family['purok']?['name'] ?? d['purok']?['name'] ?? '';
    final loc    = family['location']?['name'] ?? d['location']?['name'] ?? '';
    final resource = d['resource'] as Map? ?? {};
    final isCompleted = (d['status']?.toString() ?? '').toLowerCase() == 'completed';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.95,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xffe2e8f0), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Distribution Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ink)),
            const SizedBox(height: 12),
            _DetailRow('Relief Code', d['qr_code']?.toString() ?? d['id']?.toString()),
            _DetailRow('Family ID', _formatFamilyId(family['family_id']?.toString() ?? d['family_id']?.toString())),
            _DetailRow('Family Name', family['family_name']?.toString() ?? d['family_name']?.toString()),
            _DetailRow('Family Head', family['head_name']?.toString() ?? d['head_name']?.toString()),
            _DetailRow('Location', loc.isNotEmpty ? '$purok, $loc' : purok),
            _DetailRow('Relief', resource['name']?.toString() ?? d['resource_name']?.toString()),
            _DetailRow('Additional Items', d['additional_items']?.toString()),
            _DetailRow('Qty', d['quantity']?.toString()),
            _DetailRow('Scanned By', d['distributor']?['name']?.toString() ?? d['scanned_by']?.toString()),
            _DetailRow('Status', d['status']?.toString()),
            if (isCompleted)
              _DetailRow('Receiver', d['recipient_name']?.toString() ?? d['receiver']?.toString()),
            _DetailRow('Disaster', d['disaster']?.toString()),
            _DetailRow('Reason', d['reason']?.toString()),
            _DetailRow('Date', _formatDistDate(d['distribution_date']?.toString() ?? d['scheduled_at']?.toString())),
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
              decoration: const InputDecoration(labelText: 'Distribution Schedule', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              items: [
                const DropdownMenuItem(value: null, child: Text('All schedules')),
                ..._schedules.map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(
                    '${s['date'] ?? ''} \u2022 ${s['resource_name'] ?? ''} \u2022 ${s['location_name'] ?? ''}',
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
              ],
              onChanged: (v) => setState(() => _selectedSchedule = v),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              _MiniStatChip('Families',  '${filtered.length}',               const Color(0xff2563eb)),
              const SizedBox(width: 8),
              _MiniStatChip('Pending',   '${_countStatus('pending')}',   const Color(0xfff59e0b)),
              const SizedBox(width: 8),
              _MiniStatChip('Completed', '${_countStatus('completed')}', const Color(0xff059669)),
              const SizedBox(width: 8),
              _MiniStatChip('Cancelled', '${_countStatus('cancelled')}', const Color(0xffdc2626)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search distributions...'),
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
                    const Icon(Icons.cloud_off_outlined, size: 36, color: muted),
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: muted, fontSize: 13),
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
                ? const Center(child: Text('No distributions found.', style: TextStyle(color: muted)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final d = filtered[i];
                      final family = d['family'] as Map? ?? {};
                      final name = family['family_name']?.toString() ?? d['family_name']?.toString() ?? d['recipient_name']?.toString() ?? 'Distribution';
                      final resource = d['resource'] as Map? ?? {};
                      final resName = resource['name']?.toString() ?? d['resource_name']?.toString() ?? '';
                      final status = d['status']?.toString() ?? '';
                      final date = _formatDistDate(d['distribution_date']?.toString() ?? d['scheduled_at']?.toString());
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
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(color: const Color(0xfff0fdfa), borderRadius: BorderRadius.circular(13)),
                                    child: const Icon(Icons.local_shipping_outlined, color: Color(0xff0d9488)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                        if (resName.isNotEmpty) Text(resName, style: const TextStyle(fontSize: 12, color: muted)),
                                        if (date.isNotEmpty) Text(date, style: const TextStyle(fontSize: 11, color: muted)),
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

// ─── Location Page ────────────────────────────────────────────────────────────

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

// ─── Report Page ──────────────────────────────────────────────────────────────

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _resourcesByCategory  = [];
  List<Map<String, dynamic>> _distributionsByMonth = [];
  List<Map<String, dynamic>> _lowStock             = [];
  List<Map<String, dynamic>> _scansByType          = [];
  List<Map<String, dynamic>> _resourcesByLocation  = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await Api.req('GET', '/reports');
      final s = result['summary'] as Map<String, dynamic>? ?? result;
      if (mounted) {
        setState(() {
          _summary = s;
          _resourcesByCategory  = (result['resources_by_category']  as List? ?? [])
              .map((e) => e as Map<String, dynamic>).toList();
          _distributionsByMonth = (result['distributions_by_month'] as List? ?? [])
              .map((e) => e as Map<String, dynamic>).toList();
          _lowStock             = (result['low_stock'] as List? ?? [])
              .map((e) => e as Map<String, dynamic>).toList();
          _scansByType          = (result['qr_scans_by_type'] as List? ?? [])
              .map((e) => e as Map<String, dynamic>).toList();
          _resourcesByLocation  = (result['resources_by_location'] as List? ?? [])
              .map((e) => e as Map<String, dynamic>).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  int _val(String key) {
    final v = _summary[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '0') ?? 0;
  }

  String _formatScanTypeLabel(String raw) {
    switch (raw.toLowerCase()) {
      case 'completed': return 'Completed';
      case 'pending':   return 'Pending';
      case 'cancelled': return 'Cancelled';
      case 'released':  return 'Released';
      case 'returned':  return 'Returned';
      case 'verified':  return 'Verified';
      default:          return raw.replaceAll('_', ' ').toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) { return const Center(child: CircularProgressIndicator()); }
    if (_error != null) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 40, color: muted),
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(color: muted, fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: _load, child: const Text('Try again')),
        ],
      ));
    }

    final stats = [
      {'label': 'Total Resources',     'value': _val('total_resources'),          'icon': Icons.inventory_2_outlined,        'color': blue,                    'tint': const Color(0xffeff6ff)},
      {'label': 'Total Families',      'value': _val('total_families'),           'icon': Icons.groups_outlined,             'color': const Color(0xff4f46e5), 'tint': const Color(0xffeef2ff)},
      {'label': 'Completed',           'value': _val('completed_distributions'),  'icon': Icons.check_circle_outline,        'color': const Color(0xff059669), 'tint': const Color(0xffecfdf5)},
      {'label': 'Pending',             'value': _val('pending_distributions'),    'icon': Icons.hourglass_empty_outlined,    'color': const Color(0xfff59e0b), 'tint': const Color(0xfffffbeb)},
      {'label': 'Cancelled',           'value': _val('cancelled_distributions'),  'icon': Icons.cancel_outlined,             'color': const Color(0xffdc2626), 'tint': const Color(0xfffff1f2)},
      {'label': 'Households Served',   'value': _val('household_member_served'),  'icon': Icons.volunteer_activism_outlined, 'color': const Color(0xff0d9488), 'tint': const Color(0xfff0fdfa)},
      {'label': 'QR Scans',            'value': _val('total_scans'),              'icon': Icons.qr_code_2_rounded,           'color': const Color(0xffa855f7), 'tint': const Color(0xfffaf5ff)},
      {'label': 'Low Stock Items',     'value': _val('low_stock_count'),          'icon': Icons.warning_amber_rounded,       'color': const Color(0xffdc2626), 'tint': const Color(0xfffff1f2)},
    ];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Relief Operation Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ink)),
          const SizedBox(height: 4),
          const Text('Summary statistics for your assigned location', style: TextStyle(color: muted, fontSize: 13)),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: stats.map((s) => Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: s['tint'] as Color, borderRadius: BorderRadius.circular(11)),
                      child: Icon(s['icon'] as IconData, color: s['color'] as Color, size: 20),
                    ),
                    Text('${s['value']}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: ink, height: 1.1)),
                    Text(s['label'] as String, style: const TextStyle(fontSize: 11, color: muted), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 20),

          // Resources by Category
          if (_resourcesByCategory.isNotEmpty) ...[
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Resources by Category', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ..._resourcesByCategory.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Expanded(child: Text(c['category']?.toString() ?? 'Uncategorized', style: const TextStyle(fontSize: 13, color: ink))),
                    Text('${c['count']} items \u2022 ${c['quantity']} units', style: const TextStyle(fontSize: 12, color: muted)),
                  ]),
                )),
              ]),
            )),
            const SizedBox(height: 14),
          ],

          // Distributions by Month
          if (_distributionsByMonth.isNotEmpty) ...[
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Distributions by Month', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ..._distributionsByMonth.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Expanded(child: Text(m['month']?.toString() ?? '', style: const TextStyle(fontSize: 13, color: ink))),
                    Text('${m['count']} distributions \u2022 ${m['household_member']} served', style: const TextStyle(fontSize: 12, color: muted)),
                  ]),
                )),
              ]),
            )),
            const SizedBox(height: 14),
          ],

          // QR Scans by Type
          if (_scansByType.isNotEmpty) ...[
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('QR Scans by Type', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ..._scansByType.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Expanded(child: Text(_formatScanTypeLabel(s['scan_type']?.toString() ?? ''), style: const TextStyle(fontSize: 13, color: ink))),
                    Text('${s['count']} scans', style: const TextStyle(fontSize: 12, color: muted)),
                  ]),
                )),
              ]),
            )),
            const SizedBox(height: 14),
          ],

          // Resources by Location
          if (_resourcesByLocation.isNotEmpty) ...[
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Resources by Location', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ..._resourcesByLocation.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Expanded(child: Text(l['location']?.toString() ?? 'Unknown', style: const TextStyle(fontSize: 13, color: ink))),
                    Text('${l['resources_count']} items \u2022 ${l['total_quantity']} units', style: const TextStyle(fontSize: 12, color: muted)),
                  ]),
                )),
              ]),
            )),
            const SizedBox(height: 14),
          ],


          // Low Stock Watchlist
          if (_lowStock.isNotEmpty) ...[
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Low Stock Watchlist', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xffdc2626))),
                const SizedBox(height: 12),
                ..._lowStock.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xffdc2626), size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item['name']?.toString() ?? '', style: const TextStyle(fontSize: 13, color: ink))),
                    Text('${item['quantity']} / ${item['minimum_threshold']} ${item['unit'] ?? ''}',
                        style: const TextStyle(fontSize: 12, color: Color(0xffdc2626), fontWeight: FontWeight.w600)),
                  ]),
                )),
              ]),
            )),
            const SizedBox(height: 14),
          ],

          // Export Report button
          FilledButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Export report \u2014 coming soon.')),
            ),
            icon: const Icon(Icons.download_outlined),
            label: const Text('Export Report'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xff4f46e5),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─── Family Register Sheet (staff manually registers a family) ───────────────

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
  final _familyNameCtrl = TextEditingController();
  final _headNameCtrl   = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _phoneCtrl      = TextEditingController();
  final _addressCtrl    = TextEditingController();
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
    for (final c in [_familyNameCtrl, _headNameCtrl, _emailCtrl, _phoneCtrl,
        _addressCtrl, _pinCtrl, _confirmPinCtrl, ..._memberCtrls]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    // Validate required fields
    if (_familyNameCtrl.text.trim().isEmpty || _headNameCtrl.text.trim().isEmpty ||
        _addressCtrl.text.trim().isEmpty) {
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
        'family_name':      _familyNameCtrl.text.trim(),
        'head_name':        _headNameCtrl.text.trim(),
        'email':            _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'phone':            phone.isEmpty ? null : phone,
        'address':          _addressCtrl.text.trim(),
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
                _buildField('Family Name *', _familyNameCtrl),
                _buildField('Head of Family *', _headNameCtrl),
                _buildField('Phone (optional, 09XXXXXXXXX)', _phoneCtrl, keyboard: TextInputType.phone, maxLen: 11),
                _buildField('Email (optional, for PIN recovery)', _emailCtrl, keyboard: TextInputType.emailAddress),
                _buildField('Address *', _addressCtrl),
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
                  items: widget.puroks.map((p) => DropdownMenuItem<String>(
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
                  items: widget.locations.map((l) => DropdownMenuItem<String>(
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

// ─── Family Detail Sheet ──────────────────────────────────────────────────────

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
          Text(f['family_name']?.toString() ?? 'Family', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ink)),
          const SizedBox(height: 12),
          _DetailRow('Family', f['family_name']?.toString()),
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

// ─── Family List Page ─────────────────────────────────────────────────────────

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
      final hay = '${f['family_name']} ${f['head_name']} ${f['family_id']}'.toLowerCase();
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
                                        Text(f['family_name']?.toString() ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
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

// ─── Profile Page ─────────────────────────────────────────────────────────────

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

// ─── Scan History Page (uses _ApiListPage — kept intact) ─────────────────────

class ScanHistoryPage extends StatelessWidget {
  const ScanHistoryPage({super.key});
  @override
  Widget build(BuildContext context) => const _ApiListPage(
        path: '/qr/scans',
        listKey: 'scans',
        title: 'QR Scan History',
        subtitle: 'Recent tracking activity',
        kind: 'scan',
      );
}

// ─── _ApiListPage (kept intact for ScanHistoryPage) ──────────────────────────

class _ApiListPage extends StatefulWidget {
  const _ApiListPage({
    required this.path,
    required this.listKey,
    required this.title,
    required this.subtitle,
    required this.kind,
  });

  final String path;
  final String listKey;
  final String title;
  final String subtitle;
  final String kind;

  @override
  State<_ApiListPage> createState() => _ApiListPageState();
}

class _ApiListPageState extends State<_ApiListPage> {
  late Future<Map<String, dynamic>> future;
  String search = '';

  @override
  void initState() {
    super.initState();
    future = Api.req('GET', widget.path);
  }

  IconData get icon {
    switch (widget.kind) {
      case 'resource':     return Icons.inventory_2_outlined;
      case 'distribution': return Icons.local_shipping_outlined;
      case 'family':       return Icons.groups_outlined;
      case 'scan':         return Icons.qr_code_2;
      case 'location':     return Icons.location_on_outlined;
      case 'report':       return Icons.description_outlined;
      default:             return Icons.chat_bubble_outline;
    }
  }

  String _title(Map<String, dynamic> row) {
    return (row['family']?['family_name'] ??
            row['family_name'] ??
            row['family']?['name'] ??
            row['resource']?['name'] ??
            row['name'] ??
            row['title'] ??
            row['head_name'] ??
            row['family_id'] ??
            row['scan_type'] ??
            'Record')
        .toString();
  }

  String _subtitle(Map<String, dynamic> row) {
    final fields = switch (widget.kind) {
      'resource' => [
          row['category'],
          row['quantity'] == null ? null : '${row['quantity']} ${row['unit'] ?? ''}',
          row['location']?['name'] ?? row['location_name'],
          row['status'],
        ],
      'distribution' => [
          row['head_name'] ?? row['family_head']?['name'],
          row['purok']?['name'] ?? row['purok_name'],
          row['resource']?['name'] ?? row['resource_name'],
          row['quantity'] == null ? null : 'Qty ${row['quantity']}',
          row['status'],
          row['distribution_date'] ?? row['scheduled_at'],
        ],
      'family' => [
          row['family_id'],
          row['head_name'] ?? row['family_head'],
          row['purok']?['name'] ?? row['purok_name'],
          row['members_count'] == null ? null : '${row['members_count']} household members',
        ],
      'scan' => [
          row['family']?['family_name'],
          row['family']?['head_name'],
          row['scan_type'],
          row['quantity_change'] == null ? null : 'Qty ${row['quantity_change']}',
          row['location']?['name'],
          row['scanner']?['name'] == null ? null : 'By ${row['scanner']['name']}',
          _fmtScanDate(row['scanned_at'] ?? row['created_at']),
        ],
      'location' => [row['address'], row['purok'], row['type'], row['status']],
      'report'   => [row['description'], row['created_at'] ?? row['date']],
      _          => [row['body'] ?? row['message'], row['created_at'], row['status']],
    };

    return fields
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .map((value) => value.toString())
        .join(' \u2022 ');
  }

  String _fmtScanDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return DateFormat('MMM d, y h:mm a').format(dt);
    } catch (_) {
      return raw.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        final raw = snapshot.data?[widget.listKey] as List? ?? const [];
        final rows = raw.where((item) {
          final row = item as Map<String, dynamic>;
          final haystack = '${_title(row)} ${_subtitle(row)}';
          return haystack.toLowerCase().contains(search.toLowerCase());
        }).toList();

        return RefreshIndicator(
          onRefresh: () async => setState(() => future = Api.req('GET', widget.path)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(widget.subtitle, style: const TextStyle(color: muted, fontSize: 13)),
              const SizedBox(height: 14),
              TextField(
                onChanged: (value) => setState(() => search = value),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search ${widget.title.toLowerCase()}...',
                ),
              ),
              const SizedBox(height: 14),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator())),
              if (snapshot.hasError)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_off_outlined, size: 36, color: muted),
                        const SizedBox(height: 10),
                        Text('Could not load ${widget.title.toLowerCase()}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(snapshot.error.toString().replaceFirst('Exception: ', ''),
                            textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 12)),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => setState(() => future = Api.req('GET', widget.path)),
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!snapshot.hasError && snapshot.connectionState == ConnectionState.done && rows.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(26),
                    child: Column(
                      children: [
                        Container(
                          width: 54, height: 54,
                          decoration: BoxDecoration(color: const Color(0xffeff6ff), borderRadius: BorderRadius.circular(16)),
                          child: Icon(icon, color: blue, size: 27),
                        ),
                        const SizedBox(height: 12),
                        Text(search.isEmpty ? 'No ${widget.title.toLowerCase()} found' : 'No matching results',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 5),
                        const Text('Pull down to refresh the list.', style: TextStyle(color: muted, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ...rows.map((item) {
                final row = item as Map<String, dynamic>;
                final sub = _subtitle(row);
                final status = row['status']?.toString();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(13),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(color: const Color(0xffeff6ff), borderRadius: BorderRadius.circular(13)),
                            child: Icon(icon, color: blue),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_title(row), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                if (sub.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Text(sub, style: const TextStyle(color: muted, fontSize: 12, height: 1.4)),
                                  ),
                                if (status != null && status.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: _StatusChip(status: status),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, color: Color(0xff94a3b8)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

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

class _MiniStatChip extends StatelessWidget {
  const _MiniStatChip(this.label, this.value, this.color);
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: muted)),
        ],
      ),
    ),
  );
}
