import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// --- Theme Colors ---
const Color _lightGreen = Color(0xFFCDE8D5); 
const Color _primaryGreen = Color(0xFF1B934F); 
const Color _textDark = Color(0xFF333333); 
const Color _textLight = Color(0xFF88929A); 
const Color _dangerRed = Color(0xFFE53935); 
const Color _cardBorder = Color(0xFFF0F0F0); 
const String _fontFamily = 'Roboto'; 

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // --- Simulated State for API Readiness ---
  bool _isDarkMode = false;
  bool _isOfflineSyncEnabled = true;
  double _downloadedMB = 256.0;
  DateTime _lastSyncTime = DateTime.now().subtract(const Duration(hours: 1));
  bool _isSyncing = false;

  // Simulate an API Sync call
  Future<void> _performManualSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    
    // TODO: Connect to your actual Sync API here
    await Future.delayed(const Duration(seconds: 2)); 
    
    setState(() {
      _lastSyncTime = DateTime.now();
      _isSyncing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sync completed successfully!', style: TextStyle(fontFamily: _fontFamily)),
          backgroundColor: _primaryGreen,
        ),
      );
    }
  }

  // Simulate API logout
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout', style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out of FieldTrack?', style: TextStyle(fontFamily: _fontFamily)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _textLight, fontFamily: _fontFamily)),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Clear local tokens and push replacement to Login Route
              Navigator.pop(context); // Close dialog
              Navigator.of(context).popUntil((route) => route.isFirst); // Go to first screen as fallback
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _dangerRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white, fontFamily: _fontFamily)),
          ),
        ],
      ),
    );
  }

  String _formatSyncTime(DateTime time) {
    final now = DateTime.now();
    final isToday = now.year == time.year && now.month == time.month && now.day == time.day;
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    
    return '${isToday ? "Today" : "${time.day}/${time.month}"}, $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
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
                        child: PhosphorIcon(PhosphorIcons.caretLeft(), color: Colors.black, size: 24),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    decoration: BoxDecoration(color: _lightGreen, borderRadius: BorderRadius.circular(24)),
                    child: const Text(
                      'Settings',
                      style: TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // --- App Settings Section ---
              const Text(
                'App Settings',
                style: TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.bold, color: _primaryGreen),
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
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsNotificationsScreen())),
                        ),
                        _SettingsItem(
                          icon: PhosphorIcons.cloud(),
                          title: 'Offline Sync',
                          subtitle: 'Sync data when connection is available',
                          trailing: _TrailingTextWithCaret(text: _isOfflineSyncEnabled ? 'On' : 'Off', textColor: _isOfflineSyncEnabled ? _primaryGreen : _textLight),
                          onTap: () async {
                            final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => OfflineSyncScreen(initialValue: _isOfflineSyncEnabled)));
                            if (result != null) setState(() => _isOfflineSyncEnabled = result);
                          },
                        ),
                        _SettingsItem(
                          icon: PhosphorIcons.downloadSimple(),
                          title: 'Download Data',
                          subtitle: 'Manage offline downloaded files',
                          trailing: _TrailingTextWithCaret(text: '${_downloadedMB.toStringAsFixed(0)} MB', textColor: _primaryGreen),
                          onTap: () async {
                            final result = await Navigator.push<double>(context, MaterialPageRoute(builder: (_) => DownloadDataScreen(currentSize: _downloadedMB)));
                            if (result != null) setState(() => _downloadedMB = result);
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
                              // TODO: Connect to ThemeProvider / SharedPreferences API
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
                style: TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.bold, color: _primaryGreen),
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
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
                        ),
                        _SettingsItem(
                          icon: PhosphorIcons.shieldCheck(),
                          title: 'Privacy Policy',
                          subtitle: 'Read our privacy policy',
                          trailing: _TrailingCaret(),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                        ),
                        _SettingsItem(
                          icon: PhosphorIcons.info(),
                          title: 'About FieldTrack',
                          subtitle: 'Learn more about the application',
                          trailing: _TrailingCaret(),
                          isLast: true,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // --- Last Sync Card ---
              GestureDetector(
                onTap: _performManualSync,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(color: _lightGreen, borderRadius: BorderRadius.circular(24)),
                  child: Row(
                    children: [
                      _isSyncing
                          ? const SizedBox(
                              width: 28, height: 28,
                              child: CircularProgressIndicator(color: _primaryGreen, strokeWidth: 2.5),
                            )
                          : PhosphorIcon(PhosphorIcons.clock(), size: 28, color: Colors.black),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Last Sync',
                              style: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isSyncing ? 'Syncing now...' : 'Successfully synced',
                              style: const TextStyle(fontFamily: _fontFamily, fontSize: 14, color: _textLight),
                            ),
                          ],
                        ),
                      ),
                      if (!_isSyncing)
                        Row(
                          children: [
                            Text(
                              _formatSyncTime(_lastSyncTime),
                              style: const TextStyle(fontFamily: _fontFamily, fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
                            ),
                            const SizedBox(width: 6),
                            PhosphorIcon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), color: _primaryGreen, size: 18),
                            const SizedBox(width: 8),
                            PhosphorIcon(PhosphorIcons.caretRight(), color: _textLight, size: 20),
                          ],
                        ),
                    ],
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
                  icon: PhosphorIcon(PhosphorIcons.signOut(), color: _dangerRed, size: 24),
                  label: const Text(
                    'Logout',
                    style: TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.bold, color: _dangerRed),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _dangerRed.withOpacity(0.2), width: 1.5),
                    backgroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: isLast ? 20 : 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            PhosphorIcon(icon, size: 28, color: Colors.black),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontFamily: _fontFamily, fontSize: 13, color: _textLight)),
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
    return PhosphorIcon(PhosphorIcons.caretRight(), color: Colors.grey.shade600, size: 20);
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
        Text(text, style: TextStyle(fontFamily: _fontFamily, fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
        const SizedBox(width: 4),
        PhosphorIcon(PhosphorIcons.caretRight(), color: Colors.grey.shade600, size: 20),
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
      title: Text(title, style: const TextStyle(fontFamily: _fontFamily, color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
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
  State<SettingsNotificationsScreen> createState() => _SettingsNotificationsScreenState();
}
class _SettingsNotificationsScreenState extends State<SettingsNotificationsScreen> {
  bool push = true;
  bool email = false;
  bool dataAlerts = true;

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
            title: const Text('Push Notifications', style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold)),
            subtitle: const Text('Receive alerts on your device', style: TextStyle(fontFamily: _fontFamily)),
            value: push,
            onChanged: (v) => setState(() => push = v), // TODO: API Update
          ),
          SwitchListTile(
            activeThumbColor: _primaryGreen,
            title: const Text('Email Summaries', style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold)),
            subtitle: const Text('Weekly report of your activities', style: TextStyle(fontFamily: _fontFamily)),
            value: email,
            onChanged: (v) => setState(() => email = v), // TODO: API Update
          ),
          SwitchListTile(
            activeThumbColor: _primaryGreen,
            title: const Text('Data Upload Alerts', style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold)),
            subtitle: const Text('Notify when pending data is synced', style: TextStyle(fontFamily: _fontFamily)),
            value: dataAlerts,
            onChanged: (v) => setState(() => dataAlerts = v), // TODO: API Update
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
        leading: BackButton(onPressed: () => Navigator.pop(context, isEnabled)), // Return updated state
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Offline Sync', style: TextStyle(fontFamily: _fontFamily, color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Background Synchronization', style: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'When enabled, FieldTrack will automatically upload your saved field entries as soon as your device reconnects to a stable internet connection.',
              style: TextStyle(fontFamily: _fontFamily, color: _textLight, height: 1.5),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(border: Border.all(color: _cardBorder, width: 1.5), borderRadius: BorderRadius.circular(16)),
              child: SwitchListTile(
                activeThumbColor: _primaryGreen,
                title: const Text('Enable Offline Sync', style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold)),
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

class DownloadDataScreen extends StatefulWidget {
  final double currentSize;
  const DownloadDataScreen({super.key, required this.currentSize});
  @override
  State<DownloadDataScreen> createState() => _DownloadDataScreenState();
}
class _DownloadDataScreenState extends State<DownloadDataScreen> {
  late double _size;

  @override
  void initState() {
    super.initState();
    _size = widget.currentSize;
  }

  void _clearData() async {
    // Simulate API/Storage clearing delay
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: _primaryGreen)));
    await Future.delayed(const Duration(seconds: 1));
    Navigator.pop(context); // close loader
    
    setState(() => _size = 0.0);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offline data cleared.'), backgroundColor: _primaryGreen));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.pop(context, _size)), // Pass data back to main screen
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Download Data', style: TextStyle(fontFamily: _fontFamily, color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            PhosphorIcon(PhosphorIcons.database(), size: 64, color: _primaryGreen.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('Local Storage Used', style: TextStyle(fontFamily: _fontFamily, fontSize: 16, color: _textLight)),
            const SizedBox(height: 8),
            Text('${_size.toStringAsFixed(1)} MB', style: const TextStyle(fontFamily: _fontFamily, fontSize: 36, fontWeight: FontWeight.bold, color: _textDark)),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _size > 0 ? _clearData : null,
                icon: PhosphorIcon(PhosphorIcons.trash(), color: _size > 0 ? Colors.white : Colors.grey),
                label: const Text('Clear Offline Data', style: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _dangerRed,
                  disabledBackgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const _GenericAppbar(title: 'Help & Support'),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Frequently Asked Questions', style: TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.bold, color: _primaryGreen)),
          const SizedBox(height: 16),
          _buildFaqItem('How do I capture a new field entry?', 'Navigate to the Home screen and tap the large + button. Make sure your GPS is turned on.'),
          _buildFaqItem('Why is my data not syncing?', 'Ensure you have an active internet connection and that Offline Sync is enabled in settings.'),
          const SizedBox(height: 32),
          const Text('Contact Us', style: TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.bold, color: _primaryGreen)),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(backgroundColor: _lightGreen, child: Icon(Icons.email, color: _primaryGreen)),
            title: const Text('Email Support', style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold)),
            subtitle: const Text('support@fieldtrack.com', style: TextStyle(fontFamily: _fontFamily)),
            onTap: () {
              // TODO: launchUrl to email client
            },
          )
        ],
      ),
    );
  }
  Widget _buildFaqItem(String q, String a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ExpansionTile(
        title: Text(q, style: const TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600, color: _textDark)),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        children: [Text(a, style: const TextStyle(fontFamily: _fontFamily, color: _textLight))],
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const _GenericAppbar(title: 'Privacy Policy'),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: const Text(
          "FieldTrack Privacy Policy\n\nLast Updated: October 2024\n\n1. Information Collection\nWe collect location data and field metrics you input to assist in environmental research. Your personal information (Name, ID, Email) is used strictly for authentication and academic tracking.\n\n2. Data Usage\nAll geographic and analytical data collected is synced to university servers and may be used in aggregated research studies. Individual user tracking is kept confidential.\n\n3. Offline Data\nData stored locally on your device remains encrypted until a secure connection is established for syncing.\n\n(This is a sample privacy policy for demonstration purposes. In a real application, place your full legal terms here.)",
          style: TextStyle(fontFamily: _fontFamily, fontSize: 15, color: _textDark, height: 1.6),
        ),
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
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
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: _lightGreen, shape: BoxShape.circle),
              child: PhosphorIcon(PhosphorIcons.leaf(), size: 64, color: _primaryGreen),
            ),
            const SizedBox(height: 24),
            const Text('FieldTrack', style: TextStyle(fontFamily: _fontFamily, fontSize: 24, fontWeight: FontWeight.bold, color: _primaryGreen)),
            const SizedBox(height: 8),
            const Text('Version 1.0.0 (Build 42)', style: TextStyle(fontFamily: _fontFamily, color: _textLight)),
            const SizedBox(height: 32),
            const Text('Developed for\nPwani University, Environmental Sciences', textAlign: TextAlign.center, style: TextStyle(fontFamily: _fontFamily, fontSize: 16, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
