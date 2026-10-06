import 'package:another_telephony/telephony.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/beneficiary.dart';
import '../models/sms_log.dart';
import '../providers/beneficiary_provider.dart';
import '../services/app_error_message.dart';
import '../services/database_service.dart';
import '../services/sms_sender_service.dart';
import '../theme/app_colors.dart';

part 'parts/send_sms_screen_widgets.dart';
part 'parts/send_sms_flow.dart';

class SendSmsScreen extends StatefulWidget {
  final List<int>? selectedIds;

  const SendSmsScreen({
    super.key,
    this.selectedIds,
  });

  @override
  State<SendSmsScreen> createState() => _SendSmsScreenState();
}

class _SendSmsScreenState extends State<SendSmsScreen> {
  static const Color primaryColor = AppColors.primary;
  static const Color darkColor = Color(0xFF202020);

  final Telephony _telephony = Telephony.instance;

  final TextEditingController _searchController = TextEditingController();

  final TextEditingController _messageController = TextEditingController();

  final Set<int> _selectedBeneficiaryIds = {};

  bool _isSending = false;
  int _sendProgress = 0;
  int _sendTotal = 0;

  @override
  void initState() {
    super.initState();

    if (widget.selectedIds != null) {
      _selectedBeneficiaryIds.addAll(
        widget.selectedIds!,
      );
    }

    _searchController.addListener(_refreshScreen);
    _messageController.addListener(_refreshScreen);
  }

  @override
  void dispose() {
    _searchController.removeListener(_refreshScreen);
    _messageController.removeListener(_refreshScreen);

    _searchController.dispose();
    _messageController.dispose();

    super.dispose();
  }

  void _refreshScreen() {
    if (!mounted) return;

    setState(() {});
  }

  void _setScreenState(VoidCallback update) {
    if (!mounted) return;
    setState(update);
  }

  String _buildPersonalizedMessage(
    Beneficiary beneficiary,
    String template,
  ) {
    return template
        .replaceAll(
          '[الاسم]',
          beneficiary.name.trim().isEmpty
              ? 'المستفيد'
              : beneficiary.name.trim(),
        )
        .replaceAll(
          '[رقم الهوية]',
          beneficiary.nationalId.trim().isEmpty
              ? 'غير متوفر'
              : beneficiary.nationalId.trim(),
        )
        .replaceAll(
          '[اسم الطالب]',
          beneficiary.studentName.trim().isEmpty
              ? 'غير متوفر'
              : beneficiary.studentName.trim(),
        )
        .replaceAll(
          '[اسم ولي الأمر]',
          beneficiary.guardianName.trim().isEmpty
              ? 'غير متوفر'
              : beneficiary.guardianName.trim(),
        );
  }

  void _insertVariable(String variable) {
    final text = _messageController.text;
    final selection = _messageController.selection;

    final start = selection.start >= 0 ? selection.start : text.length;

    final end = selection.end >= 0 ? selection.end : text.length;

    final updatedText = text.replaceRange(
      start,
      end,
      variable,
    );

    _messageController.value = _messageController.value.copyWith(
      text: updatedText,
      selection: TextSelection.collapsed(
        offset: start + variable.length,
      ),
      composing: TextRange.empty,
    );
  }

  List<Beneficiary> _filterBeneficiaries(
    List<Beneficiary> beneficiaries,
  ) {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return beneficiaries;
    }

    return beneficiaries.where((beneficiary) {
      return beneficiary.name.toLowerCase().contains(query) ||
          beneficiary.phoneNumber.toLowerCase().contains(query) ||
          beneficiary.nationalId.toLowerCase().contains(query) ||
          beneficiary.area.toLowerCase().contains(query);
    }).toList();
  }

  void _toggleBeneficiary(
    Beneficiary beneficiary,
  ) {
    final id = beneficiary.id;

    if (id == null) return;

    setState(() {
      if (_selectedBeneficiaryIds.contains(id)) {
        _selectedBeneficiaryIds.remove(id);
      } else {
        _selectedBeneficiaryIds.add(id);
      }
    });
  }

  void _toggleSelectAll(
    List<Beneficiary> filteredBeneficiaries,
  ) {
    final visibleIds = filteredBeneficiaries
        .where(
          (beneficiary) => beneficiary.id != null,
        )
        .map(
          (beneficiary) => beneficiary.id!,
        )
        .toSet();

    if (visibleIds.isEmpty) return;

    final allVisibleSelected = visibleIds.every(
      _selectedBeneficiaryIds.contains,
    );

    setState(() {
      if (allVisibleSelected) {
        _selectedBeneficiaryIds.removeAll(
          visibleIds,
        );
      } else {
        _selectedBeneficiaryIds.addAll(
          visibleIds,
        );
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedBeneficiaryIds.clear();
    });
  }

  void _showMessage({
    required String text,
    required Color backgroundColor,
    required IconData icon,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSuccess = backgroundColor == Colors.green;
    final isWarning = backgroundColor == Colors.orange;
    final messageColor = isSuccess
        ? (isDarkMode ? const Color(0xFF173D2A) : const Color(0xFFE8F5E9))
        : isWarning
            ? (isDarkMode ? const Color(0xFF493710) : const Color(0xFFFFF3D6))
            : (isDarkMode ? const Color(0xFF4A2424) : const Color(0xFFFDECEC));
    final foregroundColor = isSuccess
        ? (isDarkMode ? const Color(0xFFB9F6CA) : const Color(0xFF1B5E20))
        : isWarning
            ? (isDarkMode ? const Color(0xFFFFE082) : const Color(0xFF754D00))
            : (isDarkMode ? const Color(0xFFFFCDD2) : const Color(0xFFB3261E));

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: messageColor,
        elevation: 2,
        content: Row(
          children: [
            Icon(
              icon,
              color: foregroundColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: foregroundColor.withValues(alpha: 0.18),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BeneficiaryProvider>();

    final beneficiaries = provider.beneficiaries;

    final filteredBeneficiaries = _filterBeneficiaries(
      beneficiaries,
    );

    final visibleIds = filteredBeneficiaries
        .where(
          (beneficiary) => beneficiary.id != null,
        )
        .map(
          (beneficiary) => beneficiary.id!,
        )
        .toSet();

    final allVisibleSelected = visibleIds.isNotEmpty &&
        visibleIds.every(
          _selectedBeneficiaryIds.contains,
        );

    final messageLength = _messageController.text.length;

    final canSend = !_isSending &&
        _selectedBeneficiaryIds.isNotEmpty &&
        _messageController.text.trim().isNotEmpty;

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
                Icons.send_rounded,
                size: 24,
              ),
              SizedBox(width: 7),
              Text(
                'إرسال الرسائل',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        body: provider.isLoading && beneficiaries.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  color: primaryColor,
                ),
              )
            : beneficiaries.isEmpty
                ? const _EmptyBeneficiariesState()
                : SafeArea(
                    child: Column(
                      children: [
                        _buildTopSection(
                          filteredBeneficiaries: filteredBeneficiaries,
                          allVisibleSelected: allVisibleSelected,
                          totalCount: beneficiaries.length,
                        ),
                        Expanded(
                          child: _buildBeneficiariesList(
                            filteredBeneficiaries,
                          ),
                        ),
                        if (_isSending) _buildSendProgress(),
                        _buildMessageSection(
                          messageLength: messageLength,
                          canSend: canSend,
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildSendProgress() {
    final progress = _sendTotal == 0 ? 0.0 : _sendProgress / _sendTotal;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تمت معالجة $_sendProgress من $_sendTotal رسالة',
                style: TextStyle(
                  color: AppColors.text(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(progress * 100).round()}٪',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  color: AppColors.subtitle(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.border(context),
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection({
    required List<Beneficiary> filteredBeneficiaries,
    required bool allVisibleSelected,
    required int totalCount,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        12,
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
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'بحث بالاسم أو الهاتف أو الهوية أو المنطقة',
              hintStyle: const TextStyle(
                fontSize: 13.5,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: primaryColor,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      tooltip: 'مسح البحث',
                      onPressed: _searchController.clear,
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2B2B2B)
                  : const Color(0xFFF7F2EA),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.border(context),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: primaryColor,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: filteredBeneficiaries.isEmpty
                    ? null
                    : () {
                        _toggleSelectAll(
                          filteredBeneficiaries,
                        );
                      },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 3,
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: allVisibleSelected,
                        onChanged: filteredBeneficiaries.isEmpty
                            ? null
                            : (_) {
                                _toggleSelectAll(
                                  filteredBeneficiaries,
                                );
                              },
                        activeColor: primaryColor,
                        checkColor: darkColor,
                      ),
                      const Text(
                        'تحديد الكل',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _selectedBeneficiaryIds.isNotEmpty
                      ? primaryColor.withValues(alpha: 0.14)
                      : AppColors.border(context).withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _selectedBeneficiaryIds.isNotEmpty
                          ? Icons.check_circle_outline_rounded
                          : Icons.groups_outlined,
                      size: 17,
                      color: _selectedBeneficiaryIds.isNotEmpty
                          ? const Color(0xFFD18E00)
                          : AppColors.subtitle(context),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _selectedBeneficiaryIds.isNotEmpty
                          ? 'المحدد: '
                              '${_selectedBeneficiaryIds.length}'
                          : _searchController.text.isNotEmpty
                              ? '${filteredBeneficiaries.length} من $totalCount'
                              : 'الإجمالي: $totalCount',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _selectedBeneficiaryIds.isNotEmpty
                            ? const Color(0xFFD18E00)
                            : AppColors.subtitle(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedBeneficiaryIds.isNotEmpty) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'إلغاء التحديد',
                  onPressed: _clearSelection,
                  icon: const Icon(
                    Icons.clear_all_rounded,
                    color: Colors.red,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBeneficiariesList(
    List<Beneficiary> filteredBeneficiaries,
  ) {
    if (filteredBeneficiaries.isEmpty) {
      return const _SearchEmptyState();
    }

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: () {
        return context.read<BeneficiaryProvider>().loadBeneficiaries();
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          14,
          16,
          14,
        ),
        itemCount: filteredBeneficiaries.length,
        itemBuilder: (context, index) {
          final beneficiary = filteredBeneficiaries[index];

          final id = beneficiary.id;

          final isSelected = id != null && _selectedBeneficiaryIds.contains(id);

          return _SmsBeneficiaryCard(
            beneficiary: beneficiary,
            isSelected: isSelected,
            onTap: () {
              _toggleBeneficiary(beneficiary);
            },
          );
        },
      ),
    );
  }

  Widget _buildMessageSection({
    required int messageLength,
    required bool canSend,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        13,
        16,
        15,
      ),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        border: Border(
          top: BorderSide(
            color: AppColors.border(context),
          ),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, -3),
            color: AppColors.shadow(context),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.message_outlined,
                color: primaryColor,
                size: 21,
              ),
              const SizedBox(width: 8),
              Text(
                'نص الرسالة',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text(context),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: messageLength >= 500
                      ? Colors.red.withValues(alpha: 0.1)
                      : AppColors.border(context).withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$messageLength / 500',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: messageLength >= 500
                        ? Colors.red
                        : AppColors.subtitle(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          TextField(
            controller: _messageController,
            minLines: 3,
            maxLines: 5,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'اكتب الرسالة التي تريد إرسالها...',
              hintStyle: const TextStyle(
                fontSize: 13.5,
              ),
              counterText: '',
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2B2B2B)
                  : const Color(0xFFF7F2EA),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.border(context),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: primaryColor,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Text(
                  'إضافة:',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.subtitle(context),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    ActionChip(
                      backgroundColor: primaryColor.withValues(alpha: 0.12),
                      side: BorderSide(
                        color: primaryColor.withValues(alpha: 0.25),
                      ),
                      avatar: const Icon(
                        Icons.person_outline,
                        size: 17,
                        color: Color(0xFFD18E00),
                      ),
                      label: const Text(
                        '[الاسم]',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        _insertVariable('[الاسم]');
                      },
                    ),
                    ActionChip(
                      backgroundColor: primaryColor.withValues(alpha: 0.12),
                      side: BorderSide(
                        color: primaryColor.withValues(alpha: 0.25),
                      ),
                      avatar: const Icon(
                        Icons.badge_outlined,
                        size: 17,
                        color: Color(0xFFD18E00),
                      ),
                      label: const Text(
                        '[رقم الهوية]',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        _insertVariable('[رقم الهوية]');
                      },
                    ),
                    ActionChip(
                      backgroundColor: primaryColor.withValues(alpha: 0.12),
                      side: BorderSide(
                        color: primaryColor.withValues(alpha: 0.25),
                      ),
                      avatar: const Icon(
                        Icons.school_outlined,
                        size: 17,
                        color: Color(0xFFD18E00),
                      ),
                      label: const Text(
                        '[اسم الطالب]',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        _insertVariable('[اسم الطالب]');
                      },
                    ),
                    ActionChip(
                      backgroundColor: primaryColor.withValues(alpha: 0.12),
                      side: BorderSide(
                        color: primaryColor.withValues(alpha: 0.25),
                      ),
                      avatar: const Icon(
                        Icons.family_restroom_outlined,
                        size: 17,
                        color: Color(0xFFD18E00),
                      ),
                      label: const Text(
                        '[اسم ولي الأمر]',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        _insertVariable('[اسم ولي الأمر]');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: canSend ? _prepareSending : null,
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: darkColor,
                disabledBackgroundColor:
                    Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF3A3A3A)
                        : const Color(0xFFE3D8C8),
                disabledForegroundColor:
                    Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFBDBDBD)
                        : const Color(0xFF6F665C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _isSending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        color: AppColors.text(context),
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                    ),
              label: Text(
                _isSending
                    ? 'جارٍ الإرسال...'
                    : _selectedBeneficiaryIds.isEmpty
                        ? 'حدد المستفيدين'
                        : 'إرسال إلى '
                            '${_selectedBeneficiaryIds.length} مستفيد',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
