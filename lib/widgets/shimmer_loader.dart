import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppConstants.radiusSM,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.grey800 : AppColors.grey200,
      highlightColor: isDark ? AppColors.grey700 : AppColors.grey100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? AppColors.grey800 : AppColors.grey200,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class TransactionShimmer extends StatelessWidget {
  const TransactionShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.cardDark
                : AppColors.white,
            borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          ),
          child: Row(
            children: [
              ShimmerBox(width: 46, height: 46, borderRadius: AppConstants.radiusMD),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 160, height: 14),
                    const SizedBox(height: 8),
                    ShimmerBox(width: 100, height: 12),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ShimmerBox(width: 80, height: 14),
                  const SizedBox(height: 8),
                  ShimmerBox(width: 40, height: 12),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
