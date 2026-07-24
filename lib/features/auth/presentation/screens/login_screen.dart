import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/widgets/buggo_button.dart';
import '../../../../shared/widgets/mascot_widget.dart';
import '../../data/auth_repository.dart';

enum AuthMode { login, signup }

class LoginScreen extends ConsumerStatefulWidget {
  final AuthMode initialMode;

  const LoginScreen({super.key, this.initialMode = AuthMode.login});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _authRepository = AuthRepository();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  late AuthMode _mode = widget.initialMode;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _mode = _mode == AuthMode.login ? AuthMode.signup : AuthMode.login;
      _error = null;
    });
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final name = _nameCtrl.text.trim();

    if (!email.contains('@') || password.length < 6) {
      setState(() => _error = 'Digite um e-mail válido e uma senha com 6+ caracteres.');
      return;
    }
    if (_mode == AuthMode.signup && name.isEmpty) {
      setState(() => _error = 'Digite seu nome.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = _mode == AuthMode.login
          ? await _authRepository.login(email: email, password: password)
          : await _authRepository.signup(email: email, password: password, name: name);
      if (!mounted) return;
      ref.read(userProvider.notifier).saveProfile(profile);
      context.go(AppRouter.home);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Não foi possível conectar. Verifique sua internet.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(text: _emailCtrl.text.trim());
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Recuperar senha', style: AppTextStyles.headlineSmall),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'Seu e-mail'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: AppTextStyles.bodyMedium),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text('Enviar', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );

    if (email == null || email.isEmpty || !mounted) return;
    try {
      final message = await _authRepository.forgotPassword(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível conectar. Verifique sua internet.')),
      );
    }
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textMuted),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      );

  BoxDecoration get _fieldDecoration => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
      );

  @override
  Widget build(BuildContext context) {
    final isSignup = _mode == AuthMode.signup;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Center(
                child: MascotWidget(
                  mood: MascotMood.happy,
                  speechBubble: isSignup ? 'Vamos criar sua conta!' : 'Que bom te ver de novo!',
                ),
              ).animate().scale(begin: const Offset(0.8, 0.8), duration: 400.ms).fade(),
              const SizedBox(height: 24),
              Text(
                isSignup ? 'Criar conta' : 'Entrar',
                style: AppTextStyles.headlineLarge,
              ),
              const SizedBox(height: 6),
              Text(
                isSignup
                    ? 'Seu progresso fica salvo e aparece no ranking.'
                    : 'Continue de onde você parou.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 24),
              if (isSignup) ...[
                Container(
                  decoration: _fieldDecoration,
                  child: TextField(
                    controller: _nameCtrl,
                    style: AppTextStyles.bodyLarge,
                    decoration: _decoration('Seu nome'),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Container(
                decoration: _fieldDecoration,
                child: TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTextStyles.bodyLarge,
                  decoration: _decoration('E-mail'),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                decoration: _fieldDecoration,
                child: TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  style: AppTextStyles.bodyLarge,
                  decoration: _decoration('Senha'),
                ),
              ),
              if (!isSignup) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _forgotPassword,
                    child: Text('Esqueci minha senha',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                  ),
                ),
              ] else
                const SizedBox(height: 20),
              if (_error != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
                ),
              ],
              const SizedBox(height: 8),
              BuggoButton(
                label: isSignup ? 'Criar conta' : 'Entrar',
                icon: Icons.arrow_forward_rounded,
                onPressed: _isLoading ? null : _submit,
                isLoading: _isLoading,
                width: double.infinity,
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : _toggleMode,
                  child: Text(
                    isSignup ? 'Já tem conta? Entrar' : 'Não tem conta? Criar conta',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
