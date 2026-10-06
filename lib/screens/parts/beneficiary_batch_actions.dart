part of '../beneficiary_batches_screen.dart';

extension _BeneficiaryBatchActions on _BeneficiaryBatchesScreenState {
  Future<void> _openDataFolder() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BeneficiariesScreen(
          showAllUnique: true,
        ),
      ),
    );

    if (!mounted) return;

    await context.read<BeneficiaryBatchProvider>().loadBatches();
  }

  Future<void> _openBatch(
    BeneficiaryBatch batch,
  ) async {
    final batchId = batch.id;

    if (batchId == null) {
      _showSnackBar(
        message: 'تعذر فتح الكشف',
        color: Colors.red,
        icon: Icons.error_outline,
      );

      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BeneficiariesScreen(
          batchId: batch.id!,
        ),
      ),
    );

    if (!mounted) return;

    await context.read<BeneficiaryBatchProvider>().refreshBatchCount(batchId);
  }

  Future<void> _showRenameDialog(
    BeneficiaryBatch batch,
  ) async {
    final batchId = batch.id;

    if (batchId == null) return;

    final controller = TextEditingController(
      text: batch.name,
    );

    final formKey = GlobalKey<FormState>();

    final newName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFFFFF3D0),
                  child: Icon(
                    Icons.drive_file_rename_outline_rounded,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'إعادة تسمية الكشف',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'اسم الكشف',
                  prefixIcon: const Icon(
                    Icons.folder_outlined,
                    color: AppColors.primary,
                  ),
                  filled: true,
                  fillColor: Theme.of(dialogContext)
                      .colorScheme
                      .surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.border(dialogContext),
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'أدخل اسم الكشف';
                  }

                  return null;
                },
                onFieldSubmitted: (_) {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(
                      dialogContext,
                      controller.text.trim(),
                    );
                  }
                },
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
                  if (!formKey.currentState!.validate()) {
                    return;
                  }

                  Navigator.pop(
                    dialogContext,
                    controller.text.trim(),
                  );
                },
                icon: const Icon(
                  Icons.save_outlined,
                  size: 19,
                ),
                label: const Text('حفظ'),
              ),
            ],
          ),
        );
      },
    );

    if (newName == null || newName.trim().isEmpty || !mounted) {
      return;
    }

    final result = await context.read<BeneficiaryBatchProvider>().renameBatch(
          batchId: batchId,
          newName: newName,
        );

    if (!mounted) return;

    if (result != null) {
      _showSnackBar(
        message: 'تم تغيير اسم الكشف إلى $result',
        color: Colors.green,
        icon: Icons.check_circle_outline,
      );
    } else {
      final provider = context.read<BeneficiaryBatchProvider>();

      _showSnackBar(
        message: provider.errorMessage ?? 'تعذر تغيير اسم الكشف',
        color: Colors.red,
        icon: Icons.error_outline,
      );
    }
  }

  Future<void> _deleteBatch(
    BeneficiaryBatch batch,
  ) async {
    final batchId = batch.id;

    if (batchId == null) return;

    final count =
        context.read<BeneficiaryBatchProvider>().getBeneficiariesCount(batchId);

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFFFFE8E8),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'حذف الكشف',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              'هل تريد حذف كشف "${batch.name}"؟\n\n'
              'سيتم حذف $count مستفيدًا مرتبطًا بهذا الكشف، '
              'ولا يمكن التراجع عن هذه العملية.',
              style: const TextStyle(
                height: 1.6,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    false,
                  );
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
                  Navigator.pop(
                    dialogContext,
                    true,
                  );
                },
                icon: const Icon(
                  Icons.delete_outline,
                  size: 19,
                ),
                label: const Text('حذف'),
              ),
            ],
          ),
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    final success =
        await context.read<BeneficiaryBatchProvider>().deleteBatch(batchId);

    if (!mounted) return;

    if (success) {
      _showSnackBar(
        message: 'تم حذف الكشف وجميع مستفيديه',
        color: Colors.green,
        icon: Icons.check_circle_outline,
      );
    } else {
      final provider = context.read<BeneficiaryBatchProvider>();

      _showSnackBar(
        message: provider.errorMessage ?? 'تعذر حذف الكشف',
        color: Colors.red,
        icon: Icons.error_outline,
      );
    }
  }

  Future<void> _showBatchProperties(
    BeneficiaryBatch batch,
  ) async {
    final batchId = batch.id;

    if (batchId == null) return;

    final count =
        context.read<BeneficiaryBatchProvider>().getBeneficiariesCount(batchId);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              20,
              14,
              20,
              28,
            ),
            decoration: BoxDecoration(
              color: AppColors.card(sheetContext),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.border(sheetContext),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: batch.isDuplicate
                              ? Colors.red.withValues(alpha: 0.12)
                              : AppColors.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          batch.isDuplicate
                              ? Icons.warning_amber_rounded
                              : Icons.folder_rounded,
                          color: batch.isDuplicate
                              ? Colors.red
                              : AppColors.primary,
                          size: 31,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              batch.name,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text(
                                  sheetContext,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '$count مستفيد',
                              style: TextStyle(
                                color: AppColors.subtitle(
                                  sheetContext,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _PropertyRow(
                    icon: Icons.description_outlined,
                    title: 'اسم الملف الأصلي',
                    value: batch.originalFileName.isEmpty
                        ? 'غير متوفر'
                        : batch.originalFileName,
                  ),
                  const SizedBox(height: 12),
                  _PropertyRow(
                    icon: Icons.calendar_today_outlined,
                    title: 'تاريخ الإنشاء',
                    value: _formatDate(batch.createdAt),
                  ),
                  const SizedBox(height: 12),
                  _PropertyRow(
                    icon: Icons.groups_outlined,
                    title: 'عدد المستفيدين',
                    value: '$count',
                  ),
                  if (batch.isDuplicate) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'هذا الكشف مكرر. أعد تسميته لإزالة التحذير.',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) {
      return value.isEmpty ? 'غير معروف' : value;
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}
