import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AdminProjectsScreen extends StatelessWidget {
  const AdminProjectsScreen({super.key});

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
                  _buildFilterChip('All Projects', true),
                  const SizedBox(width: 8),
                  _buildFilterChip('Active', false),
                  const SizedBox(width: 8),
                  _buildFilterChip('Completed', false),
                ],
              )
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Container(
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: _tableHeader('Research Topic')),
                        Expanded(flex: 2, child: _tableHeader('County')),
                        Expanded(flex: 2, child: _tableHeader('Supervisor')),
                        Expanded(flex: 2, child: _tableHeader('Students')),
                        Expanded(flex: 2, child: _tableHeader('Progress')),
                        Expanded(flex: 1, child: _tableHeader('Status')),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildProjectRow('Mangrove Reforestation Impact', 'Mombasa', 'Dr. Smith', '3', 75, 'Active'),
                        _buildProjectRow('Urban Heat Island Effect', 'Nairobi', 'Prof. John', '5', 40, 'Active'),
                        _buildProjectRow('Soil Erosion Assessment', 'Machakos', 'Dr. Emily', '2', 100, 'Completed'),
                        _buildProjectRow('Water Quality in Lake Victoria', 'Kisumu', 'Mr. Robert', '4', 15, 'Active'),
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

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1BA654).withValues(alpha: 0.1) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFF1BA654).withValues(alpha: 0.3) : Colors.transparent,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? const Color(0xFF1BA654) : const Color(0xFF4B5563),
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

  Widget _buildProjectRow(String topic, String county, String supervisor, String students, int progress, String status) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
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
                        child: Icon(PhosphorIcons.folders(), size: 18, color: const Color(0xFF4B5563)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          topic,
                          style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(flex: 2, child: Text(county, style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF4B5563)))),
                Expanded(flex: 2, child: Text(supervisor, style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF4B5563)))),
                Expanded(flex: 2, child: Text('$students Assigned', style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF4B5563)))),
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          backgroundColor: const Color(0xFFF3F4F6),
                          color: progress == 100 ? const Color(0xFF1BA654) : Colors.blue,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('$progress%', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF4B5563))),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
                Expanded(flex: 1, child: _buildStatusBadge(status)),
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
        color: isActive ? Colors.blue.withValues(alpha: 0.1) : const Color(0xFF1BA654).withValues(alpha: 0.1),
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
