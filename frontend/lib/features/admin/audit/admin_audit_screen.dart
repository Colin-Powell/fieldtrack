import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AdminAuditScreen extends StatelessWidget {
  const AdminAuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                onPressed: () {},
                icon: Icon(PhosphorIcons.downloadSimple(), size: 18),
                label: const Text('Export Logs'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4B5563),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Row(
                      children: [
                        Expanded(flex: 1, child: _tableHeader('Time')),
                        Expanded(flex: 2, child: _tableHeader('Administrator')),
                        Expanded(flex: 2, child: _tableHeader('Action')),
                        Expanded(flex: 2, child: _tableHeader('Affected Resource')),
                        Expanded(flex: 2, child: _tableHeader('IP Address')),
                        Expanded(flex: 1, child: _tableHeader('Status')),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildAuditRow('09:20 AM', 'Super Admin', 'Deleted Student', 'MB21/PU/42321/22', '192.168.1.10', 'Success'),
                        _buildAuditRow('08:45 AM', 'John Doe', 'Updated Profile', 'Dr. Smith', '10.0.0.45', 'Success'),
                        _buildAuditRow('Yesterday', 'System', 'Automated Backup', 'Database', 'localhost', 'Success'),
                        _buildAuditRow('Yesterday', 'Jane Smith', 'Failed Login', 'Admin Portal', '203.0.113.42', 'Failed'),
                        _buildAuditRow('2 Days Ago', 'Super Admin', 'Created Supervisor', 'Prof. John', '192.168.1.10', 'Success'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildAuditRow(String time, String admin, String action, String resource, String ip, String status) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Expanded(flex: 1, child: Text(time, style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF6B7280), fontSize: 13))),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: const Color(0xFFF3F4F6),
                    child: Text(admin[0], style: const TextStyle(color: Color(0xFF4B5563), fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Text(admin, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
            Expanded(flex: 2, child: Text(action, style: const TextStyle(fontFamily: 'Inter', color: Colors.black, fontWeight: FontWeight.w500))),
            Expanded(flex: 2, child: Text(resource, style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF4B5563)))),
            Expanded(flex: 2, child: Text(ip, style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF6B7280), fontSize: 13))),
            Expanded(flex: 1, child: _buildStatusBadge(status)),
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
        color: isSuccess ? const Color(0xFF1BA654).withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
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
