import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/board_model.dart';
import '../../../../core/models/invitation_model.dart';
import '../../../../core/models/member_model.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubit/project_detail_cubit.dart';
import '../cubit/project_detail_state.dart';

class ProjectDetailPage extends StatelessWidget {
  const ProjectDetailPage({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProjectDetailCubit(projectId: projectId)..loadDetails(),
      child: const _ProjectDetailView(),
    );
  }
}

class _ProjectDetailView extends StatefulWidget {
  const _ProjectDetailView();

  @override
  State<_ProjectDetailView> createState() => _ProjectDetailViewState();
}

class _ProjectDetailViewState extends State<_ProjectDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreateBoardDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: 'Untitled Board');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: Text('Create Drawing Board', style: AppTypography.titleLarge),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'e.g. Architecture Flow, Wireframe v1',
            filled: true,
            fillColor: AppColors.darkSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
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
                context.read<ProjectDetailCubit>().createBoard(name);
                Navigator.of(ctx).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPrimary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
            ),
            child: const Text('Create Board'),
          ),
        ],
      ),
    );
  }

  void _showRenameBoardDialog(BuildContext context, BoardSummaryModel board) {
    final nameCtrl = TextEditingController(text: board.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: Text('Rename Board', style: AppTypography.titleLarge),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.darkSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
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
                context.read<ProjectDetailCubit>().renameBoard(board.id, name);
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

  void _showInviteDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    String selectedRole = 'editor';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.darkSurfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
          title: Text('Invite Collaborator', style: AppTypography.titleLarge),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter teammate email address and role permissions:',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark),
              ),
              const SizedBox(height: 12.0),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'colleague@workspace.com',
                  filled: true,
                  fillColor: AppColors.darkSurface,
                  prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppColors.textTertiaryDark, size: 20.0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                ),
              ),
              const SizedBox(height: 16.0),
              Text('Access Role:', style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondaryDark)),
              const SizedBox(height: 6.0),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Editor'),
                    selected: selectedRole == 'editor',
                    selectedColor: AppColors.accentPrimary.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: selectedRole == 'editor' ? AppColors.accentPrimary : AppColors.textSecondaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) {
                      if (val) setDialogState(() => selectedRole = 'editor');
                    },
                  ),
                  const SizedBox(width: 8.0),
                  ChoiceChip(
                    label: const Text('Viewer'),
                    selected: selectedRole == 'viewer',
                    selectedColor: AppColors.accentCyan.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: selectedRole == 'viewer' ? AppColors.accentCyan : AppColors.textSecondaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) {
                      if (val) setDialogState(() => selectedRole = 'viewer');
                    },
                  ),
                ],
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
                final email = emailCtrl.text.trim();
                if (email.isNotEmpty && email.contains('@')) {
                  Navigator.of(ctx).pop();
                  final res = await context.read<ProjectDetailCubit>().inviteCollaborator(
                        email: email,
                        role: selectedRole,
                      );
                  if (res?.rawToken != null && context.mounted) {
                    _showTokenCreatedDialog(context, res!.rawToken!, email);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPrimary,
                foregroundColor: Colors.black,
              ),
              child: const Text('Send Invite'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTokenCreatedDialog(BuildContext context, String rawToken, String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.accentPrimary, size: 24.0),
            const SizedBox(width: 8.0),
            Text('Invitation Created', style: AppTypography.titleLarge),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invitation generated for $email. Share this token with your collaborator:',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark),
            ),
            const SizedBox(height: 14.0),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: AppColors.darkBorderHighlight),
              ),
              child: SelectableText(
                rawToken,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: AppColors.accentPrimary,
                  fontSize: 12.0,
                ),
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: rawToken));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Token copied to clipboard!')),
              );
              Navigator.of(ctx).pop();
            },
            icon: const Icon(Icons.copy_rounded, size: 16.0),
            label: const Text('Copy Token'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPrimary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.darkCanvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: BlocBuilder<ProjectDetailCubit, ProjectDetailState>(
          builder: (context, state) {
            if (state is ProjectDetailLoaded) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.project.name,
                    style: AppTypography.titleMedium.copyWith(fontSize: 17.0),
                  ),
                  Text(
                    'Workspace • ${state.project.userRole.toUpperCase()}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.accentPrimary,
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            }
            return Text('Workspace', style: AppTypography.titleMedium);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondaryDark),
            onPressed: () => context.read<ProjectDetailCubit>().loadDetails(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.accentPrimary,
          unselectedLabelColor: AppColors.textTertiaryDark,
          indicatorColor: AppColors.accentPrimary,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined, size: 20.0), text: 'Drawing Boards'),
            Tab(icon: Icon(Icons.group_outlined, size: 20.0), text: 'Collaborators'),
          ],
        ),
      ),
      body: BlocConsumer<ProjectDetailCubit, ProjectDetailState>(
        listener: (context, state) {
          if (state is ProjectDetailLoaded && state.statusMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.statusMessage!),
                behavior: SnackBarBehavior.floating,
                backgroundColor: state.statusMessage!.toLowerCase().contains('failed') ||
                        state.statusMessage!.toLowerCase().contains('error')
                    ? AppColors.error
                    : AppColors.success,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProjectDetailLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary));
          }
          if (state is ProjectDetailError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40.0),
                  const SizedBox(height: 10.0),
                  Text(state.errorMessage, style: AppTypography.bodyMedium),
                  const SizedBox(height: 14.0),
                  ElevatedButton(
                    onPressed: () => context.read<ProjectDetailCubit>().loadDetails(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is ProjectDetailLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildBoardsTab(state),
                _buildCollaboratorsTab(state),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildBoardsTab(ProjectDetailLoaded state) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${state.boards.length} ${state.boards.length == 1 ? 'Board' : 'Boards'} in Project',
                style: AppTypography.titleSmall.copyWith(color: AppColors.textSecondaryDark),
              ),
              if (state.project.canEdit)
                ElevatedButton.icon(
                  onPressed: () => _showCreateBoardDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18.0),
                  label: const Text('New Board', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 16.0),
          Expanded(
            child: state.boards.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.draw_outlined, size: 48.0, color: AppColors.textTertiaryDark),
                        const SizedBox(height: 12.0),
                        Text('No boards in this project yet', style: AppTypography.titleMedium),
                        const SizedBox(height: 4.0),
                        Text(
                          'Create a drawing board to start sketching shapes and flows.',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiaryDark),
                        ),
                        const SizedBox(height: 16.0),
                        if (state.project.canEdit)
                          ElevatedButton(
                            onPressed: () => _showCreateBoardDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentPrimary,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
                            ),
                            child: const Text('Create First Board'),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: state.boards.length,
                    itemBuilder: (ctx, idx) {
                      final board = state.boards[idx];
                      return _buildBoardCard(board, state.project);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardCard(BoardSummaryModel board, ProjectModel project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceCard,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Container(
          width: 44.0,
          height: 44.0,
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceElevated,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: AppColors.darkBorderHighlight),
          ),
          child: const Icon(Icons.gesture_rounded, color: AppColors.accentPrimary, size: 22.0),
        ),
        title: Text(
          board.name,
          style: AppTypography.titleMedium.copyWith(fontSize: 16.0),
        ),
        subtitle: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4.0),
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
              decoration: BoxDecoration(
                color: AppColors.accentSecondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Text(
                'REV ${board.revision}',
                style: const TextStyle(
                  fontSize: 10.0,
                  color: AppColors.accentSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            Text(
              board.updatedAt != null ? 'Active' : '',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiaryDark, fontSize: 11.0),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.textTertiaryDark),
              color: AppColors.darkSurfaceElevated,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              onSelected: (val) {
                if (val == 'open') {
                  context.push('/boards/${board.id}');
                } else if (val == 'duplicate') {
                  context.read<ProjectDetailCubit>().duplicateBoard(board.id);
                } else if (val == 'rename') {
                  _showRenameBoardDialog(context, board);
                } else if (val == 'delete') {
                  context.read<ProjectDetailCubit>().deleteBoard(board.id);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'open',
                  child: Row(
                    children: [
                      Icon(Icons.edit_note_rounded, size: 18.0, color: Colors.white70),
                      SizedBox(width: 8.0),
                      Text('Open Canvas', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                if (project.canEdit) ...[
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy_rounded, size: 18.0, color: Colors.white70),
                        SizedBox(width: 8.0),
                        Text('Duplicate', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.drive_file_rename_outline, size: 18.0, color: Colors.white70),
                        SizedBox(width: 8.0),
                        Text('Rename', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18.0, color: AppColors.error),
                        SizedBox(width: 8.0),
                        Text('Delete', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        onTap: () {
          context.push('/boards/${board.id}');
        },
      ),
    );
  }

  Widget _buildCollaboratorsTab(ProjectDetailLoaded state) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        // Invite Banner
        if (state.project.canEdit)
          Container(
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              gradient: AppColors.cardGlassGradient,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: AppColors.darkBorderHighlight),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Invite Teammates', style: AppTypography.titleMedium),
                      const SizedBox(height: 4.0),
                      Text(
                        'Share project canvas with editors or viewers.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiaryDark),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showInviteDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
                  ),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18.0),
                  label: const Text('Invite', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24.0),

        // Active Members Section
        Text(
          'Active Members (${state.members.length})',
          style: AppTypography.titleSmall.copyWith(color: AppColors.textSecondaryDark),
        ),
        const SizedBox(height: 12.0),
        ...state.members.map((member) => _buildMemberTile(member, state.project)),

        const SizedBox(height: 24.0),

        // Pending Invitations Section
        if (state.invitations.isNotEmpty) ...[
          Text(
            'Pending Invitations (${state.invitations.length})',
            style: AppTypography.titleSmall.copyWith(color: AppColors.textSecondaryDark),
          ),
          const SizedBox(height: 12.0),
          ...state.invitations.map((inv) => _buildInvitationTile(inv)),
        ],
      ],
    );
  }

  Widget _buildMemberTile(ProjectMemberModel member, ProjectModel project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceCard,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.darkSurfaceElevated,
          child: Text(
            (member.user?.displayName.isNotEmpty == true ? member.user!.displayName[0] : 'U').toUpperCase(),
            style: const TextStyle(color: AppColors.accentPrimary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(member.user?.displayName ?? member.user?.name ?? 'Member', style: AppTypography.bodyMedium),
        subtitle: Text(member.user?.email ?? '', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiaryDark)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: member.isOwner
                    ? AppColors.accentPrimary.withValues(alpha: 0.15)
                    : AppColors.accentSecondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: Text(
                member.role.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: member.isOwner ? AppColors.accentPrimary : AppColors.accentSecondary,
                ),
              ),
            ),
            if (project.isOwner && !member.isOwner)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 18.0),
                onPressed: () => context.read<ProjectDetailCubit>().removeMember(member.userId),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationTile(InvitationModel inv) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceCard,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: ListTile(
        leading: const Icon(Icons.mail_outline_rounded, color: AppColors.accentCyan),
        title: Text(inv.email, style: AppTypography.bodyMedium),
        subtitle: Text('Role: ${inv.role} • Expires in 7 days', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiaryDark, fontSize: 11.5)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          child: const Text(
            'PENDING',
            style: TextStyle(color: AppColors.warning, fontSize: 10.0, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
