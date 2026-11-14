import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/providers/auth_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await ref.read(authProvider.notifier).signUp(
          _usernameCtrl.text.trim(),
          _emailCtrl.text.trim(),
          _passCtrl.text,
        );
    if (ok && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CadenceColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: CadenceColors.border),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, size: 16, color: CadenceColors.textPrimary),
                ),
              ),

              const SizedBox(height: 40),

              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(gradient: CadenceColors.primaryGradient, borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.album, color: CadenceColors.onPrimary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text('cadence', style: TextStyle(color: CadenceColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                ],
              ),

              const SizedBox(height: 32),

              Text('Create account', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text('Join the community of music lovers', style: Theme.of(context).textTheme.bodyMedium),

              const SizedBox(height: 40),

              if (auth.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CadenceColors.error.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: CadenceColors.error.withAlpha(77)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: CadenceColors.error, size: 16),
                      const SizedBox(width: 8),
                      Text(auth.error!, style: const TextStyle(color: CadenceColors.error, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              _label('Username'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(hintText: 'your_username', prefixIcon: Icon(Icons.alternate_email, size: 18)),
              ),

              const SizedBox(height: 20),

              _label('Email'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'you@example.com', prefixIcon: Icon(Icons.mail_outline, size: 18)),
              ),

              const SizedBox(height: 20),

              _label('Password'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                onFieldSubmitted: (_) => _submit(),
              ),

              const SizedBox(height: 36),

              ElevatedButton(
                onPressed: auth.isLoading ? null : _submit,
                child: auth.isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: CadenceColors.onPrimary))
                    : const Text('Create Account'),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? ', style: Theme.of(context).textTheme.bodyMedium),
                  GestureDetector(
                    onTap: () => context.pushReplacement('/sign-in'),
                    child: const Text('Sign In', style: TextStyle(color: CadenceColors.primaryLight, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Center(
                child: Text(
                  'By creating an account you agree to our\nTerms of Service and Privacy Policy',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(text, style: const TextStyle(color: CadenceColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500));
  }
}
