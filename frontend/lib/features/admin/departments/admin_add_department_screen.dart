import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fieldtrack/core/network/api_client.dart';
import 'package:fieldtrack/core/utils/toast_service.dart';
import 'package:fieldtrack/features/admin/departments/admin_departments_screen.dart';
import 'package:fieldtrack/core/network/error_handler.dart';

class AdminAddDepartmentScreen extends ConsumerStatefulWidget {
  const AdminAddDepartmentScreen({super.key});

  @override
  ConsumerState<AdminAddDepartmentScreen> createState() => _AdminAddDepartmentScreenState();
}

class _AdminAddDepartmentScreenState extends ConsumerState<AdminAddDepartmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _facultyController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _facultyController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final api = ApiClient();
      await api.dio.post('/admin/departments', data: {
        'name': _nameController.text.trim(),
        'code': _codeController.text.trim(),
        'faculty': _facultyController.text.trim(),
        'description': _descriptionController.text.trim(),
      });
      
      if (mounted) {
        ToastService.showSuccess('Department created successfully');
        ref.invalidate(departmentsProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError('Failed to create department: ${ErrorHandler.getFriendlyErrorMessage(e)}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft(), color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Add New Department',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Department Details',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the information for the new department.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 32),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Card (Basic Details)
                  Expanded(
                    child: Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Basic Details',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Department Name',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                              decoration: InputDecoration(
                                hintText: 'e.g. Computer Science',
                                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontFamily: 'Inter'),
                                prefixIcon: Icon(PhosphorIcons.buildings(), color: const Color(0xFF9CA3AF)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF1BA654), width: 2),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            const Text(
                              'Department Code (Optional)',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _codeController,
                              decoration: InputDecoration(
                                hintText: 'e.g. CS',
                                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontFamily: 'Inter'),
                                prefixIcon: Icon(PhosphorIcons.hash(), color: const Color(0xFF9CA3AF)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF1BA654), width: 2),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            const Text(
                              'Faculty Name (Optional)',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _facultyController,
                              decoration: InputDecoration(
                                hintText: 'e.g. Faculty of Sciences',
                                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontFamily: 'Inter'),
                                prefixIcon: Icon(PhosphorIcons.bank(), color: const Color(0xFF9CA3AF)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF1BA654), width: 2),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  
                  // Right Card (Additional Info)
                  Expanded(
                    child: Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Additional Info',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Description (Optional)',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 6,
                              decoration: InputDecoration(
                                hintText: 'Brief description of the department...',
                                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontFamily: 'Inter'),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF1BA654), width: 2),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                              ),
                            ),
                            
                            const SizedBox(height: 48),
                            
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1BA654),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text(
                                        'Create Department',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
