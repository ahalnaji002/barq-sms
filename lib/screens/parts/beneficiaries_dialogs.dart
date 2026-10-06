part of '../beneficiaries_screen.dart';

extension _BeneficiaryDialogs on _BeneficiariesScreenState {
  Future<void> _showEditBeneficiaryDialog(
    Beneficiary beneficiary,
  ) async {
    final nameController = TextEditingController(
      text: beneficiary.name,
    );

    final phoneController = TextEditingController(
      text: beneficiary.phoneNumber,
    );

    final nationalIdController = TextEditingController(
      text: beneficiary.nationalId,
    );

    final areaController = TextEditingController(
      text: beneficiary.area,
    );

    final familyMembersController = TextEditingController(
      text: beneficiary.familyMembers.toString(),
    );

    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
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
              12,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 22,
            ),
            actionsPadding: const EdgeInsets.fromLTRB(
              22,
              12,
              22,
              20,
            ),
            title: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFFFFF3D0),
                  child: Icon(
                    Icons.edit_outlined,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'تعديل بيانات المستفيد',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogTextField(
                      controller: nameController,
                      label: 'الاسم',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'أدخل اسم المستفيد';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 13),
                    _buildDialogTextField(
                      controller: phoneController,
                      label: 'رقم الهاتف',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'أدخل رقم الهاتف';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 13),
                    _buildDialogTextField(
                      controller: nationalIdController,
                      label: 'رقم الهوية',
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null &&
                            value.trim().isNotEmpty &&
                            !Beneficiary.isValidNationalId(value)) {
                          return 'رقم الهوية يجب أن يتكون من 9 أرقام';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 13),
                    _buildDialogTextField(
                      controller: areaController,
                      label: 'المنطقة',
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 13),
                    _buildDialogTextField(
                      controller: familyMembersController,
                      label: 'عدد أفراد الأسرة',
                      icon: Icons.family_restroom,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final number = int.tryParse(
                          value?.trim() ?? '',
                        );

                        if (number == null || number < 1) {
                          return 'أدخل عددًا صحيحًا';
                        }

                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              SizedBox(
                height: 47,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        13,
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
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
                      borderRadius: BorderRadius.circular(
                        13,
                      ),
                    ),
                  ),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    final provider = context.read<BeneficiaryProvider>();

                    final duplicate =
                        await provider.findDuplicateBeneficiaryForUpdate(
                      currentId: beneficiary.id!,
                      nationalId: nationalIdController.text.trim(),
                      phoneNumber: phoneController.text.trim(),
                    );

                    if (!mounted) return;

                    if (duplicate == 'nationalId') {
                      await _showDuplicateDialog(
                        title: 'تعذر حفظ التعديل',
                        message: 'رقم الهوية مستخدم بالفعل لمستفيد آخر.',
                      );

                      return;
                    }

                    if (duplicate == 'phoneNumber') {
                      await _showDuplicateDialog(
                        title: 'تعذر حفظ التعديل',
                        message: 'رقم الهاتف مستخدم بالفعل لمستفيد آخر.',
                      );

                      return;
                    }

                    final updatedBeneficiary = Beneficiary(
                      id: beneficiary.id,
                      serialNumber: beneficiary.serialNumber,
                      name: nameController.text.trim(),
                      phoneNumber: phoneController.text.trim(),
                      nationalId: nationalIdController.text.trim(),
                      area: areaController.text.trim(),
                      familyMembers: int.parse(
                        familyMembersController.text.trim(),
                      ),
                      studentName: beneficiary.studentName,
                      guardianName: beneficiary.guardianName,
                    );

                    try {
                      await provider.updateBeneficiary(
                        updatedBeneficiary,
                      );
                    } catch (error) {
                      if (!dialogContext.mounted) {
                        return;
                      }

                      await showDialog<void>(
                        context: dialogContext,
                        builder: (errorContext) {
                          return Directionality(
                            textDirection: TextDirection.rtl,
                            child: AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  20,
                                ),
                              ),
                              title: const Text(
                                'تعذر حفظ التعديل',
                              ),
                              content: Text(
                                AppErrorMessage.from(
                                  error,
                                  action: 'حفظ التعديل',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(
                                      errorContext,
                                    );
                                  },
                                  child: const Text(
                                    'حسنًا',
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );

                      return;
                    }

                    if (!mounted || !dialogContext.mounted) return;

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'تم تعديل بيانات المستفيد بنجاح',
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.save_outlined,
                    size: 19,
                  ),
                  label: const Text('حفظ'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: AppColors.primary,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.border(context),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Future<void> _showDuplicateDialog({
    required String title,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (errorContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                ),
                const SizedBox(width: 10),
                Text(title),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(errorContext);
                },
                child: const Text('حسنًا'),
              ),
            ],
          ),
        );
      },
    );
  }
}
