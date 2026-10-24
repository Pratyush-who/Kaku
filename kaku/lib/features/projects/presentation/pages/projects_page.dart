import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/widgets/app_brand_logo.dart';
import '../../../../core/common/widgets/user_avatar.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/repositories/auth_repository.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/presentation/widgets/profile_settings_modal.dart';
import '../cubit/projects_cubit.dart';
import '../cubit/projects_state.dart';

enum ProjectFilter { all, owned, shared }

/// Home Screen for Kaku: Creative Workspace Dashboard.
/// Features workspace metrics command center, role filtering, blueprint canvas cards,
/// and obsidian studio modals.
class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProjectsCubit()..loadProjects(),
      child: const _ProjectsView(),
    );
  }
}

class _ProjectsView extends StatefulWidget {
  const _ProjectsView();

  @override
  State<_ProjectsView> createState() => _ProjectsViewState();
}

class _ProjectsViewState extends State<_ProjectsView> {
  final _searchController = TextEditingController();
  final _authRepo = AuthRepository();
  UserModel? _currentUser;
  bool _serverHealthy = false;
  ProjectFilter _selectedFilter = ProjectFilter.all;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _checkServer();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await _authRepo.checkAuthStatus();
    if (mounted) {
      setState(() => _currentUser = user);
    }
  }

  Future<void> _checkServer() async {
    final ok = await ApiClient.instance.checkHealth();
    if (mounted) {
      setState(() => _serverHealthy = ok);
    }
  }

  String _formatRelativeTime(DateTime? date) {
    if (date == null) return 'Recently';
    final now = DateTime.now();
    final diff = now.difference(date);
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

  void _showCreateProjectDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 440.0,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceCard,
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(
              color: AppColors.accentPrimary.withValues(alpha: 0.3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentPrimary.withValues(alpha: 0.15),
                blurRadius: 24.0,
                spreadRadius: 1.0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 16.0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: AppColors.accentPrimary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(Icons.create_new_folder_outlined,
                        color: AppColors.accentPrimary, size: 20.0),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Create New Project', style: AppTypography.titleLarge),
                        Text(
                          'A workspace for infinite collaborative boards',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textTertiaryDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14.5),
                decoration: InputDecoration(
                  hintText: 'e.g. Design Systems, Wireframes, Mobile UI',
                  hintStyle: const TextStyle(
                      color: AppColors.textTertiaryDark, fontSize: 13.5),
                  prefixIcon: const Icon(Icons.edit_note_rounded,
                      color: AppColors.textTertiaryDark),
                  filled: true,
                  fillColor: AppColors.darkSurface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: const BorderSide(color: AppColors.darkBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: const BorderSide(
                        color: AppColors.accentPrimary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondaryDark,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10.0),
                  ElevatedButton(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      if (name.isNotEmpty) {
                        context.read<ProjectsCubit>().createProject(name);
                        Navigator.of(ctx).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPrimary,
                      foregroundColor: const Color(0xFF090B10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      elevation: 4.0,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 18.0),
                        SizedBox(width: 6.0),
                        Text('Create Project',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
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

  void _showJoinWithTokenDialog() {
    final tokenCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 440.0,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceCard,
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(
              color: AppColors.accentSecondary.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentSecondary.withValues(alpha: 0.15),
                blurRadius: 24.0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 16.0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: AppColors.accentSecondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: AppColors.accentSecondary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(Icons.link_rounded,
                        color: AppColors.accentCyan, size: 20.0),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Join Workspace', style: AppTypography.titleLarge),
                        Text(
                          'Paste an invitation token or secret code',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textTertiaryDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18.0),
              TextField(
                controller: tokenCtrl,
                autofocus: true,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: 'Paste token hex (e.g. a7f29b...)',
                  hintStyle: const TextStyle(
                      color: AppColors.textTertiaryDark, fontSize: 13.0),
                  prefixIcon: const Icon(Icons.key_rounded,
                      color: AppColors.textTertiaryDark, size: 18.0),
                  filled: true,
                  fillColor: AppColors.darkSurface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: const BorderSide(color: AppColors.darkBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: const BorderSide(
                        color: AppColors.accentCyan, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondaryDark,
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10.0),
                  ElevatedButton(
                    onPressed: () async {
                      final token = tokenCtrl.text.trim();
                      if (token.isNotEmpty) {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          final msg = await context
                              .read<ProjectsCubit>()
                              .acceptInvitationToken(token);
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentSecondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                    ),
                    child: const Text('Accept & Join',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(ProjectModel project) {
    final nameCtrl = TextEditingController(text: project.name);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 420.0,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceCard,
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rename Project', style: AppTypography.titleLarge),
              const SizedBox(height: 16.0),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Project name',
                  filled: true,
                  fillColor: AppColors.darkSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.0),
                    borderSide: const BorderSide(color: AppColors.darkBorder),
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel',
                        style: TextStyle(color: AppColors.textSecondaryDark)),
                  ),
                  const SizedBox(width: 8.0),
                  ElevatedButton(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      if (name.isNotEmpty) {
                        context
                            .read<ProjectsCubit>()
                            .updateProjectName(project.id, name);
                        Navigator.of(ctx).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPrimary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                    ),
                    child: const Text('Save Changes',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteDialog(ProjectModel project) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 420.0,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceCard,
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.error, size: 22.0),
                  ),
                  const SizedBox(width: 12.0),
                  Text('Delete Project',
                      style: AppTypography.titleLarge
                          .copyWith(color: AppColors.error)),
                ],
              ),
              const SizedBox(height: 12.0),
              Text(
                'Are you sure you want to permanently delete "${project.name}"? All boards and drawing layers will be lost.',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondaryDark),
              ),
              const SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel',
                        style: TextStyle(color: AppColors.textSecondaryDark)),
                  ),
                  const SizedBox(width: 8.0),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ProjectsCubit>().deleteProject(project.id);
                      Navigator.of(ctx).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                    ),
                    child: const Text('Delete Permanently',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkCanvas,
      body: SafeArea(
        child: BlocConsumer<ProjectsCubit, ProjectsState>(
          listener: (context, state) {
            if (state is ProjectsLoaded && state.statusMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.statusMessage!),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor:
                      state.statusMessage!.toLowerCase().contains('error')
                          ? AppColors.error
                          : AppColors.success,
                ),
              );
            }
          },
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () async {
                await context.read<ProjectsCubit>().loadProjects();
                await _checkServer();
              },
              color: AppColors.accentPrimary,
              backgroundColor: AppColors.darkSurfaceCard,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                slivers: [
                  // App Bar with Brand Logo and Live Radar Status
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 10.0),
                      child: Row(
                        children: [
                          const AppBrandLogo(size: 34.0, fontSize: 18.0),
                          const Spacer(),

                          // Server Status Dot with glowing radar ping
                          Tooltip(
                            message: _serverHealthy
                                ? 'Live Sync Active (${ApiClient.instance.baseUrl})'
                                : 'Offline / Standalone Mode',
                            child: InkWell(
                              onTap: () {
                                ProfileSettingsModal.show(
                                  context,
                                  currentUser: _currentUser,
                                  onProfileUpdated: () {
                                    _loadUser();
                                    _checkServer();
                                  },
                                );
                              },
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusPill),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 11.0, vertical: 6.0),
                                decoration: BoxDecoration(
                                  color: AppColors.darkSurfaceElevated,
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusPill),
                                  border: Border.all(
                                      color: AppColors.darkBorder, width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 7.0,
                                      height: 7.0,
                                      decoration: BoxDecoration(
                                        color: _serverHealthy
                                            ? AppColors.accentPrimary
                                            : AppColors.error,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: (_serverHealthy
                                                    ? AppColors.accentPrimary
                                                    : AppColors.error)
                                                .withValues(alpha: 0.6),
                                            blurRadius: 5.0,
                                            spreadRadius: 1.0,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 7.0),
                                    Text(
                                      _serverHealthy ? 'Live API' : 'Offline',
                                      style: AppTypography.labelSmall.copyWith(
                                        fontSize: 11.0,
                                        fontWeight: FontWeight.w600,
                                        color: _serverHealthy
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textTertiaryDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10.0),

                          // User Profile Avatar with Command Menu
                          PopupMenuButton<String>(
                            tooltip: 'Profile & Settings',
                            offset: const Offset(0, 44),
                            color: AppColors.darkSurfaceCard,
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                              side: const BorderSide(
                                color: AppColors.darkBorderHighlight,
                                width: 1.0,
                              ),
                            ),
                            onSelected: (value) async {
                              if (value == 'profile') {
                                await context.push(AppRoutes.profile);
                                if (mounted) {
                                  _loadUser();
                                  _checkServer();
                                }
                              } else if (value == 'settings') {
                                ProfileSettingsModal.show(
                                  context,
                                  currentUser: _currentUser,
                                  onProfileUpdated: () {
                                    _loadUser();
                                    _checkServer();
                                  },
                                );
                              } else if (value == 'logout') {
                                final router = GoRouter.of(context);
                                await _authRepo.logout();
                                router.go(AppRoutes.auth);
                              }
                            },
                            itemBuilder: (ctx) => [
                              PopupMenuItem(
                                enabled: false,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentUser?.displayName.isNotEmpty == true
                                          ? _currentUser!.displayName
                                          : 'Creator Workspace',
                                      style: AppTypography.titleSmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      _currentUser?.email ?? '',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textTertiaryDark,
                                        fontSize: 11.0,
                                      ),
                                    ),
                                    const SizedBox(height: 6.0),
                                    const Divider(color: AppColors.darkBorder, height: 1.0),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'profile',
                                child: Row(
                                  children: [
                                    Icon(Icons.person_outline, size: 18.0, color: AppColors.accentPrimary),
                                    SizedBox(width: 10.0),
                                    Text('Profile Dashboard', style: TextStyle(fontSize: 13.0, color: Colors.white)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'settings',
                                child: Row(
                                  children: [
                                    Icon(Icons.tune_outlined, size: 18.0, color: AppColors.accentCyan),
                                    SizedBox(width: 10.0),
                                    Text('Quick Settings', style: TextStyle(fontSize: 13.0, color: Colors.white)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    Icon(Icons.logout_rounded, size: 18.0, color: AppColors.error),
                                    SizedBox(width: 10.0),
                                    Text('Sign Out', style: TextStyle(fontSize: 13.0, color: AppColors.error)),
                                  ],
                                ),
                              ),
                            ],
                            child: UserAvatar(
                              user: _currentUser,
                              radius: 18.0,
                              showOnline: true,
                              isOnline: _serverHealthy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Welcome Header, Metrics Command Center & Actions
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Welcome & Tagline
                          Text(
                            'Welcome back, ${_currentUser?.displayName ?? 'Creator'}',
                            style: AppTypography.displayLarge
                                .copyWith(fontSize: 25.0, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'Organize your sketches, wireframes, and collaborative boards.',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textTertiaryDark),
                          ),
                          const SizedBox(height: 18.0),

                          // Creative Workspace Metrics Command Center
                          if (state is ProjectsLoaded)
                            _buildWorkspaceMetrics(state.projects),

                          const SizedBox(height: 18.0),

                          // Action Buttons Row (New Project & Join)
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusPill),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.accentPrimary
                                            .withValues(alpha: 0.28),
                                        blurRadius: 14.0,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: _showCreateProjectDialog,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accentPrimary,
                                      foregroundColor: const Color(0xFF090B10),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14.0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            AppSpacing.radiusPill),
                                      ),
                                      elevation: 0,
                                    ),
                                    icon: const Icon(Icons.add_rounded,
                                        size: 20.0),
                                    label: const Text(
                                      'New Project',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14.0),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12.0),
                              Expanded(
                                flex: 2,
                                child: OutlinedButton.icon(
                                  onPressed: _showJoinWithTokenDialog,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: AppColors.darkBorder,
                                        width: 1.2),
                                    backgroundColor:
                                        AppColors.darkSurfaceElevated,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusPill),
                                    ),
                                  ),
                                  icon: const Icon(Icons.link_rounded,
                                      size: 18.0,
                                      color: AppColors.accentCyan),
                                  label: const Text('Join',
                                      style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),

                          // Search Bar
                          TextField(
                            controller: _searchController,
                            onChanged: (val) => context
                                .read<ProjectsCubit>()
                                .updateSearchQuery(val),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14.0),
                            decoration: InputDecoration(
                              hintText: 'Search projects...',
                              hintStyle: const TextStyle(
                                  color: AppColors.textTertiaryDark,
                                  fontSize: 13.5),
                              prefixIcon: const Icon(Icons.search_rounded,
                                  color: AppColors.textTertiaryDark, size: 20.0),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18.0),
                                      onPressed: () {
                                        _searchController.clear();
                                        context
                                            .read<ProjectsCubit>()
                                            .updateSearchQuery('');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: AppColors.darkSurface,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 12.0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusPill),
                                borderSide:
                                    const BorderSide(color: AppColors.darkBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusPill),
                                borderSide:
                                    const BorderSide(color: AppColors.darkBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusPill),
                                borderSide: const BorderSide(
                                    color: AppColors.accentPrimary, width: 1.2),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14.0),

                          // Role Filter Chips (All, Created by Me, Shared with Me)
                          _buildFilterTabs(),
                        ],
                      ),
                    ),
                  ),

                  // Projects Content (Skeletons, Empty State, or Grid List)
                  if (state is ProjectsLoading)
                    _buildLoadingSkeletons()
                  else if (state is ProjectsError)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_off_rounded,
                                  color: AppColors.error, size: 48.0),
                              const SizedBox(height: 12.0),
                              Text(state.errorMessage,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodyMedium),
                              const SizedBox(height: 16.0),
                              ElevatedButton(
                                onPressed: () =>
                                    context.read<ProjectsCubit>().loadProjects(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accentPrimary,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusPill),
                                  ),
                                ),
                                child: const Text('Retry Connection'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (state is ProjectsLoaded) ...[
                    _buildFilteredProjectsList(state),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWorkspaceMetrics(List<ProjectModel> projects) {
    final totalProjects = projects.length;
    final totalBoards = projects.fold<int>(0, (sum, p) => sum + p.boardCount);
    final totalMembers = projects.fold<int>(0, (sum, p) => sum + p.memberCount);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceCard,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: AppColors.darkBorder, width: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem(
            value: '$totalProjects',
            label: totalProjects == 1 ? 'Project' : 'Projects',
            color: AppColors.accentPrimary,
            icon: Icons.folder_copy_outlined,
          ),
          Container(width: 1.0, height: 28.0, color: AppColors.darkBorder),
          _buildMetricItem(
            value: '$totalBoards',
            label: totalBoards == 1 ? 'Whiteboard' : 'Whiteboards',
            color: AppColors.accentCyan,
            icon: Icons.draw_outlined,
          ),
          Container(width: 1.0, height: 28.0, color: AppColors.darkBorder),
          _buildMetricItem(
            value: '$totalMembers',
            label: totalMembers == 1 ? 'Collaborator' : 'Collaborators',
            color: AppColors.accentSecondary,
            icon: Icons.people_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String value,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6.0),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(icon, size: 16.0, color: color),
        ),
        const SizedBox(width: 8.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 15.0,
                color: AppColors.textPrimaryDark,
              ),
            ),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 10.0,
                color: AppColors.textTertiaryDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildFilterChip('All', ProjectFilter.all),
          const SizedBox(width: 8.0),
          _buildFilterChip('Created by Me', ProjectFilter.owned),
          const SizedBox(width: 8.0),
          _buildFilterChip('Shared with Me', ProjectFilter.shared),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ProjectFilter filter) {
    final isSelected = _selectedFilter == filter;
    return InkWell(
      onTap: () {
        setState(() => _selectedFilter = filter);
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentPrimary.withValues(alpha: 0.14)
              : AppColors.darkSurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: isSelected
                ? AppColors.accentPrimary
                : AppColors.darkBorder,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected
                ? AppColors.accentPrimary
                : AppColors.textSecondaryDark,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeletons() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 40.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Container(
            margin: const EdgeInsets.only(bottom: 14.0),
            height: 120.0,
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceCard,
              borderRadius: BorderRadius.circular(18.0),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 140.0,
                        height: 16.0,
                        decoration: BoxDecoration(
                          color: AppColors.darkSurfaceElevated,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 50.0,
                        height: 18.0,
                        decoration: BoxDecoration(
                          color: AppColors.darkSurfaceElevated,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        width: 80.0,
                        height: 14.0,
                        decoration: BoxDecoration(
                          color: AppColors.darkSurfaceElevated,
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Container(
                        width: 70.0,
                        height: 14.0,
                        decoration: BoxDecoration(
                          color: AppColors.darkSurfaceElevated,
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          childCount: 3,
        ),
      ),
    );
  }

  Widget _buildFilteredProjectsList(ProjectsLoaded state) {
    var list = state.filteredProjects;

    // Apply role filter
    if (_selectedFilter == ProjectFilter.owned) {
      list = list.where((p) => p.isOwner).toList();
    } else if (_selectedFilter == ProjectFilter.shared) {
      list = list.where((p) => !p.isOwner).toList();
    }

    if (list.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing illustrated canvas badge
                Container(
                  width: 72.0,
                  height: 72.0,
                  decoration: BoxDecoration(
                    color: AppColors.darkSurfaceElevated,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accentPrimary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentPrimary.withValues(alpha: 0.15),
                        blurRadius: 18.0,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.draw_rounded,
                      color: AppColors.accentPrimary, size: 34.0),
                ),
                const SizedBox(height: 18.0),
                Text(
                  state.searchQuery.isEmpty
                      ? (_selectedFilter == ProjectFilter.shared
                          ? 'No Shared Projects'
                          : 'No Projects Yet')
                      : 'No matching projects found',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18.0,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  state.searchQuery.isEmpty
                      ? (_selectedFilter == ProjectFilter.shared
                          ? 'Projects shared with you will appear here.'
                          : 'Create your first project to start sketching on an infinite canvas.')
                      : 'Try searching with a different term.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textTertiaryDark),
                ),
                if (state.searchQuery.isEmpty &&
                    _selectedFilter != ProjectFilter.shared) ...[
                  const SizedBox(height: 22.0),
                  ElevatedButton.icon(
                    onPressed: _showCreateProjectDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPrimary,
                      foregroundColor: const Color(0xFF090B10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22.0, vertical: 13.0),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18.0),
                    label: const Text('Create Project Now',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 40.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final project = list[index];
            return _buildProjectCard(project, index);
          },
          childCount: list.length,
        ),
      ),
    );
  }

  Widget _buildProjectCard(ProjectModel project, int index) {
    Color roleColor;
    switch (project.userRole.toLowerCase()) {
      case 'owner':
        roleColor = AppColors.accentPrimary;
        break;
      case 'editor':
        roleColor = AppColors.accentCyan;
        break;
      default:
        roleColor = AppColors.accentSecondary;
    }

    // Dynamic accent color for blueprint preview line
    final cardAccentColors = [
      AppColors.accentPrimary,
      AppColors.accentCyan,
      AppColors.accentSecondary,
      AppColors.accentPurple,
    ];
    final accentColor = cardAccentColors[index % cardAccentColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceCard,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: AppColors.darkBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.0),
          onTap: () {
            context.push('/projects/${project.id}');
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Blueprint Preview Line & Pattern
              Container(
                height: 4.0,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor,
                      accentColor.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20.0),
                    topRight: Radius.circular(20.0),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(18.0, 14.0, 18.0, 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Title, Role Badge, Menu
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Project Icon Avatar
                        Container(
                          width: 38.0,
                          height: 38.0,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.3),
                              width: 1.0,
                            ),
                          ),
                          child: Icon(
                            Icons.draw_outlined,
                            size: 19.0,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(width: 12.0),

                        // Title & Relative Time
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project.name,
                                style: AppTypography.titleMedium.copyWith(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2.0),
                              Text(
                                'Updated ${_formatRelativeTime(project.updatedAt ?? project.createdAt)}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textTertiaryDark,
                                  fontSize: 11.0,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8.0),

                        // Role Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.14),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusPill),
                            border: Border.all(
                              color: roleColor.withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            project.userRole.toUpperCase(),
                            style: TextStyle(
                              color: roleColor,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),

                        // More Actions Menu Button
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded,
                              color: AppColors.textTertiaryDark, size: 20.0),
                          color: AppColors.darkSurfaceElevated,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.0)),
                          onSelected: (val) {
                            if (val == 'open') {
                              context.push('/projects/${project.id}');
                            } else if (val == 'rename') {
                              _showRenameDialog(project);
                            } else if (val == 'delete') {
                              _confirmDeleteDialog(project);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'open',
                              child: Row(
                                children: [
                                  Icon(Icons.open_in_new_rounded,
                                      size: 17.0, color: Colors.white70),
                                  SizedBox(width: 10.0),
                                  Text('Open Workspace',
                                      style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            if (project.canEdit)
                              const PopupMenuItem(
                                value: 'rename',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined,
                                        size: 17.0, color: Colors.white70),
                                    SizedBox(width: 10.0),
                                    Text('Rename',
                                        style: TextStyle(color: Colors.white)),
                                  ],
                                ),
                              ),
                            if (project.isOwner)
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline,
                                        size: 17.0, color: AppColors.error),
                                    SizedBox(width: 10.0),
                                    Text('Delete Project',
                                        style:
                                            TextStyle(color: AppColors.error)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 14.0),

                    // Divider
                    Container(
                      height: 1.0,
                      color: AppColors.darkBorder.withValues(alpha: 0.5),
                    ),

                    const SizedBox(height: 12.0),

                    // Meta row: Boards Count, Member Count & Open Chevron
                    Row(
                      children: [
                        _buildMetaChip(
                          icon: Icons.dashboard_outlined,
                          label:
                              '${project.boardCount} ${project.boardCount == 1 ? 'board' : 'boards'}',
                        ),
                        const SizedBox(width: 14.0),
                        _buildMetaChip(
                          icon: Icons.people_outline,
                          label:
                              '${project.memberCount} ${project.memberCount == 1 ? 'member' : 'members'}',
                        ),
                        const Spacer(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Open',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.accentPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 2.0),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.accentPrimary,
                              size: 14.0,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaChip({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.5, color: AppColors.textTertiaryDark),
        const SizedBox(width: 5.0),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondaryDark,
            fontSize: 12.0,
          ),
        ),
      ],
    );
  }
}

