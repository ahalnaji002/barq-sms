import 'package:flutter/material.dart';

import '../models/sms_log.dart';
import '../services/app_error_message.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';

part 'parts/sms_logs_widgets.dart';

class SmsLogsScreen extends StatefulWidget {
  const SmsLogsScreen({super.key});

  @override
  State<SmsLogsScreen> createState() => _SmsLogsScreenState();
}

class _SmsLogsScreenState extends State<SmsLogsScreen> {
  static const Color primaryColor = Color(0xFFFFB300);
  static const Color darkColor = Color(0xFF202020);

  List<SmsLog> _logs = [];
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final logs = await DatabaseService.instance.getSmsLogs();

      if (!mounted) return;

      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showSnackBar(
        message: AppErrorMessage.from(error, action: 'تحميل سجل الإرسال'),
        color: Colors.red,
        icon: Icons.error_outline_rounded,
      );
    }
  }

  Future<void> _confirmDeleteAllLogs() async {
    if (_logs.isEmpty || _isDeleting) return;

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
                    Icons.delete_sweep_outlined,
                    color: Colors.red,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'حذف سجل الإرسال',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              'هل تريد حذف جميع سجلات الإرسال؟\n\n'
              'سيتم حذف ${_logs.length} سجلًا، ولا يمكن التراجع عن هذه العملية.',
              style: const TextStyle(
                height: 1.5,
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
                label: const Text('حذف الكل'),
              ),
            ],
          ),
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    await _deleteAllLogs();
  }

  Future<void> _deleteAllLogs() async {
    if (_isDeleting) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await DatabaseService.instance.deleteAllSmsLogs();

      if (!mounted) return;

      setState(() {
        _logs.clear();
        _isDeleting = false;
      });

      _showSnackBar(
        message: 'تم حذف سجل الإرسال بنجاح',
        color: Colors.green,
        icon: Icons.check_circle_outline_rounded,
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isDeleting = false;
      });

      _showSnackBar(
        message: AppErrorMessage.from(error, action: 'حذف سجل الإرسال'),
        color: Colors.red,
        icon: Icons.error_outline_rounded,
      );
    }
  }

  void _showSnackBar({
    required String message,
    required Color color,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: AppColors.card(context),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    final hourNumber = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final hour = hourNumber.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'م' : 'ص';

    return '$day/$month/$year  •  $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final successCount = _logs.where((log) => log.isSuccess).length;
    final failedCount =
        _logs.where((log) => log.status == SmsLogStatus.failed).length;

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
                Icons.history_rounded,
                size: 25,
              ),
              SizedBox(width: 7),
              Text(
                'سجل الإرسال',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            if (_logs.isNotEmpty)
              IconButton(
                tooltip: 'حذف السجل',
                onPressed: _isDeleting ? null : _confirmDeleteAllLogs,
                icon: _isDeleting
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          color: darkColor,
                        ),
                      )
                    : const Icon(
                        Icons.delete_sweep_outlined,
                      ),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: primaryColor,
                ),
              )
            : _logs.isEmpty
                ? const _EmptyLogsState()
                : Column(
                    children: [
                      _buildStatisticsSection(
                        successCount: successCount,
                        failedCount: failedCount,
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          color: primaryColor,
                          onRefresh: _loadLogs,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              14,
                              16,
                              24,
                            ),
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              final log = _logs[index];

                              return _SmsLogCard(
                                log: log,
                                formattedDate: _formatDate(log.sentAt),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildStatisticsSection({
    required int successCount,
    required int failedCount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        14,
      ),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ملخص الإرسال',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.text(context),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatisticsCard(
                  icon: Icons.check_circle_outline_rounded,
                  value: successCount,
                  label: 'أكد النظام إرسالها',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: _StatisticsCard(
                  icon: Icons.error_outline_rounded,
                  value: failedCount,
                  label: 'رسائل فاشلة',
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: _StatisticsCard(
                  icon: Icons.sms_outlined,
                  value: _logs.length,
                  label: 'إجمالي الرسائل',
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
