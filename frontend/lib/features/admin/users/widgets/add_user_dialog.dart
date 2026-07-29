import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/toast_service.dart';

class _C {
  static const Color green = Color(0xFF169B45);
  static const Color textDark = Color(0xFF171717);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textFaint = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
}

class AddUserDialog extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic> user, String tempPassword) onSuccess;
  const AddUserDialog({super.key, required this.onSuccess});

  @override
  ConsumerState<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends ConsumerState<AddUserDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _regStaffController = TextEditingController();
  
  // Extra fields
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  final _facultyController = TextEditingController();
  final _programmeController = TextEditingController();
  final _topicController = TextEditingController();
  
  final TextEditingController _officeController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  
  List<Map<String, dynamic>> _availableSupervisors = [];
  String? _selectedSupervisorId;

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

  String _selectedRole = 'Student';
  bool _isLoading = false;

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
        'studentCapacity': _capacityController.text.trim(),
      };

      final apiClient = ApiClient();
      final response = await apiClient.dio.post(endpoint, data: body);

      if (response.statusCode == 201) {
        ToastService.showSuccess('$_selectedRole created successfully');
        widget.onSuccess(response.data['user'] as Map<String, dynamic>, response.data['tempPassword'] as String);
        if (mounted) Navigator.pop(context);
      } else {
        ToastService.showError(response.data?['error'] ?? 'Failed to create user');
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['error'] ?? 'Failed to create user (Status ${e.response?.statusCode})';
      ToastService.showError(errorMsg);
    } catch (e) {
      ToastService.showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13, color: _C.textDark)),
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
        const Text('Assign Supervisor (Optional)', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13, color: _C.textDark)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _C.border)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSupervisorId,
              hint: const Text('Select a supervisor', style: TextStyle(fontFamily: 'Poppins', color: _C.textFaint, fontSize: 14)),
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add New User', style: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700, color: _C.textDark)),
                  IconButton(icon: Icon(PhosphorIcons.x()), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildTextField('Full Name', 'e.g. John Doe', _nameController),
                      const SizedBox(height: 16),
                      _buildTextField('Email Address', 'e.g. john@fieldtrack.edu', _emailController),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildDropdownField('Role', ['Student', 'Supervisor', 'Admin'])),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField(_selectedRole == 'Student' ? 'Reg Number' : 'Employee Number', 'Required', _regStaffController)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField('Phone', 'e.g. +254 700 000000', _phoneController),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('Faculty', 'e.g. Science', _facultyController)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField('Department', 'e.g. Computer Science', _departmentController)),
                        ],
                      ),
                      if (_selectedRole == 'Student') ...[
                        const SizedBox(height: 16),
                        _buildTextField('Programme', 'e.g. BSc Computer Science', _programmeController),
                        const SizedBox(height: 16),
                        _buildTextField('Research Topic', 'Optional', _topicController),
                        const SizedBox(height: 16),
                        _buildSupervisorDropdown(),
                      ],
                      if (_selectedRole == 'Supervisor') ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildTextField('Office', 'e.g. Room 402', _officeController)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTextField('Max Student Capacity', 'e.g. 20', _capacityController)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField('Specialization', 'e.g. AI, Machine Learning', _specializationController),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                    child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: _C.textDark)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: _C.green, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                    child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Add User', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

