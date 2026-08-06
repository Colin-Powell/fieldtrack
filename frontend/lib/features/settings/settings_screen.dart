import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:convert';
import 'package:fieldtrack/core/network/api_client.dart';
import 'package:fieldtrack/features/auth/login_screen.dart';
import 'package:fieldtrack/core/network/error_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldtrack/core/providers/auth_provider.dart';

// --- Theme Colors ---
const Color _lightGreen = Color(0xFFCDE8D5);
const Color _primaryGreen = Color(0xFF1B934F);
const Color _textDark = Color(0xFF333333);
const Color _textLight = Color(0xFF88929A);
const Color _dangerRed = Color(0xFFE53935);
const Color _cardBorder = Color(0xFFF0F0F0);
const String _fontFamily = 'Roboto';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // --- API State ---
  bool _isLoading = true;
  bool _isDarkMode = false;
  bool _isOfflineSyncEnabled = true;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _preferences;
  Map<String, dynamic>? _helpInfo;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    Map<String, dynamic> helpInfo = {};

    try {
      final helpRes = await ApiClient().dio.get('/settings/info');
      helpInfo = helpRes.data['info'] as Map<String, dynamic>? ?? {};
    } catch (_) {
      // Ignore help info failures and continue loading profile data.
    }

    try {
      final res = await ApiClient().dio.get('/settings/profile');
      final p = res.data['profile'] as Map<String, dynamic>? ?? {};
      final prefs = (p['preferences'] ?? {}) as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          _profile = p;
          _preferences = prefs;
          _helpInfo = helpInfo;
          _isDarkMode = prefs['prefTheme'] == 'Dark';
          _isOfflineSyncEnabled = prefs['chanInApp'] ?? true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _helpInfo = helpInfo;
          _isLoading = false;
        });
    }
  }

  Future<void> _updatePreferences(Map<String, dynamic> data) async {
    try {
      await ApiClient().dio.put('/settings/preferences', data: data);
      await _loadSettings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to update settings',
              style: TextStyle(fontFamily: _fontFamily),
            ),
          ),
        );
      }
    }
  }

  // Log out the current user and return to the login screen.
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Logout',
          style: TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to log out of FieldTrack?',
          style: TextStyle(fontFamily: _fontFamily),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _textLight, fontFamily: _fontFamily),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiClient().dio.post('/auth/logout');
              } catch (_) {}
              ref.read(authProvider.notifier).logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _dangerRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white, fontFamily: _fontFamily),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Custom Header ---
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: _lightGreen,
                          shape: BoxShape.circle,
                        ),
                        child: PhosphorIcon(
                          PhosphorIcons.caretLeft(),
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _lightGreen,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text(
                      'Settings',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              if (_profile != null) ...[
                const Text(
                  'Account',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _primaryGreen,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _cardBorder, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _profile?['name'] as String? ?? 'Student',
                        style: const TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _profile?['email'] as String? ?? '',
                        style: const TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 14,
                          color: _textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // --- App Settings Section ---
              const Text(
                'App Settings',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primaryGreen,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: _cardBorder, width: 1.5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        _SettingsItem(
                          icon: PhosphorIcons.bell(),
                          title: 'Notifications',
                          subtitle: 'Manage your notification preferences',
                          trailing: _TrailingCaret(),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const SettingsNotificationsScreen(),
                            ),
                          ),
                        ),
                        _SettingsItem(
                          icon: PhosphorIcons.cloud(),
                          title: 'Offline Sync',
                          subtitle: 'Sync data when connection is available',
                          trailing: _TrailingTextWithCaret(
                            text: _isOfflineSyncEnabled ? 'On' : 'Off',
                            textColor: _isOfflineSyncEnabled
                                ? _primaryGreen
                                : _textLight,
                          ),
                          onTap: () async {
                            final result = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OfflineSyncScreen(
                                  initialValue: _isOfflineSyncEnabled,
                                ),
                              ),
                            );
                            if (result != null) {
                              setState(() => _isOfflineSyncEnabled = result);
                              await _updatePreferences({'chanInApp': result});
                            }
                          },
                        ),
                        _SettingsItem(
                          icon: PhosphorIcons.slidersHorizontal(),
                          title: 'Preferences',
                          subtitle:
                              'Manage dashboard, date, and export settings',
                          trailing: _TrailingCaret(),
                          onTap: () async {
                            final result = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SettingsPreferencesScreen(
                                  initialPrefs: _preferences ?? {},
                                ),
                              ),
                            );
                            if (result == true) {
                              await _loadSettings();
                            }
                          },
                        ),
                        _SettingsItem(
                          icon: PhosphorIcons.moon(),
                          title: 'Dark Mode',
                          subtitle: 'Switch between light and dark theme',
                          trailing: CupertinoSwitch(
                            value: _isDarkMode,
                            activeTrackColor: _primaryGreen,
                            onChanged: (bool value) {
                              setState(() => _isDarkMode = value);
                              _updatePreferences({
                                'prefTheme': value ? 'Dark' : 'Light',
                              });
                            },
                          ),
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // --- Support & Information Section ---
              const Text(
                'Support & Information',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primaryGreen,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: _cardBorder, width: 1.5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        _SettingsItem(
                          icon: PhosphorIcons.headset(),
                          title: 'Help & Support',
                          subtitle: 'Get help and contact support',
                          trailing: _TrailingCaret(),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  HelpSupportScreen(helpInfo: _helpInfo ?? {}),
                            ),
                          ),
                        ),
                        _SettingsItem(
                          icon: PhosphorIcons.shieldCheck(),
                          title: 'Privacy Policy',
                          subtitle: 'Read our privacy policy',
                          trailing: _TrailingCaret(),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PrivacyPolicyScreen(
                                privacyPolicy:
                                    _helpInfo?['privacyPolicy'] as String?,
                              ),
                            ),
                          ),
                        ),
                        _SettingsItem(
                          icon: PhosphorIcons.info(),
                          title: 'About FieldTrack',
                          subtitle: 'Learn more about the application',
                          trailing: _TrailingCaret(),
                          isLast: true,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AboutScreen(
                                aboutInfo:
                                    _helpInfo?['about']
                                        as Map<String, dynamic>?,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // --- Logout Button ---
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _handleLogout,
                  icon: PhosphorIcon(
                    PhosphorIcons.signOut(),
                    color: _dangerRed,
                    size: 24,
                  ),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _dangerRed,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _dangerRed.withOpacity(0.2),
                      width: 1.5,
                    ),
                    backgroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// HELPER WIDGETS
// ============================================================================

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final bool isLast;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: isLast ? 20 : 0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            PhosphorIcon(icon, size: 28, color: Colors.black),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 13,
                      color: _textLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _TrailingCaret extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PhosphorIcon(
      PhosphorIcons.caretRight(),
      color: Colors.grey.shade600,
      size: 20,
    );
  }
}

class _TrailingTextWithCaret extends StatelessWidget {
  final String text;
  final Color textColor;

  const _TrailingTextWithCaret({required this.text, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(width: 4),
        PhosphorIcon(
          PhosphorIcons.caretRight(),
          color: Colors.grey.shade600,
          size: 20,
        ),
      ],
    );
  }
}

class _GenericAppbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const _GenericAppbar({required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.black),
      centerTitle: true,
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: _fontFamily,
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// ============================================================================
// HELPER SCREENS
// ============================================================================

class SettingsNotificationsScreen extends StatefulWidget {
  const SettingsNotificationsScreen({super.key});
  @override
  State<SettingsNotificationsScreen> createState() =>
      _SettingsNotificationsScreenState();
}

class _SettingsNotificationsScreenState
    extends State<SettingsNotificationsScreen> {
  bool push = true;
  bool email = false;
  bool dataAlerts = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final res = await ApiClient().dio.get('/settings/profile');
      final p = res.data['profile'];
      final prefs = p['preferences'] ?? {};
      if (mounted) {
        setState(() {
          push = prefs['chanInApp'] ?? true;
          email = prefs['chanEmail'] ?? false;
          dataAlerts = prefs['notifAnnouncements'] ?? true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePrefs() async {
    try {
      await ApiClient().dio.put(
        '/settings/preferences',
        data: {
          'chanInApp': push,
          'chanEmail': email,
          'notifAnnouncements': dataAlerts,
        },
      );
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const _GenericAppbar(title: 'Notifications'),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          SwitchListTile(
            activeThumbColor: _primaryGreen,
            title: const Text(
              'Push Notifications',
              style: TextStyle(
                fontFamily: _fontFamily,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              'Receive alerts on your device',
              style: TextStyle(fontFamily: _fontFamily),
            ),
            value: push,
            onChanged: (v) {
              setState(() => push = v);
              _savePrefs();
            },
          ),
          SwitchListTile(
            activeThumbColor: _primaryGreen,
            title: const Text(
              'Email Summaries',
              style: TextStyle(
                fontFamily: _fontFamily,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              'Weekly report of your activities',
              style: TextStyle(fontFamily: _fontFamily),
            ),
            value: email,
            onChanged: (v) {
              setState(() => email = v);
              _savePrefs();
            },
          ),
          SwitchListTile(
            activeThumbColor: _primaryGreen,
            title: const Text(
              'Data Upload Alerts',
              style: TextStyle(
                fontFamily: _fontFamily,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              'Notify when pending data is synced',
              style: TextStyle(fontFamily: _fontFamily),
            ),
            value: dataAlerts,
            onChanged: (v) {
              setState(() => dataAlerts = v);
              _savePrefs();
            },
          ),
        ],
      ),
    );
  }
}

class OfflineSyncScreen extends StatefulWidget {
  final bool initialValue;
  const OfflineSyncScreen({super.key, required this.initialValue});
  @override
  State<OfflineSyncScreen> createState() => _OfflineSyncScreenState();
}

class _OfflineSyncScreenState extends State<OfflineSyncScreen> {
  late bool isEnabled;

  @override
  void initState() {
    super.initState();
    isEnabled = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => Navigator.pop(context, isEnabled),
        ), // Return updated state
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Offline Sync',
          style: TextStyle(
            fontFamily: _fontFamily,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Background Synchronization',
              style: TextStyle(
                fontFamily: _fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'When enabled, FieldTrack will automatically upload your saved field entries as soon as your device reconnects to a stable internet connection.',
              style: TextStyle(
                fontFamily: _fontFamily,
                color: _textLight,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: _cardBorder, width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: SwitchListTile(
                activeThumbColor: _primaryGreen,
                title: const Text(
                  'Enable Offline Sync',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                value: isEnabled,
                onChanged: (v) {
                  setState(() => isEnabled = v);
                  // TODO: Save to SharedPreferences/API
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPreferencesScreen extends StatefulWidget {
  final Map<String, dynamic> initialPrefs;
  const SettingsPreferencesScreen({super.key, required this.initialPrefs});

  @override
  State<SettingsPreferencesScreen> createState() =>
      _SettingsPreferencesScreenState();
}

class _SettingsPreferencesScreenState extends State<SettingsPreferencesScreen> {
  late String _prefDashboard;
  late String _prefZoom;
  late String _prefDateFormat;
  late String _prefLanguage;
  late bool _exportPdf;
  late bool _exportExcel;
  late bool _exportCsv;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final prefs = widget.initialPrefs;
    _prefDashboard = prefs['prefDashboard'] ?? 'Overview';
    _prefZoom = prefs['prefZoom'] ?? 'City';
    _prefDateFormat = prefs['prefDateFormat'] ?? 'DD/MM/YYYY';
    _prefLanguage = prefs['prefLanguage'] ?? 'English';
    _exportPdf = prefs['exportPdf'] ?? true;
    _exportExcel = prefs['exportExcel'] ?? false;
    _exportCsv = prefs['exportCsv'] ?? true;
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);

    try {
      await ApiClient().dio.put(
        '/settings/preferences',
        data: {
          'prefDashboard': _prefDashboard,
          'prefZoom': _prefZoom,
          'prefDateFormat': _prefDateFormat,
          'prefLanguage': _prefLanguage,
          'exportPdf': _exportPdf,
          'exportExcel': _exportExcel,
          'exportCsv': _exportCsv,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Preferences updated successfully',
              style: TextStyle(fontFamily: _fontFamily),
            ),
            backgroundColor: _primaryGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to save preferences',
              style: TextStyle(fontFamily: _fontFamily),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildDropdownField(
    String label,
    List<String> options,
    String currentValue,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: _fontFamily,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: _cardBorder, width: 1.5),
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: DropdownButton<String>(
              value: currentValue,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: options
                  .map(
                    (option) =>
                        DropdownMenuItem(value: option, child: Text(option)),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const _GenericAppbar(title: 'Preferences'),
      body: ListView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildDropdownField(
            'Default Dashboard',
            const ['Overview', 'Map', 'Activities'],
            _prefDashboard,
            (v) {
              if (v != null) setState(() => _prefDashboard = v);
            },
          ),
          _buildDropdownField(
            'Map Zoom Level',
            const ['City', 'Region', 'Country'],
            _prefZoom,
            (v) {
              if (v != null) setState(() => _prefZoom = v);
            },
          ),
          _buildDropdownField(
            'Date Format',
            const ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'],
            _prefDateFormat,
            (v) {
              if (v != null) setState(() => _prefDateFormat = v);
            },
          ),
          _buildDropdownField(
            'Language',
            const ['English', 'Swahili'],
            _prefLanguage,
            (v) {
              if (v != null) setState(() => _prefLanguage = v);
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Export Options',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            activeColor: _primaryGreen,
            value: _exportPdf,
            title: const Text('PDF Export'),
            subtitle: const Text('Include PDF when exporting reports'),
            onChanged: (value) {
              if (value != null) setState(() => _exportPdf = value);
            },
          ),
          CheckboxListTile(
            activeColor: _primaryGreen,
            value: _exportExcel,
            title: const Text('Excel Export'),
            subtitle: const Text('Include Excel when exporting reports'),
            onChanged: (value) {
              if (value != null) setState(() => _exportExcel = value);
            },
          ),
          CheckboxListTile(
            activeColor: _primaryGreen,
            value: _exportCsv,
            title: const Text('CSV Export'),
            subtitle: const Text('Include CSV when exporting reports'),
            onChanged: (value) {
              if (value != null) setState(() => _exportCsv = value);
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _savePreferences,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Save Preferences',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class HelpSupportScreen extends StatefulWidget {
  final Map<String, dynamic> helpInfo;
  const HelpSupportScreen({super.key, required this.helpInfo});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  String _category = 'bug_report';
  String _title = '';
  String _description = '';
  String _severity = 'medium';
  String _email = '';
  bool _isSubmitting = false;

  Future<void> _submitSupportRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await ApiClient().dio.post(
        '/developer/support-request',
        data: {
          'category': _category,
          'title': _title.trim(),
          'description': _description.trim(),
          'contactEmail': _email.trim(),
          'severity': _severity,
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Support request submitted successfully.'),
        ),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to submit support request.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final faqs =
        (widget.helpInfo['faqs'] as List<dynamic>?)
            ?.map((item) => item as Map<String, dynamic>)
            .toList() ??
        [
          {
            'question': 'How do I capture a new field entry?',
            'answer':
                'Navigate to the Home screen and tap the large + button. Make sure your GPS is turned on.',
          },
          {
            'question': 'Why is my data not syncing?',
            'answer':
                'Ensure you have an active internet connection and that Offline Sync is enabled in settings.',
          },
        ];
    final supportEmail =
        widget.helpInfo['supportEmail'] as String? ?? 'support@fieldtrack.com';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const _GenericAppbar(title: 'Help & Support'),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _primaryGreen,
            ),
          ),
          const SizedBox(height: 16),
          ...faqs.map(
            (faq) => _buildFaqItem(
              faq['question'] as String? ?? '',
              faq['answer'] as String? ?? '',
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Contact Us',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _primaryGreen,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: _lightGreen,
              child: Icon(Icons.email, color: _primaryGreen),
            ),
            title: const Text(
              'Email Support',
              style: TextStyle(
                fontFamily: _fontFamily,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              supportEmail,
              style: const TextStyle(fontFamily: _fontFamily),
            ),
            onTap: () {
              // TODO: launchUrl to email client
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Send a Help Request',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _primaryGreen,
            ),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Request type'),
                  items: const [
                    DropdownMenuItem(
                      value: 'bug_report',
                      child: Text('Bug report'),
                    ),
                    DropdownMenuItem(
                      value: 'feature_request',
                      child: Text('Feature request'),
                    ),
                    DropdownMenuItem(
                      value: 'support',
                      child: Text('Support request'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _category = value ?? 'bug_report'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter a title'
                      : null,
                  onChanged: (value) => _title = value,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) => _email = value,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _severity,
                  decoration: const InputDecoration(labelText: 'Severity'),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                  ],
                  onChanged: (value) =>
                      setState(() => _severity = value ?? 'medium'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Describe the issue',
                  ),
                  maxLines: 4,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please describe the issue'
                      : null,
                  onChanged: (value) => _description = value,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitSupportRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Submit request'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String q, String a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ExpansionTile(
        title: Text(
          q,
          style: const TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w600,
            color: _textDark,
          ),
        ),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        children: [
          Text(
            a,
            style: const TextStyle(fontFamily: _fontFamily, color: _textLight),
          ),
        ],
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  final String? privacyPolicy;
  const PrivacyPolicyScreen({super.key, this.privacyPolicy});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const _GenericAppbar(title: 'Privacy Policy'),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Text(
          privacyPolicy ??
              "FieldTrack Privacy Policy\n\nLast Updated: October 2024\n\n1. Information Collection\nWe collect location data and field metrics you input to assist in environmental research. Your personal information (Name, ID, Email) is used strictly for authentication and academic tracking.\n\n2. Data Usage\nAll geographic and analytical data collected is synced to university servers and may be used in aggregated research studies. Individual user tracking is kept confidential.\n\n3. Offline Data\nData stored locally on your device remains encrypted until a secure connection is established for syncing.\n\n(This is a sample privacy policy for demonstration purposes. In a real application, place your full legal terms here.)",
          style: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15,
            color: _textDark,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  final Map<String, dynamic>? aboutInfo;
  const AboutScreen({super.key, this.aboutInfo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const _GenericAppbar(title: 'About'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Image.asset(
                'lib/assets/Images/notification.png',
                width: 64,
                height: 64,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              aboutInfo?['title'] as String? ?? 'FieldTrack',
              style: const TextStyle(
                fontFamily: _fontFamily,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _primaryGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              aboutInfo?['version'] as String? ?? 'Version 1.0.0 (Build 42)',
              style: const TextStyle(
                fontFamily: _fontFamily,
                color: _textLight,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              aboutInfo?['description'] as String? ??
                  'Developed for\nPwani University, Environmental Sciences',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: _fontFamily,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
