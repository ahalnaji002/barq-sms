import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/beneficiary.dart';
import '../providers/beneficiary_provider.dart';
import '../services/app_error_message.dart';
import '../theme/app_colors.dart';
import 'send_sms_screen.dart';

part 'parts/beneficiaries_screen_widgets.dart';
part 'parts/beneficiaries_dialogs.dart';

class BeneficiariesScreen extends StatefulWidget {
  final int? batchId;
  final bool showAllUnique;

  const BeneficiariesScreen({
    super.key,
    this.batchId,
    this.showAllUnique = false,
  });

  @override
  State<BeneficiariesScreen> createState() => _BeneficiariesScreenState();
}

class _BeneficiariesScreenState extends State<BeneficiariesScreen> {
  static const Color primaryColor = AppColors.primary;

  final TextEditingController _searchController = TextEditingController();

  final Set<int> _selectedBeneficiaryIds = {};

  @override
  void initState() {
    super.initState();

    _searchController.addListener(
      _refreshSearchResults,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BeneficiaryProvider>();

      if (widget.showAllUnique) {
        provider.loadUniqueBeneficiaries();
      } else {
        provider.loadBeneficiaries(
          batchId: widget.batchId,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(
      _refreshSearchResults,
    );

    _searchController.dispose();

    super.dispose();
  }

  void _refreshSearchResults() {
    if (!mounted) return;

    setState(() {});
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

  void _toggleSelection(
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

  Future<void> _deleteBeneficiary(
    Beneficiary beneficiary,
  ) async {
    final id = beneficiary.id;

    if (id == null) return;

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
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'حذف المستفيد',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              'هل تريد حذف ${beneficiary.name}؟\n\nلا يمكن التراجع عن هذه العملية.',
              style: const TextStyle(
                height: 1.5,
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
                    borderRadius: BorderRadius.circular(12),
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

    try {
      await context.read<BeneficiaryProvider>().deleteBeneficiary(id);

      if (!mounted) return;

      setState(() {
        _selectedBeneficiaryIds.remove(id);
      });

      _showSnackBar(
        message: 'تم حذف المستفيد',
        color: Colors.green,
        icon: Icons.check_circle_outline,
      );
    } catch (error) {
      if (!mounted) return;

      _showSnackBar(
        message: AppErrorMessage.from(error, action: 'حذف المستفيد'),
        color: Colors.red,
        icon: Icons.error_outline,
      );
    }
  }

  Future<void> _deleteSelectedBeneficiaries() async {
    if (_selectedBeneficiaryIds.isEmpty) {
      return;
    }

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
                Text(
                  'حذف المستفيدين',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              'هل تريد حذف ${_selectedBeneficiaryIds.length} مستفيدًا؟\n\nلا يمكن التراجع عن هذه العملية.',
              style: const TextStyle(
                height: 1.5,
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
                    borderRadius: BorderRadius.circular(12),
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

    final count = _selectedBeneficiaryIds.length;

    try {
      await context.read<BeneficiaryProvider>().deleteBeneficiaries(
            _selectedBeneficiaryIds.toList(),
          );

      if (!mounted) return;

      setState(() {
        _selectedBeneficiaryIds.clear();
      });

      _showSnackBar(
        message: 'تم حذف $count مستفيدًا بنجاح',
        color: Colors.green,
        icon: Icons.check_circle_outline,
      );
    } catch (error) {
      if (!mounted) return;

      _showSnackBar(
        message: AppErrorMessage.from(error, action: 'حذف المستفيدين'),
        color: Colors.red,
        icon: Icons.error_outline,
      );
    }
  }

  Future<void> _sendToSelected() async {
    if (_selectedBeneficiaryIds.isEmpty) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SendSmsScreen(
          selectedIds: _selectedBeneficiaryIds.toList(),
        ),
      ),
    );
  }

  void _showSnackBar({
    required String message,
    required Color color,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        margin: const EdgeInsets.all(16),
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

    final isSelectionMode = _selectedBeneficiaryIds.isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background(context),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: const Color(0xFF202020),
          centerTitle: !isSelectionMode,
          leading: isSelectionMode
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                  ),
                  tooltip: 'إلغاء التحديد',
                  onPressed: () {
                    setState(() {
                      _selectedBeneficiaryIds.clear();
                    });
                  },
                )
              : null,
          title: isSelectionMode
              ? Text(
                  'تم تحديد ${_selectedBeneficiaryIds.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.groups_rounded,
                      size: 25,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      widget.showAllUnique ? 'Data' : 'المستفيدون',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
          actions: isSelectionMode
              ? [
                  IconButton(
                    tooltip: 'إرسال رسالة',
                    icon: const Icon(
                      Icons.send_rounded,
                    ),
                    onPressed: _sendToSelected,
                  ),
                  IconButton(
                    tooltip: 'حذف المحددين',
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                    ),
                    onPressed: _deleteSelectedBeneficiaries,
                  ),
                ]
              : null,
        ),
        body: Column(
          children: [
            _buildHeaderSection(
              filteredCount: filteredBeneficiaries.length,
              totalCount: beneficiaries.length,
              selectedCount: _selectedBeneficiaryIds.length,
              allVisibleSelected: allVisibleSelected,
              filteredBeneficiaries: filteredBeneficiaries,
            ),
            Expanded(
              child: _buildContent(
                isLoading: provider.isLoading,
                beneficiaries: beneficiaries,
                filteredBeneficiaries: filteredBeneficiaries,
              ),
            ),
          ],
        ),
        floatingActionButton: isSelectionMode
            ? FloatingActionButton.extended(
                backgroundColor: primaryColor,
                foregroundColor: const Color(0xFF202020),
                onPressed: _sendToSelected,
                icon: const Icon(
                  Icons.send_rounded,
                ),
                label: Text(
                  'إرسال إلى ${_selectedBeneficiaryIds.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildHeaderSection({
    required int filteredCount,
    required int totalCount,
    required int selectedCount,
    required bool allVisibleSelected,
    required List<Beneficiary> filteredBeneficiaries,
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
              hintText: 'بحث بالاسم أو الهوية أو الهاتف أو المنطقة',
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
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 15,
                horizontal: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  16,
                ),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  16,
                ),
                borderSide: BorderSide(
                  color: AppColors.border(context),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  16,
                ),
                borderSide: const BorderSide(
                  color: primaryColor,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(
                  12,
                ),
                onTap: filteredBeneficiaries.isEmpty
                    ? null
                    : () {
                        _toggleSelectAll(
                          filteredBeneficiaries,
                        );
                      },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
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
                        checkColor: const Color(0xFF202020),
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
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selectedCount > 0
                      ? primaryColor.withValues(alpha: 0.14)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(
                    20,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selectedCount > 0
                          ? Icons.check_circle_outline
                          : Icons.groups_outlined,
                      size: 17,
                      color: selectedCount > 0
                          ? const Color(
                              0xFFD18E00,
                            )
                          : AppColors.subtitle(context),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      selectedCount > 0
                          ? 'المحدد: $selectedCount'
                          : _searchController.text.isNotEmpty
                              ? '$filteredCount من $totalCount'
                              : 'الإجمالي: $totalCount',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: selectedCount > 0
                            ? const Color(
                                0xFFD18E00,
                              )
                            : AppColors.subtitle(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent({
    required bool isLoading,
    required List<Beneficiary> beneficiaries,
    required List<Beneficiary> filteredBeneficiaries,
  }) {
    if (isLoading && beneficiaries.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      );
    }

    if (beneficiaries.isEmpty) {
      return const _EmptyState(
        icon: Icons.groups_outlined,
        title: 'لا يوجد مستفيدون',
        subtitle: 'استورد ملف Excel من الشاشة الرئيسية أولًا',
      );
    }

    if (filteredBeneficiaries.isEmpty) {
      return const _EmptyState(
        icon: Icons.search_off_rounded,
        title: 'لا توجد نتائج',
        subtitle: 'جرّب البحث بكلمة مختلفة',
      );
    }

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: () {
        final provider = context.read<BeneficiaryProvider>();

        if (widget.showAllUnique) {
          return provider.loadUniqueBeneficiaries();
        }

        return provider.loadBeneficiaries(
          batchId: widget.batchId,
        );
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          14,
          16,
          100,
        ),
        itemCount: filteredBeneficiaries.length,
        itemBuilder: (context, index) {
          final beneficiary = filteredBeneficiaries[index];

          final id = beneficiary.id;

          final isSelected = id != null && _selectedBeneficiaryIds.contains(id);

          return BeneficiaryCard(
            beneficiary: beneficiary,
            isSelected: isSelected,
            selectionMode: _selectedBeneficiaryIds.isNotEmpty,
            onTap: () {
              _toggleSelection(
                beneficiary,
              );
            },
            onEdit: () {
              _showEditBeneficiaryDialog(
                beneficiary,
              );
            },
            onDelete: () {
              _deleteBeneficiary(
                beneficiary,
              );
            },
          );
        },
      ),
    );
  }
}
