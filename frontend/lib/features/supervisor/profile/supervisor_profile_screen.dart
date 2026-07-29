import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';

class SupervisorProfileScreen extends ConsumerWidget {
  const SupervisorProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final userName = user?.name ?? 'Supervisor';
    final userEmail = user?.email ?? 'Not provided';
    final initial = userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'S';
    final phone = user?.phone ?? 'Not provided';
    final staffNumber = user?.staffNumber ?? 'Not provided';
    final department = user?.supervisorDepartment ?? 'Not provided';
    final specialization = user?.specialization ?? 'Not provided';
    final office = user?.office ?? 'Not provided';
    final capacity = user?.studentCapacity?.toString() ?? 'Not provided';

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Supervisor Profile',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column (Profile Details)
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Profile Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundColor: const Color(0xFF1BA654),
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName,
                                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        userEmail,
                                        style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF6B7280)),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1BA654).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(40),
                                        ),
                                        child: const Text(
                                          'Supervisor',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1BA654),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              const Divider(color: Color(0xFFE5E7EB)),
                              const SizedBox(height: 32),
                              
                              Row(
                                children: [
                                  Expanded(child: _buildTextField('Full Name', userName)),
                                  const SizedBox(width: 24),
                                  Expanded(child: _buildTextField('Staff Number', staffNumber)),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(child: _buildTextField('Email Address', userEmail)),
                                  const SizedBox(width: 24),
                                  Expanded(child: _buildTextField('Phone Number', phone)),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(child: _buildTextField('Department', department)),
                                  const SizedBox(width: 24),
                                  Expanded(child: _buildTextField('Specialization', specialization)),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(child: _buildTextField('Office Location', office)),
                                  const SizedBox(width: 24),
                                  Expanded(child: _buildTextField('Student Capacity', capacity)),
                                ],
                              ),

                              const SizedBox(height: 32),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1BA654),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                                  elevation: 0,
                                ),
                                child: const Text('Save Profile Updates', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                
                // Right Column (Security)
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Security & Password', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 24),
                        _buildTextField('Current Password', '••••••••', obscure: true),
                        const SizedBox(height: 24),
                        _buildTextField('New Password', '', obscure: true),
                        const SizedBox(height: 24),
                        const Divider(color: Color(0xFFE5E7EB)),
                        const SizedBox(height: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Two-Factor Authentication (2FA)', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('Add an extra layer of security', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.grey.shade500)),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1BA654),
                                side: const BorderSide(color: Color(0xFF1BA654)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                              ),
                              child: const Text('Enable 2FA'),
                            ),
                          ],
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
    );
  }

  Widget _buildTextField(String label, String value, {bool obscure = false}) {
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
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: TextFormField(
            initialValue: value,
            obscureText: obscure,
            readOnly: true, // Form fields are read-only for now until edit logic is added
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
                borderSide: const BorderSide(color: Color(0xFF1BA654), width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
