import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:dio/dio.dart';
import 'package:fieldtrack/core/network/api_client.dart';
import 'package:image_picker/image_picker.dart';

// ==========================================
// DESIGN TOKENS
// ==========================================
class _C {
  static const bg = Color(0xFFF3F4F6);
  static const green = Color(0xFF1BA654);
  static const greenLight = Color(0xFFE6F5EC);
  static const red = Color(0xFFEF4444);
  static const textDark = Color(0xFF111827);
  static const textMuted = Color(0xFF6B7280);
  static const textFaint = Color(0xFF9CA3AF);
  static const border = Color(0xFFE5E7EB);
  static const cardRadius = 40.0;
  static const inputRadius = 40.0;
}

// ==========================================
// MAIN SCREEN
// ==========================================
class SupervisorSettingsScreen extends StatefulWidget {
  final String initialTab;
  const SupervisorSettingsScreen({
    super.key,
    this.initialTab = 'Notifications',
  });

  @override
  State<SupervisorSettingsScreen> createState() =>
      _SupervisorSettingsScreenState();
}

class _SupervisorSettingsScreenState extends State<SupervisorSettingsScreen> {
  String _globalSearch = '';
  late String _selectedTab;
  bool _isSaving = false;

  final List<String> _tabs = [
    'Profile',
    'Account',
    'Notifications',
    'Preferences',
    'Security',
  ];

  // --- STATE: NOTIFICATIONS ---
  bool _notifNewActivity = true;
  bool _notifCheckInOut = true;
  bool _notifReview = true;
  bool _notifComments = true;
  bool _notifAnnouncements = true;
  bool _chanEmail = true;
  bool _chanInApp = true;
  String _quietStart = '10:00 PM';
  String _quietEnd = '06:00 AM';

  // --- STATE: PROFILE ---
  final _nameCtrl = TextEditingController(text: 'Prof. Okeyo Benards');
  final _staffNoCtrl = TextEditingController(text: 'PU/STF/1029');
  final _emailCtrl = TextEditingController(text: 'okeyobenards@yahoo.com');
  final _phoneCtrl = TextEditingController(text: '+254 712 345 678');
  final _uniCtrl = TextEditingController(text: 'Pwani University');
  final _facultyCtrl =
      TextEditingController(text: 'School of Environmental Sciences');
  final _deptCtrl =
      TextEditingController(text: 'Geography and Environmental Studies');
  final _rankCtrl = TextEditingController(text: 'Associate Professor');
  final _researchCtrl =
      TextEditingController(text: 'Coastal Erosion & GIS Mapping');
  final _officeCtrl = TextEditingController(text: 'Block A, Room 102');
  final _hoursCtrl =
      TextEditingController(text: 'Mon-Wed, 10:00 AM - 12:00 PM');

  // --- STATE: ACCOUNT ---
  bool _twoFactorAuth = false;

  // --- STATE: PREFERENCES ---
  String _prefDashboard = 'Overview';
  String _prefLanding = 'Home';
  String _prefZoom = 'City';
  String _prefMapType = 'Satellite';
  String _prefDateFormat = 'DD/MM/YYYY';
  String _prefTimeFormat = '12 Hour';
  String _prefLanguage = 'English';
  String _prefRefresh = 'Every 30 seconds';
  String _prefRows = '20';
  String _prefTheme = 'Light';
  bool _exportPdf = true;
  bool _exportExcel = false;
  bool _exportCsv = true;

  // --- STATE: SECURITY ---
  bool _secLoginAlerts = true;
  final _currPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confPassCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _loadSettings();
  }

  List<dynamic> _activeSessions = [];
  String? _avatarPath;

  Future<void> _loadSettings() async {
    try {
      final res = await ApiClient().dio.get('/settings/profile');
      final p = res.data['profile'];
      final sup = p['supervisorProfile'] ?? {};
      final prefs = p['preferences'] ?? {};
      final sessions = p['refreshTokens'] ?? [];
      
      if (mounted) {
        setState(() {
          _nameCtrl.text = p['name'] ?? '';
          _emailCtrl.text = p['email'] ?? '';
          _phoneCtrl.text = sup['phone'] ?? '';
          _deptCtrl.text = sup['department'] ?? '';
          _facultyCtrl.text = sup['faculty'] ?? '';
          _researchCtrl.text = sup['specialization'] ?? '';
          _officeCtrl.text = sup['office'] ?? '';
          _twoFactorAuth = p['twoFactorEnabled'] ?? false;
          _secLoginAlerts = p['loginAlertsEnabled'] ?? true;
          _avatarPath = sup['avatar'];
          _activeSessions = sessions;

          // Notifications
          _notifNewActivity = prefs['notifNewActivity'] ?? true;
          _notifCheckInOut = prefs['notifCheckInOut'] ?? true;
          _notifReview = prefs['notifReview'] ?? true;
          _notifComments = prefs['notifComments'] ?? true;
          _notifAnnouncements = prefs['notifAnnouncements'] ?? true;
          _chanEmail = prefs['chanEmail'] ?? true;
          _chanInApp = prefs['chanInApp'] ?? true;
          _quietStart = prefs['quietStart'] ?? '10:00 PM';
          _quietEnd = prefs['quietEnd'] ?? '06:00 AM';

          // Preferences
          _prefDashboard = prefs['prefDashboard'] ?? 'Overview';
          _prefLanding = prefs['prefLanding'] ?? 'Home';
          _prefZoom = prefs['prefZoom'] ?? 'City';
          _prefMapType = prefs['prefMapType'] ?? 'Satellite';
          _prefDateFormat = prefs['prefDateFormat'] ?? 'DD/MM/YYYY';
          _prefTimeFormat = prefs['prefTimeFormat'] ?? '12 Hour';
          _prefLanguage = prefs['prefLanguage'] ?? 'English';
          _prefRefresh = prefs['prefRefresh'] ?? 'Every 30 seconds';
          _prefRows = prefs['prefRows'] ?? '20';
          _prefTheme = prefs['prefTheme'] ?? 'Light';
          _exportPdf = prefs['exportPdf'] ?? true;
          _exportExcel = prefs['exportExcel'] ?? false;
          _exportCsv = prefs['exportCsv'] ?? true;
        });
      }
    } catch (e) {
      if (mounted) _showSnackbar('Failed to load settings');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _staffNoCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _uniCtrl.dispose();
    _facultyCtrl.dispose();
    _deptCtrl.dispose();
    _rankCtrl.dispose();
    _researchCtrl.dispose();
    _officeCtrl.dispose();
    _hoursCtrl.dispose();
    _currPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confPassCtrl.dispose();
    super.dispose();
  }

  // --- ACTIONS ---
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _C.textDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40),
        ),
        margin: EdgeInsets.only(
          bottom: 40,
          left: MediaQuery.of(context).size.width > 600
              ? MediaQuery.of(context).size.width * 0.3
              : 24,
          right: MediaQuery.of(context).size.width > 600
              ? MediaQuery.of(context).size.width * 0.3
              : 24,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    
    try {
      await ApiClient().dio.put('/settings/profile', data: {
        'name': _nameCtrl.text,
        'phone': _phoneCtrl.text,
        'department': _deptCtrl.text,
        'faculty': _facultyCtrl.text,
        'specialization': _researchCtrl.text,
        'office': _officeCtrl.text,
      });

      await ApiClient().dio.put('/settings/security', data: {
        'twoFactorEnabled': _twoFactorAuth,
        'loginAlertsEnabled': _secLoginAlerts,
      });

      await ApiClient().dio.put('/settings/preferences', data: {
        'notifNewActivity': _notifNewActivity,
        'notifCheckInOut': _notifCheckInOut,
        'notifReview': _notifReview,
        'notifComments': _notifComments,
        'notifAnnouncements': _notifAnnouncements,
        'chanEmail': _chanEmail,
        'chanInApp': _chanInApp,
        'quietStart': _quietStart,
        'quietEnd': _quietEnd,
        'prefDashboard': _prefDashboard,
        'prefLanding': _prefLanding,
        'prefZoom': _prefZoom,
        'prefMapType': _prefMapType,
        'prefDateFormat': _prefDateFormat,
        'prefTimeFormat': _prefTimeFormat,
        'prefLanguage': _prefLanguage,
        'prefRefresh': _prefRefresh,
        'prefRows': _prefRows,
        'prefTheme': _prefTheme,
        'exportPdf': _exportPdf,
        'exportExcel': _exportExcel,
        'exportCsv': _exportCsv,
      });

      if (mounted) _showSnackbar('Settings updated successfully!');
    } catch (e) {
      if (mounted) {
        String msg = 'Failed to save settings';
        if (e is DioException) {
          msg = e.response?.data?['message'] ?? msg;
        }
        _showSnackbar(msg);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) { 
         setState(() => _isSaving = true);
         final formData = FormData.fromMap({
           'avatar': await MultipartFile.fromFile(pickedFile.path),
         });
         
         final res = await ApiClient().dio.post('/settings/avatar', data: formData);
         
         if (mounted) {
           setState(() {
             _avatarPath = res.data['avatar'];
             _isSaving = false;
           });
           _showSnackbar('Profile picture updated successfully!');
         }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnackbar('Failed to update picture');
      }
    }
  }

  void _confirmPasswordChange() {
    if (_currPassCtrl.text.isEmpty ||
        _newPassCtrl.text.isEmpty ||
        _confPassCtrl.text.isEmpty) {
      _showSnackbar('Please fill all password fields');
      return;
    }
    if (_newPassCtrl.text != _confPassCtrl.text) {
      _showSnackbar('New passwords do not match');
      return;
    }
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: const Text('Change Password',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: const Text(
            'Are you sure you want to update your password? You may be logged out of other active sessions.',
            style: TextStyle(fontFamily: 'Poppins', color: _C.textDark)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(fontFamily: 'Poppins', color: _C.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiClient().dio.put('/settings/password', data: {
                  'currentPassword': _currPassCtrl.text,
                  'newPassword': _newPassCtrl.text,
                });
                _currPassCtrl.clear();
                _newPassCtrl.clear();
                _confPassCtrl.clear();
                if (mounted) _showSnackbar('Password updated successfully!');
              } catch (e) {
                if (mounted) {
                  String msg = 'Failed to update password';
                  if (e is DioException) {
                    msg = e.response?.data?['message'] ?? msg;
                  }
                  _showSnackbar(msg);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.green,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Confirm & Update',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeactivation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: const Text('Deactivate Account',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: _C.red)),
        content: const Text(
            'Are you sure you want to deactivate your account? This action is irreversible and you will lose access immediately.',
            style: TextStyle(fontFamily: 'Poppins', color: _C.textDark)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(fontFamily: 'Poppins', color: _C.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiClient().dio.delete('/settings/deactivate');
                if (mounted) {
                  _showSnackbar('Account deactivated successfully.');
                }
              } catch (e) {
                if (mounted) {
                  String msg = 'Failed to deactivate account';
                  if (e is DioException) {
                    msg = e.response?.data?['message'] ?? msg;
                  }
                  _showSnackbar(msg);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Deactivate',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopHeader(),
              const SizedBox(height: 32),
              _buildTabsBar(),
              const SizedBox(height: 32),
              _buildTabContent(),
            ],
          ),
        ),
      ),
    );
  }

  // ── 1. Top Header ─────────────────────────────────────────────────────
  Widget _buildTopHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;

        const titleBlock = Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: _C.textDark,
          ),
        );

        final bellIcon = Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(PhosphorIcons.bell(), color: _C.textMuted, size: 24),
        );

        final searchBar = SizedBox(
          width: isNarrow ? double.infinity : 320,
          height: 52,
          child: TextField(
            onChanged: (v) {
              setState(() => _globalSearch = v);
              // TODO(API): Implement local or remote search filtering
            },
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Search Settings',
              hintStyle: const TextStyle(
                fontFamily: 'Poppins',
                color: _C.textFaint,
                fontSize: 14,
              ),
              prefixIcon: Icon(PhosphorIcons.magnifyingGlass(),
                  color: _C.textFaint, size: 20),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: BorderSide.none, // Removes the double material effect
              ),
            ),
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: searchBar),
                  const SizedBox(width: 16),
                  bellIcon,
                ],
              ),
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleBlock),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                searchBar,
                const SizedBox(width: 16),
                bellIcon,
              ],
            ),
          ],
        );
      },
    );
  }

  // ── 2. Tabs Bar ───────────────────────────────────────────────────────
  Widget _buildTabsBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 800;

        final tabWidgets = _tabs.map((tab) {
          final isSelected = _selectedTab == tab;
          return InkWell(
            onTap: () => setState(() => _selectedTab = tab),
            borderRadius: BorderRadius.circular(30),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: isSelected ? null : Colors.white,
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [_C.green, Color(0xFF34D399)],
                      )
                    : null,
                borderRadius: BorderRadius.circular(30),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _C.green.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                tab,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: isSelected ? Colors.white : _C.textMuted,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
          );
        }).toList();

        // Narrow screen: horizontally scrollable pills
        if (isNarrow) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: tabWidgets
                  .map((w) => Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: w,
                      ))
                  .toList(),
            ),
          );
        }

        // Wide screen: Reach end-to-end of the margins perfectly
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: tabWidgets,
        );
      },
    );
  }

  // ── 3. Tab Content Router ─────────────────────────────────────────────
  Widget _buildTabContent() {
    Widget content;
    switch (_selectedTab) {
      case 'Profile':
        content = _buildProfileTab();
        break;
      case 'Account':
        content = _buildAccountTab();
        break;
      case 'Notifications':
        content = _buildNotificationsTab();
        break;
      case 'Preferences':
        content = _buildPreferencesTab();
        break;
      case 'Security':
        content = _buildSecurityTab();
        break;
      default:
        content = const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [content, const SizedBox(height: 40), _buildSaveCancelFooter()],
    );
  }

  // ── SHARED LAYOUT HELPER ──────────────────────────────────────────────
  Widget _buildSplitLayout({required Widget left, required Widget right}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [left, const SizedBox(height: 24), right],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 55, child: left),
            const SizedBox(width: 24),
            Expanded(flex: 45, child: right),
          ],
        );
      },
    );
  }

  // ── TAB: NOTIFICATIONS ────────────────────────────────────────────────
  Widget _buildNotificationsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            'Notifications', 'Choose What you want to be notified about'),
        _buildSplitLayout(
          left: _buildCard(
            child: Column(
              children: [
                _buildNotificationToggle(
                  'New Activity Submitted',
                  'Notify me when a student submit a new activity',
                  _notifNewActivity,
                  (v) => setState(() => _notifNewActivity = v),
                ),
                const SizedBox(height: 32),
                _buildNotificationToggle(
                  'Student Check Out/In',
                  'Notify me when a student checks in or out',
                  _notifCheckInOut,
                  (v) => setState(() => _notifCheckInOut = v),
                ),
                const SizedBox(height: 32),
                _buildNotificationToggle(
                  'Activity Needs Review',
                  'Notify me when an activity needs a review',
                  _notifReview,
                  (v) => setState(() => _notifReview = v),
                ),
                const SizedBox(height: 32),
                _buildNotificationToggle(
                  'Comments',
                  'Notify me for new comments in activities',
                  _notifComments,
                  (v) => setState(() => _notifComments = v),
                ),
                const SizedBox(height: 32),
                _buildNotificationToggle(
                  'System Announcements',
                  'Important updates and information',
                  _notifAnnouncements,
                  (v) => setState(() => _notifAnnouncements = v),
                ),
              ],
            ),
          ),
          right: Column(
            children: [
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notification Channels',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _C.textDark,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildChannelCheckbox(
                      'Email',
                      'okeyobenards@yahoo.com',
                      PhosphorIcons.envelopeSimple(),
                      _chanEmail,
                      () => setState(() => _chanEmail = !_chanEmail),
                    ),
                    const SizedBox(height: 24),
                    _buildChannelCheckbox(
                      'In-App',
                      'Push notifications to devices',
                      PhosphorIcons.deviceMobile(),
                      _chanInApp,
                      () => setState(() => _chanInApp = !_chanInApp),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quiet Hours',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _C.textDark,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTimeDropdownRow('Start', _quietStart, (v) {
                      if (v != null) setState(() => _quietStart = v);
                    }),
                    const SizedBox(height: 16),
                    _buildTimeDropdownRow('End', _quietEnd, (v) {
                      if (v != null) setState(() => _quietEnd = v);
                    }),
                    const SizedBox(height: 24),
                    const Text(
                      'You will not recieve notifications during quiet hours.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: _C.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── TAB: PROFILE ──────────────────────────────────────────────────────
  Widget _buildProfileTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            'Profile Information', 'Update your personal and academic details.'),
        _buildSplitLayout(
          left: _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _C.textDark,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    ClipOval(
                      child: _avatarPath != null
                          ? Image.network(
                              'http://192.168.18.5:3000$_avatarPath',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 80,
                                height: 80,
                                color: _C.bg,
                                child: Icon(PhosphorIcons.user(),
                                    color: _C.textDark),
                              ),
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              color: _C.bg,
                              child: Icon(PhosphorIcons.user(),
                                  color: _C.textDark),
                            ),
                    ),
                    const SizedBox(width: 24),
                    OutlinedButton.icon(
                      onPressed: _pickImage, // Wired to file explorer
                      icon: Icon(PhosphorIcons.camera(),
                          size: 18, color: _C.textDark),
                      label: const Text(
                        'Change Picture',
                        style: TextStyle(
                            fontFamily: 'Poppins', color: _C.textDark),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildTextField('Full Name', _nameCtrl),
                const SizedBox(height: 16),
                _buildTextField('Staff Number', _staffNoCtrl),
                const SizedBox(height: 16),
                _buildTextField('Email Address', _emailCtrl),
                const SizedBox(height: 16),
                _buildTextField('Phone Number', _phoneCtrl),
              ],
            ),
          ),
          right: _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Institutional Information',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _C.textDark,
                  ),
                ),
                const SizedBox(height: 24),
                _buildTextField('University', _uniCtrl),
                const SizedBox(height: 16),
                _buildTextField('Faculty/School', _facultyCtrl),
                const SizedBox(height: 16),
                _buildTextField('Department', _deptCtrl),
                const SizedBox(height: 16),
                _buildTextField('Academic Rank', _rankCtrl),
                const SizedBox(height: 16),
                _buildTextField('Research Area', _researchCtrl),
                const SizedBox(height: 16),
                _buildTextField('Office Location', _officeCtrl),
                const SizedBox(height: 16),
                _buildTextField('Office Hours (Optional)', _hoursCtrl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── TAB: ACCOUNT ──────────────────────────────────────────────────────
  Widget _buildAccountTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            'Account Information', 'Manage authentication and sessions.'),
        _buildSplitLayout(
          left: Column(
            children: [
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Login Credentials',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _C.textDark,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                        'Username', TextEditingController(text: 'okeyo_b'),
                        readOnly: true),
                    const SizedBox(height: 16),
                    _buildTextField(
                        'Email', TextEditingController(text: 'okeyobenards@yahoo.com'),
                        readOnly: true),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider(color: _C.border),
                    ),
                    _buildToggleRow(
                      'Two-Factor Authentication',
                      'Require 2FA verification on new devices',
                      _twoFactorAuth,
                      (v) {
                        setState(() => _twoFactorAuth = v);
                        // TODO(API): Ping API to setup 2FA
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Danger Zone',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: _C.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Once you deactivate your account, you will lose access to all supervisor tools.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: _C.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: _confirmDeactivation,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _C.red),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      child: const Text(
                        'Deactivate Account',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: _C.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          right: _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Login Sessions',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _C.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Devices currently logged into your account.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: _C.textMuted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                ..._activeSessions.map((session) => Column(
                  children: [
                    _buildSessionItem(
                      PhosphorIcons.desktop(),
                      session['deviceInfo'] ?? 'Unknown Device',
                      'IP: ${session['ipAddress'] ?? 'Unknown'}',
                      false,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: _C.border),
                    ),
                  ],
                )),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: () async {
                      try {
                        await ApiClient().dio.post('/settings/logout-others');
                        if (mounted) _showSnackbar('Other devices logged out successfully.');
                      } catch (e) {
                        if (mounted) _showSnackbar('Failed to logout other devices');
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    child: const Text(
                      'Logout Other Devices',
                      style: TextStyle(
                          fontFamily: 'Poppins', color: _C.textDark),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── TAB: PREFERENCES ──────────────────────────────────────────────────
  Widget _buildPreferencesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            'System Preferences', 'Customize how your data is displayed.'),
        _buildSplitLayout(
          left: _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dashboard Preferences',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _C.textDark,
                  ),
                ),
                const SizedBox(height: 24),
                _buildDropdownField(
                    'Default Dashboard',
                    ['Overview', 'Reports', 'Map'],
                    _prefDashboard,
                    (v) => setState(() => _prefDashboard = v!)),
                const SizedBox(height: 16),
                _buildDropdownField(
                    'Default Landing Page',
                    ['Home', 'Reports', 'Students', 'Map'],
                    _prefLanding,
                    (v) => setState(() => _prefLanding = v!)),
                const SizedBox(height: 16),
                _buildDropdownField(
                    'Default Zoom Level (Map)',
                    ['Street', 'City', 'Region'],
                    _prefZoom,
                    (v) => setState(() => _prefZoom = v!)),
                const SizedBox(height: 16),
                _buildDropdownField(
                    'Map Type',
                    ['Satellite', 'Terrain', 'Street'],
                    _prefMapType,
                    (v) => setState(() => _prefMapType = v!)),
              ],
            ),
          ),
          right: _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'System & Localization',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _C.textDark,
                  ),
                ),
                const SizedBox(height: 24),
                _buildDropdownField(
                    'Date Format',
                    ['DD/MM/YYYY', 'MM/DD/YYYY'],
                    _prefDateFormat,
                    (v) => setState(() => _prefDateFormat = v!)),
                const SizedBox(height: 16),
                _buildDropdownField(
                    'Time Format',
                    ['12 Hour', '24 Hour'],
                    _prefTimeFormat,
                    (v) => setState(() => _prefTimeFormat = v!)),
                const SizedBox(height: 16),
                _buildDropdownField('Language', ['English'], _prefLanguage,
                    (v) => setState(() => _prefLanguage = v!)),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Divider(color: _C.border),
                ),
                const Text(
                  'Theme',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _C.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildRadioOption('Light', _prefTheme == 'Light',
                        () => setState(() => _prefTheme = 'Light')),
                    const SizedBox(width: 24),
                    _buildRadioOption('Dark', _prefTheme == 'Dark',
                        () => setState(() => _prefTheme = 'Dark')),
                    const SizedBox(width: 24),
                    _buildRadioOption('System', _prefTheme == 'System',
                        () => setState(() => _prefTheme = 'System')),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Divider(color: _C.border),
                ),
                const Text(
                  'Report Export Format',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _C.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildCheckboxOption('PDF', _exportPdf,
                        () => setState(() => _exportPdf = !_exportPdf)),
                    const SizedBox(width: 24),
                    _buildCheckboxOption('Excel', _exportExcel,
                        () => setState(() => _exportExcel = !_exportExcel)),
                    const SizedBox(width: 24),
                    _buildCheckboxOption('CSV', _exportCsv,
                        () => setState(() => _exportCsv = !_exportCsv)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── TAB: SECURITY ─────────────────────────────────────────────────────
  Widget _buildSecurityTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            'Security Settings', 'Protect your supervisor account.'),
        _buildSplitLayout(
          left: Column(
            children: [
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Security',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _C.textDark,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildToggleRow(
                      'Login Alerts',
                      'Email me when a new device logs in.',
                      _secLoginAlerts,
                      (v) {
                         setState(() => _secLoginAlerts = v);
                         // TODO(API): Toggle login alert setting in backend
                      }
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider(color: _C.border),
                    ),
                    const Text(
                      'Security Questions',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: _C.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {
                         _showSnackbar('Security questions configuration launched.');
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      child: const Text(
                        'Configure Recovery Questions',
                        style: TextStyle(
                            fontFamily: 'Poppins', color: _C.textDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Change Password',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _C.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Last changed 45 days ago',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: _C.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField('Current Password', _currPassCtrl,
                        isPassword: true),
                    const SizedBox(height: 16),
                    _buildTextField('New Password', _newPassCtrl,
                        isPassword: true),
                    const SizedBox(height: 16),
                    _buildTextField('Confirm Password', _confPassCtrl,
                        isPassword: true),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton(
                        onPressed: _confirmPasswordChange,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.textDark,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                        child: const Text(
                          'Update Password',
                          style: TextStyle(
                              fontFamily: 'Poppins', color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          right: _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Activity Log',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _C.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Recent security events on your account.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: _C.textMuted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                _buildTimelineItem('Password Changed', 'July 12', true),
                _buildTimelineItem(
                    'Logged In (Windows Desktop)', 'July 11', false),
                _buildTimelineItem('Profile Updated', 'July 8', false),
                _buildTimelineItem('Enabled Email Notifications', 'July 1', false,
                    isLast: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── SHARED COMPONENTS ─────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _C.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: _C.textFaint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_C.cardRadius),
      ),
      child: child,
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool readOnly = false, bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: _C.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          obscureText: isPassword,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: readOnly ? _C.textMuted : _C.textDark,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? _C.bg : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_C.inputRadius),
              borderSide: const BorderSide(color: _C.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_C.inputRadius),
              borderSide: const BorderSide(color: _C.green, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> options, String value,
      ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: _C.textDark,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          icon: Icon(PhosphorIcons.caretDown(), size: 16),
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: _C.textDark,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(24),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_C.inputRadius),
              borderSide: const BorderSide(color: _C.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_C.inputRadius),
              borderSide: const BorderSide(color: _C.green, width: 2),
            ),
          ),
          items: options
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildToggleRow(
      String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: _C.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: _C.textMuted,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: _C.green,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: _C.border,
        ),
      ],
    );
  }

  Widget _buildNotificationToggle(
      String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(PhosphorIcons.bell(), color: _C.textDark, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: _C.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: _C.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: _C.green,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: _C.border,
        ),
      ],
    );
  }

  Widget _buildChannelCheckbox(String title, String subtitle, IconData icon,
      bool checked, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _C.textDark, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _C.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: _C.textMuted,
                  ),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: checked ? _C.green : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: checked ? _C.green : _C.textFaint),
            ),
            child: checked
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDropdownRow(
      String label, String value, ValueChanged<String?> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: _C.textDark,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _C.bg,
            borderRadius: BorderRadius.circular(_C.inputRadius),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(24),
              icon: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(PhosphorIcons.caretDown(),
                    size: 16, color: _C.textDark),
              ),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _C.textDark,
              ),
              items: ['10:00 PM', '11:00 PM', '06:00 AM', '07:00 AM']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionItem(
      IconData icon, String title, String subtitle, bool isCurrent) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(color: _C.bg, shape: BoxShape.circle),
          child: Icon(icon, color: _C.textDark, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _C.textDark,
                    ),
                  ),
                  if (isCurrent) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _C.greenLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Current',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: _C.green,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: _C.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRadioOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? _C.green : _C.border,
                width: 2,
              ),
            ),
            child: isSelected
                ? Container(
                    decoration: const BoxDecoration(
                      color: _C.green,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: _C.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxOption(
      String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isSelected ? _C.green : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isSelected ? _C.green : _C.border),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: _C.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String date, bool isRecent,
      {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isRecent ? _C.green : _C.border,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast) Container(width: 2, height: 32, color: _C.border),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _C.textDark,
                  ),
                ),
                Text(
                  date,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: _C.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Footer Actions ────────────────────────────────────────────────────
  Widget _buildSaveCancelFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
            side: const BorderSide(color: _C.border),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: _C.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: _C.green,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }
}
