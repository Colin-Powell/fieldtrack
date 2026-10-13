import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:math';
import '../../../../core/network/api_client.dart';

// ── Audit Log Model ──
class AuditLogEntry {
  final String id;
  final String time;
  final String administrator;
  final String action;
  final String affectedResource;
  final String ipAddress;
  final String status;

  const AuditLogEntry({
    required this.id,
    required this.time,
    required this.administrator,
    required this.action,
    required this.affectedResource,
    required this.ipAddress,
    required this.status,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'] ?? '',
      time: json['time'] ?? '',
      administrator: json['administrator'] ?? 'System',
      action: json['action'] ?? '',
      affectedResource: json['affectedResource'] ?? '-',
      ipAddress: json['ipAddress'] ?? '-',
      status: json['status'] ?? 'Success',
    );
  }

  String get formattedTime {
    try {
      final dt = DateTime.parse(time);
      return DateFormat('MMM d, yyyy HH:mm').format(dt);
    } catch (_) {
      return time;
    }
  }
}

// ── Pagination Model ──
class AuditLogsPage {
  final List<AuditLogEntry> logs;
  final int totalCount;
  final int currentPage;
  final int pageSize;

  AuditLogsPage({
    required this.logs,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
  });

  int get totalPages => (totalCount / pageSize).ceil();
  bool get hasNextPage => currentPage < totalPages - 1;
}

// ── Provider ──
final auditLogsPageProvider = FutureProvider.family<AuditLogsPage, (int, int)>((
  ref,
  params,
) async {
  final (page, pageSize) = params;
  final api = ApiClient();
  final offset = page * pageSize;

  final response = await api.dio.get(
    '/admin/audit-logs',
    queryParameters: {'limit': pageSize, 'offset': offset},
  );

  final List<dynamic> logsData = response.data['logs'] ?? [];
  final logs = logsData
      .map((e) => AuditLogEntry.fromJson(e as Map<String, dynamic>))
      .toList();

  return AuditLogsPage(
    logs: logs,
    totalCount: response.data['totalCount'] ?? 0,
    currentPage: page,
    pageSize: pageSize,
  );
});

// ── Export utilities ──
class _ExportUtils {
  static String generateCsv(List<AuditLogEntry> logs) {
    final buffer = StringBuffer();
    buffer.writeln(
      'Time,Administrator,Action,Affected Resource,IP Address,Status',
    );

    for (var log in logs) {
      buffer.writeln(
        '"${log.formattedTime}",'
        '"${log.administrator}",'
        '"${log.action}",'
        '"${log.affectedResource}",'
        '"${log.ipAddress}",'
        '"${log.status}"',
      );
    }

    return buffer.toString();
  }
}

// ── Audit Screen ──
class AdminAuditScreen extends ConsumerStatefulWidget {
  const AdminAuditScreen({super.key});

  @override
  ConsumerState<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends ConsumerState<AdminAuditScreen> {
  int _currentPage = 0;
  final int _pageSize = 25;

  Future<void> _exportAuditLogs() async {
    try {
      final response = await ApiClient().dio.get(
        '/admin/audit-logs',
        queryParameters: {'limit': 10000, 'offset': 0},
      );

      final List<dynamic> logsData = response.data['logs'] ?? [];
      final logs = logsData
          .map((e) => AuditLogEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      final csv = _ExportUtils.generateCsv(logs);
      final bytes = utf8.encode(csv);
      base64Encode(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported ${logs.length} audit logs')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageAsync = ref.watch(
      auditLogsPageProvider((_currentPage, _pageSize)),
    );

    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'System Audit Logs',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _exportAuditLogs,
                icon: Icon(PhosphorIcons.downloadSimple(), size: 18),
                label: const Text('Export Logs'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4B5563),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: pageAsync.when(
              data: (page) {
                if (page.logs.isEmpty && _currentPage == 0) {
                  return _buildEmptyContainer();
                }
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const minWidth = 1000.0;
                      final isNarrow = constraints.maxWidth < minWidth;

                      Widget content = Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 20,
                            ),
                            child: Row(
                              children: [
                                Expanded(flex: 2, child: _tableHeader('Time')),
                                Expanded(
                                  flex: 2,
                                  child: _tableHeader('Administrator'),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _tableHeader('Action'),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _tableHeader('Affected Resource'),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _tableHeader('IP Address'),
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
                            child: ListView.separated(
                              itemCount: page.logs.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                color: Color(0xFFE5E7EB),
                              ),
                              itemBuilder: (context, index) =>
                                  _buildAuditRow(page.logs[index]),
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Showing ${page.currentPage * _pageSize + 1}-${min((page.currentPage + 1) * _pageSize, page.totalCount)} of ${page.totalCount}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: _currentPage > 0
                                          ? () => setState(() => _currentPage--)
                                          : null,
                                      icon: Icon(
                                        PhosphorIcons.caretLeft(),
                                        size: 16,
                                      ),
                                      label: const Text('Previous'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Page ${page.currentPage + 1}/${page.totalPages}',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: page.hasNextPage
                                          ? () => setState(() => _currentPage++)
                                          : null,
                                      icon: Icon(
                                        PhosphorIcons.caretRight(),
                                        size: 16,
                                      ),
                                      label: const Text('Next'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );

                      if (isNarrow) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(width: minWidth, child: content),
                        );
                      }
                      return content;
                    },
                  ),
                );
              },
              loading: () => _buildLoadingContainer(),
              error: (err, stack) => _buildErrorContainer(err.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContainer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.listBullets(),
              size: 64,
              color: const Color(0xFFD1D5DB),
            ),
            const SizedBox(height: 16),
            const Text(
              'No audit logs available',
              style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingContainer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF1BA654)),
      ),
    );
  }

  Widget _buildErrorContainer(String error) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
              'Failed to load audit logs',
              style: TextStyle(fontFamily: 'Poppins', color: Color(0xFFEF4444)),
            ),
          ],
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

  Widget _buildAuditRow(AuditLogEntry log) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                log.formattedTime,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF6B7280),
                  fontSize: 13,
                ),
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
                      log.administrator.isNotEmpty ? log.administrator[0] : 'S',
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      log.administrator,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
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
                log.action,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                log.affectedResource,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF4B5563),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                log.ipAddress,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF6B7280),
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(flex: 1, child: _buildStatusBadge(log.status)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isSuccess = status == 'Success';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSuccess
            ? const Color(0xFF1BA654).withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSuccess ? const Color(0xFF1BA654) : Colors.red,
        ),
      ),
    );
  }
}
