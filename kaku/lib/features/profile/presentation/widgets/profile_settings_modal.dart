import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/repositories/auth_repository.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class ProfileSettingsModal extends StatefulWidget {
  const ProfileSettingsModal({super.key, this.currentUser, this.onProfileUpdated});

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
  final _authRepo = AuthRepository();

  late TextEditingController _nameController;
  late TextEditingController _displayNameController;
  late TextEditingController _serverUrlController;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isSavingProfile = false;
  bool _isChangingPassword = false;
  bool _isTestingServer = false;
  bool? _serverOnline;
  String? _statusBanner;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _nameController = TextEditingController(text: widget.currentUser?.name ?? '');
    _displayNameController =
        TextEditingController(text: widget.currentUser?.displayName ?? '');
    _serverUrlController =
        TextEditingController(text: ApiClient.instance.baseUrl);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _displayNameController.dispose();
    _serverUrlController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
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
    setState(() {
      _isTestingServer = false;
      _serverOnline = isOk;
      _statusBanner = isOk
          ? 'Connected to server (${ApiClient.instance.baseUrl})'
          : 'Failed to reach server at ${ApiClient.instance.baseUrl}';
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _isSavingProfile = true);
    try {
      await _authRepo.updateProfile(
        name: _nameController.text,
        displayName: _displayNameController.text,
      );
      setState(() {
        _isSavingProfile = false;
        _statusBanner = 'Profile updated successfully!';
      });
      widget.onProfileUpdated?.call();
    } catch (e) {
      setState(() {
        _isSavingProfile = false;
        _statusBanner = 'Error: $e';
      });
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text.length < 8) {
      setState(() => _statusBanner = 'New password must be at least 8 characters');
      return;
    }
    setState(() => _isChangingPassword = true);
    try {
      final msg = await _authRepo.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      setState(() {
        _isChangingPassword = false;
        _statusBanner = msg;
      });
    } catch (e) {
      setState(() {
        _isChangingPassword = false;
        _statusBanner = 'Error: $e';
      });
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
      height: MediaQuery.of(context).size.height * 0.75 + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.darkSurfaceCard,
        borderRadius: AppSpacing.sheetTopCurvature,
        border: Border(
          top: BorderSide(color: AppColors.darkBorderHighlight, width: 1.0),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.currentUser?.displayName ?? 'Account Settings',
                      style: AppTypography.titleLarge,
                    ),
                    Text(
                      widget.currentUser?.email ?? 'Preferences & Workspace',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiaryDark,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondaryDark),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10.0),

          if (_statusBanner != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6.0),
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: _statusBanner!.startsWith('Error') || _statusBanner!.startsWith('Failed')
                    ? AppColors.error.withValues(alpha: 0.15)
                    : AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: _statusBanner!.startsWith('Error') || _statusBanner!.startsWith('Failed')
                      ? AppColors.error.withValues(alpha: 0.4)
                      : AppColors.success.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _statusBanner!.startsWith('Error') || _statusBanner!.startsWith('Failed')
                        ? Icons.error_outline
                        : Icons.check_circle_outline,
                    size: 16.0,
                    color: _statusBanner!.startsWith('Error') || _statusBanner!.startsWith('Failed')
                        ? AppColors.error
                        : AppColors.success,
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
              Tab(text: 'Security'),
              Tab(text: 'Server IP'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(),
                _buildSecurityTab(),
                _buildServerTab(),
              ],
            ),
          ),

          // Logout Action
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: OutlinedButton.icon(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error, width: 0.8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
                minimumSize: const Size.fromHeight(48.0),
              ),
              icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18.0),
              label: const Text('Sign Out of Kaku', style: TextStyle(color: AppColors.error)),
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
          _buildTextField('Full Name', _nameController, Icons.person_outline),
          const SizedBox(height: 16.0),
          _buildTextField('Display Name', _displayNameController, Icons.badge_outlined),
          const SizedBox(height: 24.0),
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

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField('Current Password', _currentPasswordController, Icons.lock_outline, obscure: true),
          const SizedBox(height: 16.0),
          _buildTextField('New Password (min 8 chars)', _newPasswordController, Icons.vpn_key_outlined, obscure: true),
          const SizedBox(height: 24.0),
          ElevatedButton(
            onPressed: _isChangingPassword ? null : _changePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentSecondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
              padding: const EdgeInsets.symmetric(vertical: 14.0),
            ),
            child: _isChangingPassword
                ? const SizedBox(
                    width: 20.0,
                    height: 20.0,
                    child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white),
                  )
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
                  setState(() => _statusBanner = 'Server URL saved!');
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondaryDark),
        ),
        const SizedBox(height: 6.0),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(color: Colors.white, fontSize: 14.0),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.textTertiaryDark, size: 20.0),
            filled: true,
            fillColor: AppColors.darkSurface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: AppColors.darkBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: AppColors.darkBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: AppColors.accentPrimary, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}
