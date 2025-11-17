import 'package:flutter/material.dart';
import 'package:secpanel/theme/colors.dart';
import 'package:shimmer/shimmer.dart';

class IssueDetailCardSkeleton extends StatelessWidget {
  const IssueDetailCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CircleAvatar(backgroundColor: Colors.white, radius: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, width: 150, color: Colors.white),
                      const SizedBox(height: 4),
                      Container(height: 10, width: 100, color: Colors.white),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 40,
                  width: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            Container(height: 12, width: 80, color: Colors.white),
            const SizedBox(height: 8),
            Container(height: 11, width: double.infinity, color: Colors.white),
            const SizedBox(height: 4),
            Container(height: 11, width: double.infinity, color: Colors.white),
            const SizedBox(height: 4),
            Container(height: 11, width: 180, color: Colors.white),
            const SizedBox(height: 24),
            
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.grayLight.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, width: 100, color: Colors.white),
                  const Padding(
                    padding: EdgeInsets.only(top: 12.0),
                    child: Divider(color: AppColors.grayLight, height: 1),
                  ),
                  const SizedBox(height: 16),
                  _buildActivityLogRowSkeleton(),
                  const SizedBox(height: 16),
                  _buildActivityLogRowSkeleton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLogRowSkeleton() {
    return Row(
      children: [
        const CircleAvatar(backgroundColor: Colors.white, radius: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 11,
                width: double.infinity,
                color: Colors.white,
              ),
              const SizedBox(height: 4),
              Container(height: 10, width: 80, color: Colors.white),
            ],
          ),
        ),
      ],
    );
  }
}
