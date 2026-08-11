import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fieldtrack/core/utils/image_utils.dart';
import 'package:fieldtrack/core/widgets/app_avatar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fieldtrack/core/network/api_client.dart';

final departmentDetailsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, deptId) async {
  final api = ApiClient();
  final response = await api.dio.get('/admin/departments/$deptId');
  return response.data;
});

class AdminDepartmentDetailScreen extends ConsumerWidget {
  final String departmentId;

  const AdminDepartmentDetailScreen({
    super.key,
    required this.departmentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          'Department Details',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ref.watch(departmentDetailsProvider(departmentId)).when(
        data: (data) {
          final dept = data['department'];
          final students = data['students'] as List<dynamic>;
          final supervisors = data['supervisors'] as List<dynamic>;
          final projects = data['projects'] as List<dynamic>;

          return DefaultTabController(
            length: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dept['name'] ?? 'Unknown Department',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      if (dept['description'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          dept['description'],
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF6B7280),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const TabBar(
                  labelColor: Color(0xFF1BA654),
                  unselectedLabelColor: Color(0xFF9CA3AF),
                  indicatorColor: Color(0xFF1BA654),
                  indicatorWeight: 3,
                  labelStyle: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                  tabs: [
                    Tab(text: 'Students'),
                    Tab(text: 'Supervisors'),
                    Tab(text: 'Projects'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildList(students, 'student'),
                      _buildList(supervisors, 'supervisor'),
                      _buildProjectList(projects),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1BA654))),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIcons.warning(), size: 48, color: const Color(0xFFEF4444)),
              const SizedBox(height: 16),
              const Text('Failed to load department details', style: TextStyle(fontFamily: 'Poppins', color: Color(0xFFEF4444))),
              Text(err.toString(), style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF6B7280))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<dynamic> items, String type) {
    if (items.isEmpty) {
      return Center(
        child: Text('No ${type}s found in this department.', style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF6B7280))),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(32),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final user = item['user'];
        return ListTile(
          leading: AppAvatar(
            imagePath: user['avatar'] as String?,
            initials: user['name']?.substring(0, 1) ?? 'U',
            size: 40,
            shape: AvatarShape.circle,
          ),
          title: Text(user['name'] ?? 'Unknown', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          subtitle: Text(user['email'] ?? '', style: const TextStyle(fontFamily: 'Inter')),
          trailing: const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB)),
          onTap: () {
            // Navigate to user profile if needed
          },
        );
      },
    );
  }

  Widget _buildProjectList(List<dynamic> projects) {
    if (projects.isEmpty) {
      return const Center(
        child: Text('No projects found in this department.', style: TextStyle(fontFamily: 'Inter', color: Color(0xFF6B7280))),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(32),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(PhosphorIcons.folder(), color: const Color(0xFF3B82F6)),
          ),
          title: Text(project['title'] ?? 'Untitled Project', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          subtitle: Text('By ${project['studentName']}', style: const TextStyle(fontFamily: 'Inter')),
          trailing: const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB)),
          onTap: () {
            // Navigate to project details if needed
          },
        );
      },
    );
  }
}
