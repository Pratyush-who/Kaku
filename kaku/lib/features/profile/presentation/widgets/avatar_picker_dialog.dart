import 'package:flutter/material.dart';
import '../../../../core/common/widgets/user_avatar.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/avatar_presets.dart';

class AvatarPickerDialog extends StatefulWidget {
  const AvatarPickerDialog({
    super.key,
    required this.currentUser,
    required this.onSelectPreset,
    required this.onCustomUrl,
    required this.onRemoveAvatar,
  });

  final UserModel? currentUser;
  final ValueChanged<String> onSelectPreset;
  final ValueChanged<String> onCustomUrl;
  final VoidCallback onRemoveAvatar;

  static Future<void> show(
    BuildContext context, {
    required UserModel? currentUser,
    required ValueChanged<String> onSelectPreset,
    required ValueChanged<String> onCustomUrl,
    required VoidCallback onRemoveAvatar,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AvatarPickerDialog(
        currentUser: currentUser,
        onSelectPreset: onSelectPreset,
        onCustomUrl: onCustomUrl,
        onRemoveAvatar: onRemoveAvatar,
      ),
    );
  }

  @override
  State<AvatarPickerDialog> createState() => _AvatarPickerDialogState();
}

class _AvatarPickerDialogState extends State<AvatarPickerDialog> {
  late final TextEditingController _urlController;
  String _previewUrl = '';

  @override
  void initState() {
    super.initState();
    _previewUrl = widget.currentUser?.avatarUrl ?? '';
    _urlController = TextEditingController(text: _previewUrl);
    _urlController.addListener(() {
      setState(() {
        _previewUrl = _urlController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Container(
        width: 520.0,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: AppColors.darkSurfaceCard,
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(color: AppColors.darkBorderHighlight, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentPrimary.withValues(alpha: 0.15),
              blurRadius: 28.0,
              spreadRadius: 1.0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 20.0,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 20.0, 16.0, 12.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: const Icon(
                      Icons.palette_outlined,
                      color: AppColors.accentPrimary,
                      size: 20.0,
                    ),
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Customize Avatar', style: AppTypography.titleLarge),
                        Text(
                          'Select a curated designer style or paste a custom image URL',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondaryDark),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.darkBorder, height: 1.0),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Live Avatar Preview with Action Buttons
                    Center(
                      child: Column(
                        children: [
                          UserAvatar(
                            user: widget.currentUser?.copyWith(
                              avatarUrl: _previewUrl,
                            ),
                            avatarUrl: _previewUrl,
                            fallbackName: widget.currentUser?.displayName,
                            radius: 46.0,
                            borderColor: AppColors.accentPrimary,
                            borderWidth: 2.0,
                          ),
                          const SizedBox(height: 12.0),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.currentUser?.avatarUrl.isNotEmpty == true)
                                OutlinedButton.icon(
                                  onPressed: () {
                                    widget.onRemoveAvatar();
                                    Navigator.of(context).pop();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: AppColors.error,
                                      width: 0.8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusPill,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14.0,
                                      vertical: 8.0,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 16.0,
                                    color: AppColors.error,
                                  ),
                                  label: const Text(
                                    'Remove Avatar',
                                    style: TextStyle(
                                      color: AppColors.error,
                                      fontSize: 12.0,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // Section 1: Curated Designer Presets
                    Text(
                      'CURATED DESIGNER STYLES',
                      style: AppTypography.brandTagline.copyWith(
                        fontSize: 11.0,
                        letterSpacing: 2.0,
                        color: AppColors.accentPrimary,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 12.0,
                        mainAxisSpacing: 12.0,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: AvatarPresets.list.length,
                      itemBuilder: (context, index) {
                        final preset = AvatarPresets.list[index];
                        final isSelected = _previewUrl == preset.url;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _previewUrl = preset.url;
                              _urlController.text = preset.url;
                            });
                          },
                          borderRadius: BorderRadius.circular(16.0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.darkSurfaceElevated
                                  : AppColors.darkSurface,
                              borderRadius: BorderRadius.circular(16.0),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accentPrimary
                                    : AppColors.darkBorder,
                                width: isSelected ? 1.8 : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.accentPrimary
                                            .withValues(alpha: 0.3),
                                        blurRadius: 10.0,
                                      ),
                                    ]
                                  : null,
                            ),
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ClipOval(
                                  child: Image.network(
                                    preset.url,
                                    width: 44.0,
                                    height: 44.0,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.face,
                                      color: AppColors.textTertiaryDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6.0),
                                Text(
                                  preset.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.labelSmall.copyWith(
                                    fontSize: 10.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.accentPrimary
                                        : AppColors.textSecondaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24.0),

                    // Section 2: Custom Avatar Image URL
                    Text(
                      'CUSTOM IMAGE URL',
                      style: AppTypography.brandTagline.copyWith(
                        fontSize: 11.0,
                        letterSpacing: 2.0,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    TextField(
                      controller: _urlController,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'https://images.unsplash.com/... or /uploads/...',
                        prefixIcon: const Icon(
                          Icons.link_rounded,
                          color: AppColors.accentCyan,
                          size: 20.0,
                        ),
                        suffixIcon: _previewUrl.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18.0),
                                onPressed: () {
                                  _urlController.clear();
                                  setState(() => _previewUrl = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.darkBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _previewUrl.trim().isEmpty
                          ? null
                          : () {
                              final url = _previewUrl.trim();
                              widget.onCustomUrl(url);
                              Navigator.of(context).pop();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentPrimary,
                        foregroundColor: const Color(0xFF090B10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Apply Avatar',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
