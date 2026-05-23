import 'package:flutter/material.dart';

class StaffDashboardScreen extends StatelessWidget {
  final String role;

  const StaffDashboardScreen({super.key, required this.role});

  String get title => 'Admin Dashboard';
  String get subtitle => 'Full campus oversight and user management tools.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            _buildInfoCard(
              icon: Icons.group,
              title: 'User Management',
              subtitle: 'View, verify, and change roles for students and security personnel.',
              color: Colors.purple,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.map,
              title: 'Active Alerts',
              subtitle: 'Monitor active alerts and broadcast campus-wide messages.',
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.directions_walk,
              title: 'Escort Requests',
              subtitle: 'Accept pending walk requests and manage pickups.',
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.report,
              title: 'Verification Queue',
              subtitle: 'Verify new accounts and manage security clearances.',
              color: Colors.orange,
            ),
            const SizedBox(height: 28),
            _buildRoleCapabilities(
              'As an Administrator',
              [
                'Full control over the campus safety system',
                'Manage all user accounts and assign roles',
                'View system-wide alerts and activity logs',
                'Broadcast emergency messages to campus',
                'Review and verify security clearances',
                'Accept and manage walk requests',
                'View and manage real-time safety alerts',
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildRoleCapabilities(String title, List<String> capabilities) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A73E8).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1A73E8).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A73E8),
            ),
          ),
          const SizedBox(height: 12),
          ...capabilities.map((capability) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.check_circle,
                      size: 18,
                      color: Color(0xFF1A73E8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      capability,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color.darken()),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension ColorExtension on Color {
  Color darken([double amount = .15]) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
}
