import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/beneficiary_provider.dart';
import '../services/excel_service.dart';
import '../services/app_error_message.dart';
import 'send_sms_screen.dart';
import 'sms_logs_screen.dart';
import 'settings_screen.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';
import 'beneficiary_batches_screen.dart';
import '../providers/beneficiary_batch_provider.dart';

part 'parts/home_screen_widgets.dart';
part 'parts/home_import_flow.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryColor = AppColors.primary;

  final ExcelService _excelService = ExcelService();

  late final AnimationController _pageAnimationController;

  bool _isImporting = false;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();

    _pageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pageAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    super.dispose();
  }

  Future<void> _importExcelFile() async {
    if (_isImporting) return;

    setState(() {
      _isImporting = true;
    });

    try {
      final result = await _excelService.pickAndReadExcelFile();

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _isImporting = false;
        });

        return;
      }

      final provider = context.read<BeneficiaryProvider>();

      final addedCount = await provider.importBeneficiaries(
        beneficiaries: result.beneficiaries,
        fileName: result.fileName,
      );

      if (!mounted) return;

      await context.read<BeneficiaryBatchProvider>().loadBatches();

      if (!mounted) return;

      final databaseDuplicateCount = result.beneficiaries.length - addedCount;

      setState(() {
        _selectedFileName = result.fileName;
        _isImporting = false;
      });

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      await _showImportResultBottomSheet(
        result: result,
        addedCount: addedCount,
        databaseDuplicateCount: databaseDuplicateCount,
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isImporting = false;
      });

      _showSnackBar(
        message: AppErrorMessage.from(error, action: 'استيراد الملف'),
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

  void _openScreen(Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(
          milliseconds: 380,
        ),
        reverseTransitionDuration: const Duration(
          milliseconds: 280,
        ),
        pageBuilder: (
          context,
          animation,
          secondaryAnimation,
        ) {
          return screen;
        },
        transitionsBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          final slideAnimation = Tween<Offset>(
            begin: const Offset(-0.08, 0),
            end: Offset.zero,
          ).animate(curvedAnimation);

          return FadeTransition(
            opacity: curvedAnimation,
            child: SlideTransition(
              position: slideAnimation,
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final beneficiaryProvider = context.watch<BeneficiaryProvider>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background(context),
        appBar: AppBar(
          actions: [
            IconButton(
              icon: Icon(
                Icons.settings,
                color: isDarkMode
                    ? const Color(0xFFFFD54F)
                    : const Color(0xFF202020),
              ),
              color: isDarkMode
                  ? const Color(0xFFFFD54F)
                  : const Color(0xFF202020),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: IconButton(
                tooltip:
                    isDarkMode ? 'تفعيل الوضع الفاتح' : 'تفعيل الوضع المظلم',
                onPressed: () {
                  themeProvider.toggleTheme();
                },
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return RotationTransition(
                      turns: animation,
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Icon(
                    isDarkMode
                        ? Icons.wb_sunny_rounded
                        : Icons.nightlight_round,
                    key: ValueKey(isDarkMode),
                    color: isDarkMode
                        ? const Color(0xFFFFD54F)
                        : const Color(0xFF202020),
                  ),
                ),
              ),
            ),
          ],
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          backgroundColor: AppColors.background(context),
          foregroundColor: AppColors.text(context),
          centerTitle: false,
          toolbarHeight: 72,
          titleSpacing: 18,
          title: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  color: AppColors.card(context),
                  size: 29,
                ),
              ),
              const SizedBox(width: 11),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Barq SMS',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text(context),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'إدارة الرسائل والمستفيدين',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.subtitle(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            color: primaryColor,
            onRefresh: () async {
              await beneficiaryProvider.loadBeneficiaries();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                18,
                18,
                18,
                28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedEntrance(
                    controller: _pageAnimationController,
                    begin: 0.00,
                    end: 0.30,
                    offset: const Offset(0, 0.10),
                    child: _buildWelcomeCard(),
                  ),
                  const SizedBox(height: 18),
                  AnimatedEntrance(
                    controller: _pageAnimationController,
                    begin: 0.12,
                    end: 0.42,
                    offset: const Offset(0, 0.12),
                    child: Row(
                      children: [
                        Expanded(
                          child: DashboardStatCard(
                            icon: Icons.groups_rounded,
                            value: '${beneficiaryProvider.uniqueCount}',
                            label: 'المستفيدون',
                            animateNumber: true,
                            iconColor: primaryColor,
                            iconBackground:
                                primaryColor.withValues(alpha: 0.16),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DashboardStatCard(
                            icon: _selectedFileName == null
                                ? Icons.cloud_upload_outlined
                                : Icons.check_circle_outline_rounded,
                            value: _selectedFileName == null ? 'جاهز' : 'تم',
                            label: _selectedFileName == null
                                ? 'لاستيراد البيانات'
                                : 'آخر استيراد',
                            iconColor: _selectedFileName == null
                                ? Colors.blue
                                : Colors.green,
                            iconBackground: (_selectedFileName == null
                                    ? Colors.blue
                                    : Colors.green)
                                .withValues(alpha: 0.12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (
                      child,
                      animation,
                    ) {
                      return FadeTransition(
                        opacity: animation,
                        child: SizeTransition(
                          sizeFactor: animation,
                          alignment: Alignment.topCenter,
                          child: child,
                        ),
                      );
                    },
                    child: _selectedFileName == null
                        ? const SizedBox.shrink(
                            key: ValueKey(
                              'no-file',
                            ),
                          )
                        : Padding(
                            key: ValueKey(
                              _selectedFileName,
                            ),
                            padding: const EdgeInsets.only(
                              top: 12,
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.green.withValues(alpha: 0.18),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.description_outlined,
                                    color: Colors.green,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'آخر ملف:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _selectedFileName!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColors.subtitle(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 26),
                  AnimatedEntrance(
                    controller: _pageAnimationController,
                    begin: 0.25,
                    end: 0.50,
                    offset: const Offset(0, 0.10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الخدمات',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text(context),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'اختر الخدمة التي تريد استخدامها',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.subtitle(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedEntrance(
                    controller: _pageAnimationController,
                    begin: 0.32,
                    end: 0.62,
                    offset: const Offset(0, 0.14),
                    child: HomeActionCard(
                      title: 'استيراد ملف Excel',
                      subtitle: _isImporting
                          ? 'جاري قراءة وتحليل ملف Excel...'
                          : 'إضافة بيانات المستفيدين من ملف جديد',
                      icon: Icons.upload_file_rounded,
                      isLoading: _isImporting,
                      onTap: _importExcelFile,
                    ),
                  ),
                  AnimatedEntrance(
                    controller: _pageAnimationController,
                    begin: 0.40,
                    end: 0.70,
                    offset: const Offset(0, 0.14),
                    child: HomeActionCard(
                      title: 'المستفيدون',
                      subtitle: 'عرض البيانات وتعديلها وتحديد المستفيدين',
                      icon: Icons.groups_2_outlined,
                      onTap: () {
                        _openScreen(
                          const BeneficiaryBatchesScreen(),
                        );
                      },
                    ),
                  ),
                  AnimatedEntrance(
                    controller: _pageAnimationController,
                    begin: 0.48,
                    end: 0.78,
                    offset: const Offset(0, 0.14),
                    child: HomeActionCard(
                      title: 'إرسال رسالة',
                      subtitle: 'كتابة وإرسال رسائل SMS للمستفيدين',
                      icon: Icons.send_rounded,
                      onTap: () {
                        _openScreen(
                          const SendSmsScreen(),
                        );
                      },
                    ),
                  ),
                  AnimatedEntrance(
                    controller: _pageAnimationController,
                    begin: 0.56,
                    end: 0.86,
                    offset: const Offset(0, 0.14),
                    child: HomeActionCard(
                      title: 'سجل الإرسال',
                      subtitle: 'مراجعة الرسائل الناجحة والفاشلة',
                      icon: Icons.history_rounded,
                      onTap: () {
                        _openScreen(
                          const SmsLogsScreen(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  AnimatedEntrance(
                    controller: _pageAnimationController,
                    begin: 0.72,
                    end: 1.00,
                    offset: const Offset(0, 0.08),
                    child: Center(
                      child: Text(
                        'Barq SMS  •  Version 1.0.0',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.subtitle(context),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFFFFC533),
            Color(0xFFFFB300),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحبًا بك في Barq SMS',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF202020),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'إدارة بيانات المستفيدين وإرسال الرسائل بسهولة وسرعة.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 14),
          AnimatedBoltIcon(),
        ],
      ),
    );
  }
}
