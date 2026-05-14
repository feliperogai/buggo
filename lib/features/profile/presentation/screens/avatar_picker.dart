import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/widgets/pixel_avatars.dart';

/// Opens the avatar picker bottom sheet.
Future<void> showAvatarPicker(BuildContext context, WidgetRef ref) {
  final container = ProviderScope.containerOf(context);
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => UncontrolledProviderScope(
      container: container,
      child: const _AvatarPickerSheet(),
    ),
  );
}

class _AvatarPickerSheet extends ConsumerWidget {
  const _AvatarPickerSheet();

  Future<void> _pickPhoto(BuildContext ctx, WidgetRef ref) async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file != null && ctx.mounted) {
      ref.read(userProvider.notifier).updateAvatar(
            ref.read(userProvider)?.avatarIndex ?? 0,
            photoPath: file.path,
          );
      if (ctx.mounted) Navigator.of(ctx).pop();
    }
  }

  Future<void> _takePhoto(BuildContext ctx, WidgetRef ref) async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file != null && ctx.mounted) {
      ref.read(userProvider.notifier).updateAvatar(
            ref.read(userProvider)?.avatarIndex ?? 0,
            photoPath: file.path,
          );
      if (ctx.mounted) Navigator.of(ctx).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final currentIdx = user?.avatarIndex ?? 0;
    final hasPhoto = user?.customPhotoPath?.isNotEmpty ?? false;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Text('Escolher avatar', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 4),
          Text('Toque para selecionar um personagem',
              style: AppTextStyles.bodySmall),

          const SizedBox(height: 20),

          // 3×2 avatar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: kPixelAvatars.length,
            itemBuilder: (ctx, i) {
              final av = kPixelAvatars[i];
              final isSelected = !hasPhoto && currentIdx == i;
              return GestureDetector(
                onTap: () {
                  ref.read(userProvider.notifier).updateAvatar(
                        i,
                        clearPhoto: true,
                      );
                  Navigator.of(ctx).pop();
                },
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.cardBorder,
                          width: isSelected ? 2.5 : 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: PixelAvatar(
                          avatarIndex: i,
                          size: 80,
                          circular: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      av.name,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ).animate(delay: (i * 50).ms).scale(begin: const Offset(0.85, 0.85)).fade();
            },
          ),

          const SizedBox(height: 20),

          Container(
            height: 1,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 16),

          Text('Ou use sua foto',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _PhotoButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Galeria',
                  color: AppColors.levelBlue,
                  onTap: () => _pickPhoto(context, ref),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PhotoButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Câmera',
                  color: AppColors.success,
                  onTap: () => _takePhoto(context, ref),
                ),
              ),
            ],
          ),

          if (hasPhoto) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                ref
                    .read(userProvider.notifier)
                    .updateAvatar(currentIdx, clearPhoto: true);
                Navigator.of(context).pop();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Text(
                  'Remover foto',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.error),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PhotoButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 5),
            Text(label,
                style: AppTextStyles.bodySmall
                    .copyWith(color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
