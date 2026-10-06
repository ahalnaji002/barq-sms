part of '../home_screen.dart';

extension _HomeImportFlow on _HomeScreenState {
  Future<void> _showImportResultBottomSheet({
    required ExcelImportResult result,
    required int addedCount,
    required int databaseDuplicateCount,
  }) async {
    final totalRejected = result.skippedRows + databaseDuplicateCount;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      useSafeArea: true,
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: DraggableScrollableSheet(
            initialChildSize: 0.62,
            minChildSize: 0.35,
            maxChildSize: 0.92,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.fact_check_outlined,
                                color: AppColors.primary,
                                size: 27,
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'نتيجة الاستيراد',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.text(context),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'تفاصيل معالجة ملف Excel',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.subtitle(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(
                            20,
                            18,
                            20,
                            24,
                          ),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.green.withValues(alpha: 0.18),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.green,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'اكتمل الاستيراد',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'تمت إضافة $addedCount مستفيد بنجاح',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.subtitle(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            _buildImportResultRow(
                              icon: Icons.description_outlined,
                              title: 'اسم الملف',
                              value: result.fileName,
                            ),
                            const Divider(height: 26),
                            _buildImportResultRow(
                              icon: Icons.person_add_alt_1_rounded,
                              title: 'تمت إضافتهم',
                              value: '$addedCount',
                              color: Colors.green,
                            ),
                            _buildImportResultRow(
                              icon: Icons.content_copy_rounded,
                              title: 'موجودون مسبقًا',
                              value: '$databaseDuplicateCount',
                              color: Colors.orange,
                            ),
                            _buildImportResultRow(
                              icon: Icons.phone_disabled_outlined,
                              title: 'أرقام جوال غير صحيحة',
                              value: '${result.invalidPhoneRows}',
                              color: Colors.red,
                            ),
                            _buildImportResultRow(
                              icon: Icons.badge_outlined,
                              title: 'أرقام هوية غير صحيحة',
                              value: '${result.invalidNationalIdRows}',
                              color: Colors.red,
                            ),
                            _buildImportResultRow(
                              icon: Icons.person_off_outlined,
                              title: 'أسماء غير صحيحة',
                              value: '${result.invalidNameRows}',
                              color: Colors.red,
                            ),
                            _buildImportResultRow(
                              icon: Icons.phone_android_outlined,
                              title: 'جوال مكرر داخل الملف',
                              value: '${result.duplicatePhoneRows}',
                              color: Colors.orange,
                            ),
                            _buildImportResultRow(
                              icon: Icons.badge_outlined,
                              title: 'هوية مكررة داخل الملف',
                              value: '${result.duplicateNationalIdRows}',
                              color: Colors.orange,
                            ),
                            _buildImportResultRow(
                              icon: Icons.table_rows_outlined,
                              title: 'صفوف فارغة',
                              value: '${result.emptyRows}',
                              color: Colors.grey,
                            ),
                            const Divider(height: 28),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: (totalRejected > 0
                                        ? Colors.orange
                                        : Colors.green)
                                    .withValues(alpha: 0.09),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: (totalRejected > 0
                                          ? Colors.orange
                                          : Colors.green)
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    totalRejected > 0
                                        ? Icons.warning_amber_rounded
                                        : Icons.check_circle_outline_rounded,
                                    color: totalRejected > 0
                                        ? Colors.orange
                                        : Colors.green,
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'إجمالي الصفوف المرفوضة',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$totalRejected',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: totalRejected > 0
                                          ? Colors.orange
                                          : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 50,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.text(context),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(sheetContext);
                                },
                                child: const Text(
                                  'إغلاق',
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildImportResultRow({
    required IconData icon,
    required String title,
    required String value,
    Color? color,
  }) {
    final effectiveColor = color ?? AppColors.text(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: effectiveColor.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 20,
              color: effectiveColor,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.text(context),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: effectiveColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
