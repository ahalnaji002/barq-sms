part of '../send_sms_screen.dart';

class _SmsBeneficiaryCard extends StatelessWidget {
  static const Color primaryColor = AppColors.primary;

  final Beneficiary beneficiary;
  final bool isSelected;
  final VoidCallback onTap;

  const _SmsBeneficiaryCard({
    required this.beneficiary,
    required this.isSelected,
    required this.onTap,
  });

  String _getFirstLetter() {
    final trimmedName = beneficiary.name.trim();

    if (trimmedName.isEmpty) {
      return '؟';
    }

    return trimmedName.substring(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: isSelected
            ? (Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF4A3A12)
                : const Color(0xFFFFF4CC))
            : AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isSelected ? const Color(0xFFFFB300) : AppColors.border(context),
          width: isSelected ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context).withValues(
              alpha: isSelected ? 0.22 : 0.12,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFFB300)
                        : (Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF3A321F)
                            : const Color(0xFFFFF3D0)),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF202020),
                          size: 27,
                        )
                      : Text(
                          _getFirstLetter(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: primaryColor,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        beneficiary.name.isEmpty
                            ? 'مستفيد بدون اسم'
                            : beneficiary.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text(context),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 7,
                        runSpacing: 6,
                        children: [
                          _SmsInfoChip(
                            icon: Icons.phone_outlined,
                            text: beneficiary.phoneNumber.isEmpty
                                ? 'لا يوجد هاتف'
                                : beneficiary.phoneNumber,
                            isError: beneficiary.phoneNumber.isEmpty,
                          ),
                          if (beneficiary.area.isNotEmpty)
                            _SmsInfoChip(
                              icon: Icons.location_on_outlined,
                              text: beneficiary.area,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Checkbox(
                  value: isSelected,
                  onChanged: (_) {
                    onTap();
                  },
                  activeColor: primaryColor,
                  checkColor: const Color(0xFF202020),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
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

class _SmsInfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isError;

  const _SmsInfoChip({
    required this.icon,
    required this.text,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isError
            ? Colors.red.withValues(alpha: 0.08)
            : (Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2B2B2B)
                : const Color(0xFFF7F2EA)),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: isError
              ? Colors.red.withValues(alpha: 0.20)
              : AppColors.border(context),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isError ? Colors.red : AppColors.subtitle(context),
          ),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 145,
            ),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection:
                  icon == Icons.phone_outlined ? TextDirection.ltr : null,
              style: TextStyle(
                fontSize: 11.5,
                color: isError ? Colors.red : AppColors.subtitle(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 105,
              height: 105,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 54,
                color: Color(0xFFFFB300),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'لا توجد نتائج',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'جرّب البحث بكلمة مختلفة',
              style: TextStyle(
                color: AppColors.subtitle(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBeneficiariesState extends StatelessWidget {
  const _EmptyBeneficiariesState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 115,
              height: 115,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.groups_outlined,
                size: 60,
                color: Color(0xFFFFB300),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'لا يوجد مستفيدون',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'استورد ملف Excel من الشاشة الرئيسية أولًا',
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.45,
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
