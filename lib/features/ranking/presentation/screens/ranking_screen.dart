import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/widgets/buggo_button.dart';
import '../../../../shared/widgets/pixel_avatars.dart';
import '../../data/ranking_entry.dart';
import '../../data/ranking_repository.dart';

enum _RankingMode { xp, streak }

/// Id of the locally-built row shown for someone who isn't in the server
/// list (a guest, or an account ranked below the fetched page).
const _localRowId = '__voce__';

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  final _repository = RankingRepository();
  _RankingMode _mode = _RankingMode.xp;
  late Future<List<RankingEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.fetchTopByXp();
  }

  void _switchMode(_RankingMode mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      _future = mode == _RankingMode.xp
          ? _repository.fetchTopByXp()
          : _repository.fetchTopByStreak();
    });
  }

  /// A signed-in account already comes back in the server list, so appending
  /// a local "você" row would show the same person twice. The local row is
  /// only added for someone the server didn't return: a guest (no account) or
  /// an account ranked below the fetched page.
  List<RankingEntry> _withCurrentUser(
    List<RankingEntry> entries,
    UserProfile user,
  ) {
    final merged = [...entries];
    if (!_isListed(entries, user)) {
      merged.add(RankingEntry(
        id: _localRowId,
        name: '${user.name} (você)',
        avatarIndex: user.avatarIndex,
        xp: user.xp,
        streak: user.streak,
      ));
    }
    merged.sort((a, b) => _mode == _RankingMode.xp
        ? b.xp.compareTo(a.xp)
        : b.streak.compareTo(a.streak));
    return merged;
  }

  bool _isListed(List<RankingEntry> entries, UserProfile user) =>
      user.id != null && entries.any((e) => e.id == user.id);

  bool _isMe(RankingEntry entry, UserProfile user) =>
      entry.id == _localRowId || (user.id != null && entry.id == user.id);

  void _reload() {
    setState(() {
      _future = _mode == _RankingMode.xp
          ? _repository.fetchTopByXp()
          : _repository.fetchTopByStreak();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.headerGradient,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.28),
                                width: 1.4,
                              ),
                            ),
                            child: const Icon(
                              Icons.emoji_events_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ranking',
                                  style: AppTextStyles.headlineLarge
                                      .copyWith(color: Colors.white),
                                ),
                                Text(
                                  'Veja como você está entre os outros usuários',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white.withValues(alpha: 0.76),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _ModeToggle(mode: _mode, onChanged: _switchMode),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: _WeeklyPrizeBanner(),
            ),
          ),
          if (user.isGuest)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: _GuestSignInBanner(
                  onSignIn: () =>
                      context.push(AppRouter.login, extra: AuthMode.login),
                  onSignUp: () =>
                      context.push(AppRouter.login, extra: AuthMode.signup),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Row(
                children: [
                  Text(
                    _mode == _RankingMode.xp
                        ? 'Ranking por nível'
                        : 'Ranking por sequência',
                    style: AppTextStyles.headlineSmall,
                  ),
                ],
              ),
            ),
          ),
          FutureBuilder<List<RankingEntry>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: _RankingError(
                    message: snapshot.error is RankingUnavailable
                        ? '${snapshot.error}'
                        : 'Erro inesperado: ${snapshot.error}',
                    onRetry: _reload,
                  ),
                );
              }
              final entries = _withCurrentUser(snapshot.data!, user);
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
                sliver: SliverList.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RankingTile(
                        position: index + 1,
                        entry: entry,
                        mode: _mode,
                        isCurrentUser: _isMe(entry, user),
                      ),
                    )
                        .animate(delay: (index * 45).ms)
                        .slideY(begin: 0.12)
                        .fade();
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final _RankingMode mode;
  final ValueChanged<_RankingMode> onChanged;

  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              label: 'Nível',
              icon: Icons.bolt_rounded,
              selected: mode == _RankingMode.xp,
              onTap: () => onChanged(_RankingMode.xp),
            ),
          ),
          Expanded(
            child: _ModeButton(
              label: 'Sequência',
              icon: Icons.local_fire_department_rounded,
              selected: mode == _RankingMode.streak,
              onTap: () => onChanged(_RankingMode.streak),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? AppColors.primary : Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: selected ? AppColors.primary : Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyPrizeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prêmio semanal da sequência',
                  style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  'Top 3 no fim da semana ganham '
                  '${weeklyStreakPrizeCoins[0]}, ${weeklyStreakPrizeCoins[1]} e '
                  '${weeklyStreakPrizeCoins[2]} moedas',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingTile extends StatelessWidget {
  final int position;
  final RankingEntry entry;
  final _RankingMode mode;
  final bool isCurrentUser;

  const _RankingTile({
    required this.position,
    required this.entry,
    required this.mode,
    required this.isCurrentUser,
  });

  Color get _medalColor {
    switch (position) {
      case 1:
        return const Color(0xFFFFC94A);
      case 2:
        return const Color(0xFFC7CCDA);
      case 3:
        return const Color(0xFFD79A5E);
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final value =
        mode == _RankingMode.xp ? '${entry.xp} XP' : '${entry.streak} dias';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primary.withValues(alpha: 0.07)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.cardBorder,
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: position <= 3
                ? Icon(Icons.emoji_events_rounded, color: _medalColor, size: 22)
                : Text('$position',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.textMuted)),
          ),
          const SizedBox(width: 10),
          PixelAvatar(avatarIndex: entry.avatarIndex, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.name,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: isCurrentUser ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}


/// Shown to a guest: the leaderboard above is real, but a local-only profile
/// never reaches the server, so it can't be ranked against other people.
class _GuestSignInBanner extends StatelessWidget {
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;

  const _GuestSignInBanner({required this.onSignIn, required this.onSignUp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.person_add_alt_1_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Você está como convidado',
                        style: AppTextStyles.bodyLarge
                            .copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      'Entre na sua conta para salvar seu progresso e aparecer no ranking.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: BuggoButton(
                  label: 'Entrar',
                  icon: Icons.login_rounded,
                  onPressed: onSignIn,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: BuggoButton(
                  label: 'Criar conta',
                  variant: BuggoButtonVariant.secondary,
                  onPressed: onSignUp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Replaces the list when the leaderboard couldn't be read. Names the real
/// cause and offers a retry — the previous behaviour (silently showing five
/// invented people) made a broken backend look healthy.
class _RankingError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _RankingError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.cloud_off_rounded,
                color: AppColors.error, size: 28),
          ),
          const SizedBox(height: 14),
          Text('Não foi possível carregar o ranking',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge
                  .copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          BuggoButton(
            label: 'Tentar de novo',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
