import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Admin Dashboard', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Platform Overview',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Total Users', '1,245', Icons.people)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('Active Sessions', '342', Icons.computer)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Videos Uploaded', '45', Icons.video_library)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('Revenue (INR)', '₹24,500', Icons.currency_rupee)),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Content Management',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 16),
              _buildActionCard(
                context,
                title: 'Manage Video Lessons',
                subtitle: 'Add, update or remove YouTube unlisted links.',
                icon: Icons.ondemand_video,
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                context,
                title: 'Manage Practice Questions',
                subtitle: 'Review AI generated MCQs and add custom questions.',
                icon: Icons.quiz,
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                context,
                title: 'User Management',
                subtitle: 'View user progress, manage subscriptions.',
                icon: Icons.manage_accounts,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary, size: 28),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.primary.withAlpha(20), shape: BoxShape.circle),
              child: Icon(icon, color: AppTheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
