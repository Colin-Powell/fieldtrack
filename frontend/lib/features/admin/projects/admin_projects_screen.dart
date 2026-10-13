import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../../../../core/network/api_client.dart';

// ── Project Model ──
class ResearchProject {
  final String id;
  final String topic;
  final String county;
  final String supervisor;
  final int students;
  final int progress;
  final String status;
  final String studentUserId;

  const ResearchProject({
    required this.id,
    required this.topic,
    required this.county,
    required this.supervisor,
    required this.students,
    required this.progress,
    required this.status,
    required this.studentUserId,
  });

  factory ResearchProject.fromJson(Map<String, dynamic> json) {
    return ResearchProject(
      id: json['id'] ?? '',
      topic: json['topic'] ?? 'Untitled Research',
      county: json['county'] ?? '',
      supervisor: json['supervisor'] ?? 'Not Assigned',
      students: json['students'] ?? 1,
      progress: json['progress'] ?? 0,
      status: json['status'] ?? 'Active',
      studentUserId: json['studentUserId'] ?? '',
    );
  }

  bool get isActive => status == 'Active';
  bool get isCompleted => status == 'Completed';
  double get progressFraction => progress / 100.0;
}

// ── Provider ──
final projectsProvider = FutureProvider<List<ResearchProject>>((ref) async {
  final api = ApiClient();
  final response = await api.dio.get('/admin/projects');
  final List<dynamic> data = response.data['projects'];
  return data
      .map((e) => ResearchProject.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ── Projects Screen ──
class AdminProjectsScreen extends ConsumerStatefulWidget {
  const AdminProjectsScreen({super.key});

  @override
  ConsumerState<AdminProjectsScreen> createState() =>
      _AdminProjectsScreenState();
}

class _AdminProjectsScreenState extends ConsumerState<AdminProjectsScreen> {
  String _filter = 'All Projects';

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
                'University Research Projects',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              Row(
                children: [
                  _buildFilterChip(
                    'All Projects',
                    _filter == 'All Projects',
                    () => setState(() => _filter = 'All Projects'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Active',
                    _filter == 'Active',
                    () => setState(() => _filter = 'Active'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Completed',
                    _filter == 'Completed',
                    () => setState(() => _filter = 'Completed'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ref
                .watch(projectsProvider)
                .when(
                  data: (projects) {
                    var filtered = projects;
                    if (_filter == 'Active')
                      filtered = projects.where((p) => p.isActive).toList();
                    if (_filter == 'Completed')
                      filtered = projects.where((p) => p.isCompleted).toList();

                    if (filtered.isEmpty) {
                      return Container(
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
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                PhosphorIcons.folders(),
                                size: 64,
                                color: const Color(0xFFD1D5DB),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No projects found',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Container(
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
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 20,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _tableHeader('Research Topic'),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _tableHeader('Supervisor'),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _tableHeader('Students'),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _tableHeader('Progress'),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: _tableHeader('Status'),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: () async {
                                ref.invalidate(projectsProvider);
                                await ref.read(projectsProvider.future);
                              },
                              child: ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => const Divider(
                                  height: 1,
                                  color: Color(0xFFE5E7EB),
                                ),
                                itemBuilder: (context, index) =>
                                    _buildProjectRow(filtered[index]),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => Container(
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
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1BA654),
                      ),
                    ),
                  ),
                  error: (err, stack) => Container(
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
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            PhosphorIcons.warning(),
                            size: 48,
                            color: const Color(0xFFEF4444),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Failed to load projects',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1BA654).withValues(alpha: 0.1)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1BA654).withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? const Color(0xFF1BA654)
                : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }

  Widget _tableHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6B7280),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildProjectRow(ResearchProject project) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (project.studentUserId.isNotEmpty) {
              context.push('/admin/users/profile/${project.studentUserId}');
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          PhosphorIcons.folders(),
                          size: 18,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          project.topic,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: const Color(0xFFF3F4F6),
                        child: Text(
                          project.supervisor.isNotEmpty
                              ? project.supervisor[0]
                              : '?',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          project.supervisor,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF4B5563),
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${project.students} Assigned',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: project.progressFraction,
                          backgroundColor: const Color(0xFFF3F4F6),
                          color: project.isCompleted
                              ? const Color(0xFF1BA654)
                              : Colors.blue,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${project.progress}%',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
                Expanded(flex: 1, child: _buildStatusBadge(project.status)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isActive = status == 'Active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.blue.withValues(alpha: 0.1)
            : const Color(0xFF1BA654).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.blue : const Color(0xFF1BA654),
        ),
      ),
    );
  }
}
