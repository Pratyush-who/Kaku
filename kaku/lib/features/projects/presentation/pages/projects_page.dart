import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/widgets/app_brand_logo.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/repositories/auth_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/presentation/widgets/profile_settings_modal.dart';
import '../cubit/projects_cubit.dart';
import '../cubit/projects_state.dart';

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

  void _showCreateProjectDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: Text('Create New Project', style: AppTypography.titleLarge),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'e.g. Design Systems, Wireframes',
            hintStyle: TextStyle(color: AppColors.textTertiaryDark),
            filled: true,
            fillColor: AppColors.darkSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: AppColors.darkBorder),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
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
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
            ),
            child: const Text('Create Project', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showJoinWithTokenDialog() {
    final tokenCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: Text('Accept Invitation', style: AppTypography.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste the invitation token or hash shared by the project collaborator.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark),
            ),
            const SizedBox(height: 12.0),
            TextField(
              controller: tokenCtrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 13.0),
              decoration: InputDecoration(
                hintText: 'Paste token hex...',
                hintStyle: TextStyle(color: AppColors.textTertiaryDark),
                filled: true,
                fillColor: AppColors.darkSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: AppColors.darkBorder),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
          ElevatedButton(
            onPressed: () async {
              final token = tokenCtrl.text.trim();
              if (token.isNotEmpty) {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final msg = await context.read<ProjectsCubit>().acceptInvitationToken(token);
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    messenger.showSnackBar(
                      SnackBar(content: Text(msg), backgroundColor: AppColors.success),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentSecondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
            ),
            child: const Text('Accept & Join', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(ProjectModel project) {
    final nameCtrl = TextEditingController(text: project.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: Text('Rename Project', style: AppTypography.titleLarge),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Project name',
            filled: true,
            fillColor: AppColors.darkSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                context.read<ProjectsCubit>().updateProjectName(project.id, name);
                Navigator.of(ctx).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPrimary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDialog(ProjectModel project) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: const Text('Delete Project', style: TextStyle(color: AppColors.error)),
        content: Text(
          'Are you sure you want to delete "${project.name}"? All boards and invitations will be permanently removed.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ProjectsCubit>().deleteProject(project.id);
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
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
                  backgroundColor: state.statusMessage!.toLowerCase().contains('error')
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
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  // App Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 8.0),
                      child: Row(
                        children: [
                          const AppBrandLogo(size: 32.0, fontSize: 17.0),
                          const Spacer(),
                          // Server Status Dot
                          Tooltip(
                            message: _serverHealthy
                                ? 'Backend Online (${ApiClient.instance.baseUrl})'
                                : 'Backend Offline (${ApiClient.instance.baseUrl})',
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
                              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                                decoration: BoxDecoration(
                                  color: AppColors.darkSurfaceElevated,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                                  border: Border.all(color: AppColors.darkBorder, width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 7.0,
                                      height: 7.0,
                                      decoration: BoxDecoration(
                                        color: _serverHealthy ? AppColors.accentPrimary : AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6.0),
                                    Text(
                                      _serverHealthy ? 'Live API' : 'Offline',
                                      style: AppTypography.labelSmall.copyWith(
                                        fontSize: 11.0,
                                        color: AppColors.textSecondaryDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10.0),
                          // User Settings Avatar
                          IconButton(
                            icon: Container(
                              width: 34.0,
                              height: 34.0,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.accentGlowGradient,
                              ),
                              child: Center(
                                child: Text(
                                  (_currentUser?.displayName.isNotEmpty == true
                                          ? _currentUser!.displayName[0]
                                          : 'K')
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.0,
                                  ),
                                ),
                              ),
                            ),
                            onPressed: () {
                              ProfileSettingsModal.show(
                                context,
                                currentUser: _currentUser,
                                onProfileUpdated: () {
                                  _loadUser();
                                  _checkServer();
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Welcome Banner & Quick Action Buttons
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back, ${_currentUser?.displayName ?? 'Creator'}',
                            style: AppTypography.displayLarge.copyWith(fontSize: 24.0),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'Organize your sketches, wireframes, and collaborative boards.',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiaryDark),
                          ),
                          const SizedBox(height: 18.0),

                          // Action Buttons Row
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: ElevatedButton.icon(
                                  onPressed: _showCreateProjectDialog,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accentPrimary,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add_rounded, size: 20.0),
                                  label: const Text(
                                    'New Project',
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12.0),
                              Expanded(
                                flex: 2,
                                child: OutlinedButton.icon(
                                  onPressed: _showJoinWithTokenDialog,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.darkBorder),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                                    ),
                                  ),
                                  icon: const Icon(Icons.link_rounded, size: 18.0, color: AppColors.accentCyan),
                                  label: const Text('Join', style: TextStyle(fontSize: 13.0)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18.0),

                          // Search Bar
                          TextField(
                            controller: _searchController,
                            onChanged: (val) => context.read<ProjectsCubit>().updateSearchQuery(val),
                            style: const TextStyle(color: Colors.white, fontSize: 14.0),
                            decoration: InputDecoration(
                              hintText: 'Search projects...',
                              hintStyle: TextStyle(color: AppColors.textTertiaryDark, fontSize: 13.5),
                              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textTertiaryDark, size: 20.0),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18.0),
                                      onPressed: () {
                                        _searchController.clear();
                                        context.read<ProjectsCubit>().updateSearchQuery('');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: AppColors.darkSurface,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                                borderSide: const BorderSide(color: AppColors.darkBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                                borderSide: const BorderSide(color: AppColors.darkBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                                borderSide: const BorderSide(color: AppColors.accentPrimary, width: 1.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Projects Grid/List View
                  if (state is ProjectsLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.accentPrimary),
                      ),
                    )
                  else if (state is ProjectsError)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 48.0),
                              const SizedBox(height: 12.0),
                              Text(state.errorMessage, textAlign: TextAlign.center, style: AppTypography.bodyMedium),
                              const SizedBox(height: 16.0),
                              ElevatedButton(
                                onPressed: () => context.read<ProjectsCubit>().loadProjects(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accentPrimary,
                                  foregroundColor: Colors.black,
                                ),
                                child: const Text('Retry Connection'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (state is ProjectsLoaded) ...[
                    if (state.filteredProjects.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 64.0,
                                  height: 64.0,
                                  decoration: BoxDecoration(
                                    color: AppColors.darkSurfaceElevated,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.darkBorder),
                                  ),
                                  child: const Icon(Icons.folder_open_rounded, color: AppColors.accentPrimary, size: 30.0),
                                ),
                                const SizedBox(height: 16.0),
                                Text(
                                  state.searchQuery.isEmpty ? 'No Projects Yet' : 'No matching projects found',
                                  style: AppTypography.titleMedium,
                                ),
                                const SizedBox(height: 6.0),
                                Text(
                                  state.searchQuery.isEmpty
                                      ? 'Create your first project to start creating sketchboards.'
                                      : 'Try searching with a different term.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiaryDark),
                                ),
                                if (state.searchQuery.isEmpty) ...[
                                  const SizedBox(height: 20.0),
                                  ElevatedButton(
                                    onPressed: _showCreateProjectDialog,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accentPrimary,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
                                    ),
                                    child: const Text('Create Project Now'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 40.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final project = state.filteredProjects[index];
                              return _buildProjectCard(project);
                            },
                            childCount: state.filteredProjects.length,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProjectCard(ProjectModel project) {
    Color roleColor;
    switch (project.userRole.toLowerCase()) {
      case 'owner':
        roleColor = AppColors.accentPrimary;
        break;
      case 'editor':
        roleColor = AppColors.accentCyan;
        break;
      default:
        roleColor = AppColors.textTertiaryDark;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.darkBorder, width: 0.9),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: () {
            context.push('/projects/${project.id}');
          },
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Title, Role Badge, Menu
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.name,
                        style: AppTypography.titleMedium.copyWith(fontSize: 17.0),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        border: Border.all(color: roleColor.withValues(alpha: 0.4), width: 0.8),
                      ),
                      child: Text(
                        project.userRole.toUpperCase(),
                        style: TextStyle(
                          color: roleColor,
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textTertiaryDark, size: 20.0),
                      color: AppColors.darkSurfaceElevated,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
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
                              Icon(Icons.open_in_new_rounded, size: 18.0, color: Colors.white70),
                              SizedBox(width: 10.0),
                              Text('Open Workspace', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        if (project.canEdit)
                          const PopupMenuItem(
                            value: 'rename',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18.0, color: Colors.white70),
                                SizedBox(width: 10.0),
                                Text('Rename', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                        if (project.isOwner)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 18.0, color: AppColors.error),
                                SizedBox(width: 10.0),
                                Text('Delete Project', style: TextStyle(color: AppColors.error)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14.0),

                // Meta row: Boards Count, Member Count
                Row(
                  children: [
                    _buildMetaChip(
                      icon: Icons.dashboard_outlined,
                      label: '${project.boardCount} ${project.boardCount == 1 ? 'board' : 'boards'}',
                    ),
                    const SizedBox(width: 14.0),
                    _buildMetaChip(
                      icon: Icons.people_outline,
                      label: '${project.memberCount} ${project.memberCount == 1 ? 'member' : 'members'}',
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiaryDark, size: 20.0),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaChip({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15.0, color: AppColors.textTertiaryDark),
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
