import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_repository.dart';
import '../providers.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  // Lives with the screen, not with the dialog: disposing it as the dialog
  // animates out would tear the field down mid-frame.
  final _resetEmail = TextEditingController();
  bool _isRegister = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _resetEmail.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final email = _email.text.trim();
      final password = _password.text;
      if (_isRegister) {
        await repo.signUp(email: email, password: password);
      } else {
        await repo.signIn(email: email, password: password);
      }
      // AuthGate reacts to the auth state stream; nothing more to do here.
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Asks for the address (pre-filled from the form) and sends the reset
  /// link. The confirmation is deliberately vague about whether an account
  /// exists — same reason the repository swallows "user not found".
  Future<void> _forgotPassword() async {
    _resetEmail.text = _email.text.trim();
    final formKey = GlobalKey<FormState>();
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset your password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'We will email you a link to set a new password. '
                'Your current password cannot be looked up — it is only '
                'ever stored encrypted.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('reset-email'),
                controller: _resetEmail,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'Enter a valid email'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('send-reset'),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(context).pop(_resetEmail.text.trim());
            },
            child: const Text('Send link'),
          ),
        ],
      ),
    );
    if (email == null) return;

    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('If $email has an account, a reset link is on its '
              'way. Check your spam folder too.'),
        ),
      );
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Could not send the reset email. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/icon/dayforge.png',
                    width: 96,
                    height: 96,
                    filterQuality: FilterQuality.medium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'DayForge',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    key: const Key('email'),
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('password'),
                    controller: _password,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Password must be at least 6 characters'
                        : null,
                    onFieldSubmitted: (_) => _busy ? null : _submit(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('submit'),
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isRegister ? 'Create account' : 'Sign in'),
                  ),
                  // Only for existing accounts — nothing to reset while
                  // registering.
                  if (!_isRegister)
                    TextButton(
                      key: const Key('forgot-password'),
                      onPressed: _busy ? null : _forgotPassword,
                      child: const Text('Forgot password?'),
                    ),
                  TextButton(
                    key: const Key('toggle-mode'),
                    onPressed: _busy
                        ? null
                        : () => setState(() => _isRegister = !_isRegister),
                    child: Text(
                      _isRegister
                          ? 'Already have an account? Sign in'
                          : 'New here? Create an account',
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
}
