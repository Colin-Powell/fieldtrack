import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fieldtrack/core/network/api_client.dart';
import 'package:fieldtrack/features/auth/login_screen.dart';
import 'package:fieldtrack/core/network/error_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldtrack/core/providers/auth_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:fieldtrack/core/services/version_check_service.dart';
import 'package:fieldtrack/shared/widgets/update_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fieldtrack/core/theme/theme_provider.dart';

// --- Theme Colors (Base/Light) ---
const Color _lightGreen = Color(0xFFCDE8D5);
const Color _primaryGreen = Color(0xFF1B934F);
const Color _textDark = Color(0xFF333333);
const Color _textLight = Color(0xFF88929A);
const Color _dangerRed = Color(0xFFE53935);
const Color _cardBorder = Color(0xFFF0F0F0);
const String _fontFamily = 'Poppins';

// --- Dark Mode Specific Colors ---
const Color _darkBg = Color(0xFF121212);
const Color _darkSurface = Color(0xFF1E1E1E);
const Color _darkBorder = Color(0xFF333333);
const Color _darkPrimaryText = Color(0xFF4ADE80);
const Color _darkHintText = Color(0xFFA1A1AA);
const Color _darkDangerRed = Color(0xFFFCA5A5);

// --- Standard Button Style (Dynamic) ---
ButtonStyle _buildPrimaryButtonStyle(bool isDark) {
  return ElevatedButton.styleFrom(
    backgroundColor: isDark ? const Color(0xFF14532D) : _primaryGreen,
    foregroundColor: isDark ? _darkPrimaryText : Colors.white,
    elevation: 0,
    minimumSize: const Size(double.infinity, 56),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(40),
    ),
  );
}

// --- Standard Input Decoration (Dynamic) ---
InputDecoration _buildInputDecoration(String label, bool isDark) {
  final bgColor = isDark ? _darkSurface : Colors.white;
  final borderColor = isDark ? _darkBorder : _cardBorder;
  final focusColor = isDark ? _darkPrimaryText : _primaryGreen;
  final hintColor = isDark ? _darkHintText : _textLight;

  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(fontFamily: _fontFamily, color: hintColor),
    filled: true,
    fillColor: bgColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: BorderSide(color: borderColor, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: BorderSide(color: borderColor, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: BorderSide(color: focusColor, width: 1.5),
    ),
  );
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // --- API State ---
  bool _isOfflineSyncEnabled = true;
  Map<String, dynamic>? _profile;
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
    } catch (_) {}

    try {
      final res = await ApiClient().dio.get('/settings/profile');
      final p = res.data['profile'] as Map<String, dynamic>? ?? {};
      final prefs = (p['preferences'] ?? {}) as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          _profile = p;
          _helpInfo = helpInfo;
          _isOfflineSyncEnabled = prefs['chanInApp'] ?? true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _helpInfo = helpInfo;
        });
      }
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

  void _handleLogout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? _darkSurface : Colors.white,
        title: Text(
          'Logout',
          style: TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          'Are you sure you want to log out of FieldTrack?',
          style: TextStyle(
            fontFamily: _fontFamily,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? _darkHintText : _textLight,
                fontFamily: _fontFamily,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              try {
                await ApiClient().dio.post('/auth/logout');
              } catch (_) {}
              ref.read(authProvider.notifier).logout();
              nav.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF450A0A) : _dangerRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
            ),
            child: Text(
              'Logout',
              style: TextStyle(
                color: isDark ? _darkDangerRed : Colors.white,
                fontFamily: _fontFamily,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleDeleteAccount() {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final TextEditingController emailController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final bool isEmailMatch =
              emailController.text.trim().toLowerCase() ==
              user.email.toLowerCase();

          return AlertDialog(
            backgroundColor: isDark ? _darkSurface : Colors.white,
            title: Text(
              'Delete Account',
              style: TextStyle(
                fontFamily: _fontFamily,
                fontWeight: FontWeight.bold,
                color: isDark ? _darkDangerRed : _dangerRed,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete your account? This action cannot be undone.',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Type ${user.email} to confirm:',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontFamily: _fontFamily,
                  ),
                  decoration: _buildInputDecoration('Email address', isDark),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDark ? _darkHintText : _textLight,
                    fontFamily: _fontFamily,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: isEmailMatch
                    ? () async {
                        final nav = Navigator.of(context);
                        final sm = ScaffoldMessenger.of(context);
                        try {
                          await ApiClient().dio.delete('/settings/deactivate');
                          ref.read(authProvider.notifier).logout();
                          if (mounted) {
                            nav.pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            nav.pop();
                            sm.showSnackBar(
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
                  backgroundColor: isDark ? const Color(0xFF450A0A) : _dangerRed,
                  disabledBackgroundColor: isDark
                      ? const Color(0xFF450A0A).withValues(alpha: 0.5)
                      : _dangerRed.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
                child: Text(
                  'Delete Account',
                  style: TextStyle(
                    color: isDark ? _darkDangerRed : Colors.white,
                    fontFamily: _fontFamily,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final bgColor = isDark ? _darkBg : theme.scaffoldBackgroundColor;
    final cardBgColor = isDark ? _darkSurface : Colors.white;
    final borderColor = isDark ? _darkBorder : _cardBorder;
    final headerBgColor = isDark ? const Color(0xFF14532D) : _lightGreen;
    final headerTextColor = isDark ? _darkPrimaryText : Colors.black;
    final sectionTitleColor = isDark ? _darkPrimaryText : _primaryGreen;

    return Scaffold(
      backgroundColor: bgColor,
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
                        decoration: BoxDecoration(
                          color: headerBgColor,
                          shape: BoxShape.circle,
                        ),
                        child: PhosphorIcon(
                          PhosphorIcons.caretLeft(),
                          color: headerTextColor,
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
                      color: headerBgColor,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: headerTextColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              if (_profile != null) ...[
                Text(
                  'Account',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: sectionTitleColor,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _profile?['name'] as String? ?? 'Student',
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : _textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _profile?['email'] as String? ?? '',
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 14,
                          color: isDark ? _darkHintText : _textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // --- App Settings Section ---
              Text(
                'App Settings',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: sectionTitleColor,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: cardBgColor,
                  border: Border.all(color: borderColor, width: 1.5),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
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
                              builder: (_) => const SettingsNotificationsScreen(),
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
                                ? (isDark ? _darkPrimaryText : _primaryGreen)
                                : (isDark ? _darkHintText : _textLight),
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
                        Consumer(
                          builder: (context, ref, _) {
                            final currentTheme = ref.watch(themeModeProvider);
                            final isCurrentlyDark =
                                currentTheme == ThemeMode.dark ||
                                (currentTheme == ThemeMode.system &&
                                    MediaQuery.platformBrightnessOf(context) ==
                                        Brightness.dark);
                            final subtitleText =
                                currentTheme == ThemeMode.system
                                ? 'System default (${isCurrentlyDark ? "Dark" : "Light"})'
                                : (currentTheme == ThemeMode.dark
                                      ? 'Dark'
                                      : 'Light');

                            return _SettingsItem(
                              icon: isCurrentlyDark
                                  ? PhosphorIcons.moon()
                                  : PhosphorIcons.sun(),
                              title: 'Appearance',
                              subtitle: subtitleText,
                              trailing: _TrailingTextWithCaret(
                                text: currentTheme == ThemeMode.system
                                    ? 'System'
                                    : (currentTheme == ThemeMode.dark
                                          ? 'Dark'
                                          : 'Light'),
                                textColor: isDark ? _darkPrimaryText : _primaryGreen,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AppearanceScreen(),
                                  ),
                                );
                              },
                              isLast: true,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // --- Support & Information Section ---
              Text(
                'Support & Information',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: sectionTitleColor,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: cardBgColor,
                  border: Border.all(color: borderColor, width: 1.5),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
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
                    color: isDark ? _darkDangerRed : _dangerRed,
                    size: 24,
                  ),
                  label: Text(
                    'Logout',
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? _darkDangerRed : _dangerRed,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isDark 
                          ? _darkDangerRed.withValues(alpha: 0.3) 
                          : _dangerRed.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    backgroundColor: isDark ? const Color(0xFF450A0A) : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // --- Delete Account Button ---
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton.icon(
                  onPressed: _handleDeleteAccount,
                  icon: PhosphorIcon(
                    PhosphorIcons.trash(),
                    color: isDark ? _darkDangerRed : _dangerRed,
                    size: 24,
                  ),
                  label: Text(
                    'Delete Account',
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? _darkDangerRed : _dangerRed,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : _textDark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: isLast ? 24 : 0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            PhosphorIcon(icon, size: 28, color: textColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 13,
                      color: isDark ? _darkHintText : _textLight,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PhosphorIcon(
      PhosphorIcons.caretRight(),
      color: isDark ? _darkHintText : Colors.grey.shade600,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          color: isDark ? _darkHintText : Colors.grey.shade600,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? _darkBg : theme.scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : _textDark;

    return AppBar(
      backgroundColor: bgColor,
      elevation: 0,
      iconTheme: IconThemeData(color: textColor),
      centerTitle: true,
      title: Text(
        title,
        style: TextStyle(
          fontFamily: _fontFamily,
          color: textColor,
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

  Widget _buildSwitchRow(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: isLast ? 24 : 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 13,
                    color: isDark ? _darkHintText : _textLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CupertinoSwitch(
            value: value,
            activeTrackColor: isDark ? _darkPrimaryText : _primaryGreen,
            thumbColor: Colors.white,
            trackColor: isDark ? const Color(0xFF333333) : CupertinoColors.systemFill,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? _darkBg : Colors.white,
      appBar: const _GenericAppbar(title: 'Notifications'),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: isDark ? _darkPrimaryText : _primaryGreen,
              ),
            )
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? _darkSurface : Colors.white,
                    border: Border.all(
                      color: isDark ? _darkBorder : _cardBorder,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Column(
                      children: [
                        _buildSwitchRow(
                          'Push Notifications',
                          'Receive alerts on your device',
                          push,
                          (v) {
                            setState(() => push = v);
                            _savePrefs();
                          },
                          isDark,
                        ),
                        _buildSwitchRow(
                          'Email Summaries',
                          'Weekly report of your activities',
                          email,
                          (v) {
                            setState(() => email = v);
                            _savePrefs();
                          },
                          isDark,
                        ),
                        _buildSwitchRow(
                          'Data Upload Alerts',
                          'Notify when pending data is synced',
                          dataAlerts,
                          (v) {
                            setState(() => dataAlerts = v);
                            _savePrefs();
                          },
                          isDark,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? _darkBg : Colors.white,
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.pop(context, isEnabled)),
        backgroundColor: isDark ? _darkBg : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        centerTitle: true,
        title: Text(
          'Offline Sync',
          style: TextStyle(
            fontFamily: _fontFamily,
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Background Synchronization',
              style: TextStyle(
                fontFamily: _fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When enabled, FieldTrack will automatically upload your saved field entries as soon as your device reconnects to a stable internet connection.',
              style: TextStyle(
                fontFamily: _fontFamily,
                color: isDark ? _darkHintText : _textLight,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: isDark ? _darkSurface : Colors.transparent,
                border: Border.all(
                  color: isDark ? _darkBorder : _cardBorder, 
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Enable Offline Sync',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CupertinoSwitch(
                    value: isEnabled,
                    activeTrackColor: isDark ? _darkPrimaryText : _primaryGreen,
                    trackColor: isDark ? const Color(0xFF333333) : CupertinoColors.systemFill,
                    onChanged: (v) {
                      setState(() => isEnabled = v);
                    },
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

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  Widget _buildThemeRadioTile({
    required BuildContext context,
    required WidgetRef ref,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isSelected = currentMode == mode;
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = isDark ? _darkPrimaryText : _primaryGreen;

    final cardBorderColor = isSelected
        ? accentColor
        : (isDark ? _darkBorder : _cardBorder);
    final cardBgColor = isSelected
        ? (isDark
              ? const Color(0xFF14532D).withValues(alpha: 0.25)
              : const Color(0xFFDCFCE7).withValues(alpha: 0.4))
        : (isDark ? _darkSurface : Colors.white);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        ref.read(themeModeProvider.notifier).setThemeMode(mode);
        try {
          ApiClient().dio.put(
            '/settings/preferences',
            data: {
              'prefTheme': mode == ThemeMode.dark
                  ? 'Dark'
                  : (mode == ThemeMode.light ? 'Light' : 'System'),
            },
          );
        } catch (_) {}
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: cardBorderColor,
            width: isSelected ? 2.0 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.15)
                    : (isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? accentColor
                    : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : _textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 13,
                      color: isDark ? _darkHintText : _textLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Radio<ThemeMode>(
              value: mode,
              groupValue: currentMode,
              fillColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? accentColor
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
              onChanged: (newMode) {
                if (newMode != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(newMode);
                  try {
                    ApiClient().dio.put(
                      '/settings/preferences',
                      data: {
                        'prefTheme': newMode == ThemeMode.dark
                            ? 'Dark'
                            : (newMode == ThemeMode.light ? 'Light' : 'System'),
                      },
                    );
                  } catch (_) {}
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: isDark ? _darkBg : theme.scaffoldBackgroundColor,
      appBar: const _GenericAppbar(title: 'Appearance'),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        physics: const BouncingScrollPhysics(),
        children: [
          Text(
            'Theme Preference',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : _textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose how FieldTrack looks to you. Select System Default to automatically match your device settings.',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: 14,
              color: isDark ? _darkHintText : _textLight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          _buildThemeRadioTile(
            context: context,
            ref: ref,
            mode: ThemeMode.system,
            currentMode: currentMode,
            title: 'System Default',
            description:
                'Automatically adjust to your system light or dark settings',
            icon: Icons.brightness_auto,
          ),
          const SizedBox(height: 16),
          _buildThemeRadioTile(
            context: context,
            ref: ref,
            mode: ThemeMode.light,
            currentMode: currentMode,
            title: 'Light Theme',
            description:
                'Bright and clean with white surfaces and crisp contrast',
            icon: Icons.light_mode_outlined,
          ),
          const SizedBox(height: 16),
          _buildThemeRadioTile(
            context: context,
            ref: ref,
            mode: ThemeMode.dark,
            currentMode: currentMode,
            title: 'Dark Theme',
            description: 'Deep contrast surfaces easy on the eyes in low light',
            icon: Icons.dark_mode_outlined,
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
        'developer/support-request',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
        widget.helpInfo['supportEmail'] as String? ?? 'support@fieldtrack.top';

    return Scaffold(
      backgroundColor: isDark ? _darkBg : Colors.white,
      appBar: const _GenericAppbar(title: 'Help & Support'),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? _darkPrimaryText : _primaryGreen,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: isDark ? _darkSurface : Colors.white,
              border: Border.all(
                color: isDark ? _darkBorder : _cardBorder, 
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Column(
                children: faqs
                    .map(
                      (faq) => _buildFaqItem(
                        faq['question'] as String? ?? '',
                        faq['answer'] as String? ?? '',
                        isDark,
                        isLast: faqs.last == faq,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Contact Us',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? _darkPrimaryText : _primaryGreen,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final uri = Uri(
                scheme: 'mailto',
                path: supportEmail,
                query: 'subject=FieldTrack%20Support%20Request',
              );
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            borderRadius: BorderRadius.circular(40),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? _darkSurface : Colors.white,
                border: Border.all(
                  color: isDark ? _darkBorder : _cardBorder, 
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isDark ? const Color(0xFF14532D) : _lightGreen,
                    radius: 24,
                    child: Icon(
                      Icons.email, 
                      color: isDark ? _darkPrimaryText : _primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email Support',
                          style: TextStyle(
                            fontFamily: _fontFamily,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : _textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          supportEmail,
                          style: TextStyle(
                            fontFamily: _fontFamily,
                            color: isDark ? _darkHintText : _textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PhosphorIcon(
                    PhosphorIcons.caretRight(), 
                    color: isDark ? _darkHintText : _textLight,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Send a Help Request',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? _darkPrimaryText : _primaryGreen,
            ),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _category,
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: _buildInputDecoration('Request type', isDark),
                  icon: PhosphorIcon(
                    PhosphorIcons.caretDown(),
                    size: 20,
                    color: isDark ? _darkHintText : _textLight,
                  ),
                  dropdownColor: isDark ? _darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  items: const [
                    DropdownMenuItem(value: 'bug_report', child: Text('Bug report')),
                    DropdownMenuItem(value: 'feature_request', child: Text('Feature request')),
                    DropdownMenuItem(value: 'support', child: Text('Support request')),
                  ],
                  onChanged: (value) =>
                      setState(() => _category = value ?? 'bug_report'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: _buildInputDecoration('Title', isDark),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter a title'
                      : null,
                  onChanged: (value) => _title = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: _buildInputDecoration('Email (optional)', isDark),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) => _email = value,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _severity,
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: _buildInputDecoration('Severity', isDark),
                  icon: PhosphorIcon(
                    PhosphorIcons.caretDown(),
                    size: 20,
                    color: isDark ? _darkHintText : _textLight,
                  ),
                  dropdownColor: isDark ? _darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                  ],
                  onChanged: (value) =>
                      setState(() => _severity = value ?? 'medium'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: _buildInputDecoration('Describe the issue', isDark),
                  maxLines: 4,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please describe the issue'
                      : null,
                  onChanged: (value) => _description = value,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitSupportRequest,
                  style: _buildPrimaryButtonStyle(isDark),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Submit request',
                          style: TextStyle(
                            fontFamily: _fontFamily,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? _darkPrimaryText : Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String q, String a, bool isDark, {bool isLast = false}) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: isDark ? _darkBorder : _cardBorder, 
                  width: 1.5,
                ),
              ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: isDark ? _darkPrimaryText : _primaryGreen,
          collapsedIconColor: isDark ? _darkHintText : _textLight,
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              q,
              style: TextStyle(
                fontFamily: _fontFamily,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : _textDark,
              ),
            ),
          ),
          childrenPadding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 24,
          ),
          children: [
            Text(
              a,
              style: TextStyle(
                fontFamily: _fontFamily,
                color: isDark ? _darkHintText : _textLight,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  final String? privacyPolicy;
  const PrivacyPolicyScreen({super.key, this.privacyPolicy});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? _darkBg : Colors.white,
      appBar: const _GenericAppbar(title: 'Privacy Policy'),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Text(
          privacyPolicy ??
              "FieldTrack Privacy Policy\n\nLast Updated: October 2024\n\n1. Information Collection\nWe collect location data and field metrics you input to assist in environmental research. Your personal information (Name, ID, Email) is used strictly for authentication and academic tracking.\n\n2. Data Usage\nAll geographic and analytical data collected is synced to university servers and may be used in aggregated research studies. Individual user tracking is kept confidential.\n\n3. Offline Data\nData stored locally on your device remains encrypted until a secure connection is established for syncing.\n\n(This is a sample privacy policy for demonstration purposes. In a real application, place your full legal terms here.)",
          style: TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15,
            color: isDark ? Colors.white70 : _textDark,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}

class AboutScreen extends StatefulWidget {
  final Map<String, dynamic>? aboutInfo;
  const AboutScreen({super.key, this.aboutInfo});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _appVersion = 'Loading...';
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion =
            'Version ${packageInfo.version} (Build ${packageInfo.buildNumber})';
      });
    } catch (e) {
      setState(() {
        _appVersion =
            widget.aboutInfo?['version'] as String? ??
            'Version 1.0.0 (Build 42)';
      });
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final versionService = VersionCheckService(ApiClient().dio);
      final versionResult = await versionService.checkVersion();

      if (!mounted) return;

      if (versionResult['updateRequired'] == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => UpdateDialog(
            isRequired: true,
            updateUrl: versionResult['updateUrl'],
          ),
        );
      } else if (versionResult['updateAvailable'] == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => UpdateDialog(
            isRequired: false,
            updateUrl: versionResult['updateUrl'],
          ),
        );
      } else {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'FieldTrack is up to date.',
              style: TextStyle(color: isDark ? _darkPrimaryText : Colors.white),
            ),
            backgroundColor: isDark ? const Color(0xFF14532D) : _primaryGreen,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to check for updates. Please check your connection.',
              style: TextStyle(color: isDark ? _darkDangerRed : Colors.white),
            ),
            backgroundColor: isDark ? const Color(0xFF450A0A) : _dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? _darkBg : Colors.white,
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
              widget.aboutInfo?['title'] as String? ?? 'FieldTrack',
              style: TextStyle(
                fontFamily: _fontFamily,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? _darkPrimaryText : _primaryGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _appVersion,
              style: TextStyle(
                fontFamily: _fontFamily,
                color: isDark ? _darkHintText : _textLight,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              widget.aboutInfo?['description'] as String? ??
                  'Developed for\nPwani University, Environmental Sciences',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: _fontFamily,
                fontSize: 16,
                height: 1.5,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _isChecking ? null : _checkForUpdates,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF14532D) : _primaryGreen,
                foregroundColor: isDark ? _darkPrimaryText : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isChecking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Check for Updates',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}