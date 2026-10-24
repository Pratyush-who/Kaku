import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/constants/app_constants.dart';
import '../../../../core/common/widgets/user_avatar.dart';
import '../../../../core/models/recent_board_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../widgets/avatar_picker_dialog.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit()..loadProfile(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers for Profile Edit
  late TextEditingController _nameController;
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;

  // Controllers for Password Change
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  // Controllers for Server & Health
  late TextEditingController _serverUrlController;
  bool _isTestingServer = false;
  bool? _serverOnline;
  String? _serverPingResult;

  bool _initializedControllers = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _nameController = TextEditingController();
    _displayNameController = TextEditingController();
    _bioController = TextEditingController();
    _serverUrlController =
        TextEditingController(text: ApiClient.instance.baseUrl);
    _checkServer();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _serverUrlController.dispose();
    super.dispose();
  }

  Future<void> _checkServer() async {
    final ok = await ApiClient.instance.checkHealth();
    if (mounted) {
      setState(() => _serverOnline = ok);
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingServer = true;
      _serverPingResult = null;
    });

    final targetUrl = _serverUrlController.text.trim();
    if (targetUrl.isNotEmpty) {
      await ApiClient.instance.setBaseUrl(targetUrl);
    }

    final stopwatch = Stopwatch()..start();
    final isOk = await ApiClient.instance.checkHealth();
    stopwatch.stop();

    if (mounted) {
      setState(() {
        _isTestingServer = false;
        _serverOnline = isOk;
        _serverPingResult = isOk
            ? 'Online (${stopwatch.elapsedMilliseconds}ms)'
            : 'Unreachable';
      });
    }
  }

  void _populateControllers(ProfileState state) {
    if (!_initializedControllers && state.user != null) {
      _nameController.text = state.user!.name;
      _displayNameController.text = state.user!.displayName;
      _bioController.text = state.user!.bio;
      _initializedControllers = true;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Recently';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatRelativeTime(DateTime? date) {
    if (date == null) return 'Recently';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (diff.inDays >= 1) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _openAvatarPicker(ProfileState state) {
    AvatarPickerDialog.show(
      context,
      currentUser: state.user,
      onSelectPreset: (url) {
        context.read<ProfileCubit>().setAvatarUrl(url);
      },
      onCustomUrl: (url) {
        context.read<ProfileCubit>().setAvatarUrl(url);
      },
      onRemoveAvatar: () {
        context.read<ProfileCubit>().removeAvatar();
      },
    );
  }

  void _showChangeEmailDialog(ProfileState state) {
    final newEmailCtrl = TextEditingController(text: state.user?.email ?? '');
    final passwordCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 440.0,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceCard,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 20.0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.mark_email_read_outlined,
                      color: AppColors.accentCyan, size: 22.0),
                  const SizedBox(width: 10.0),
                  Text('Update Account Email', style: AppTypography.titleMedium),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                'Enter your new email address and confirm with your current account password. Your authentication session will be securely updated.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiaryDark),
              ),
              const SizedBox(height: 18.0),
              TextField(
                controller: newEmailCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14.0),
                decoration: const InputDecoration(
                  labelText: 'New Email Address',
                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.accentCyan, size: 20.0),
                ),
              ),
              const SizedBox(height: 14.0),
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white, fontSize: 14.0),
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: Icon(Icons.lock_outline, color: AppColors.textTertiaryDark, size: 20.0),
                ),
              ),
              const SizedBox(height: 24.0),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final email = newEmailCtrl.text.trim();
                        final pass = passwordCtrl.text;
                        if (email.isNotEmpty && pass.isNotEmpty) {
                          Navigator.of(ctx).pop();
                          await context.read<ProfileCubit>().changeEmail(newEmail: email, password: pass);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentCyan,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
                      ),
                      child: const Text('Update Email', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final passwordCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 440.0,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceCard,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.5), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withValues(alpha: 0.2),
                blurRadius: 24.0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24.0),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Text('Delete Account Permanently', style: AppTypography.titleMedium.copyWith(color: AppColors.error)),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Text(
                'This action is irreversible. All your owned projects, collaborative whiteboards, invitations, and workspace data will be permanently wiped from the database.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark),
              ),
              const SizedBox(height: 18.0),
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white, fontSize: 14.0),
                decoration: const InputDecoration(
                  labelText: 'Confirm with Password',
                  prefixIcon: Icon(Icons.lock_outline, color: AppColors.error, size: 20.0),
                ),
              ),
              const SizedBox(height: 24.0),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final pass = passwordCtrl.text;
                        if (pass.isNotEmpty) {
                          Navigator.of(ctx).pop();
                          final ok = await context.read<ProfileCubit>().deleteAccount(password: pass);
                          if (ok && mounted) {
                            context.go(AppRoutes.auth);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
                      ),
                      child: const Text('Delete Forever', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await ApiClient.instance.clearAuth();
    if (mounted) {
      context.go(AppRoutes.auth);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkCanvas,
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          _populateControllers(state);
        },
        builder: (context, state) {
          _populateControllers(state);

          if (state.isLoading && state.user == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accentPrimary),
            );
          }

          final user = state.user;
          final stats = state.stats;

          return SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  // App Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20.0),
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go(AppRoutes.projects);
                              }
                            },
                          ),
                          const SizedBox(width: 8.0),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: AppColors.darkSurfaceElevated,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                              border: Border.all(color: AppColors.darkBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6.0,
                                  height: 6.0,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accentPrimary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6.0),
                                Text(
                                  '${AppConstants.appName} • ${AppConstants.appJapaneseKanji}',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontSize: 11.0,
                                    color: AppColors.textSecondaryDark,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Refresh Workspace Data',
                            icon: const Icon(Icons.refresh_rounded, color: AppColors.accentPrimary, size: 20.0),
                            onPressed: () => context.read<ProfileCubit>().loadProfile(silent: false),
                          ),
                          IconButton(
                            tooltip: 'Sign Out',
                            icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20.0),
                            onPressed: _logout,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Status Banner
                  if (state.bannerMessage != null)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          color: state.isBannerError
                              ? AppColors.error.withValues(alpha: 0.15)
                              : AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: state.isBannerError
                                ? AppColors.error.withValues(alpha: 0.4)
                                : AppColors.success.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              state.isBannerError ? Icons.error_outline : Icons.check_circle_outline,
                              size: 18.0,
                              color: state.isBannerError ? AppColors.error : AppColors.success,
                            ),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: Text(
                                state.bannerMessage!,
                                style: AppTypography.bodySmall.copyWith(color: Colors.white),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16.0, color: Colors.white70),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => context.read<ProfileCubit>().dismissBanner(),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Hero Profile Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                      child: _buildHeroProfileCard(user),
                    ),
                  ),

                  // Metrics Command Center
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                      child: _buildMetricsGrid(stats),
                    ),
                  ),

                  // Sticky Tab Bar
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _ProfileTabBarDelegate(
                      TabBar(
                        controller: _tabController,
                        labelColor: AppColors.accentPrimary,
                        unselectedLabelColor: AppColors.textTertiaryDark,
                        indicatorColor: AppColors.accentPrimary,
                        indicatorWeight: 2.5,
                        indicatorSize: TabBarIndicatorSize.tab,
                        tabs: const [
                          Tab(icon: Icon(Icons.space_dashboard_outlined, size: 18.0), text: 'Activity'),
                          Tab(icon: Icon(Icons.person_outline, size: 18.0), text: 'Profile'),
                          Tab(icon: Icon(Icons.tune_outlined, size: 18.0), text: 'Preferences'),
                          Tab(icon: Icon(Icons.security_outlined, size: 18.0), text: 'Security'),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildActivityTab(state),
                  _buildEditProfileTab(state),
                  _buildPreferencesTab(state),
                  _buildSecurityTab(state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroProfileCard(UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(22.0),
      decoration: BoxDecoration(
        gradient: AppColors.cardGlassGradient,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: AppColors.darkBorderHighlight, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPrimary.withValues(alpha: 0.1),
            blurRadius: 24.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with Edit Button
              UserAvatar(
                user: user,
                radius: 40.0,
                showOnline: true,
                isOnline: _serverOnline ?? false,
                showEditBadge: true,
                onEditTap: () => _openAvatarPicker(context.read<ProfileCubit>().state),
              ),
              const SizedBox(width: 18.0),

              // Names & Badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user?.displayName.isNotEmpty == true
                                ? user!.displayName
                                : (user?.name ?? 'Kaku Creator'),
                            style: AppTypography.headlineMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              color: Color(0xFF090B10),
                              fontWeight: FontWeight.w900,
                              fontSize: 10.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '@${user?.name.toLowerCase().replaceAll(' ', '') ?? 'creator'}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.accentPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined, size: 14.0, color: AppColors.textTertiaryDark),
                        const SizedBox(width: 4.0),
                        Flexible(
                          child: Text(
                            user?.email ?? '',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textTertiaryDark,
                              fontSize: 12.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Bio Section
          const SizedBox(height: 16.0),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: AppColors.darkSurface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(color: AppColors.darkBorder, width: 0.8),
            ),
            child: Text(
              user?.bio.isNotEmpty == true
                  ? user!.bio
                  : 'No bio added yet. Click "Edit Profile" below to introduce yourself and describe your drawing focus.',
              style: AppTypography.bodySmall.copyWith(
                color: user?.bio.isNotEmpty == true
                    ? AppColors.textPrimaryDark
                    : AppColors.textTertiaryDark,
                fontStyle: user?.bio.isNotEmpty == true ? FontStyle.normal : FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),

          // Metadata Badges (Joined & Live Status)
          const SizedBox(height: 14.0),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceElevated,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  border: Border.all(color: AppColors.darkBorder, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 12.0, color: AppColors.textTertiaryDark),
                    const SizedBox(width: 6.0),
                    Text(
                      'Joined ${_formatDate(user?.createdAt)}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondaryDark,
                        fontSize: 11.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceElevated,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  border: Border.all(
                    color: _serverOnline == true
                        ? AppColors.accentPrimary.withValues(alpha: 0.3)
                        : AppColors.error.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.0,
                      height: 6.0,
                      decoration: BoxDecoration(
                        color: _serverOnline == true ? AppColors.accentPrimary : AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      _serverOnline == true ? 'Live Sync Active' : 'Offline Mode',
                      style: AppTypography.labelSmall.copyWith(
                        color: _serverOnline == true ? AppColors.accentPrimary : AppColors.error,
                        fontSize: 11.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(dynamic stats) {
    final owned = stats?.ownedProjectsCount ?? 0;
    final shared = stats?.sharedProjectsCount ?? 0;
    final createdBoards = stats?.createdBoardsCount ?? 0;
    final totalBoards = stats?.totalBoardsCount ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'Owned Projects',
            value: '$owned',
            icon: Icons.folder_special_outlined,
            accentColor: AppColors.accentPrimary,
          ),
        ),
        const SizedBox(width: 10.0),
        Expanded(
          child: _buildStatCard(
            label: 'Shared Spaces',
            value: '$shared',
            icon: Icons.group_work_outlined,
            accentColor: AppColors.accentSecondary,
          ),
        ),
        const SizedBox(width: 10.0),
        Expanded(
          child: _buildStatCard(
            label: 'Drafted Boards',
            value: '$createdBoards',
            icon: Icons.draw_outlined,
            accentColor: AppColors.accentCyan,
          ),
        ),
        const SizedBox(width: 10.0),
        Expanded(
          child: _buildStatCard(
            label: 'Total Boards',
            value: '$totalBoards',
            icon: Icons.dashboard_customize_outlined,
            accentColor: AppColors.accentPurple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceCard,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.darkBorder, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 18.0),
          const SizedBox(height: 8.0),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.0,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2.0),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiaryDark,
              fontSize: 10.0,
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: Activity & Recent Boards ---
  Widget _buildActivityTab(ProfileState state) {
    final boards = state.recentBoards;

    if (boards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceElevated,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.draw_outlined, color: AppColors.accentPrimary, size: 36.0),
              ),
              const SizedBox(height: 16.0),
              Text('No whiteboard activity recorded yet', style: AppTypography.titleMedium),
              const SizedBox(height: 8.0),
              Text(
                'Create a project and open a drawing canvas to see your recent sketch revisions and boards here.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiaryDark),
              ),
              const SizedBox(height: 20.0),
              ElevatedButton.icon(
                onPressed: () => context.go(AppRoutes.projects),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPrimary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18.0),
                label: const Text('Go to Projects', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20.0),
      itemCount: boards.length,
      itemBuilder: (context, index) {
        final board = boards[index];
        return _buildRecentBoardCard(board);
      },
    );
  }

  Widget _buildRecentBoardCard(RecentBoardModel board) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceCard,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: AppColors.darkBorder, width: 0.8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Container(
          width: 44.0,
          height: 44.0,
          decoration: BoxDecoration(
            gradient: AppColors.accentGlowGradient,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: const Center(
            child: Icon(Icons.draw_outlined, color: Colors.black, size: 22.0),
          ),
        ),
        title: Text(
          board.name,
          style: AppTypography.titleMedium.copyWith(fontSize: 15.0),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
              decoration: BoxDecoration(
                color: AppColors.darkSurfaceElevated,
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Text(
                board.projectName,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.accentCyan,
                  fontSize: 10.5,
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            Text(
              'Rev ${board.revision} • ${_formatRelativeTime(board.updatedAt)}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiaryDark,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: board.role == 'owner'
                    ? AppColors.accentPrimary.withValues(alpha: 0.15)
                    : AppColors.accentSecondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: Text(
                board.role.toUpperCase(),
                style: TextStyle(
                  color: board.role == 'owner' ? AppColors.accentPrimary : AppColors.accentSecondary,
                  fontSize: 10.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 6.0),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiaryDark),
          ],
        ),
        onTap: () {
          context.push('/boards/${board.id}');
        },
      ),
    );
  }

  // --- TAB 2: Edit Profile ---
  Widget _buildEditProfileTab(ProfileState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Avatar Editor Shortcut Card
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceElevated,
              borderRadius: BorderRadius.circular(18.0),
              border: Border.all(color: AppColors.darkBorder, width: 0.8),
            ),
            child: Row(
              children: [
                UserAvatar(
                  user: state.user,
                  radius: 28.0,
                  borderColor: AppColors.accentPrimary,
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Profile Avatar', style: AppTypography.titleMedium.copyWith(fontSize: 14.0)),
                      Text(
                        'Change persona, select preset style, or paste URL',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiaryDark, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openAvatarPicker(state),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkSurface,
                    foregroundColor: AppColors.accentPrimary,
                    side: const BorderSide(color: AppColors.accentPrimary, width: 0.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                  ),
                  icon: const Icon(Icons.palette_outlined, size: 16.0),
                  label: const Text('Change', style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),

          _buildLabel('FULL NAME'),
          const SizedBox(height: 6.0),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white, fontSize: 14.0),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline, color: AppColors.textTertiaryDark, size: 20.0),
              hintText: 'e.g. John Doe',
            ),
          ),
          const SizedBox(height: 18.0),

          _buildLabel('DISPLAY NAME (WORKSPACE HANDLE)'),
          const SizedBox(height: 6.0),
          TextField(
            controller: _displayNameController,
            style: const TextStyle(color: Colors.white, fontSize: 14.0),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.badge_outlined, color: AppColors.textTertiaryDark, size: 20.0),
              hintText: 'e.g. Johnny Sketch',
            ),
          ),
          const SizedBox(height: 18.0),

          _buildLabel('BIO / WORKSPACE INTRO (MAX 500 CHARACTERS)'),
          const SizedBox(height: 6.0),
          TextField(
            controller: _bioController,
            maxLines: 4,
            maxLength: 500,
            style: const TextStyle(color: Colors.white, fontSize: 14.0),
            decoration: const InputDecoration(
              hintText: 'Tell collaborators about your focus, role, and drawing style...',
              contentPadding: EdgeInsets.all(16.0),
            ),
          ),
          const SizedBox(height: 24.0),

          ElevatedButton(
            onPressed: state.isSavingProfile
                ? null
                : () {
                    context.read<ProfileCubit>().updateProfileDetails(
                          name: _nameController.text,
                          displayName: _displayNameController.text,
                          bio: _bioController.text,
                        );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPrimary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
              padding: const EdgeInsets.symmetric(vertical: 16.0),
            ),
            child: state.isSavingProfile
                ? const SizedBox(
                    width: 22.0,
                    height: 22.0,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                  )
                : const Text('Save Profile Changes', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
          ),
        ],
      ),
    );
  }

  // --- TAB 3: Preferences & Canvas ---
  Widget _buildPreferencesTab(ProfileState state) {
    final prefs = state.preferences;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLabel('APP THEME APPEARANCE'),
          const SizedBox(height: 10.0),
          Row(
            children: [
              Expanded(
                child: _buildThemeOptionCard(
                  title: 'Dark Obsidian',
                  subtitle: 'Midnight Canvas',
                  icon: Icons.dark_mode_outlined,
                  isSelected: prefs.theme == 'dark' || prefs.theme == 'system',
                  onTap: () {
                    context.read<ProfileCubit>().updatePreferences(prefs.copyWith(theme: 'dark'));
                  },
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: _buildThemeOptionCard(
                  title: 'Light Studio',
                  subtitle: 'Clean Canvas',
                  icon: Icons.light_mode_outlined,
                  isSelected: prefs.theme == 'light',
                  onTap: () {
                    context.read<ProfileCubit>().updatePreferences(prefs.copyWith(theme: 'light'));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 28.0),

          _buildLabel('WHITEBOARD & DRAWING DEFAULTS'),
          const SizedBox(height: 10.0),

          // Canvas Grid Switch
          _buildPreferenceSwitchTile(
            title: 'Architectural Grid Dots',
            subtitle: 'Render infinite dot grid coordinates on canvas by default',
            icon: Icons.grid_4x4_rounded,
            value: prefs.grid,
            onChanged: (val) {
              context.read<ProfileCubit>().updatePreferences(prefs.copyWith(grid: val));
            },
          ),
          const SizedBox(height: 12.0),

          // Snap to Grid Switch
          _buildPreferenceSwitchTile(
            title: 'Snap to Grid Magnet',
            subtitle: 'Automatically align newly drawn shapes and lines to nearest grid point',
            icon: Icons.align_horizontal_left_rounded,
            value: prefs.snapToGrid,
            onChanged: (val) {
              context.read<ProfileCubit>().updatePreferences(prefs.copyWith(snapToGrid: val));
            },
          ),
          const SizedBox(height: 12.0),

          // Email Notifications Switch
          _buildPreferenceSwitchTile(
            title: 'Email Notifications & Invites',
            subtitle: 'Receive notification alerts when invited to collaborate on projects',
            icon: Icons.notifications_active_outlined,
            value: prefs.emailNotifications,
            onChanged: (val) {
              context.read<ProfileCubit>().updatePreferences(prefs.copyWith(emailNotifications: val));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkSurfaceElevated : AppColors.darkSurfaceCard,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isSelected ? AppColors.accentPrimary : AppColors.darkBorder,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accentPrimary.withValues(alpha: 0.2),
                    blurRadius: 12.0,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.accentPrimary : AppColors.textTertiaryDark,
                  size: 22.0,
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded, color: AppColors.accentPrimary, size: 18.0),
              ],
            ),
            const SizedBox(height: 12.0),
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                fontSize: 14.0,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiaryDark,
                fontSize: 11.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceCard,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.darkBorder, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceElevated,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Icon(icon, color: AppColors.accentPrimary, size: 20.0),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleMedium.copyWith(fontSize: 13.5)),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiaryDark,
                    fontSize: 11.0,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.accentPrimary,
            activeTrackColor: AppColors.accentPrimary.withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.textTertiaryDark,
            inactiveTrackColor: AppColors.darkSurfaceElevated,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // --- TAB 4: Security & Account ---
  Widget _buildSecurityTab(ProfileState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email Card
          _buildSecurityCard(
            title: 'Account Email Address',
            subtitle: state.user?.email ?? '',
            actionLabel: 'Change Email',
            icon: Icons.email_outlined,
            onAction: () => _showChangeEmailDialog(state),
          ),
          const SizedBox(height: 20.0),

          // Change Password Card
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceCard,
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: AppColors.darkBorder, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock_reset_rounded, color: AppColors.accentSecondary, size: 20.0),
                    const SizedBox(width: 10.0),
                    Text('Change Password', style: AppTypography.titleMedium),
                  ],
                ),
                const SizedBox(height: 14.0),
                TextField(
                  controller: _currentPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: Icon(Icons.lock_outline, size: 18.0),
                  ),
                ),
                const SizedBox(height: 12.0),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  decoration: const InputDecoration(
                    labelText: 'New Password (min 8 characters)',
                    prefixIcon: Icon(Icons.vpn_key_outlined, size: 18.0),
                  ),
                ),
                const SizedBox(height: 18.0),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: state.isChangingPassword
                        ? null
                        : () async {
                            final cur = _currentPasswordController.text;
                            final next = _newPasswordController.text;
                            if (cur.isNotEmpty && next.isNotEmpty) {
                              final ok = await context.read<ProfileCubit>().changePassword(
                                    currentPassword: cur,
                                    newPassword: next,
                                  );
                              if (ok) {
                                _currentPasswordController.clear();
                                _newPasswordController.clear();
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentSecondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    ),
                    child: state.isChangingPassword
                        ? const SizedBox(
                            width: 18.0,
                            height: 18.0,
                            child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white),
                          )
                        : const Text('Update Password', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),

          // Backend API Server Configuration
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceCard,
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: AppColors.darkBorder, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.dns_outlined, color: AppColors.accentCyan, size: 20.0),
                        const SizedBox(width: 10.0),
                        Text('Backend API Endpoint', style: AppTypography.titleMedium),
                      ],
                    ),
                    if (_serverPingResult != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                        decoration: BoxDecoration(
                          color: _serverOnline == true
                              ? AppColors.success.withValues(alpha: 0.2)
                              : AppColors.error.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        ),
                        child: Text(
                          _serverPingResult!,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: _serverOnline == true ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12.0),
                TextField(
                  controller: _serverUrlController,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.link_rounded, size: 18.0),
                    hintText: 'http://localhost:8080',
                  ),
                ),
                const SizedBox(height: 14.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isTestingServer ? null : _testConnection,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
                      ),
                      icon: _isTestingServer
                          ? const SizedBox(
                              width: 14.0,
                              height: 14.0,
                              child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white),
                            )
                          : const Icon(Icons.speed_rounded, size: 16.0),
                      label: const Text('Ping Health', style: TextStyle(fontSize: 12.0)),
                    ),
                    const SizedBox(width: 10.0),
                    ElevatedButton(
                      onPressed: () async {
                        await ApiClient.instance.setBaseUrl(_serverUrlController.text);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Server API URL saved!')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentCyan,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
                      ),
                      child: const Text('Save URL', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.0)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28.0),

          // Danger Zone
          _buildLabel('DANGER ZONE'),
          const SizedBox(height: 8.0),
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.35), width: 1.0),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delete Account',
                        style: AppTypography.titleMedium.copyWith(color: AppColors.error, fontSize: 14.5),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        'Permanently wipe your profile, projects, and collaborative boards.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiaryDark, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12.0),
                ElevatedButton(
                  onPressed: _showDeleteAccountDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  ),
                  child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32.0),
        ],
      ),
    );
  }

  Widget _buildSecurityCard({
    required String title,
    required String subtitle,
    required String actionLabel,
    required IconData icon,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceCard,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.darkBorder, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceElevated,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Icon(icon, color: AppColors.accentCyan, size: 20.0),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleMedium.copyWith(fontSize: 13.5)),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiaryDark, fontSize: 12.0),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.accentCyan, width: 0.8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
            ),
            child: Text(actionLabel, style: const TextStyle(color: AppColors.accentCyan, fontSize: 11.5, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTypography.brandTagline.copyWith(
        fontSize: 10.5,
        letterSpacing: 2.0,
        color: AppColors.textTertiaryDark,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ProfileTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _ProfileTabBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height + 12.0;

  @override
  double get maxExtent => _tabBar.preferredSize.height + 12.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.darkCanvas,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _ProfileTabBarDelegate oldDelegate) {
    return false;
  }
}
