import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/toast_service.dart';

// ── Department Model ──
class DepartmentData {
  final String id;
  final String name;
  final int students;
  final int supervisors;
  final int projects;

  const DepartmentData({
    required this.id,
    required this.name,
    required this.students,
    required this.supervisors,
    required this.projects,
  });

  factory DepartmentData.fromJson(Map<String, dynamic> json) {
    return DepartmentData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      students: json['students'] ?? 0,
      supervisors: json['supervisors'] ?? 0,
      projects: json['projects'] ?? 0,
    );
  }
}

// ── Department Provider ──
final departmentsProvider = FutureProvider<List<DepartmentData>>((ref) async {
  final api = ApiClient();
  final response = await api.dio.get('/admin/departments');
  final List<dynamic> data = response.data['departments'];
  return data
      .map((e) => DepartmentData.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ── Department Screen ──
class AdminDepartmentsScreen extends ConsumerWidget {
  const AdminDepartmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine screen width for responsive padding
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth < 600 ? 16.0 : 32.0;

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Responsive Header
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 16,
              spacing: 16,
              children: [
                const Text(
                  'University Departments',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => context.push('/admin/departments/add'),
                  icon: Icon(PhosphorIcons.plus(), size: 18),
                  label: const Text('Add Department'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1BA654),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ref.watch(departmentsProvider).when(
                  data: (departments) {
                    if (departments.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              PhosphorIcons.buildings(),
                              size: 64,
                              color: const Color(0xFFD1D5DB),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No departments found',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Color(0xFF6B7280),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    // Responsive Grid using LayoutBuilder
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 4;
                        double aspectRatio = 1.2;

                        if (constraints.maxWidth < 600) {
                          crossAxisCount = 1;
                          aspectRatio = 1.5;
                        } else if (constraints.maxWidth < 900) {
                          crossAxisCount = 2;
                          aspectRatio = 1.3;
                        } else if (constraints.maxWidth < 1200) {
                          crossAxisCount = 3;
                          aspectRatio = 1.2;
                        }

                        return GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 24,
                            mainAxisSpacing: 24,
                            childAspectRatio: aspectRatio,
                          ),
                          itemCount: departments.length,
                          itemBuilder: (context, index) {
                            final dept = departments[index];
                            return _buildDeptCard(context, dept);
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1BA654)),
                  ),
                  error: (err, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIcons.warning(),
                          size: 48,
                          color: const Color(0xFFEF4444),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Error loading departments',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Color(0xFFEF4444),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$err',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  // Helper function to resolve dynamic icons based on department name
  IconData _getDepartmentIcon(String deptName) {
    final name = deptName.toLowerCase();
    
    if (name.contains('computer') || name.contains('software') || name.contains('tech') || name.contains('it')) {
      return PhosphorIcons.laptop();
    } else if (name.contains('engineer') || name.contains('mechanic')) {
      return PhosphorIcons.gear();
    } else if (name.contains('business') || name.contains('finance') || name.contains('commerce') || name.contains('management')) {
      return PhosphorIcons.briefcase();
    } else if (name.contains('medicin') || name.contains('nurs') || name.contains('health') || name.contains('clinic')) {
      return PhosphorIcons.firstAid();
    } else if (name.contains('art') || name.contains('design') || name.contains('architect')) {
      return PhosphorIcons.palette();
    } else if (name.contains('science') || name.contains('biology') || name.contains('chemistry') || name.contains('physics')) {
      return PhosphorIcons.flask();
    } else if (name.contains('law') || name.contains('legal')) {
      return PhosphorIcons.scales();
    } else if (name.contains('educat') || name.contains('teach')) {
      return PhosphorIcons.bookOpen();
    } else if (name.contains('agricultur') || name.contains('environment')) {
      return PhosphorIcons.plant();
    }
    
    return PhosphorIcons.buildings(); // Fallback icon
  }

  Widget _buildDeptCard(BuildContext context, DepartmentData dept) {
    // Generate a color based on the department name
    final colors = [
      const Color(0xFF169B45),
      const Color(0xFF3B82F6),
      const Color(0xFFA855F7),
      const Color(0xFF14B8A6),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];
    final colorIdx = dept.name.hashCode.abs() % colors.length;
    final accentColor = colors[colorIdx];
    final dynamicIcon = _getDepartmentIcon(dept.name);

    return GestureDetector(
      onTap: () => context.push('/admin/departments/${Uri.encodeComponent(dept.name)}'),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    dynamicIcon, // Applied Dynamic Icon Here
                    color: accentColor,
                    size: 24,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    PhosphorIcons.arrowRight(),
                    color: const Color(0xFF6B7280),
                  ),
                  onPressed: () => context.push(
                      '/admin/departments/${Uri.encodeComponent(dept.name)}'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              dept.name,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            const Divider(color: Color(0xFFE5E7EB)),
            const SizedBox(height: 16),
            
            // Expanded/Wrap to handle responsive content cleanly
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: 12,
                  children: [
                    _buildStat('Students', dept.students.toString()),
                    _buildStat('Supervisors', dept.supervisors.toString()),
                    _buildStat('Projects', dept.projects.toString()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}