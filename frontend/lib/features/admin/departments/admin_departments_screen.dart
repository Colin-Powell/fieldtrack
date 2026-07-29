import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AdminDepartmentsScreen extends StatelessWidget {
  const AdminDepartmentsScreen({super.key});

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
                'University Departments',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(PhosphorIcons.plus(), size: 18),
                label: const Text('Add Department'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1BA654),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 1.2,
              children: [
                _buildDeptCard('Environmental Sciences', 42, 6, 18),
                _buildDeptCard('Computer Science', 150, 12, 45),
                _buildDeptCard('Information Technology', 120, 10, 32),
                _buildDeptCard('Civil Engineering', 80, 8, 25),
                _buildDeptCard('Architecture', 65, 5, 20),
                _buildDeptCard('Business Administration', 210, 15, 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeptCard(String name, int students, int supervisors, int projects) {
    return Container(
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
                  color: const Color(0xFF169B45),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(PhosphorIcons.buildings(), color: const Color(0xFF4B5563), size: 24),
              ),
              IconButton(
                icon: Icon(PhosphorIcons.dotsThree(), color: const Color(0xFF6B7280)),
                onPressed: () {},
              )
            ],
          ),
          const SizedBox(height: 24),
          Text(
            name,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat('Students', students.toString()),
              _buildStat('Supervisors', supervisors.toString()),
              _buildStat('Projects', projects.toString()),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
