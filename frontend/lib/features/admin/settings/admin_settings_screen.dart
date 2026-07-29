import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  int _selectedIndex = 0;

  // Track the state of the toggle switches
  final Map<String, bool> _toggles = {
    'strict_bounds': true,
    'sso': false,
    '2fa': true,
    'auto_backup': true,
    'alpha_pass': true,
    'webhook_sync': false,
  };

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
  Widget build(BuildContext context) {
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings saved successfully.')),
                  );
                },
                icon: Icon(PhosphorIcons.floppyDisk(), size: 18),
                label: const Text('Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF169B45),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
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
                                color: isSelected ? const Color(0xFF169B45) : Colors.transparent,
                                width: 4,
                              ),
                            ),
                            color: isSelected ? const Color(0xFFF3F4F6) : Colors.transparent,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Text(
                            _sections[index],
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? const Color(0xFF169B45) : const Color(0xFF4B5563),
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
                    // Wrapped in SingleChildScrollView to prevent overflow on smaller screens
                    child: SingleChildScrollView(
                      child: _buildSectionContent(),
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
            style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF6B7280)),
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
        const Text('General Settings', style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 32),
        _buildTextField('University Name', 'Pwani University'),
        const SizedBox(height: 24),
        _buildTextField('System Administrator Name', 'FieldTrack Admin'),
        const SizedBox(height: 24),
        _buildTextField('Contact Email', 'admin@fieldtrack.com'),
      ],
    );
  }

  Widget _buildAuthenticationSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Authentication', style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 32),
        _buildTextField('Session Timeout (Minutes)', '30'),
        const SizedBox(height: 32),
        _buildSwitchRow('Enable Single Sign-On (SSO)', 'sso'),
        const SizedBox(height: 24),
        _buildSwitchRow('Enforce Two-Factor Authentication (2FA) for Supervisors', '2fa'),
      ],
    );
  }

  Widget _buildGpsSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('GPS Tracking Settings', style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 32),
        _buildTextField('Allowed Deviation Radius (Meters)', '500'),
        const SizedBox(height: 24),
        _buildTextField('Sync Interval (Minutes)', '15'),
        const SizedBox(height: 32),
        _buildSwitchRow('Enable strict boundary enforcement', 'strict_bounds'),
      ],
    );
  }

  Widget _buildEmailSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Email Configuration', style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 32),
        _buildTextField('SMTP Host', 'smtp.fieldtrack.com'),
        const SizedBox(height: 24),
        _buildTextField('SMTP Port', '587'),
        const SizedBox(height: 24),
        _buildTextField('Sender Email Address', 'noreply@fieldtrack.com'),
        const SizedBox(height: 24),
        _buildTextField('SMTP Password', '********', isPassword: true),
      ],
    );
  }

  Widget _buildBackupSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('System Backups', style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 32),
        _buildTextField('AWS S3 Bucket URI', 's3://fieldtrack-prod-backups'),
        const SizedBox(height: 24),
        _buildTextField('Backup Frequency (Days)', '1'),
        const SizedBox(height: 32),
        _buildSwitchRow('Enable Automated Backups', 'auto_backup'),
        const SizedBox(height: 32),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: Icon(PhosphorIcons.downloadSimple(), size: 18),
            label: const Text('Run Manual Backup Now'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF169B45),
              side: const BorderSide(color: Color(0xFF169B45), width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
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
        const Text('Security Policies', style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 32),
        _buildTextField('Minimum Password Length', '8'),
        const SizedBox(height: 24),
        _buildTextField('Max Failed Login Attempts (Lockout)', '5'),
        const SizedBox(height: 32),
        _buildSwitchRow('Require Alphanumeric Passwords', 'alpha_pass'),
      ],
    );
  }

  Widget _buildIntegrationSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('External Integrations', style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 32),
        _buildTextField('Slack Webhook URL', 'https://hooks.slack.com/services/T0000/B000/XXX'),
        const SizedBox(height: 24),
        _buildTextField('Google Maps API Key', 'AIzaSyB-XXXXXXXXXXXXXXXXXXXXXXX', isPassword: true),
        const SizedBox(height: 32),
        _buildSwitchRow('Enable Third-Party Webhook Sync', 'webhook_sync'),
      ],
    );
  }

  // ==========================================
  // REUSABLE UI COMPONENTS
  // ==========================================

  Widget _buildTextField(String label, String value, {bool isPassword = false}) {
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
            initialValue: value,
            obscureText: isPassword,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF111827)),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                borderSide: const BorderSide(color: Color(0xFF169B45), width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchRow(String label, String toggleKey) {
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
          value: _toggles[toggleKey] ?? false,
          onChanged: (val) {
            setState(() {
              _toggles[toggleKey] = val;
            });
          },
          activeColor: const Color(0xFF169B45),
        ),
      ],
    );
  }
}