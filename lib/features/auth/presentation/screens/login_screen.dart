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
import '../../data/google_sign_in_service.dart';

enum AuthMode { login, signup }

class LoginScreen extends ConsumerStatefulWidget {
  final AuthMode initialMode;

  const LoginScreen({super.key, this.initialMode = AuthMode.login});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _authRepository = AuthRepository();
  final _googleSignIn = GoogleSignInService();
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
      // Signing up from a guest session carries the progress earned on this
      // device into the new account; logging in keeps the account as it is.
      ref.read(userProvider.notifier).adoptServerProfile(
            profile,
            carryGuestProgress: _mode == AuthMode.signup,
          );
      context.go(AppRouter.home);
    } on NetworkException catch (e) {
      setState(() => _error = e.message);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      // Anything left here reached the server and broke afterwards, so it
      // must not be reported as a connection problem — show what it was.
      setState(() => _error = 'Erro inesperado: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Google flow: the picker gives an ID token, the backend turns it into a
  /// session. A guest's local progress is carried over on the way in — the
  /// server decides whether this is a new account or an existing one, so
  /// [UserNotifier.adoptServerProfile] only merges when the account came
  /// back empty of progress.
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final idToken = await _googleSignIn.signInAndGetIdToken();
      if (idToken == null) return; // usuário fechou o seletor
      final profile = await _authRepository.loginWithGoogle(idToken);
      if (!mounted) return;
      ref.read(userProvider.notifier).adoptServerProfile(
            profile,
            carryGuestProgress: profile.xp == 0 && profile.completedLessons.isEmpty,
          );
      context.go(AppRouter.home);
    } on GoogleSignInFailure catch (e) {
      setState(() => _error = e.message);
    } on NetworkException catch (e) {
      setState(() => _error = e.message);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Erro inesperado: $e');
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
    } on NetworkException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro inesperado: $e')));
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
              if (_googleSignIn.isConfigured) ...[
                _GoogleButton(
                  label: isSignup
                      ? 'Criar conta com Google'
                      : 'Continuar com Google',
                  onPressed: _isLoading ? null : _signInWithGoogle,
                ),
                const SizedBox(height: 18),
                Row(children: [
                  const Expanded(child: Divider(color: AppColors.cardBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('ou use seu e-mail',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textMuted)),
                  ),
                  const Expanded(child: Divider(color: AppColors.cardBorder)),
                ]),
                const SizedBox(height: 18),
              ],
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


/// Google's button, following their branding rules: white surface, neutral
/// border, and the four-colour G. Drawn in code so there is no image asset
/// to ship or to go missing in a release build.
class _GoogleButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _GoogleButton({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFDADCE0), width: 1.4),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _GoogleG(size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTextStyles.bodyLarge.copyWith(
                color: const Color(0xFF3C4043),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleG extends StatelessWidget {
  final double size;
  const _GoogleG({required this.size});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _GoogleGPainter());
}

class _GoogleGPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = s * 0.22;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, s - stroke, s - stroke);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Quatro arcos de 90°, começando à direita e girando no sentido horário.
    void arc(Color color, double startDeg, double sweepDeg) {
      paint.color = color;
      canvas.drawArc(
        rect,
        startDeg * 3.1415926535 / 180,
        sweepDeg * 3.1415926535 / 180,
        false,
        paint,
      );
    }

    arc(_red, -50, 95);
    arc(_yellow, 45, 90);
    arc(_green, 135, 95);
    arc(_blue, -140, 90);

    // A barra horizontal do "G".
    final bar = Paint()..color = _blue;
    canvas.drawRect(
      Rect.fromLTWH(s * 0.5, s * 0.39, s * 0.5 - stroke / 2, stroke),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
