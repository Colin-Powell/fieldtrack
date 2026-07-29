import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/toast_service.dart';
import 'package:intl/intl.dart';

class _C {
  static const Color green = Color(0xFF169B45);
  static const Color textDark = Color(0xFF171717);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textFaint = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color bg = Color(0xFFF5F6F7);
}

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _user;
  List<dynamic> _auditLogs = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get('/admin/users/${widget.userId}');
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _user = response.data['user'];
            _auditLogs = _user?['auditLogs'] ?? [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError('Failed to load user profile');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to reset this user\'s password?', style: TextStyle(fontFamily: 'Poppins')),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: _C.textMuted))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.post('/admin/users/${widget.userId}/reset-password');
      if (response.statusCode == 200) {
        final tempPassword = response.data['tempPassword'];
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Password Reset Successful', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('The user\'s password has been reset. Please share this temporary password with them securely:', style: TextStyle(fontFamily: 'Poppins')),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)),
                    child: Center(
                      child: SelectableText(tempPassword, style: const TextStyle(fontFamily: 'Courier', fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    ),
                  )
                ],
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done', style: TextStyle(color: _C.green, fontWeight: FontWeight.bold))),
              ],
            ),
          );
          _fetchData();
        }
      }
    } catch (e) {
      if (mounted) ToastService.showError('Failed to reset password');
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.patch('/admin/users/${widget.userId}/status', data: {'status': newStatus});
      if (response.statusCode == 200) {
        ToastService.showSuccess('Status updated to $newStatus');
        _fetchData();
      }
    } catch (e) {
      if (mounted) ToastService.showError('Failed to update status');
    }
  }

  Future<void> _deleteUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive User', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to archive this user? They will no longer be able to log in, but their data will be preserved.', style: TextStyle(fontFamily: 'Poppins')),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: _C.textMuted))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Archive', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.delete('/admin/users/${widget.userId}');
      if (response.statusCode == 200) {
        ToastService.showSuccess('User archived successfully');
        if (mounted) context.go('/admin/users');
      }
    } catch (e) {
      if (mounted) ToastService.showError('Failed to archive user');
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE': return Colors.green;
      case 'PENDING': return Colors.orange;
      case 'SUSPENDED': return Colors.red;
      case 'DISABLED': return Colors.grey;
      case 'LOCKED': return Colors.deepPurple;
      case 'ARCHIVED': return Colors.black54;
      default: return Colors.grey;
    }
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.border),
      ),
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600, color: _C.textDark)),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontFamily: 'Poppins', color: _C.textMuted, fontSize: 14))),
          Expanded(child: Text(value, style: const TextStyle(fontFamily: 'Poppins', color: _C.textDark, fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildAuditLogList() {
    if (_auditLogs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No audit logs available for this user.', style: TextStyle(fontFamily: 'Poppins', color: _C.textMuted)),
        ),
      );
    }
    
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _auditLogs.length,
      separatorBuilder: (context, index) => const Divider(color: _C.border),
      itemBuilder: (context, index) {
        final log = _auditLogs[index];
        final date = DateTime.parse(log['timestamp']);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(8)),
                child: Icon(PhosphorIcons.listBullets(), color: _C.textMuted, size: 16),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log['action'], style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: _C.textDark, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(log['details']?.toString() ?? '', style: const TextStyle(fontFamily: 'Poppins', color: _C.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              Text(
                DateFormat('MMM d, yyyy HH:mm').format(date),
                style: const TextStyle(fontFamily: 'Poppins', color: _C.textFaint, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(color: _C.bg, child: const Center(child: CircularProgressIndicator(color: _C.green)));
    }

    if (_user == null) {
      return Container(color: _C.bg, child: const Center(child: Text('User not found')));
    }

    final String role = _user!['role'];
    final Map<String, dynamic>? profile = role == 'STUDENT' ? _user!['studentProfile'] : (role == 'SUPERVISOR' ? _user!['supervisorProfile'] : null);
    
    String regOrStaffNo = '-';
    if (role == 'STUDENT' && profile != null) regOrStaffNo = profile['registrationNo'] ?? '-';
    if (role == 'SUPERVISOR' && profile != null) regOrStaffNo = profile['staffNumber'] ?? '-';

    return Container(
      color: _C.bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => context.go('/admin/users'),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 18, offset: const Offset(0, 6)),
                            ],
                          ),
                          child: Icon(PhosphorIcons.arrowLeft(), color: _C.textDark),
                        ),
                      ),
                      const SizedBox(width: 24),
                      const Text(
                        'User Profile',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 28, fontWeight: FontWeight.bold, color: _C.textDark),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => context.push('/admin/users/${widget.userId}/edit'),
                        icon: Icon(PhosphorIcons.pencilSimple(), size: 18),
                        label: const Text('Edit Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _C.textDark,
                          side: const BorderSide(color: _C.border),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'reset') _resetPassword();
                          else if (value == 'delete') _deleteUser();
                          else _updateStatus(value);
                        },
                        itemBuilder: (context) => [
                          if (_user!['status'] != 'SUSPENDED')
                            const PopupMenuItem(value: 'SUSPENDED', child: Text('Suspend User', style: TextStyle(color: Colors.red))),
                          if (_user!['status'] == 'SUSPENDED')
                            const PopupMenuItem(value: 'ACTIVE', child: Text('Reactivate User', style: TextStyle(color: _C.green))),
                          const PopupMenuItem(value: 'reset', child: Text('Reset Password')),
                          const PopupMenuDivider(),
                          const PopupMenuItem(value: 'delete', child: Text('Archive User', style: TextStyle(color: Colors.red))),
                        ],
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _C.border),
                          ),
                          child: Icon(PhosphorIcons.dotsThreeVertical(), color: _C.textDark),
                        ),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 32),
              
              // Main Content
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column (Details)
                    Expanded(
                      flex: 4,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // User Summary Card
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: _C.border),
                              ),
                              padding: const EdgeInsets.all(32),
                              margin: const EdgeInsets.only(bottom: 24),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundColor: _C.green.withOpacity(0.1),
                                    child: Text(
                                      _user!['name'][0].toUpperCase(),
                                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 32, fontWeight: FontWeight.bold, color: _C.green),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_user!['name'], style: const TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.bold, color: _C.textDark)),
                                        const SizedBox(height: 4),
                                        Text(_user!['email'], style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: _C.textMuted)),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _C.bg,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                role,
                                                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: _C.textDark),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(_user!['status']).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                _user!['status'],
                                                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.bold, color: _getStatusColor(_user!['status'])),
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Specific Details
                            _buildInfoCard('Account Information', [
                              _buildInfoRow('Identifier', regOrStaffNo),
                              _buildInfoRow('Phone Number', profile?['phone'] ?? '-'),
                              _buildInfoRow('Department', profile?['department'] ?? '-'),
                              _buildInfoRow('Faculty', profile?['faculty'] ?? '-'),
                              if (role == 'STUDENT') _buildInfoRow('Programme', profile?['programme'] ?? '-'),
                              if (role == 'STUDENT') _buildInfoRow('Research Topic', profile?['topic'] ?? '-'),
                              if (role == 'SUPERVISOR') _buildInfoRow('Office', profile?['office'] ?? '-'),
                              if (role == 'SUPERVISOR') _buildInfoRow('Specialization', profile?['specialization'] ?? '-'),
                            ]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Right Column (Activity & Audit)
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _C.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Text('Audit & Activity Log', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600, color: _C.textDark)),
                            ),
                            const Divider(color: _C.border, height: 1),
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: _buildAuditLogList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

