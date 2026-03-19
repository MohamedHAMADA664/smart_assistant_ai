import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/assistant_profile_service.dart';
import '../services/voice_response_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AssistantProfileService _profileService = AssistantProfileService();
  final VoiceResponseService _voiceResponseService = VoiceResponseService();

  final TextEditingController _assistantNameController =
      TextEditingController();
  final TextEditingController _wakeWordController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isTestingVoice = false;
  bool _isRequestingPermissions = false;

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
    _voiceResponseService.dispose();
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
      await _voiceResponseService.refreshSettings();

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

      await _voiceResponseService.refreshSettings();

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
  // TEST VOICE
  // ================================

  Future<void> _testVoice() async {
    if (_isTestingVoice) {
      return;
    }

    setState(() {
      _isTestingVoice = true;
    });

    try {
      await _saveProfile();

      final testMessage = _voiceLanguage == 'en'
          ? 'Hello, I am ready to help you.'
          : 'مرحبًا، أنا جاهز لمساعدتك.';

      await _voiceResponseService.speak(testMessage);
    } catch (_) {
      _showSnackBar('تعذر اختبار الصوت');
    } finally {
      if (mounted) {
        setState(() {
          _isTestingVoice = false;
        });
      }
    }
  }

  // ================================
  // PERMISSIONS
  // ================================

  Future<void> _requestEssentialPermissions() async {
    if (_isRequestingPermissions) {
      return;
    }

    setState(() {
      _isRequestingPermissions = true;
    });

    try {
      final microphone = await Permission.microphone.request();
      final contacts = await Permission.contacts.request();
      final phone = await Permission.phone.request();
      final notification = await Permission.notification.request();

      final allGranted = microphone.isGranted &&
          contacts.isGranted &&
          phone.isGranted &&
          notification.isGranted;

      if (allGranted) {
        _showSnackBar('تم منح الصلاحيات الأساسية');
      } else {
        _showSnackBar('بعض الصلاحيات ما زالت غير مفعلة');
      }
    } catch (_) {
      _showSnackBar('تعذر طلب الصلاحيات');
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingPermissions = false;
        });
      }
    }
  }

  Future<void> _openAppPermissionSettings() async {
    final opened = await openAppSettings();

    if (!opened) {
      _showSnackBar('تعذر فتح إعدادات التطبيق');
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
                        value: _voiceLanguage,
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
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isTestingVoice ? null : _testVoice,
                          icon: _isTestingVoice
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.volume_up),
                          label: Text(
                            _isTestingVoice
                                ? 'جارٍ اختبار الصوت...'
                                : 'اختبار الصوت',
                          ),
                        ),
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
                _buildSectionTitle('الصلاحيات والتشخيص'),
                _buildCard(
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isRequestingPermissions
                              ? null
                              : _requestEssentialPermissions,
                          icon: _isRequestingPermissions
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.security),
                          label: Text(
                            _isRequestingPermissions
                                ? 'جارٍ طلب الصلاحيات...'
                                : 'طلب الصلاحيات الأساسية',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _openAppPermissionSettings,
                          icon: const Icon(Icons.settings_applications),
                          label: const Text('فتح إعدادات التطبيق'),
                        ),
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
