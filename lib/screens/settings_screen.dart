import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SharedPreferences _prefs;
  bool _locationEnabled = true;
  bool _liveUpdates = true;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _locationEnabled = _prefs.getBool('location_enabled') ?? true;
      _liveUpdates = _prefs.getBool('live_updates') ?? true;
      _themeMode = ThemeMode.values[_prefs.getInt('theme_mode') ?? 0];
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await _prefs.setBool('location_enabled', _locationEnabled);
    await _prefs.setBool('live_updates', _liveUpdates);
    await _prefs.setInt('theme_mode', _themeMode.index);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildPreferenceCard(
            'Features',
            [
              SwitchListTile(
                value: _locationEnabled,
                onChanged: (value) {
                  setState(() => _locationEnabled = value);
                  _saveSettings();
                },
                title: const Text('Location Services'),
                subtitle: const Text('Show nearby stops and routes'),
                secondary: const Icon(Icons.location_on_outlined),
              ),
              SwitchListTile(
                value: _liveUpdates,
                onChanged: (value) {
                  setState(() => _liveUpdates = value);
                  _saveSettings();
                },
                title: const Text('Live Updates'),
                subtitle: const Text('Receive real-time bus locations'),
                secondary: const Icon(Icons.sync),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPreferenceCard(
            'Appearance',
            [
              ListTile(
                title: const Text('Theme'),
                subtitle: Text(_getThemeText()),
                leading: const Icon(Icons.palette_outlined),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showThemeDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPreferenceCard(
            'About',
            [
              ListTile(
                title: const Text('Powered by domz'),
                subtitle: const Text('1.0.0'),
                leading: const Icon(Icons.info_outline),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPreferenceCard(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  String _getThemeText() {
    switch (_themeMode) {
      case ThemeMode.system:
        return 'System default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('System default'),
              value: ThemeMode.system,
              groupValue: _themeMode,
              onChanged: (value) {
                setState(() => _themeMode = value!);
                _saveSettings();
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: _themeMode,
              onChanged: (value) {
                setState(() => _themeMode = value!);
                _saveSettings();
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: _themeMode,
              onChanged: (value) {
                setState(() => _themeMode = value!);
                _saveSettings();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}