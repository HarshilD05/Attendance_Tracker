import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_manager.dart';

class ThemeDebugScreen extends StatefulWidget {
  const ThemeDebugScreen({super.key});

  @override
  State<ThemeDebugScreen> createState() => _ThemeDebugScreenState();
}

class _ThemeDebugScreenState extends State<ThemeDebugScreen> {
  final ThemeManager _themeManager = ThemeManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Debug'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme Debug Information',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            
            // Theme Mode Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Theme: ${_themeManager.isDarkMode ? 'Dark' : 'Light'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        await _themeManager.toggleTheme();
                        setState(() {});
                      },
                      child: Text('Switch to ${_themeManager.isDarkMode ? 'Light' : 'Dark'} Theme'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Color Palette Preview
            Text(
              'Color Palette',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildColorCard('Primary', AppColors.primary),
                  _buildColorCard('Primary Light', AppColors.primaryLight),
                  _buildColorCard('Secondary', AppColors.secondary),
                  _buildColorCard('Background', AppColors.background),
                  _buildColorCard('Surface', AppColors.surface),
                  _buildColorCard('Card', AppColors.card),
                  _buildColorCard('Text Primary', AppColors.textPrimary),
                  _buildColorCard('Text Secondary', AppColors.textSecondary),
                  _buildColorCard('Error', AppColors.error),
                  _buildColorCard('Success', AppColors.success),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorCard(String name, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Text(
          name,
          style: TextStyle(
            color: _getContrastColor(color),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Color _getContrastColor(Color color) {
    // Simple contrast calculation
    double luminance = (0.299 * color.r + 0.587 * color.g + 0.114 * color.b) / 255;
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
