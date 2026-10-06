part of '../beneficiary_batches_screen.dart';

class _DataFolderCard extends StatelessWidget {
  final VoidCallback onTap;

  const _DataFolderCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const dataColor = AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: dataColor.withValues(alpha: 0.55),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
            blurRadius: 13,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(21),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(21),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: dataColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: dataColor.withValues(alpha: 0.30),
                    ),
                  ),
                  child: const Icon(
                    Icons.folder_special_rounded,
                    size: 38,
                    color: dataColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text(context),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'جميع المستفيدين بدون تكرار',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.subtitle(context),
                        ),
                      ),
                      const SizedBox(height: 9),
                      const _BatchInfoChip(
                        icon: Icons.auto_awesome_rounded,
                        text: 'مجلد تلقائي',
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AppColors.subtitle(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BatchCard extends StatelessWidget {
  static const Color primaryColor = AppColors.primary;

  final BeneficiaryBatch batch;
  final int beneficiaryCount;
  final String formattedDate;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onProperties;

  const _BatchCard({
    required this.batch,
    required this.beneficiaryCount,
    required this.formattedDate,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
    required this.onProperties,
  });

  @override
  Widget build(BuildContext context) {
    final isDuplicate = batch.isDuplicate;

    final cardColor = isDuplicate
        ? Colors.red.withValues(
            alpha:
                Theme.of(context).brightness == Brightness.dark ? 0.13 : 0.06,
          )
        : AppColors.card(context);

    final borderColor = isDuplicate
        ? Colors.red.withValues(alpha: 0.55)
        : AppColors.border(context);

    final iconColor = isDuplicate ? Colors.red : primaryColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: borderColor,
          width: isDuplicate ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
            blurRadius: 13,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(21),
        child: InkWell(
          borderRadius: BorderRadius.circular(21),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.folder_rounded,
                        size: 38,
                        color: iconColor,
                      ),
                      if (isDuplicate)
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.priority_high_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              batch.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: isDuplicate
                                    ? Colors.red
                                    : AppColors.text(
                                        context,
                                      ),
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'خيارات الكشف',
                            icon: Icon(
                              Icons.more_vert_rounded,
                              color: AppColors.subtitle(
                                context,
                              ),
                            ),
                            onSelected: (value) {
                              switch (value) {
                                case 'rename':
                                  onRename();
                                  break;
                                case 'properties':
                                  onProperties();
                                  break;
                                case 'delete':
                                  onDelete();
                                  break;
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'rename',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.drive_file_rename_outline,
                                      color: primaryColor,
                                    ),
                                    SizedBox(width: 10),
                                    Text('إعادة التسمية'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'properties',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                    ),
                                    SizedBox(width: 10),
                                    Text('الخصائص'),
                                  ],
                                ),
                              ),
                              PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'حذف الكشف',
                                      style: TextStyle(
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _BatchInfoChip(
                            icon: Icons.groups_outlined,
                            text: '$beneficiaryCount مستفيد',
                          ),
                          _BatchInfoChip(
                            icon: Icons.calendar_today_outlined,
                            text: formattedDate,
                          ),
                        ],
                      ),
                      if (isDuplicate) ...[
                        const SizedBox(height: 9),
                        const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 17,
                              color: Colors.red,
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'كشف مكرر — أعد تسميته',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BatchInfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BatchInfoChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: AppColors.subtitle(context),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.subtitle(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _PropertyRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.subtitle(context),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.text(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;

  const _BatchEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: AppColors.text(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppColors.subtitle(context),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: const Color(0xFF202020),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onPressed,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                buttonText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
