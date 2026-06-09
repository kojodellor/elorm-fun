import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_animations.dart';
import '../../../data/repositories/auth_repository.dart';

final _loginLoadingProvider = StateProvider<bool>((_) => false);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  // Jhey hero animation — only on the login icon. Nowhere else.
  late final AnimationController _heroCtrl;
  late final Animation<double> _heroScale;
  late final Animation<double> _heroRotate;

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _heroScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _heroCtrl, curve: const ElasticOutCurve(0.8)),
    );
    _heroRotate = Tween<double>(begin: -0.15, end: 0.0).animate(
      CurvedAnimation(parent: _heroCtrl, curve: AppMotion.spring),
    );
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _heroCtrl.forward();
    });
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);
    ref.read(_loginLoadingProvider.notifier).state = true;

    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
      if (mounted) context.go(Routes.dashboard);
    } catch (e) {
      setState(() {
        _errorMessage = _friendlyError(e.toString());
      });
    } finally {
      ref.read(_loginLoadingProvider.notifier).state = false;
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('Invalid login')) return 'Incorrect email or password.';
    if (raw.contains('network')) return 'No connection. Check your network.';
    return 'Sign in failed. Please try again.';
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() =>
          _errorMessage = 'Enter your email address above first.');
      return;
    }

    ref.read(_loginLoadingProvider.notifier).state = true;
    try {
      await ref.read(authRepositoryProvider).resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent. Check your inbox.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Could not send reset email. Try again.');
    } finally {
      ref.read(_loginLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(_loginLoadingProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            // Header with hero icon
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Hero icon (Jhey: elastic spring, only here) ---
                    AnimatedBuilder(
                      animation: _heroCtrl,
                      builder: (_, __) => Transform.rotate(
                        angle: _heroRotate.value,
                        child: Transform.scale(
                          scale: _heroScale.value,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.monitor_heart_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedMount(
                      delay: const Duration(milliseconds: 300),
                      child: const Text(
                        'Team D Clinical',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedMount(
                      delay: const Duration(milliseconds: 380),
                      child: Text(
                        'OB/GYN · KBTH · Accra',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Form card
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedMount(
                          delay: const Duration(milliseconds: 480),
                          child: Text(
                            'Sign in',
                            style:
                                Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedMount(
                          delay: const Duration(milliseconds: 520),
                          child: Text(
                            'Use your department credentials.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Email
                        AnimatedMount(
                          delay: const Duration(milliseconds: 600),
                          child: TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email address',
                              prefixIcon:
                                  Icon(Icons.mail_outline_rounded),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Enter your email';
                              }
                              if (!v.contains('@')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password
                        AnimatedMount(
                          delay: const Duration(milliseconds: 680),
                          child: TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _signIn(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(() =>
                                    _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Enter your password';
                              }
                              if (v.length < 6) return 'Password too short';
                              return null;
                            },
                          ),
                        ),

                        // Error message
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.danger.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    color: AppColors.danger, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: AppColors.danger,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Forgot password
                        AnimatedMount(
                          delay: const Duration(milliseconds: 740),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed:
                                  isLoading ? null : _forgotPassword,
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Sign in button
                        AnimatedMount(
                          delay: const Duration(milliseconds: 800),
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _signIn,
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Sign In'),
                          ),
                        ),

                        const SizedBox(height: 24),
                        AnimatedMount(
                          delay: const Duration(milliseconds: 860),
                          child: const Center(
                            child: Text(
                              'Contact your administrator to get access.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
