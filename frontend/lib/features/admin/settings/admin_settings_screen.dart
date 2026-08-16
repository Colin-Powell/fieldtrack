import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/toast_service.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../features/admin/auth/admin_login_screen.dart';
import '../../../../core/network/error_handler.dart';

// ── Settings Model ──
class SystemSettings {
  String universityName;
  String systemAdmin;
  String contactEmail;
  int sessionTimeout;
  bool ssoEnabled;
  bool twoFAEnabled;
  int gpsDeviationRadius;
  int gpsSyncInterval;
  bool strictBounds;
  String smtpHost;
  String smtpPort;
  String senderEmail;
  String smtpPassword;
  String s3BucketUri;
  int backupFrequency;
  bool autoBackup;
  int minPasswordLength;
  int maxLoginAttempts;
  bool alphaPass;
  String slackWebhook;
  String googleMapsKey;
  bool webhookSync;

  SystemSettings({
    this.universityName = 'Pwani University',
    this.systemAdmin = 'FieldTrack Admin',
    this.contactEmail = 'admin@fieldtrack.com',
    this.sessionTimeout = 30,
    this.ssoEnabled = false,
    this.twoFAEnabled = true,
    this.gpsDeviationRadius = 500,
    this.gpsSyncInterval = 15,
    this.strictBounds = true,
    this.smtpHost = 'smtp.fieldtrack.com',
    this.smtpPort = '587',
    this.senderEmail = 'noreply@fieldtrack.com',
    this.smtpPassword = '',
    this.s3BucketUri = 's3://fieldtrack-prod-backups',
    this.backupFrequency = 1,
    this.autoBackup = true,
    this.minPasswordLength = 8,
    this.maxLoginAttempts = 5,
    this.alphaPass = true,
    this.slackWebhook = '',
    this.googleMapsKey = '',
    this.webhookSync = false,
  });

  factory SystemSettings.fromJson(Map<String, dynamic> json) {
    return SystemSettings(
      universityName: json['universityName'] ?? 'Pwani University',
      systemAdmin: json['systemAdmin'] ?? 'FieldTrack Admin',
      contactEmail: json['contactEmail'] ?? 'admin@fieldtrack.com',
      sessionTimeout: json['sessionTimeout'] ?? 30,
      ssoEnabled: json['ssoEnabled'] ?? false,
      twoFAEnabled: json['twoFAEnabled'] ?? true,
      gpsDeviationRadius: json['gpsDeviationRadius'] ?? 500,
      gpsSyncInterval: json['gpsSyncInterval'] ?? 15,
      strictBounds: json['strictBounds'] ?? true,
      smtpHost: json['smtpHost'] ?? 'smtp.fieldtrack.com',
      smtpPort: json['smtpPort'] ?? '587',
      senderEmail: json['senderEmail'] ?? 'noreply@fieldtrack.com',
      smtpPassword: json['smtpPassword'] ?? '',
      s3BucketUri: json['s3BucketUri'] ?? 's3://fieldtrack-prod-backups',
      backupFrequency: json['backupFrequency'] ?? 1,
      autoBackup: json['autoBackup'] ?? true,
      minPasswordLength: json['minPasswordLength'] ?? 8,
      maxLoginAttempts: json['maxLoginAttempts'] ?? 5,
      alphaPass: json['alphaPass'] ?? true,
      slackWebhook: json['slackWebhook'] ?? '',
      googleMapsKey: json['googleMapsKey'] ?? '',
      webhookSync: json['webhookSync'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'universityName': universityName,
      'systemAdmin': systemAdmin,
      'contactEmail': contactEmail,
      'sessionTimeout': sessionTimeout,
      'ssoEnabled': ssoEnabled,
      'twoFAEnabled': twoFAEnabled,
      'gpsDeviationRadius': gpsDeviationRadius,
      'gpsSyncInterval': gpsSyncInterval,
      'strictBounds': strictBounds,
      'smtpHost': smtpHost,
      'smtpPort': smtpPort,
      'senderEmail': senderEmail,
      'smtpPassword': smtpPassword,
      's3BucketUri': s3BucketUri,
      'backupFrequency': backupFrequency,
      'autoBackup': autoBackup,
      'minPasswordLength': minPasswordLength,
      'maxLoginAttempts': maxLoginAttempts,
      'alphaPass': alphaPass,
      'slackWebhook': slackWebhook,
      'googleMapsKey': googleMapsKey,
      'webhookSync': webhookSync,
    };
  }
}

// ── Settings Provider ──
final settingsProvider = FutureProvider<SystemSettings>((ref) async {
  final api = ApiClient();
  final response = await api.dio.get('/admin/settings');
  final data = response.data['settings'] as Map<String, dynamic>;
  return SystemSettings.fromJson(data);
});

// ── Settings Screen ──
class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  int _selectedIndex = 0;
  bool _isSaving = false;
  bool _isBackingUp = false;

  void _handleDeleteAccount() {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final bool isEmailMatch =
              emailController.text.trim().toLowerCase() ==
              user.email.toLowerCase();

          return AlertDialog(
            title: const Text(
              'Delete Account',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: Color(0xFFEF4444),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Are you sure you want to delete your admin account? This action cannot be undone.',
                  style: TextStyle(fontFamily: 'Inter'),
                ),
                const SizedBox(height: 16),
                Text(
                  'Type ${user.email} to confirm:',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Email address',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: isEmailMatch
                    ? () async {
                        try {
                          await ApiClient().dio.delete('/settings/deactivate');
                          ref.read(authProvider.notifier).logout();
                        } catch (e) {
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to delete account: ${ErrorHandler.getFriendlyErrorMessage(e)}',
                                ),
                              ),
                            );
                          }
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  disabledBackgroundColor: const Color(
                    0xFFEF4444,
                  ).withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Delete Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Controllers for text fields
  final _universityNameCtrl = TextEditingController();
  final _systemAdminCtrl = TextEditingController();
  final _contactEmailCtrl = TextEditingController();
  final _sessionTimeoutCtrl = TextEditingController();
  final _gpsDeviationRadiusCtrl = TextEditingController();
  final _gpsSyncIntervalCtrl = TextEditingController();
  final _smtpHostCtrl = TextEditingController();
  final _smtpPortCtrl = TextEditingController();
  final _senderEmailCtrl = TextEditingController();
  final _smtpPasswordCtrl = TextEditingController();
  final _s3BucketUriCtrl = TextEditingController();
  final _backupFrequencyCtrl = TextEditingController();
  final _minPasswordLengthCtrl = TextEditingController();
  final _maxLoginAttemptsCtrl = TextEditingController();
  final _slackWebhookCtrl = TextEditingController();
  final _googleMapsKeyCtrl = TextEditingController();

  // Toggle states
  bool _strictBounds = true;
  bool _ssoEnabled = false;
  bool _twoFAEnabled = true;
  bool _autoBackup = true;
  bool _alphaPass = true;
  bool _webhookSync = false;

  final List<String> _sections = [
    'General',
    'Authentication',
    'GPS Settings',
    'Email Configuration',
    'Backups',
    'Security',
    'Integrations',
  ];

  @override
  void dispose() {
    _universityNameCtrl.dispose();
    _systemAdminCtrl.dispose();
    _contactEmailCtrl.dispose();
    _sessionTimeoutCtrl.dispose();
    _gpsDeviationRadiusCtrl.dispose();
    _gpsSyncIntervalCtrl.dispose();
    _smtpHostCtrl.dispose();
    _smtpPortCtrl.dispose();
    _senderEmailCtrl.dispose();
    _smtpPasswordCtrl.dispose();
    _s3BucketUriCtrl.dispose();
    _backupFrequencyCtrl.dispose();
    _minPasswordLengthCtrl.dispose();
    _maxLoginAttemptsCtrl.dispose();
    _slackWebhookCtrl.dispose();
    _googleMapsKeyCtrl.dispose();
    super.dispose();
  }

  void _populateFromSettings(SystemSettings settings) {
    _universityNameCtrl.text = settings.universityName;
    _systemAdminCtrl.text = settings.systemAdmin;
    _contactEmailCtrl.text = settings.contactEmail;
    _sessionTimeoutCtrl.text = settings.sessionTimeout.toString();
    _gpsDeviationRadiusCtrl.text = settings.gpsDeviationRadius.toString();
    _gpsSyncIntervalCtrl.text = settings.gpsSyncInterval.toString();
    _smtpHostCtrl.text = settings.smtpHost;
    _smtpPortCtrl.text = settings.smtpPort;
    _senderEmailCtrl.text = settings.senderEmail;
    _smtpPasswordCtrl.text = settings.smtpPassword;
    _s3BucketUriCtrl.text = settings.s3BucketUri;
    _backupFrequencyCtrl.text = settings.backupFrequency.toString();
    _minPasswordLengthCtrl.text = settings.minPasswordLength.toString();
    _maxLoginAttemptsCtrl.text = settings.maxLoginAttempts.toString();
    _slackWebhookCtrl.text = settings.slackWebhook;
    _googleMapsKeyCtrl.text = settings.googleMapsKey;

    _strictBounds = settings.strictBounds;
    _ssoEnabled = settings.ssoEnabled;
    _twoFAEnabled = settings.twoFAEnabled;
    _autoBackup = settings.autoBackup;
    _alphaPass = settings.alphaPass;
    _webhookSync = settings.webhookSync;
  }

  SystemSettings _collectSettings() {
    return SystemSettings(
      universityName: _universityNameCtrl.text,
      systemAdmin: _systemAdminCtrl.text,
      contactEmail: _contactEmailCtrl.text,
      sessionTimeout: int.tryParse(_sessionTimeoutCtrl.text) ?? 30,
      ssoEnabled: _ssoEnabled,
      twoFAEnabled: _twoFAEnabled,
      gpsDeviationRadius: int.tryParse(_gpsDeviationRadiusCtrl.text) ?? 500,
      gpsSyncInterval: int.tryParse(_gpsSyncIntervalCtrl.text) ?? 15,
      strictBounds: _strictBounds,
      smtpHost: _smtpHostCtrl.text,
      smtpPort: _smtpPortCtrl.text,
      senderEmail: _senderEmailCtrl.text,
      smtpPassword: _smtpPasswordCtrl.text,
      s3BucketUri: _s3BucketUriCtrl.text,
      backupFrequency: int.tryParse(_backupFrequencyCtrl.text) ?? 1,
      autoBackup: _autoBackup,
      minPasswordLength: int.tryParse(_minPasswordLengthCtrl.text) ?? 8,
      maxLoginAttempts: int.tryParse(_maxLoginAttemptsCtrl.text) ?? 5,
      alphaPass: _alphaPass,
      slackWebhook: _slackWebhookCtrl.text,
      googleMapsKey: _googleMapsKeyCtrl.text,
      webhookSync: _webhookSync,
    );
  }

  // Validate settings before saving
  bool _validateSettings() {
    final errors = <String>[];

    // Contact email validation
    if (_contactEmailCtrl.text.trim().isEmpty) {
      errors.add('Contact email is required');
    } else if (!RegExp(
      r'^[^@]+@[^@]+\.[^@]+$',
    ).hasMatch(_contactEmailCtrl.text.trim())) {
      errors.add('Contact email is invalid');
    }

    // Session timeout validation
    if (_sessionTimeoutCtrl.text.trim().isEmpty) {
      errors.add('Session timeout is required');
    } else if (int.tryParse(_sessionTimeoutCtrl.text) == null) {
      errors.add('Session timeout must be a number');
    } else if (int.parse(_sessionTimeoutCtrl.text) < 1 ||
        int.parse(_sessionTimeoutCtrl.text) > 1440) {
      errors.add('Session timeout must be between 1 and 1440 minutes');
    }

    // GPS deviation radius validation
    if (_gpsDeviationRadiusCtrl.text.trim().isEmpty) {
      errors.add('GPS deviation radius is required');
    } else if (int.tryParse(_gpsDeviationRadiusCtrl.text) == null) {
      errors.add('GPS deviation radius must be a number');
    } else if (int.parse(_gpsDeviationRadiusCtrl.text) < 1) {
      errors.add('GPS deviation radius must be greater than 0');
    }

    // GPS sync interval validation
    if (_gpsSyncIntervalCtrl.text.trim().isEmpty) {
      errors.add('GPS sync interval is required');
    } else if (int.tryParse(_gpsSyncIntervalCtrl.text) == null) {
      errors.add('GPS sync interval must be a number');
    } else if (int.parse(_gpsSyncIntervalCtrl.text) < 1) {
      errors.add('GPS sync interval must be greater than 0');
    }

    // SMTP validation (if SMTP is being configured)
    if (_smtpHostCtrl.text.trim().isNotEmpty) {
      if (_smtpPortCtrl.text.trim().isEmpty) {
        errors.add('SMTP port is required if SMTP host is provided');
      } else if (int.tryParse(_smtpPortCtrl.text) == null) {
        errors.add('SMTP port must be a number');
      }

      if (_senderEmailCtrl.text.trim().isEmpty) {
        errors.add('Sender email is required if SMTP is configured');
      } else if (!RegExp(
        r'^[^@]+@[^@]+\.[^@]+$',
      ).hasMatch(_senderEmailCtrl.text.trim())) {
        errors.add('Sender email is invalid');
      }
    }

    // Min password length validation
    if (_minPasswordLengthCtrl.text.trim().isEmpty) {
      errors.add('Minimum password length is required');
    } else if (int.tryParse(_minPasswordLengthCtrl.text) == null) {
      errors.add('Minimum password length must be a number');
    } else if (int.parse(_minPasswordLengthCtrl.text) < 6 ||
        int.parse(_minPasswordLengthCtrl.text) > 128) {
      errors.add('Minimum password length must be between 6 and 128');
    }

    // Backup frequency validation
    if (_backupFrequencyCtrl.text.trim().isEmpty) {
      errors.add('Backup frequency is required');
    } else if (int.tryParse(_backupFrequencyCtrl.text) == null) {
      errors.add('Backup frequency must be a number');
    } else if (int.parse(_backupFrequencyCtrl.text) < 1) {
      errors.add('Backup frequency must be at least 1 hour');
    }

    if (errors.isNotEmpty) {
      ToastService.showError(errors.join('\n'));
      return false;
    }
    return true;
  }

  Future<void> _saveSettings() async {
    if (!_validateSettings()) {
      return;
    }

    // Check if sensitive settings are being changed
    final settingsAsync = ref.watch(settingsProvider);
    final isSensitiveChange =
        settingsAsync
            .whenData((currentSettings) {
              final newSettings = _collectSettings();
              return currentSettings.smtpHost != newSettings.smtpHost ||
                  currentSettings.smtpPort != newSettings.smtpPort ||
                  currentSettings.smtpPassword != newSettings.smtpPassword ||
                  currentSettings.s3BucketUri != newSettings.s3BucketUri ||
                  currentSettings.ssoEnabled != newSettings.ssoEnabled ||
                  currentSettings.twoFAEnabled != newSettings.twoFAEnabled;
            })
            .asData
            ?.value ??
        false;

    // If sensitive settings are being changed, require password confirmation
    if (isSensitiveChange) {
      final passwordCtrl = TextEditingController();
      final confirmed =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirm Sensitive Changes'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'You are making changes to sensitive system settings. Please enter your admin password to confirm.',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Admin Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1BA654),
                  ),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirmed || passwordCtrl.text.isEmpty) {
        passwordCtrl.dispose();
        return;
      }
      passwordCtrl.dispose();
    }

    setState(() => _isSaving = true);
    try {
      final settings = _collectSettings();
      await ApiClient().dio.put('/admin/settings', data: settings.toJson());
      ref.invalidate(settingsProvider);
      ToastService.showSuccess('Settings saved successfully.');
    } catch (e) {
      ToastService.showError('Failed to save settings.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _runManualBackup() async {
    setState(() => _isBackingUp = true);
    try {
      await ApiClient().dio.post('/admin/settings/backup');
      ToastService.showSuccess('Manual backup initiated successfully.');
    } catch (e) {
      ToastService.showError('Failed to initiate backup.');
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      data: (settings) {
        // Populate controllers on first load
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _populateFromSettings(settings);
        });

        return _buildSettingsUI();
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF169B45)),
      ),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIcons.warning(),
                size: 48,
                color: const Color(0xFFEF4444),
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load settings',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Color(0xFFEF4444),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ErrorHandler.getFriendlyErrorMessage(err),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF6B7280),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(settingsProvider),
                icon: Icon(PhosphorIcons.arrowsClockwise(), size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF169B45),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsUI() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'System Settings',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveSettings,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(PhosphorIcons.floppyDisk(), size: 18),
                label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF169B45),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Settings Sidebar
                Container(
                  width: 280,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    itemCount: _sections.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedIndex == index;
                      return InkWell(
                        onTap: () => setState(() => _selectedIndex = index),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF169B45)
                                    : Colors.transparent,
                                width: 4,
                              ),
                            ),
                            color: isSelected
                                ? const Color(0xFFF3F4F6)
                                : Colors.transparent,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Text(
                            _sections[index],
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF169B45)
                                  : const Color(0xFF4B5563),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 24),
                // Settings Content
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(child: _buildSectionContent()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildGeneralSettings();
      case 1:
        return _buildAuthenticationSettings();
      case 2:
        return _buildGpsSettings();
      case 3:
        return _buildEmailSettings();
      case 4:
        return _buildBackupSettings();
      case 5:
        return _buildSecuritySettings();
      case 6:
        return _buildIntegrationSettings();
      default:
        return Center(
          child: Text(
            '${_sections[_selectedIndex]} configuration goes here.',
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF6B7280),
            ),
          ),
        );
    }
  }

  // ==========================================
  // SECTION BUILDERS
  // ==========================================

  Widget _buildGeneralSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'General Settings',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 32),
        _buildTextField('University Name', _universityNameCtrl),
        const SizedBox(height: 24),
        _buildTextField('System Administrator Name', _systemAdminCtrl),
        const SizedBox(height: 24),
        _buildTextField('Contact Email', _contactEmailCtrl),
      ],
    );
  }

  Widget _buildAuthenticationSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Authentication',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 32),
        _buildTextField('Session Timeout (Minutes)', _sessionTimeoutCtrl),
        const SizedBox(height: 32),
        _buildSwitchRow('Enable Single Sign-On (SSO)', _ssoEnabled, (val) {
          setState(() => _ssoEnabled = val);
        }),
        const SizedBox(height: 24),
        _buildSwitchRow(
          'Enforce Two-Factor Authentication (2FA) for Supervisors',
          _twoFAEnabled,
          (val) {
            setState(() => _twoFAEnabled = val);
          },
        ),
      ],
    );
  }

  Widget _buildGpsSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GPS Tracking Settings',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 32),
        _buildTextField(
          'Allowed Deviation Radius (Meters)',
          _gpsDeviationRadiusCtrl,
        ),
        const SizedBox(height: 24),
        _buildTextField('Sync Interval (Minutes)', _gpsSyncIntervalCtrl),
        const SizedBox(height: 32),
        _buildSwitchRow('Enable strict boundary enforcement', _strictBounds, (
          val,
        ) {
          setState(() => _strictBounds = val);
        }),
      ],
    );
  }

  Widget _buildEmailSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email Configuration',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 32),
        _buildTextField('SMTP Host', _smtpHostCtrl),
        const SizedBox(height: 24),
        _buildTextField('SMTP Port', _smtpPortCtrl),
        const SizedBox(height: 24),
        _buildTextField('Sender Email Address', _senderEmailCtrl),
        const SizedBox(height: 24),
        _buildTextField('SMTP Password', _smtpPasswordCtrl, isPassword: true),
      ],
    );
  }

  Widget _buildBackupSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'System Backups',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 32),
        _buildTextField('AWS S3 Bucket URI', _s3BucketUriCtrl),
        const SizedBox(height: 24),
        _buildTextField('Backup Frequency (Days)', _backupFrequencyCtrl),
        const SizedBox(height: 32),
        _buildSwitchRow('Enable Automated Backups', _autoBackup, (val) {
          setState(() => _autoBackup = val);
        }),
        const SizedBox(height: 32),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _isBackingUp ? null : _runManualBackup,
            icon: _isBackingUp
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(PhosphorIcons.downloadSimple(), size: 18),
            label: Text(
              _isBackingUp ? 'Backing up...' : 'Run Manual Backup Now',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF169B45),
              side: const BorderSide(color: Color(0xFF169B45), width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Security Policies',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 32),
        _buildTextField('Minimum Password Length', _minPasswordLengthCtrl),
        const SizedBox(height: 24),
        _buildTextField(
          'Max Failed Login Attempts (Lockout)',
          _maxLoginAttemptsCtrl,
        ),
        const SizedBox(height: 32),
        _buildSwitchRow('Require Alphanumeric Passwords', _alphaPass, (val) {
          setState(() => _alphaPass = val);
        }),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 32),
        const Text(
          'Danger Zone',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFFEF4444),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Once you delete your admin account, there is no going back.',
          style: TextStyle(fontFamily: 'Inter', color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _handleDeleteAccount,
          icon: const Icon(PhosphorIconsRegular.trash, size: 20),
          label: const Text('Delete Account'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIntegrationSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'External Integrations',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 32),
        _buildTextField('Slack Webhook URL', _slackWebhookCtrl),
        const SizedBox(height: 24),
        _buildTextField(
          'Google Maps API Key',
          _googleMapsKeyCtrl,
          isPassword: true,
        ),
        const SizedBox(height: 32),
        _buildSwitchRow('Enable Third-Party Webhook Sync', _webhookSync, (val) {
          setState(() => _webhookSync = val);
        }),
      ],
    );
  }

  // ==========================================
  // REUSABLE UI COMPONENTS
  // ==========================================

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF111827),
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: const BorderSide(
                  color: Color(0xFF169B45),
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchRow(
    String label,
    bool value,
    void Function(bool) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Color(0xFF4B5563),
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF169B45),
        ),
      ],
    );
  }
}
