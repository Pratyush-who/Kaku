import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../theme/app_colors.dart';

/// Highly polished user avatar component supporting remote URLs, fallback initials,
/// obsidian studio gradients, status indicators, and edit triggers.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.user,
    this.avatarUrl,
    this.fallbackName,
    this.radius = 20.0,
    this.showOnline = false,
    this.isOnline = true,
    this.showEditBadge = false,
    this.onTap,
    this.onEditTap,
    this.borderColor,
    this.borderWidth = 1.0,
  });

  final UserModel? user;
  final String? avatarUrl;
  final String? fallbackName;
  final double radius;
  final bool showOnline;
  final bool isOnline;
  final bool showEditBadge;
  final VoidCallback? onTap;
  final VoidCallback? onEditTap;
  final Color? borderColor;
  final double borderWidth;

  String get _effectiveUrl {
    if (user != null && user!.effectiveAvatarUrl.isNotEmpty) {
      return user!.effectiveAvatarUrl;
    }
    final url = avatarUrl?.trim() ?? '';
    return url;
  }

  String get _initials {
    if (user != null) {
      return user!.initials;
    }
    final name = (fallbackName ?? '').trim();
    if (name.isEmpty) return 'U';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final url = _effectiveUrl;

    Widget avatarContent;
    if (url.isNotEmpty) {
      avatarContent = Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: size,
            height: size,
            color: AppColors.darkSurfaceElevated,
            child: Center(
              child: SizedBox(
                width: radius * 0.7,
                height: radius * 0.7,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: AppColors.accentPrimary.withValues(alpha: 0.6),
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildInitialsPlaceholder(size);
        },
      );
    } else {
      avatarContent = _buildInitialsPlaceholder(size);
    }

    Widget mainAvatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor ?? AppColors.darkBorderHighlight,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPrimary.withValues(alpha: 0.15),
            blurRadius: 8.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: ClipOval(child: avatarContent),
    );

    if (onTap != null) {
      mainAvatar = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: mainAvatar,
      );
    }

    if (!showOnline && !showEditBadge) {
      return mainAvatar;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        mainAvatar,
        if (showOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: (radius * 0.55).clamp(8.0, 14.0),
              height: (radius * 0.55).clamp(8.0, 14.0),
              decoration: BoxDecoration(
                color: isOnline ? AppColors.accentPrimary : AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.darkCanvas,
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isOnline ? AppColors.accentPrimary : AppColors.error)
                        .withValues(alpha: 0.6),
                    blurRadius: 4.0,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
            ),
          ),
        if (showEditBadge)
          Positioned(
            right: -2,
            bottom: -2,
            child: GestureDetector(
              onTap: onEditTap ?? onTap,
              child: Container(
                padding: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.darkCanvas,
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentPrimary.withValues(alpha: 0.4),
                      blurRadius: 6.0,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: (radius * 0.55).clamp(10.0, 16.0),
                  color: const Color(0xFF090B10),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInitialsPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: const Color(0xFF090B10),
            fontWeight: FontWeight.w800,
            fontSize: (radius * 0.75).clamp(10.0, 36.0),
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}
