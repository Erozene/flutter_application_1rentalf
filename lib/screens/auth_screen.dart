// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  late TabController _tabController;

  final _loginEmail = TextEditingController();
  final _loginPass = TextEditingController();
  final _regName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPass = TextEditingController();
  final _regConfirm = TextEditingController();
  final _resetEmail = TextEditingController();

  bool _loading = false;
  bool _loginObscure = true;
  bool _regObscure = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmail.dispose(); _loginPass.dispose();
    _regName.dispose(); _regEmail.dispose();
    _regPass.dispose(); _regConfirm.dispose();
    _resetEmail.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loginEmail.text.isEmpty || _loginPass.text.isEmpty) {
      showAppSnackBar(context, 'Please fill in all fields', isError: true); return;
    }
    setState(() => _loading = true);
    try {
      await _auth.signIn(_loginEmail.text, _loginPass.text);
      Navigator.pop(context);
    } catch (e) {
      showAppSnackBar(context, _parseError(e.toString()), isError: true);
    } finally { setState(() => _loading = false); }
  }

  Future<void> _register() async {
    if (_regName.text.isEmpty || _regEmail.text.isEmpty || _regPass.text.isEmpty) {
      showAppSnackBar(context, 'Please fill in all fields', isError: true); return;
    }
    if (_regPass.text != _regConfirm.text) {
      showAppSnackBar(context, 'Passwords do not match', isError: true); return;
    }
    if (_regPass.text.length < 6) {
      showAppSnackBar(context, 'Password must be at least 6 characters', isError: true); return;
    }
    setState(() => _loading = true);
    try {
      await _auth.register(_regEmail.text, _regPass.text, _regName.text);
      Navigator.pop(context);
    } catch (e) {
      showAppSnackBar(context, _parseError(e.toString()), isError: true);
    } finally { setState(() => _loading = false); }
  }

  Future<void> _forgotPassword() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const AppHeading('Reset Password', size: 22),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Enter your email to receive a reset link.',
              style: AppFonts.dmMono(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          TextField(
            controller: _resetEmail,
            style: AppFonts.dmMono(fontSize: 13),
            decoration: const InputDecoration(hintText: 'Email'),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: AppFonts.dmMono(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () async {
              try {
                await _auth.sendPasswordReset(_resetEmail.text);
                Navigator.pop(context);
                showAppSnackBar(context, 'Reset email sent!');
              } catch (e) {
                showAppSnackBar(context, _parseError(e.toString()), isError: true);
              }
            },
            child: const Text('SEND'),
          ),
        ],
      ),
    );
  }

  String _parseError(String raw) {
    if (raw.contains('user-not-found')) return 'No account with that email';
    if (raw.contains('wrong-password')) return 'Incorrect password';
    if (raw.contains('email-already-in-use')) return 'Email already registered';
    if (raw.contains('invalid-email')) return 'Invalid email address';
    if (raw.contains('network-request-failed')) return 'Network error';
    return 'Something went wrong. Try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(children: [
        SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 16),
                RichText(text: TextSpan(children: [
                  TextSpan(text: 'BASE', style: AppFonts.bebasNeue(fontSize: 52, letterSpacing: 6)),
                  TextSpan(text: 'RENT', style: AppFonts.bebasNeue(fontSize: 52, letterSpacing: 6, color: AppColors.orange)),
                ])),
                Text('Pro gear, on demand.', style: AppFonts.dmMono(fontSize: 12, color: AppColors.textMuted, letterSpacing: 1)),
              ]),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.orange,
                indicatorWeight: 2,
                labelColor: AppColors.text,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: AppFonts.dmMono(fontSize: 11, letterSpacing: 2),
                tabs: const [Tab(text: 'SIGN IN'), Tab(text: 'REGISTER')],
              ),
            ),
            Expanded(child: TabBarView(controller: _tabController, children: [_loginTab(), _registerTab()])),
          ]),
        ),
        if (_loading) const LoadingOverlay(message: 'Authenticating...'),
      ]),
    );
  }

  Widget _loginTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 8),
          _field('Email', _loginEmail, hint: 'you@example.com'),
          const SizedBox(height: 12),
          _field('Password', _loginPass, hint: '••••••••', obscure: _loginObscure,
              toggleObscure: () => setState(() => _loginObscure = !_loginObscure)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _forgotPassword,
              child: Text('Forgot password?', style: AppFonts.dmMono(fontSize: 11, color: AppColors.textMuted)),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _login,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
            child: const Text('SIGN IN →'),
          ),
        ]),
      );

  Widget _registerTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 8),
          _field('Full Name', _regName, hint: 'John Doe'),
          const SizedBox(height: 12),
          _field('Email', _regEmail, hint: 'you@example.com'),
          const SizedBox(height: 12),
          _field('Password', _regPass, hint: '6+ characters', obscure: _regObscure,
              toggleObscure: () => setState(() => _regObscure = !_regObscure)),
          const SizedBox(height: 12),
          _field('Confirm Password', _regConfirm, hint: 'Repeat password', obscure: true),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _register,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
            child: const Text('CREATE ACCOUNT →'),
          ),
          const SizedBox(height: 16),
          Text(
            'By registering you agree to our Terms of Service.',
            textAlign: TextAlign.center,
            style: AppFonts.dmMono(fontSize: 10, color: AppColors.textMuted),
          ),
        ]),
      );

  Widget _field(String label, TextEditingController ctrl,
      {String? hint, bool obscure = false, VoidCallback? toggleObscure}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AppLabel(label),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        obscureText: obscure,
        style: AppFonts.dmMono(fontSize: 13, color: AppColors.text),
        decoration: InputDecoration(
          hintText: hint,
          suffixIcon: toggleObscure != null
              ? IconButton(
                  icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
                      size: 16, color: AppColors.textMuted),
                  onPressed: toggleObscure)
              : null,
        ),
      ),
    ]);
  }
}
