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

class AddUserScreen extends ConsumerStatefulWidget {
  const AddUserScreen({super.key});

  @override
  ConsumerState<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends ConsumerState<AddUserScreen> {
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSupervisors();
  }

  Future<void> _fetchSupervisors() async {
    try {
      final response = await ApiClient().dio.get('/admin/users');
      if (response.statusCode == 200) {
        final users = response.data['users'] as List<dynamic>;
        final supervisors = users.where((u) => u['role'] == 'SUPERVISOR').toList();
        if (mounted) {
          setState(() {
            _availableSupervisors = supervisors.map((s) => {
              'id': s['id'],
              'name': s['name'],
            }).toList();
          });
        }
      }
    } catch (e) {
      // Silently fail or log
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
    final email = _emailController.text.trim();
    final regStaff = _regStaffController.text.trim();

    if (name.isEmpty || email.isEmpty || regStaff.isEmpty) {
      ToastService.showError('Please fill required fields (Name, Email, Number)');
      return;
    }

    if (_selectedRole == 'Admin') {
      ToastService.showError('Admin creation not supported yet');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final parts = name.split(' ');
      final firstName = parts.first;
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : 'User';

      final endpoint = _selectedRole == 'Student' 
          ? '/admin/users/students' 
          : '/admin/users/supervisors';

      final body = _selectedRole == 'Student' ? {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'registrationNo': regStaff,
        'phone': _phoneController.text.trim(),
        'programme': _programmeController.text.trim(),
        'department': _departmentController.text.trim(),
        'faculty': _facultyController.text.trim(),
        'researchTopic': _topicController.text.trim(),
        if (_selectedSupervisorId != null) 'supervisorId': _selectedSupervisorId,
      } : {
        'fullName': name,
        'email': email,
        'staffNumber': regStaff,
        'phone': _phoneController.text.trim(),
        'department': _departmentController.text.trim(),
        'faculty': _facultyController.text.trim(),
        'office': _officeController.text.trim(),
        'specialization': _specializationController.text.trim(),
        'studentCapacity': int.tryParse(_capacityController.text.trim()) ?? 20,
      };

      final apiClient = ApiClient();
      final response = await apiClient.dio.post(endpoint, data: body);

      if (response.statusCode == 201) {
        ToastService.showSuccess('$_selectedRole created successfully');
        final tempPassword = response.data['tempPassword'] as String;
        
        // Show temp password dialog before navigating back
        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('User Created', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
              content: SelectableText(
                'The user was created successfully.\n\nTemporary Password:\n$tempPassword\n\nPlease copy this password and share it with the user securely. They will be forced to change it on their first login.',
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('I copied it, Done', style: TextStyle(color: _C.green, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
          
          if (mounted) {
            context.go('/admin/users'); // Go back to users list, where it will refresh
          }
        }
      } else {
        ToastService.showError(response.data?['error'] ?? 'Failed to create user');
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['error'] ?? 'Failed to create user (Status ${e.response?.statusCode})';
      ToastService.showError(errorMsg);
    } catch (e) {
      ToastService.showError(ErrorHandler.getFriendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13, color: _C.textDark),
            children: [
              if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontFamily: 'Poppins', color: _C.textFaint, fontSize: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _C.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _C.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _C.green)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13, color: _C.textDark)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _C.border)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRole,
              isExpanded: true,
              icon: Icon(PhosphorIcons.caretDown(), color: _C.textMuted, size: 16),
              style: const TextStyle(fontFamily: 'Poppins', color: _C.textDark, fontSize: 14),
              items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedRole = v);
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
        const Text('Assign Supervisor', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13, color: _C.textDark)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _C.border)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSupervisorId,
              hint: const Text('Select a supervisor (Optional)', style: TextStyle(fontFamily: 'Poppins', color: _C.textFaint, fontSize: 14)),
              isExpanded: true,
              icon: const Icon(PhosphorIconsRegular.caretDown, color: _C.textMuted, size: 16),
              style: const TextStyle(fontFamily: 'Poppins', color: _C.textDark, fontSize: 14),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('None')),
                ..._availableSupervisors.map((s) => DropdownMenuItem<String>(value: s['id'], child: Text(s['name']))),
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
        child: Padding(
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
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Icon(PhosphorIcons.arrowLeft(), color: _C.textDark),
                    ),
                  ),
                  const SizedBox(width: 24),
                  const Text(
                    'Add New User',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 28, fontWeight: FontWeight.bold, color: _C.textDark),
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
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 6)),
                    ],
                  ),
                  padding: const EdgeInsets.all(40),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Account Information', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600, color: _C.textDark)),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: _buildTextField('Full Name', 'e.g. John Doe', _nameController, isRequired: true)),
                            const SizedBox(width: 24),
                            Expanded(child: _buildTextField('Email Address', 'e.g. john@fieldtrack.edu', _emailController, isRequired: true)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: _buildDropdownField('Role', ['Student', 'Supervisor', 'Admin'])),
                            const SizedBox(width: 24),
                            Expanded(child: _buildTextField(_selectedRole == 'Student' ? 'Reg Number' : 'Employee Number', 'Required', _regStaffController, isRequired: true)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildTextField('Phone Number', 'e.g. +254 700 000000', _phoneController),
                        
                        const SizedBox(height: 48),
                        const Divider(color: _C.border),
                        const SizedBox(height: 32),
                        
                        Text('${_selectedRole} Details', style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600, color: _C.textDark)),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: _buildTextField('Faculty', 'e.g. Science', _facultyController)),
                            const SizedBox(width: 24),
                            Expanded(child: _buildTextField('Department', 'e.g. Computer Science', _departmentController)),
                          ],
                        ),
                        
                        if (_selectedRole == 'Student') ...[
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(child: _buildTextField('Programme', 'e.g. BSc Computer Science', _programmeController)),
                              const SizedBox(width: 24),
                              Expanded(child: _buildTextField('Research Topic', 'Optional', _topicController)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildSupervisorDropdown(),
                        ],
                        
                        if (_selectedRole == 'Supervisor') ...[
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(child: _buildTextField('Office', 'e.g. Room 402', _officeController)),
                              const SizedBox(width: 24),
                              Expanded(child: _buildTextField('Max Student Capacity', 'e.g. 20', _capacityController)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildTextField('Specialization', 'e.g. AI, Machine Learning', _specializationController),
                        ],
                        
                        const SizedBox(height: 48),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: _isLoading ? null : () => context.go('/admin/users'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                side: const BorderSide(color: _C.border),
                              ),
                              child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: _C.textDark)),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _C.green,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _isLoading 
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Create Account', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        )
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

