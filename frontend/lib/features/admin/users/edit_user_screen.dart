import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/toast_service.dart';
import 'package:fieldtrack/core/network/error_handler.dart';

class _C {
  static const Color green = Color(0xFF169B45);
  static const Color textDark = Color(0xFF171717);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textFaint = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color bg = Color(0xFFF5F6F7);
}

class EditUserScreen extends ConsumerStatefulWidget {
  final String userId;
  const EditUserScreen({super.key, required this.userId});

  @override
  ConsumerState<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends ConsumerState<EditUserScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _regStaffController = TextEditingController();

  // Extra fields
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  final _facultyController = TextEditingController();
  final _programmeController = TextEditingController();
  final _topicController = TextEditingController();

  final _officeController = TextEditingController();
  final _specializationController = TextEditingController();
  final _capacityController = TextEditingController();

  List<Map<String, dynamic>> _availableSupervisors = [];
  String? _selectedSupervisorId;
  String _selectedRole = 'Student';
  String _selectedStatus = 'ACTIVE';

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final apiClient = ApiClient();

      // Fetch users for supervisor dropdown
      final usersResponse = await apiClient.dio.get('/admin/users');
      if (usersResponse.statusCode == 200) {
        final users = usersResponse.data['users'] as List<dynamic>;
        final supervisors = users
            .where((u) => u['role'] == 'SUPERVISOR')
            .toList();
        _availableSupervisors = supervisors
            .map((s) => {'id': s['id'], 'name': s['name']})
            .toList();
      }

      // Fetch user data
      final userResponse = await apiClient.dio.get(
        '/admin/users/${widget.userId}',
      );
      if (userResponse.statusCode == 200) {
        final user = userResponse.data['user'];
        _selectedRole = user['role'] == 'STUDENT'
            ? 'Student'
            : (user['role'] == 'SUPERVISOR' ? 'Supervisor' : 'Admin');
        _selectedStatus = user['status'];
        _nameController.text = user['name'] ?? '';
        _emailController.text = user['email'] ?? '';

        if (user['role'] == 'STUDENT' && user['studentProfile'] != null) {
          final p = user['studentProfile'];
          _regStaffController.text = p['registrationNo'] ?? '';
          _phoneController.text = p['phone'] ?? '';
          _departmentController.text = p['department'] ?? '';
          _facultyController.text = p['faculty'] ?? '';
          _programmeController.text = p['programme'] ?? '';
          _topicController.text = p['topic'] ?? '';
          _selectedSupervisorId = p['supervisorId'];
        } else if (user['role'] == 'SUPERVISOR' &&
            user['supervisorProfile'] != null) {
          final p = user['supervisorProfile'];
          _regStaffController.text = p['staffNumber'] ?? '';
          _phoneController.text = p['phone'] ?? '';
          _departmentController.text = p['department'] ?? '';
          _facultyController.text = p['faculty'] ?? '';
          _officeController.text = p['office'] ?? '';
          _specializationController.text = p['specialization'] ?? '';
          _capacityController.text = p['studentCapacity']?.toString() ?? '20';
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError('Failed to load user data');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _regStaffController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _facultyController.dispose();
    _programmeController.dispose();
    _topicController.dispose();
    _officeController.dispose();
    _specializationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ToastService.showError('Please fill required fields (Name)');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final body = {
        'name': name,
        'status': _selectedStatus,
        'phone': _phoneController.text.trim(),
        'programme': _programmeController.text.trim(),
        'department': _departmentController.text.trim(),
        'faculty': _facultyController.text.trim(),
        'topic': _topicController.text.trim(),
        'supervisorId': _selectedSupervisorId,
        'studentCapacity': _capacityController.text.trim(),
      };

      final apiClient = ApiClient();
      final response = await apiClient.dio.put(
        '/admin/users/${widget.userId}',
        data: body,
      );

      if (response.statusCode == 200) {
        ToastService.showSuccess('User updated successfully');
        if (mounted) context.go('/admin/users');
      } else {
        ToastService.showError(
          ErrorHandler.getFriendlyErrorMessage(response.data),
        );
      }
    } on DioException catch (e) {
      final errorMsg = ErrorHandler.getFriendlyErrorMessage(e);
      ToastService.showError(errorMsg);
    } catch (e) {
      ToastService.showError(ErrorHandler.getFriendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller, {
    bool isRequired = false,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: _C.textDark,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
              if (readOnly)
                const TextSpan(
                  text: ' (Restricted)',
                  style: TextStyle(
                    color: _C.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          style: TextStyle(
            fontFamily: 'Poppins',
            color: readOnly ? _C.textMuted : _C.textDark,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: 'Poppins',
              color: _C.textFaint,
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _C.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _C.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: readOnly ? _C.border : _C.green),
            ),
            filled: true,
            fillColor: readOnly ? _C.border.withOpacity(0.3) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    List<String> options,
    String currentValue,
    Function(String) onChanged, {
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: _C.textDark,
            ),
            children: [
              if (readOnly)
                const TextSpan(
                  text: ' (Restricted)',
                  style: TextStyle(
                    color: _C.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: readOnly ? _C.border.withOpacity(0.3) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentValue,
              isExpanded: true,
              icon: Icon(
                PhosphorIcons.caretDown(),
                color: readOnly ? Colors.transparent : _C.textMuted,
                size: 16,
              ),
              style: TextStyle(
                fontFamily: 'Poppins',
                color: readOnly ? _C.textMuted : _C.textDark,
                fontSize: 14,
              ),
              items: options
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: readOnly
                  ? null
                  : (v) {
                      if (v != null) onChanged(v);
                    },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupervisorDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assign Supervisor',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: _C.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSupervisorId,
              hint: const Text(
                'Select a supervisor (Optional)',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: _C.textFaint,
                  fontSize: 14,
                ),
              ),
              isExpanded: true,
              icon: Icon(
                PhosphorIcons.caretDown(),
                color: _C.textMuted,
                size: 16,
              ),
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: _C.textDark,
                fontSize: 14,
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('None'),
                ),
                ..._availableSupervisors.map(
                  (s) => DropdownMenuItem<String>(
                    value: s['id'],
                    child: Text(s['name']),
                  ),
                ),
              ],
              onChanged: (v) {
                setState(() => _selectedSupervisorId = v);
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _C.bg,
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _C.green))
            : Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
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
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              PhosphorIcons.arrowLeft(),
                              color: _C.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        const Text(
                          'Edit User',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _C.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Main Content
                    Expanded(
                      child: Container(
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
                        padding: const EdgeInsets.all(40),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Account Information',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: _C.textDark,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      'Full Name',
                                      'e.g. John Doe',
                                      _nameController,
                                      isRequired: true,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: _buildTextField(
                                      'Email Address',
                                      'e.g. john@fieldtrack.edu',
                                      _emailController,
                                      readOnly: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDropdownField(
                                      'Role',
                                      ['Student', 'Supervisor', 'Admin'],
                                      _selectedRole,
                                      (v) {},
                                      readOnly: true,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: _buildTextField(
                                      _selectedRole == 'Student'
                                          ? 'Reg Number'
                                          : 'Employee Number',
                                      'Required',
                                      _regStaffController,
                                      readOnly: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      'Phone Number',
                                      'e.g. +254 700 000000',
                                      _phoneController,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: _buildDropdownField(
                                      'Status',
                                      [
                                        'ACTIVE',
                                        'PENDING',
                                        'DISABLED',
                                        'SUSPENDED',
                                        'LOCKED',
                                        'ARCHIVED',
                                      ],
                                      _selectedStatus,
                                      (v) =>
                                          setState(() => _selectedStatus = v),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 48),
                              const Divider(color: _C.border),
                              const SizedBox(height: 32),

                              Text(
                                '${_selectedRole} Details',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: _C.textDark,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      'Faculty',
                                      'e.g. Science',
                                      _facultyController,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: _buildTextField(
                                      'Department',
                                      'e.g. Computer Science',
                                      _departmentController,
                                    ),
                                  ),
                                ],
                              ),

                              if (_selectedRole == 'Student') ...[
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        'Programme',
                                        'e.g. BSc Computer Science',
                                        _programmeController,
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: _buildTextField(
                                        'Research Topic',
                                        'Optional',
                                        _topicController,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                _buildSupervisorDropdown(),
                              ],

                              if (_selectedRole == 'Supervisor') ...[
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        'Office',
                                        'e.g. Room 402',
                                        _officeController,
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: _buildTextField(
                                        'Max Student Capacity',
                                        'e.g. 20',
                                        _capacityController,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                _buildTextField(
                                  'Specialization',
                                  'e.g. AI, Machine Learning',
                                  _specializationController,
                                ),
                              ],

                              const SizedBox(height: 48),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton(
                                    onPressed: _isSaving
                                        ? null
                                        : () => context.go('/admin/users'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 20,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      side: const BorderSide(color: _C.border),
                                    ),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                        color: _C.textDark,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    onPressed: _isSaving ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _C.green,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 20,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isSaving
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'Save Changes',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 16,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
