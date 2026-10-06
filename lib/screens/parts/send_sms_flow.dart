part of '../send_sms_screen.dart';

extension _SendSmsFlow on _SendSmsScreenState {
  Future<void> _sendMessages(
    List<Beneficiary> beneficiaries,
    String template,
  ) async {
    if (_isSending) return;

    _setScreenState(() {
      _isSending = true;
      _sendProgress = 0;
      _sendTotal = beneficiaries.length;
    });

    int successCount = 0;
    int failedCount = 0;

    try {
      final permissionGranted =
          await _telephony.requestPhoneAndSmsPermissions ?? false;

      if (!permissionGranted) {
        _showMessage(
          text: 'يجب السماح للتطبيق بإرسال الرسائل',
          backgroundColor: Colors.red,
          icon: Icons.lock_outline_rounded,
        );

        return;
      }

      for (var index = 0; index < beneficiaries.length; index++) {
        final beneficiary = beneficiaries[index];
        final phone = beneficiary.phoneNumber.trim();

        final personalizedMessage = _buildPersonalizedMessage(
          beneficiary,
          template,
        );

        if (phone.isEmpty) {
          failedCount++;

          await DatabaseService.instance.insertSmsLog(
            SmsLog(
              beneficiaryName: beneficiary.name,
              phoneNumber: phone,
              message: personalizedMessage,
              sentAt: DateTime.now(),
              status: SmsLogStatus.failed,
              errorMessage: 'رقم الهاتف فارغ',
            ),
          );

          _setScreenState(() {
            _sendProgress = index + 1;
          });
          continue;
        }

        try {
          final logId = await DatabaseService.instance.insertSmsLog(
            SmsLog(
              beneficiaryName: beneficiary.name,
              phoneNumber: phone,
              message: personalizedMessage,
              sentAt: DateTime.now(),
              status: SmsLogStatus.pending,
            ),
          );

          final status = await SmsSenderService.instance.send(
            logId: logId,
            phoneNumber: phone,
            message: personalizedMessage,
          );

          if (status == SmsLogStatus.sent || status == SmsLogStatus.delivered) {
            successCount++;
          } else {
            failedCount++;
          }
        } catch (error) {
          failedCount++;

          await DatabaseService.instance.insertSmsLog(
            SmsLog(
              beneficiaryName: beneficiary.name,
              phoneNumber: phone,
              message: personalizedMessage,
              sentAt: DateTime.now(),
              status: SmsLogStatus.failed,
              errorMessage: AppErrorMessage.from(
                error,
                action: 'إرسال الرسالة إلى هذا المستفيد',
              ),
            ),
          );
        }

        _setScreenState(() {
          _sendProgress = index + 1;
        });

        await Future<void>.delayed(
          const Duration(milliseconds: 700),
        );
      }

      if (!mounted) return;

      if (failedCount == 0) {
        _showMessage(
          text: 'أكد النظام إرسال $successCount رسالة',
          backgroundColor: Colors.green,
          icon: Icons.check_circle_outline_rounded,
        );
      } else {
        _showMessage(
          text: 'أكد النظام إرسال $successCount رسالة، وفشل $failedCount',
          backgroundColor: Colors.orange,
          icon: Icons.warning_amber_rounded,
        );
      }

      if (successCount > 0) {
        _clearSelection();
      }
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        text: AppErrorMessage.from(error, action: 'إرسال الرسائل'),
        backgroundColor: Colors.red,
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) {
        _setScreenState(() {
          _isSending = false;
        });
      }
    }
  }

  void _prepareSending() {
    final message = _messageController.text.trim();

    final provider = context.read<BeneficiaryProvider>();

    if (_selectedBeneficiaryIds.isEmpty) {
      _showMessage(
        text: 'حدد مستفيدًا واحدًا على الأقل',
        backgroundColor: Colors.orange,
        icon: Icons.person_add_alt_rounded,
      );

      return;
    }

    if (message.isEmpty) {
      _showMessage(
        text: 'اكتب نص الرسالة أولًا',
        backgroundColor: Colors.orange,
        icon: Icons.edit_note_rounded,
      );

      return;
    }

    final selectedBeneficiaries = provider.beneficiaries.where((beneficiary) {
      final id = beneficiary.id;

      return id != null && _selectedBeneficiaryIds.contains(id);
    }).toList();

    if (selectedBeneficiaries.isEmpty) {
      _showMessage(
        text: 'لم يتم العثور على المستفيدين المحددين',
        backgroundColor: Colors.red,
        icon: Icons.error_outline_rounded,
      );

      return;
    }

    final previewMessage = _buildPersonalizedMessage(
      selectedBeneficiaries.first,
      message,
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            titlePadding: const EdgeInsets.fromLTRB(
              22,
              22,
              22,
              10,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 22,
            ),
            actionsPadding: const EdgeInsets.fromLTRB(
              22,
              14,
              22,
              20,
            ),
            title: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFFFFF3D0),
                  child: Icon(
                    Icons.send_rounded,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'تأكيد إرسال الرسائل',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.groups_rounded,
                          color: Color(0xFFD18E00),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'عدد المستلمين: '
                          '${selectedBeneficiaries.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.text(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'معاينة الرسالة لأول مستفيد',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      maxHeight: 180,
                    ),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.border(context).withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.border(context),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        previewMessage,
                        style: TextStyle(
                          height: 1.55,
                          color: AppColors.text(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: AppColors.subtitle(context),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'سيتم استبدال المتغيرات ببيانات كل مستفيد تلقائيًا.',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: AppColors.subtitle(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              SizedBox(
                height: 47,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('إلغاء'),
                ),
              ),
              SizedBox(
                height: 47,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: const Color(0xFF202020),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(dialogContext);

                    await _sendMessages(
                      selectedBeneficiaries,
                      message,
                    );
                  },
                  icon: const Icon(
                    Icons.send_rounded,
                    size: 19,
                  ),
                  label: const Text(
                    'تأكيد الإرسال',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
