import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/beneficiary_batch.dart';
import '../providers/beneficiary_batch_provider.dart';
import '../theme/app_colors.dart';
import 'beneficiaries_screen.dart';

part 'parts/beneficiary_batches_screen_widgets.dart';
part 'parts/beneficiary_batch_actions.dart';

class BeneficiaryBatchesScreen extends StatefulWidget {
  const BeneficiaryBatchesScreen({super.key});

  @override
  State<BeneficiaryBatchesScreen> createState() =>
      _BeneficiaryBatchesScreenState();
}

class _BeneficiaryBatchesScreenState extends State<BeneficiaryBatchesScreen> {
  static const Color primaryColor = AppColors.primary;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_refreshSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_refreshSearch);
    _searchController.dispose();

    super.dispose();
  }

  void _refreshSearch() {
    if (!mounted) return;

    setState(() {});
  }

  bool _shouldShowDataFolder() {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return true;
    }

    return 'data'.contains(query) ||
        'البيانات'.contains(query) ||
        'جميع المستفيدين'.contains(query);
  }

  List<BeneficiaryBatch> _filterBatches(
    List<BeneficiaryBatch> batches,
  ) {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return batches;
    }

    return batches.where((batch) {
      return batch.name.toLowerCase().contains(query) ||
          batch.originalFileName.toLowerCase().contains(query);
    }).toList();
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
    final provider = context.watch<BeneficiaryBatchProvider>();

    final batches = provider.batches;
    final filteredBatches = _filterBatches(batches);
    final showDataFolder = _shouldShowDataFolder();

    final totalFolderCount = batches.length + 1;
    final filteredFolderCount =
        filteredBatches.length + (showDataFolder ? 1 : 0);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background(context),
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: primaryColor,
          foregroundColor: const Color(0xFF202020),
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_copy_rounded,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'الكشوفات',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildHeader(
              totalCount: totalFolderCount,
              filteredCount: filteredFolderCount,
            ),
            Expanded(
              child: _buildContent(
                provider: provider,
                batches: batches,
                filteredBatches: filteredBatches,
                showDataFolder: showDataFolder,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required int totalCount,
    required int filteredCount,
  }) {
    return Container(
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
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'البحث عن كشف',
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
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.folder_outlined,
                size: 20,
                color: AppColors.subtitle(context),
              ),
              const SizedBox(width: 7),
              Text(
                _searchController.text.isEmpty
                    ? 'عدد المجلدات: $totalCount'
                    : '$filteredCount من $totalCount',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.subtitle(context),
                ),
              ),
              const Spacer(),
              if (totalCount > 0)
                Text(
                  'اضغط على المجلد لفتحه',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.subtitle(context),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent({
    required BeneficiaryBatchProvider provider,
    required List<BeneficiaryBatch> batches,
    required List<BeneficiaryBatch> filteredBatches,
    required bool showDataFolder,
  }) {
    if (provider.isLoading && batches.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      );
    }

    if (provider.hasError && batches.isEmpty) {
      return _BatchEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'تعذر تحميل الكشوفات',
        subtitle: provider.errorMessage ?? 'حدث خطأ غير متوقع',
        buttonText: 'إعادة المحاولة',
        onPressed: provider.loadBatches,
      );
    }

    if (filteredBatches.isEmpty && !showDataFolder) {
      return _BatchEmptyState(
        icon: Icons.search_off_rounded,
        title: 'لا توجد نتائج',
        subtitle: 'لم يتم العثور على مجلد مطابق للبحث',
        buttonText: 'مسح البحث',
        onPressed: _searchController.clear,
      );
    }

    final itemCount = filteredBatches.length + (showDataFolder ? 1 : 0);

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: provider.loadBatches,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          30,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (showDataFolder && index == 0) {
            return _DataFolderCard(
              onTap: _openDataFolder,
            );
          }

          final batchIndex = index - (showDataFolder ? 1 : 0);

          final batch = filteredBatches[batchIndex];
          final batchId = batch.id;

          final beneficiaryCount = batchId == null
              ? 0
              : provider.getBeneficiariesCount(
                  batchId,
                );

          return _BatchCard(
            batch: batch,
            beneficiaryCount: beneficiaryCount,
            formattedDate: _formatDate(batch.createdAt),
            onTap: () => _openBatch(batch),
            onRename: () => _showRenameDialog(batch),
            onDelete: () => _deleteBatch(batch),
            onProperties: () => _showBatchProperties(batch),
          );
        },
      ),
    );
  }
}
