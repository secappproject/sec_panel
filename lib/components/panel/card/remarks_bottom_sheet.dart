// lib/components/panel/card/remarks_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:secpanel/models/busbarremark.dart';
import 'package:secpanel/theme/colors.dart';

class RemarksBottomSheet extends StatelessWidget {
  // [PERUBAHAN] Menerima List<BusbarRemark> bukan String
  final List<BusbarRemark> remarks;

  const RemarksBottomSheet({super.key, required this.remarks});

  @override
  Widget build(BuildContext context) {
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
          const Row(
            children: [
              Icon(Icons.notes_rounded, color: AppColors.schneiderGreen),
              SizedBox(width: 8),
              Text(
                "Busbar Remarks",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // [PERUBAHAN] Menggunakan ListView untuk menampilkan log
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: remarks.isEmpty
                ? const Center(
                    child: Text(
                      "Belum ada remark.",
                      style: TextStyle(color: AppColors.gray),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: remarks.length,
                    itemBuilder: (context, index) {
                      final remark = remarks[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            remark.vendorName, // Tampilkan nama vendor
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            remark.remark ??
                                '(Tidak ada komentar)', // Tampilkan remarknya
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
