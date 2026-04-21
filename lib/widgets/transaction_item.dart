import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/formatters.dart';
import '../data/models/transaction_model.dart';

class TransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final bool showDate;

  const TransactionItem({
    super.key,
    required this.transaction,
    this.onTap,
    this.showDate = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCredit = transaction.isCredit;
    final color = _typeColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.08 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_typeIcon(), color: color, size: 22),
            ),
            const SizedBox(width: 14),
            // Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.white : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (transaction.status != TransactionStatus.completed)
                        _statusChip(isDark)
                      else if (showDate)
                        Text(
                          AppFormatters.formatRelativeDate(transaction.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textOnDarkSecondary
                                : AppColors.textTertiary,
                          ),
                        ),
                      if (showDate &&
                          transaction.status == TransactionStatus.completed) ...[
                        Text(
                          ' · ${AppFormatters.formatTime(transaction.date)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.grey600
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? '+' : '-'} ${AppFormatters.formatCurrencyCompact(transaction.amount)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isCredit
                        ? AppColors.success
                        : isDark
                            ? AppColors.white
                            : AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    transaction.typeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(bool isDark) {
    Color color;
    switch (transaction.status) {
      case TransactionStatus.pending:
        color = AppColors.warning;
        break;
      case TransactionStatus.failed:
        color = AppColors.error;
        break;
      default:
        color = AppColors.grey400;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        transaction.statusLabel,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _typeColor() {
    switch (transaction.type) {
      case TransactionType.deposit:
      case TransactionType.topup:
        return AppColors.depositColor;
      case TransactionType.withdrawal:
        return AppColors.withdrawColor;
      case TransactionType.transfer:
        return AppColors.transferColor;
      case TransactionType.payment:
        return AppColors.paymentColor;
      case TransactionType.airtime:
        return AppColors.airtimeColor;
      case TransactionType.service:
        return AppColors.servicesColor;
    }
  }

  IconData _typeIcon() {
    switch (transaction.type) {
      case TransactionType.deposit:
        return Icons.arrow_downward_rounded;
      case TransactionType.withdrawal:
        return Icons.arrow_upward_rounded;
      case TransactionType.transfer:
        return Icons.swap_horiz_rounded;
      case TransactionType.payment:
        return Icons.contactless_rounded;
      case TransactionType.topup:
        return Icons.account_balance_wallet_rounded;
      case TransactionType.airtime:
        return Icons.phone_android_rounded;
      case TransactionType.service:
        return Icons.receipt_long_rounded;
    }
  }
}
