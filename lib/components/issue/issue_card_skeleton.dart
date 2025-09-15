import 'package:flutter/material.dart';
import 'package:secpanel/theme/colors.dart';
import 'package:shimmer/shimmer.dart';

class IssueCardSkeleton extends StatelessWidget {
  const IssueCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    // Helper widget untuk membuat placeholder abu-abu
    Widget placeholder({double? width, double height = 14.0}) {
      return Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white, // Warna dasar untuk shimmer
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ).copyWith(bottom: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          border: Border.all(width: 1, color: AppColors.grayLight),
        ),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[200]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Skeleton
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          placeholder(
                            width: 180,
                            height: 14,
                          ), // Nama user & aksi
                          const SizedBox(height: 6),
                          placeholder(width: 80, height: 12), // Timestamp
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    placeholder(width: 36, height: 36), // Ikon status
                  ],
                ),
              ),
              // Content Skeleton
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    placeholder(
                      width: MediaQuery.of(context).size.width * 0.6,
                      height: 20,
                    ), // Judul
                    const SizedBox(height: 8),
                    placeholder(
                      width: double.infinity,
                      height: 14,
                    ), // Deskripsi baris 1
                    const SizedBox(height: 4),
                    placeholder(
                      width: MediaQuery.of(context).size.width * 0.7,
                      height: 14,
                    ), // Deskripsi baris 2
                  ],
                ),
              ),
              // Photo Grid Skeleton (Opsional, jika ingin lebih detail)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.25, // Sesuaikan rasio aspek
                  children: List.generate(
                    2,
                    (index) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(color: Colors.white),
                    ),
                  ),
                ),
              ),
              // Footer Skeleton
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(child: placeholder(height: 36)),
                    const SizedBox(width: 12),
                    Expanded(child: placeholder(height: 36)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
