import 'package:flutter/material.dart';

import '../services/assistant_profile_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AssistantProfileService _profileService = AssistantProfileService();

  final TextEditingController _assistantNameController =
      TextEditingController();
  final TextEditingController _wakeWordController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  String _voiceLanguage = 'ar';
  double _speechRate = 0.5;
  bool _notificationsEnabled = true;
  bool _onlineAiEnabled = false;
  bool _backgroundModeEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _assistantNameController.dispose();
    _wakeWordController.dispose();
    super.dispose();
  }

  // ================================
  // LOAD PROFILE
  // ================================

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profile = await _profileService.loadProfile();

      _assistantNameController.text = profile.assistantName;
      _wakeWordController.text = profile.wakeWord;
      _voiceLanguage = profile.voiceLanguage;
      _speechRate = profile.speechRate;
      _notificationsEnabled = profile.notificationsEnabled;
      _onlineAiEnabled = profile.onlineAiEnabled;
      _backgroundModeEnabled = profile.backgroundModeEnabled;
    } catch (_) {
      _showSnackBar('تعذر تحميل الإعدادات');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ================================
  // SAVE PROFILE
  // ================================

  Future<void> _saveProfile() async {
    final assistantName = _assistantNameController.text.trim();
    final wakeWord = _wakeWordController.text.trim();

    if (assistantName.isEmpty) {
      _showSnackBar('اكتب اسم المساعد');
      return;
    }

    if (wakeWord.isEmpty) {
      _showSnackBar('اكتب كلمة النداء');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final profile = AssistantProfile(
        assistantName: assistantName,
        wakeWord: wakeWord,
        voiceLanguage: _voiceLanguage,
        speechRate: _speechRate,
        notificationsEnabled: _notificationsEnabled,
        onlineAiEnabled: _onlineAiEnabled,
        backgroundModeEnabled: _backgroundModeEnabled,
      );

      await _profileService.saveProfile(profile);

      _showSnackBar('تم حفظ الإعدادات');
    } catch (_) {
      _showSnackBar('حدث خطأ أثناء حفظ الإعدادات');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ================================
  // RESET PROFILE
  // ================================

  Future<void> _resetProfile() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final profile = await _profileService.resetProfile();

      _assistantNameController.text = profile.assistantName;
      _wakeWordController.text = profile.wakeWord;
      _voiceLanguage = profile.voiceLanguage;
      _speechRate = profile.speechRate;
      _notificationsEnabled = profile.notificationsEnabled;
      _onlineAiEnabled = profile.onlineAiEnabled;
      _backgroundModeEnabled = profile.backgroundModeEnabled;

      _showSnackBar('تمت إعادة ضبط الإعدادات');
    } catch (_) {
      _showSnackBar('تعذر إعادة ضبط الإعدادات');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ================================
  // UI HELPERS
  // ================================

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  // ================================
  // BUILD
  // ================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionTitle('هوية المساعد'),
                _buildCard(
                  child: Column(
                    children: [
                      TextField(
                        controller: _assistantNameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم المساعد',
                          hintText: 'مثال: مساعدي',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _wakeWordController,
                        decoration: const InputDecoration(
                          labelText: 'كلمة النداء',
                          hintText: 'مثال: يا مساعدي',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildSectionTitle('الصوت'),
                _buildCard(
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _voiceLanguage,
                        decoration: const InputDecoration(
                          labelText: 'لغة الصوت',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'ar',
                            child: Text('العربية'),
                          ),
                          DropdownMenuItem(
                            value: 'en',
                            child: Text('English'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            _voiceLanguage = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'سرعة الصوت: ${_speechRate.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Slider(
                        value: _speechRate,
                        min: 0.1,
                        max: 1.0,
                        divisions: 9,
                        label: _speechRate.toStringAsFixed(2),
                        onChanged: (value) {
                          setState(() {
                            _speechRate = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                _buildSectionTitle('السلوك'),
                _buildCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('تفعيل قراءة الإشعارات'),
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('تفعيل الذكاء عبر الإنترنت'),
                        subtitle: const Text(
                          'سيتم استخدامه لاحقًا للأسئلة العامة والمهام الذكية',
                        ),
                        value: _onlineAiEnabled,
                        onChanged: (value) {
                          setState(() {
                            _onlineAiEnabled = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('العمل في الخلفية'),
                        value: _backgroundModeEnabled,
                        onChanged: (value) {
                          setState(() {
                            _backgroundModeEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isSaving ? 'جارٍ الحفظ...' : 'حفظ الإعدادات',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _resetProfile,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('إعادة ضبط الإعدادات'),
                ),
              ],
            ),
    );
  }
}
