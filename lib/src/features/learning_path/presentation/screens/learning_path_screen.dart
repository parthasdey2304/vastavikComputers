import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class LearningPathScreen extends StatelessWidget {
  const LearningPathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for the learning path nodes
    final nodes = [
      {'title': 'Variables & Types', 'icon': Icons.data_object, 'color': Colors.green},
      {'title': 'Control Flow', 'icon': Icons.alt_route, 'color': Colors.green},
      {'title': 'Loops', 'icon': Icons.loop, 'color': Colors.orange},
      {'title': 'Functions', 'icon': Icons.functions, 'color': Colors.grey},
      {'title': 'Arrays', 'icon': Icons.view_array, 'color': Colors.grey},
      {'title': 'OOP Basics', 'icon': Icons.category, 'color': Colors.grey},
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Java Path', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 32),
        itemCount: nodes.length,
        itemBuilder: (context, index) {
          final node = nodes[index];
          // Calculate horizontal offset for zig-zag effect using a sine-like pattern
          // 0 -> center, 1 -> right, 2 -> right, 3 -> center, 4 -> left, 5 -> left
          double alignment = 0;
          final cycle = index % 4;
          if (cycle == 1) alignment = 0.5;
          if (cycle == 2) alignment = 0.5;
          if (cycle == 3) alignment = -0.5;
          if (cycle == 0 && index > 0) alignment = -0.5;
          if (index % 4 == 0) alignment = 0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Align(
              alignment: Alignment(alignment, 0),
              child: GestureDetector(
                onTap: () {
                  // Navigate to lesson detail
                  context.push('/lesson-detail', extra: node);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: node['color'] as Color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (node['color'] as Color).withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 4,
                        ),
                      ),
                      child: Icon(
                        node['icon'] as IconData,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      node['title'] as String,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
