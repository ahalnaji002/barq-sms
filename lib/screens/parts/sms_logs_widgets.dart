part of '../sms_logs_screen.dart';

class _StatisticsCard extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  const _StatisticsCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 112,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 26,
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: AppColors.subtitle(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmsLogCard extends StatelessWidget {
  final SmsLog log;
  final String formattedDate;

  const _SmsLogCard({
    required this.log,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (log.status) {
      SmsLogStatus.delivered => Colors.green,
      SmsLogStatus.sent => Colors.blue,
      SmsLogStatus.pending => Colors.orange,
      SmsLogStatus.failed => Colors.red,
    };
    final statusLabel = switch (log.status) {
      SmsLogStatus.delivered => 'تم التسليم',
      SmsLogStatus.sent => 'أُرسلت من الجهاز',
      SmsLogStatus.pending => 'قيد الإرسال',
      SmsLogStatus.failed => 'فشلت',
    };
    final statusIcon = switch (log.status) {
      SmsLogStatus.delivered => Icons.mark_email_read_outlined,
      SmsLogStatus.sent => Icons.send_rounded,
      SmsLogStatus.pending => Icons.schedule_rounded,
      SmsLogStatus.failed => Icons.error_outline,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
            blurRadius: 13,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.11),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.beneficiaryName.trim().isEmpty
                            ? 'مستفيد بدون اسم'
                            : log.beneficiaryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text(context),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 16,
                            color: log.phoneNumber.trim().isEmpty
                                ? Colors.red
                                : AppColors.subtitle(context),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              log.phoneNumber.trim().isEmpty
                                  ? 'رقم الهاتف غير متوفر'
                                  : log.phoneNumber,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 13,
                                color: log.phoneNumber.trim().isEmpty
                                    ? Colors.red
                                    : AppColors.subtitle(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        size: 15,
                        color: statusColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.background(context)
                    : const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.border(context),
                ),
              ),
              child: Text(
                log.message.trim().isEmpty
                    ? 'نص الرسالة غير متوفر'
                    : log.message,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.55,
                  color: AppColors.text(context),
                ),
              ),
            ),
            if (log.status == SmsLogStatus.failed &&
                log.errorMessage != null &&
                log.errorMessage!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        log.errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 11),
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: AppColors.subtitle(context),
                ),
                const SizedBox(width: 6),
                Text(
                  formattedDate,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.subtitle(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyLogsState extends StatelessWidget {
  const _EmptyLogsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 61,
                color: Color(0xFFFFB300),
              ),
            ),
            const SizedBox(height: 21),
            Text(
              'لا يوجد سجل إرسال',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: AppColors.text(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ستظهر هنا الرسائل التي تم إرسالها مع حالة كل رسالة.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.subtitle(context),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFB300),
                foregroundColor: const Color(0xFF202020),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_forward_rounded,
              ),
              label: const Text(
                'العودة للرئيسية',
                style: TextStyle(
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
