// lib/components/panel/card/remarks_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:secpanel/theme/colors.dart';

class RemarksBottomSheet extends StatelessWidget {
  final String title;
  final Map<String, String?> remarksMap;

  const RemarksBottomSheet({
    super.key,
    required this.title,
    required this.remarksMap,
  });

  @override
  Widget build(BuildContext context) {
    final entries = remarksMap.entries.toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 5,
              width: 40,
              decoration: BoxDecoration(
                color: AppColors.grayLight,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.notes_rounded, color: AppColors.schneiderGreen),
              const SizedBox(width: 8),
              Text(
                title, // <-- Gunakan title dari parameter
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: remarksMap.isEmpty
                ? const Center(/* ... */)
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key, // Nama Vendor
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.value ?? '(Tidak ada komentar)', // Remark
                            style: const TextStyle(
                              color: AppColors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const Divider(height: 24, color: AppColors.grayLight),
                  ),
          ),
        ],
      ),
    );
  }
}
