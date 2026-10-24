import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/widgets/user_avatar.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/user_preferences_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/repositories/auth_repository.dart';
import '../../../../core/repositories/profile_repository.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/avatar_presets.dart';
import 'avatar_picker_dialog.dart';

class ProfileSettingsModal extends StatefulWidget {
  const ProfileSettingsModal({
    super.key,
    this.currentUser,
    this.onProfileUpdated,
  });

  final UserModel? currentUser;
  final VoidCallback? onProfileUpdated;

  static Future<void> show(
    BuildContext context, {
    UserModel? currentUser,
    VoidCallback? onProfileUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProfileSettingsModal(
        currentUser: currentUser,
        onProfileUpdated: onProfileUpdated,
      ),
    );
  }

  @override
  State<ProfileSettingsModal> createState() => _ProfileSettingsModalState();
}

class _ProfileSettingsModalState extends State<ProfileSettingsModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _profileRepo = ProfileRepository();
  final _authRepo = AuthRepository();

  late UserModel? _user;
  late TextEditingController _nameController;
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  late TextEditingController _serverUrlController;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  final _newEmailController = TextEditingController();
  final _emailPasswordController = TextEditingController();

  UserPreferencesModel _preferences = const UserPreferencesModel();

  bool _isSavingProfile = false;
  bool _isChangingPassword = false;
  bool _isChangingEmail = false;
  bool _isTestingServer = false;
  bool? _serverOnline;
  String? _statusBanner;
  bool _isErrorBanner = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _user = widget.currentUser;
    _nameController = TextEditingController(text: _user?.name ?? '');
    _displayNameController = TextEditingController(text: _user?.displayName ?? '');
    _bioController = TextEditingController(text: _user?.bio ?? '');
    _serverUrlController = TextEditingController(text: ApiClient.instance.baseUrl);

    if (_user?.preferences != null) {
      _preferences = UserPreferencesModel.fromJson(_user!.preferences);
    }
    _fetchPreferences();
  }

  Future<void> _fetchPreferences() async {
    try {
      final p = await _profileRepo.getPreferences();
      if (mounted) {
        setState(() => _preferences = p);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    _serverUrlController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _newEmailController.dispose();
    _emailPasswordController.dispose();
    super.dispose();
  }

  void _showBanner(String message, {bool isError = false}) {
    setState(() {
      _statusBanner = message;
      _isErrorBanner = isError;
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingServer = true;
      _statusBanner = null;
    });

    final targetUrl = _serverUrlController.text.trim();
    if (targetUrl.isNotEmpty) {
      await ApiClient.instance.setBaseUrl(targetUrl);
    }

    final isOk = await ApiClient.instance.checkHealth();
    if (mounted) {
      setState(() {
        _isTestingServer = false;
        _serverOnline = isOk;
      });
      _showBanner(
        isOk
            ? 'Connected to server (${ApiClient.instance.baseUrl})'
            : 'Failed to reach server at ${ApiClient.instance.baseUrl}',
        isError: !isOk,
      );
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSavingProfile = true);
    try {
      final updated = await _profileRepo.updateProfile(
        name: _nameController.text,
        displayName: _displayNameController.text,
        bio: _bioController.text,
      );
      setState(() {
        _isSavingProfile = false;
        _user = updated;
      });
      _showBanner('Profile updated successfully!');
      widget.onProfileUpdated?.call();
    } catch (e) {
      setState(() => _isSavingProfile = false);
      _showBanner('Error: $e', isError: true);
    }
  }

  Future<void> _updateAvatar(String url) async {
    try {
      final updated = await _profileRepo.updateAvatarUrl(url);
      setState(() => _user = updated);
      _showBanner('Avatar updated!');
      widget.onProfileUpdated?.call();
    } catch (e) {
      _showBanner('Error updating avatar: $e', isError: true);
    }
  }

  Future<void> _removeAvatar() async {
    try {
      final updated = await _profileRepo.removeAvatar();
      setState(() => _user = updated);
      _showBanner('Avatar removed.');
      widget.onProfileUpdated?.call();
    } catch (e) {
      _showBanner('Error removing avatar: $e', isError: true);
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text.length < 8) {
      _showBanner('New password must be at least 8 characters', isError: true);
      return;
    }
    setState(() => _isChangingPassword = true);
    try {
      final msg = await _profileRepo.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      setState(() => _isChangingPassword = false);
      _showBanner(msg);
    } catch (e) {
      setState(() => _isChangingPassword = false);
      _showBanner('Error: $e', isError: true);
    }
  }

  Future<void> _changeEmail() async {
    final newEmail = _newEmailController.text.trim().toLowerCase();
    final pass = _emailPasswordController.text;
    if (newEmail.isEmpty || !newEmail.contains('@') || pass.isEmpty) {
      _showBanner('Please provide a valid new email and current password', isError: true);
      return;
    }

    setState(() => _isChangingEmail = true);
    try {
      final updated = await _profileRepo.changeEmail(newEmail: newEmail, password: pass);
      setState(() {
        _isChangingEmail = false;
        _user = updated;
      });
      _newEmailController.clear();
      _emailPasswordController.clear();
      _showBanner('Email updated to $newEmail');
      widget.onProfileUpdated?.call();
    } catch (e) {
      setState(() => _isChangingEmail = false);
      _showBanner('Error: $e', isError: true);
    }
  }

  Future<void> _togglePreference(UserPreferencesModel newPrefs) async {
    setState(() => _preferences = newPrefs);
    try {
      await _profileRepo.updatePreferences(newPrefs);
      _showBanner('Preference updated');
      widget.onProfileUpdated?.call();
    } catch (e) {
      _showBanner('Error saving preferences: $e', isError: true);
    }
  }

  Future<void> _logout() async {
    await _authRepo.logout();
    if (mounted) {
      Navigator.of(context).pop();
      context.go(AppRoutes.auth);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82 + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.darkSurfaceCard,
        borderRadius: AppSpacing.sheetTopCurvature,
        border: Border(
          top: BorderSide(color: AppColors.darkBorderHighlight, width: 1.2),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12.0),
          // Drag handle
          Container(
            width: 44.0,
            height: 4.5,
            decoration: BoxDecoration(
              color: AppColors.darkBorder,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
          ),
          const SizedBox(height: 14.0),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                UserAvatar(
                  user: _user,
                  radius: 22.0,
                  borderColor: AppColors.accentPrimary,
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user?.displayName.isNotEmpty == true
                            ? _user!.displayName
                            : 'Workspace Settings',
                        style: AppTypography.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _user?.email ?? 'Preferences & Workspace',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiaryDark,
                          fontSize: 12.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(AppRoutes.profile);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accentPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16.0),
                  label: const Text('Full View', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.0)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondaryDark),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6.0),

          // Status Banner
          if (_statusBanner != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6.0),
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: _isErrorBanner
                    ? AppColors.error.withValues(alpha: 0.15)
                    : AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: _isErrorBanner
                      ? AppColors.error.withValues(alpha: 0.4)
                      : AppColors.success.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isErrorBanner ? Icons.error_outline : Icons.check_circle_outline,
                    size: 16.0,
                    color: _isErrorBanner ? AppColors.error : AppColors.success,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      _statusBanner!,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Tab Selector
          TabBar(
            controller: _tabController,
            labelColor: AppColors.accentPrimary,
            unselectedLabelColor: AppColors.textTertiaryDark,
            indicatorColor: AppColors.accentPrimary,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'Profile'),
              Tab(text: 'Preferences'),
              Tab(text: 'Security'),
              Tab(text: 'Server IP'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(),
                _buildPreferencesTab(),
                _buildSecurityTab(),
                _buildServerTab(),
              ],
            ),
          ),

          // Logout Action
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: OutlinedButton.icon(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error, width: 0.8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
                minimumSize: const Size.fromHeight(44.0),
              ),
              icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18.0),
              label: const Text('Sign Out of Kaku', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Avatar Picker Row
          Row(
            children: [
              UserAvatar(
                user: _user,
                radius: 26.0,
                borderColor: AppColors.accentPrimary,
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Avatar Persona', style: AppTypography.titleMedium.copyWith(fontSize: 13.5)),
                    Text('Select a quick style or choose custom URL',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiaryDark, fontSize: 11.0)),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  AvatarPickerDialog.show(
                    context,
                    currentUser: _user,
                    onSelectPreset: _updateAvatar,
                    onCustomUrl: _updateAvatar,
                    onRemoveAvatar: _removeAvatar,
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.accentPrimary, width: 0.8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                ),
                icon: const Icon(Icons.palette_outlined, size: 15.0, color: AppColors.accentPrimary),
                label: const Text('Customize', style: TextStyle(color: AppColors.accentPrimary, fontSize: 11.5)),
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Quick Presets Row
          SizedBox(
            height: 38.0,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AvatarPresets.list.take(6).length,
              separatorBuilder: (context, index) => const SizedBox(width: 8.0),
              itemBuilder: (context, idx) {
                final preset = AvatarPresets.list[idx];
                final isCurrent = _user?.avatarUrl == preset.url;
                return InkWell(
                  onTap: () => _updateAvatar(preset.url),
                  borderRadius: BorderRadius.circular(19.0),
                  child: Container(
                    padding: const EdgeInsets.all(2.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCurrent ? AppColors.accentPrimary : AppColors.darkBorder,
                        width: isCurrent ? 2.0 : 1.0,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.network(preset.url, width: 32.0, height: 32.0, fit: BoxFit.cover),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18.0),

          _buildTextField('Full Name', _nameController, Icons.person_outline),
          const SizedBox(height: 14.0),
          _buildTextField('Display Name', _displayNameController, Icons.badge_outlined),
          const SizedBox(height: 14.0),
          _buildTextField('Bio (Drawing focus & intro)', _bioController, Icons.notes_outlined, maxLines: 2),
          const SizedBox(height: 22.0),

          ElevatedButton(
            onPressed: _isSavingProfile ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPrimary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
              padding: const EdgeInsets.symmetric(vertical: 14.0),
            ),
            child: _isSavingProfile
                ? const SizedBox(
                    width: 20.0,
                    height: 20.0,
                    child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.black),
                  )
                : const Text('Update Profile', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'WHITEBOARD SETTINGS',
            style: AppTypography.brandTagline.copyWith(fontSize: 10.5, letterSpacing: 2.0, color: AppColors.accentPrimary),
          ),
          const SizedBox(height: 12.0),

          SwitchListTile(
            title: const Text('Canvas Grid Dots', style: TextStyle(color: Colors.white, fontSize: 13.5)),
            subtitle: Text('Render drafting coordinates by default', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiaryDark, fontSize: 11.0)),
            value: _preferences.grid,
            activeThumbColor: AppColors.accentPrimary,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => _togglePreference(_preferences.copyWith(grid: val)),
          ),
          const Divider(color: AppColors.darkBorder, height: 1.0),

          SwitchListTile(
            title: const Text('Snap to Grid Magnet', style: TextStyle(color: Colors.white, fontSize: 13.5)),
            subtitle: Text('Align strokes and cards automatically', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiaryDark, fontSize: 11.0)),
            value: _preferences.snapToGrid,
            activeThumbColor: AppColors.accentPrimary,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => _togglePreference(_preferences.copyWith(snapToGrid: val)),
          ),
          const Divider(color: AppColors.darkBorder, height: 1.0),

          SwitchListTile(
            title: const Text('Email Notifications', style: TextStyle(color: Colors.white, fontSize: 13.5)),
            subtitle: Text('Receive alerts on team invites', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiaryDark, fontSize: 11.0)),
            value: _preferences.emailNotifications,
            activeThumbColor: AppColors.accentPrimary,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => _togglePreference(_preferences.copyWith(emailNotifications: val)),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Update Email Section
          Text(
            'CHANGE ACCOUNT EMAIL',
            style: AppTypography.brandTagline.copyWith(fontSize: 10.5, letterSpacing: 2.0, color: AppColors.accentCyan),
          ),
          const SizedBox(height: 10.0),
          _buildTextField('New Email Address', _newEmailController, Icons.alternate_email_rounded),
          const SizedBox(height: 10.0),
          _buildTextField('Current Password to Confirm', _emailPasswordController, Icons.lock_outline, obscure: true),
          const SizedBox(height: 12.0),
          ElevatedButton(
            onPressed: _isChangingEmail ? null : _changeEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentCyan,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
              padding: const EdgeInsets.symmetric(vertical: 12.0),
            ),
            child: _isChangingEmail
                ? const SizedBox(width: 18.0, height: 18.0, child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.black))
                : const Text('Update Email', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 24.0),
          const Divider(color: AppColors.darkBorder, height: 1.0),
          const SizedBox(height: 20.0),

          // Change Password Section
          Text(
            'CHANGE PASSWORD',
            style: AppTypography.brandTagline.copyWith(fontSize: 10.5, letterSpacing: 2.0, color: AppColors.accentSecondary),
          ),
          const SizedBox(height: 10.0),
          _buildTextField('Current Password', _currentPasswordController, Icons.lock_outline, obscure: true),
          const SizedBox(height: 10.0),
          _buildTextField('New Password (min 8 chars)', _newPasswordController, Icons.vpn_key_outlined, obscure: true),
          const SizedBox(height: 14.0),
          ElevatedButton(
            onPressed: _isChangingPassword ? null : _changePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentSecondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
              padding: const EdgeInsets.symmetric(vertical: 12.0),
            ),
            child: _isChangingPassword
                ? const SizedBox(width: 18.0, height: 18.0, child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white))
                : const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildServerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField('Backend API Base URL', _serverUrlController, Icons.dns_outlined),
          const SizedBox(height: 8.0),
          Text(
            'Defaults: "http://localhost:8080" (Desktop/Web) or "http://10.0.2.2:8080" (Android Emulator)',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiaryDark, fontSize: 11.0),
          ),
          const SizedBox(height: 24.0),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isTestingServer ? null : _testConnection,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _serverOnline == true
                          ? AppColors.success
                          : (_serverOnline == false ? AppColors.error : AppColors.darkBorder),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                  ),
                  icon: _isTestingServer
                      ? const SizedBox(
                          width: 16.0,
                          height: 16.0,
                          child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white),
                        )
                      : Icon(
                          _serverOnline == true
                              ? Icons.cloud_done
                              : (_serverOnline == false ? Icons.cloud_off : Icons.network_check),
                          size: 18.0,
                          color: _serverOnline == true
                              ? AppColors.success
                              : (_serverOnline == false ? AppColors.error : AppColors.accentPrimary),
                        ),
                  label: Text(
                    _isTestingServer ? 'Testing...' : 'Test Connection',
                    style: TextStyle(
                      color: _serverOnline == true
                          ? AppColors.success
                          : (_serverOnline == false ? AppColors.error : Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              ElevatedButton(
                onPressed: () async {
                  await ApiClient.instance.setBaseUrl(_serverUrlController.text);
                  _showBanner('Server URL saved!');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPrimary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                ),
                child: const Text('Save URL', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool obscure = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondaryDark, fontSize: 12.0),
        ),
        const SizedBox(height: 6.0),
        TextField(
          controller: controller,
          obscureText: obscure,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 13.5),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.textTertiaryDark, size: 18.0),
            filled: true,
            fillColor: AppColors.darkSurface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          ),
        ),
      ],
    );
  }
}
