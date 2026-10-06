part of '../settings_screen.dart';

extension _SettingsActions on _SettingsScreenState {
  Future<void> _showDefaultMessageDialog() async {
    final controller = TextEditingController(
      text: _defaultMessage,
    );

    final savedMessage = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: AppColors.card(dialogContext),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'الرسالة الافتراضية',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(dialogContext),
                    ),
                  ),
                ),
              ],
            ),
            content: TextField(
              controller: controller,
              maxLines: 6,
              minLines: 4,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'اكتب الرسالة الافتراضية هنا...',
                filled: true,
                fillColor: AppColors.background(dialogContext),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: AppColors.border(dialogContext),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: AppColors.border(dialogContext),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
              style: TextStyle(
                color: AppColors.text(dialogContext),
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('إلغاء'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: const Color(0xFF202020),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                onPressed: () {
                  final message = controller.text.trim();

                  if (message.isEmpty) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'يرجى كتابة نص الرسالة',
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(
                    dialogContext,
                    message,
                  );
                },
                icon: const Icon(
                  Icons.save_outlined,
                  size: 19,
                ),
                label: const Text(
                  'حفظ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (savedMessage == null || !mounted) return;

    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      'default_sms_message',
      savedMessage,
    );

    if (!mounted) return;

    _setScreenState(() {
      _defaultMessage = savedMessage;
    });

    _showSnackBar(
      message: 'تم حفظ الرسالة الافتراضية',
      color: Colors.green,
      icon: Icons.check_circle_outline_rounded,
    );
  }

  Future<void> _confirmDeleteSmsLogs() async {
    if (_isDeletingLogs) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: AppColors.card(dialogContext),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.delete_sweep_outlined,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'حذف سجل الرسائل',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(dialogContext),
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              'هل تريد حذف جميع سجلات الرسائل؟\n\n'
              'لا يمكن التراجع عن هذه العملية.',
              style: TextStyle(
                height: 1.5,
                color: AppColors.text(dialogContext),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text('إلغاء'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 19,
                ),
                label: const Text(
                  'حذف الكل',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    _setScreenState(() {
      _isDeletingLogs = true;
    });

    try {
      await DatabaseService.instance.deleteAllSmsLogs();

      if (!mounted) return;

      _setScreenState(() {
        _isDeletingLogs = false;
      });

      _showSnackBar(
        message: 'تم حذف سجل الرسائل بنجاح',
        color: Colors.green,
        icon: Icons.check_circle_outline_rounded,
      );
    } catch (error) {
      if (!mounted) return;

      _setScreenState(() {
        _isDeletingLogs = false;
      });

      _showSnackBar(
        message: AppErrorMessage.from(error, action: 'حذف سجل الرسائل'),
        color: Colors.red,
        icon: Icons.error_outline_rounded,
      );
    }
  }

  Future<String?> _requestPin({
    required String title,
    String? confirmationLabel,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 8,
            decoration: const InputDecoration(
              labelText: 'رمز PIN (من 4 إلى 8 أرقام)',
              prefixIcon: Icon(Icons.password_rounded),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final pin = controller.text.trim();
                if (!RegExp(r'^\d{4,8}$').hasMatch(pin)) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('يجب أن يتكون الرمز من 4 إلى 8 أرقام'),
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext, pin);
              },
              child: Text(confirmationLabel ?? 'تأكيد'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _enableAppLock() async {
    final first = await _requestPin(title: 'إنشاء رمز PIN');
    if (first == null || !mounted) return;
    final second = await _requestPin(title: 'تأكيد رمز PIN');
    if (second == null || !mounted) return;
    if (first != second) {
      _showSnackBar(
        message: 'رمزا PIN غير متطابقين',
        color: Colors.red,
        icon: Icons.error_outline_rounded,
      );
      return;
    }
    await context.read<AppSecurityProvider>().enable(first);
    if (!mounted) return;
    _showSnackBar(
      message: 'تم تفعيل قفل التطبيق',
      color: Colors.green,
      icon: Icons.lock_rounded,
    );
  }

  Future<void> _disableAppLock() async {
    final pin = await _requestPin(title: 'أدخل رمز PIN الحالي');
    if (pin == null || !mounted) return;
    final success = await context.read<AppSecurityProvider>().disable(pin);
    if (!mounted) return;
    _showSnackBar(
      message: success ? 'تم إلغاء قفل التطبيق' : 'رمز PIN غير صحيح',
      color: success ? Colors.green : Colors.red,
      icon: success ? Icons.lock_open_rounded : Icons.error_outline_rounded,
    );
  }

  Future<void> _changeAppPin() async {
    final current = await _requestPin(title: 'رمز PIN الحالي');
    if (current == null || !mounted) return;
    final next = await _requestPin(title: 'رمز PIN الجديد');
    if (next == null || !mounted) return;
    final confirmation = await _requestPin(title: 'تأكيد رمز PIN الجديد');
    if (confirmation == null || !mounted) return;
    if (next != confirmation) {
      _showSnackBar(
        message: 'رمزا PIN الجديدان غير متطابقين',
        color: Colors.red,
        icon: Icons.error_outline_rounded,
      );
      return;
    }
    final success =
        await context.read<AppSecurityProvider>().changePin(current, next);
    if (!mounted) return;
    _showSnackBar(
      message: success ? 'تم تغيير رمز PIN' : 'رمز PIN الحالي غير صحيح',
      color: success ? Colors.green : Colors.red,
      icon: success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
    );
  }

  Future<void> _confirmDeleteAllSensitiveData() async {
    if (_isDeletingAllData) return;
    final security = context.read<AppSecurityProvider>();
    if (security.isEnabled) {
      final pin = await _requestPin(title: 'أدخل رمز PIN للمتابعة');
      if (pin == null || !mounted) return;
      if (!await security.verifyPin(pin)) {
        if (!mounted) return;
        _showSnackBar(
          message: 'رمز PIN غير صحيح',
          color: Colors.red,
          icon: Icons.error_outline_rounded,
        );
        return;
      }
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف جميع البيانات الحساسة؟'),
          content: const Text(
            'سيتم حذف جميع الكشوف والمستفيدين وسجل الرسائل نهائيًا. '
            'لن تتأثر إعدادات المظهر أو الرسالة الافتراضية.\n\n'
            'لا يمكن التراجع عن هذه العملية.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.delete_forever_rounded),
              label: const Text('حذف نهائي'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    _setScreenState(() => _isDeletingAllData = true);
    try {
      await DatabaseService.instance.deleteAllSensitiveData();
      if (!mounted) return;
      context.read<BeneficiaryProvider>().clear();
      context.read<BeneficiaryBatchProvider>().clear();
      _setScreenState(() => _isDeletingAllData = false);
      _showSnackBar(
        message: 'تم حذف جميع البيانات الحساسة',
        color: Colors.green,
        icon: Icons.check_circle_outline_rounded,
      );
    } catch (error) {
      if (!mounted) return;
      _setScreenState(() => _isDeletingAllData = false);
      _showSnackBar(
        message: AppErrorMessage.from(error, action: 'حذف البيانات الحساسة'),
        color: Colors.red,
        icon: Icons.error_outline_rounded,
      );
    }
  }
}
