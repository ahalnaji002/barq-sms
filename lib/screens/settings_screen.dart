import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/app_error_message.dart';
import '../services/database_service.dart';
import '../providers/app_security_provider.dart';
import '../providers/beneficiary_batch_provider.dart';
import '../providers/beneficiary_provider.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';

part 'parts/settings_screen_widgets.dart';
part 'parts/settings_actions.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color primaryColor = Color(0xFFFFB300);
  static const Color darkColor = Color(0xFF202020);

  static const String _defaultMessageKey = 'default_sms_message';
  static const String _confirmBeforeSendKey = 'confirm_before_send';

  bool _isLoading = true;
  bool _confirmBeforeSend = true;
  bool _isDeletingLogs = false;
  bool _isDeletingAllData = false;

  String _defaultMessage =
      'مرحبًا، يرجى التوجه إلى مركز التوزيع لاستلام المساعدة الخاصة بك.';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final preferences = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _defaultMessage = preferences.getString(_defaultMessageKey) ??
          'مرحبًا، يرجى التوجه إلى مركز التوزيع لاستلام المساعدة الخاصة بك.';

      _confirmBeforeSend = preferences.getBool(_confirmBeforeSendKey) ?? true;

      _isLoading = false;
    });
  }

  Future<void> _saveConfirmBeforeSend(bool value) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(
      _confirmBeforeSendKey,
      value,
    );

    if (!mounted) return;

    setState(() {
      _confirmBeforeSend = value;
    });
  }

  void _setScreenState(VoidCallback update) {
    if (!mounted) return;
    setState(update);
  }

  void _showAboutApplication() {
    showAboutDialog(
      context: context,
      applicationName: 'Barq SMS',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(17),
        ),
        child: const Icon(
          Icons.bolt_rounded,
          size: 38,
          color: darkColor,
        ),
      ),
      children: const [
        SizedBox(height: 10),
        Text(
          'تطبيق لإدارة بيانات المستفيدين وإرسال الرسائل '
          'وتوثيق عمليات التواصل والتوزيع.',
          textDirection: TextDirection.rtl,
          style: TextStyle(
            height: 1.6,
          ),
        ),
      ],
    );
  }

  void _showSnackBar({
    required String message,
    required Color color,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final securityProvider = context.watch<AppSecurityProvider>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background(context),
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: primaryColor,
          foregroundColor: darkColor,
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.settings_rounded,
                size: 24,
              ),
              SizedBox(width: 7),
              Text(
                'الإعدادات',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: primaryColor,
                ),
              )
            : SafeArea(
                top: false,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    18,
                    16,
                    28,
                  ),
                  children: [
                    _SettingsHeader(
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 22),
                    const _SectionTitle(
                      icon: Icons.palette_outlined,
                      title: 'المظهر',
                    ),
                    const SizedBox(height: 10),
                    _SettingsCard(
                      children: [
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 4,
                          ),
                          secondary: _SettingsIcon(
                            icon: isDarkMode
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                          ),
                          title: Text(
                            'الوضع الداكن',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.text(context),
                            ),
                          ),
                          subtitle: Text(
                            isDarkMode
                                ? 'الوضع الداكن مفعّل'
                                : 'تفعيل المظهر الداكن للتطبيق',
                            style: TextStyle(
                              color: AppColors.subtitle(context),
                            ),
                          ),
                          activeThumbColor: primaryColor,
                          value: themeProvider.isDarkMode,
                          onChanged: (_) {
                            themeProvider.toggleTheme();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const _SectionTitle(
                      icon: Icons.security_rounded,
                      title: 'الأمان والخصوصية',
                    ),
                    const SizedBox(height: 10),
                    _SettingsCard(
                      children: [
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 4,
                          ),
                          secondary: _SettingsIcon(
                            icon: securityProvider.isEnabled
                                ? Icons.lock_rounded
                                : Icons.lock_open_rounded,
                          ),
                          title: Text(
                            'قفل التطبيق برمز PIN',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.text(context),
                            ),
                          ),
                          subtitle: Text(
                            securityProvider.isEnabled
                                ? 'يُقفل تلقائيًا عند مغادرة التطبيق'
                                : 'حماية بيانات المستفيدين من الوصول غير المصرح',
                            style:
                                TextStyle(color: AppColors.subtitle(context)),
                          ),
                          activeThumbColor: primaryColor,
                          value: securityProvider.isEnabled,
                          onChanged: (enabled) {
                            if (enabled) {
                              _enableAppLock();
                            } else {
                              _disableAppLock();
                            }
                          },
                        ),
                        if (securityProvider.isEnabled) ...[
                          _SettingsDivider(),
                          _SettingsTile(
                            icon: Icons.password_rounded,
                            title: 'تغيير رمز PIN',
                            subtitle: 'إنشاء رمز جديد لقفل التطبيق',
                            onTap: _changeAppPin,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 22),
                    const _SectionTitle(
                      icon: Icons.sms_outlined,
                      title: 'إعدادات الرسائل',
                    ),
                    const SizedBox(height: 10),
                    _SettingsCard(
                      children: [
                        _SettingsTile(
                          icon: Icons.edit_note_rounded,
                          title: 'الرسالة الافتراضية',
                          subtitle: _defaultMessage,
                          onTap: _showDefaultMessageDialog,
                        ),
                        _SettingsDivider(),
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 4,
                          ),
                          secondary: const _SettingsIcon(
                            icon: Icons.verified_user_outlined,
                          ),
                          title: Text(
                            'تأكيد قبل الإرسال',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.text(context),
                            ),
                          ),
                          subtitle: Text(
                            'إظهار رسالة تأكيد قبل إرسال الرسائل',
                            style: TextStyle(
                              color: AppColors.subtitle(context),
                            ),
                          ),
                          activeThumbColor: primaryColor,
                          value: _confirmBeforeSend,
                          onChanged: _saveConfirmBeforeSend,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const _SectionTitle(
                      icon: Icons.storage_rounded,
                      title: 'إدارة البيانات',
                    ),
                    const SizedBox(height: 10),
                    _SettingsCard(
                      children: [
                        _SettingsTile(
                          icon: Icons.delete_sweep_outlined,
                          iconColor: Colors.red,
                          title: 'حذف سجل الرسائل',
                          subtitle: 'حذف جميع عمليات الإرسال المحفوظة',
                          trailing: _isDeletingLogs
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.3,
                                    color: Colors.red,
                                  ),
                                )
                              : const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: Colors.red,
                                ),
                          onTap: _isDeletingLogs ? null : _confirmDeleteSmsLogs,
                        ),
                        _SettingsDivider(),
                        _SettingsTile(
                          icon: Icons.delete_forever_rounded,
                          iconColor: Colors.red,
                          title: 'حذف جميع البيانات الحساسة',
                          subtitle:
                              'حذف الكشوف والمستفيدين وسجل الرسائل نهائيًا',
                          trailing: _isDeletingAllData
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.3,
                                    color: Colors.red,
                                  ),
                                )
                              : const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red,
                                ),
                          onTap: _isDeletingAllData
                              ? null
                              : _confirmDeleteAllSensitiveData,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const _SectionTitle(
                      icon: Icons.info_outline_rounded,
                      title: 'حول التطبيق',
                    ),
                    const SizedBox(height: 10),
                    _SettingsCard(
                      children: [
                        _SettingsTile(
                          icon: Icons.bolt_rounded,
                          title: 'Barq SMS',
                          subtitle: 'الإصدار 1.0.0',
                          onTap: _showAboutApplication,
                        ),
                        _SettingsDivider(),
                        const _SettingsTile(
                          icon: Icons.code_rounded,
                          title: 'تطوير التطبيق',
                          subtitle: 'Ahmed Alnaji',
                          showArrow: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
