import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:travalapp/model/traval_session.dart';
import 'package:travalapp/theme/app_theme.dart';
import 'package:travalapp/widgets/glass_container.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Box _settingsBox;

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box('user_settings');
  }

  // ── Read saved settings from Hive ──
  String get _userName => _settingsBox.get('userName', defaultValue: 'Traveler');
  bool get _soundEnabled => _settingsBox.get('soundEnabled', defaultValue: true);
  bool get _vibrationEnabled => _settingsBox.get('vibrationEnabled', defaultValue: true);

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('travel_sessions');
    final sessions = box
        .toMap()
        .entries
        .map((e) => TravelSession.fromMap(e.value))
        .toList();

    double totalDistance = 0;
    for (final s in sessions) {
      totalDistance += s.distance;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Settings',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 24),

            // ── Profile card with Edit button ──
            GradientGlassCard(
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: AppColors.primaryGradient,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(totalDistance / 1000).toStringAsFixed(1)} km total • ${sessions.length} trips',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Edit profile button
                  IconButton(
                    onPressed: () => _showEditProfileDialog(context),
                    icon: Icon(Icons.edit_rounded, color: AppColors.primary, size: 22),
                    tooltip: 'Edit Profile',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Notifications ──
            _sectionTitle('Notifications'),
            const SizedBox(height: 8),
            GradientGlassCard(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: Column(
                children: [
                  _settingsToggle(
                    'Sound Effects',
                    Icons.volume_up_rounded,
                    _soundEnabled,
                    (val) {
                      _settingsBox.put('soundEnabled', val);
                      setState(() {});
                    },
                  ),
                  _divider(),
                  _settingsToggle(
                    'Vibration',
                    Icons.vibration_rounded,
                    _vibrationEnabled,
                    (val) {
                      _settingsBox.put('vibrationEnabled', val);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Appearance ──
            _sectionTitle('Appearance'),
            const SizedBox(height: 8),
            GradientGlassCard(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: _settingsToggle(
                'Dark Mode',
                Icons.dark_mode_rounded,
                _settingsBox.get('isDarkMode', defaultValue: true),
                (val) {
                  _settingsBox.put('isDarkMode', val);
                  setState(() {});
                },
              ),
            ),

            const SizedBox(height: 24),

            // ── Data management ──
            _sectionTitle('Data'),
            const SizedBox(height: 8),
            GradientGlassCard(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: Column(
                children: [
                  _settingsAction(
                    'Clear All Data',
                    Icons.delete_sweep_rounded,
                    AppColors.accentRed,
                    () => _showClearConfirmation(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── About ──
            _sectionTitle('About'),
            const SizedBox(height: 8),
            GradientGlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: AppColors.primaryGradient,
                        ),
                        child: const Icon(
                          Icons.explore_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Travel Tracker',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Version 2.0.0',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Track your journeys, earn achievements, and visualize your travel stats. Built with Flutter.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // EDIT PROFILE DIALOG — actually saves to Hive
  // ══════════════════════════════════════════════════
  void _showEditProfileDialog(BuildContext context) {
    final nameController = TextEditingController(text: _userName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar display
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: AppColors.primaryGradient,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
            const SizedBox(height: 20),
            // Name field
            TextField(
              controller: nameController,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Your Name',
                labelStyle: TextStyle(color: AppColors.textMuted),
                hintText: 'Enter your name',
                hintStyle: TextStyle(color: AppColors.textMuted),
                prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.surfaceCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                _settingsBox.put('userName', nameController.text);
                setState(() {});
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── CONFIRMATION DIALOG ──
  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all your travel history and settings. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Hive.box('travel_sessions').clear();
              Hive.box('user_settings').clear();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared successfully.')),
              );
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRed),
            child: const Text('Clear Everything', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // HELPER WIDGETS
  // ══════════════════════════════════════════════════

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _settingsToggle(String title, IconData icon, bool value, Function(bool) onChanged) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      secondary: Icon(icon, color: AppColors.primary, size: 22),
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _settingsAction(String title, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: Icon(icon, color: color, size: 22),
      trailing: Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _divider() {
    return Divider(
      color: Colors.white.withAlpha((255 * 0.06).round()),
      height: 1,
      thickness: 1,
    );
  }
}
