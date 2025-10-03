import 'package:flutter/material.dart';
import 'package:secpanel/components/issue/issue_detail/issue_detail_card.dart';
import 'package:secpanel/models/company.dart';
import 'package:secpanel/theme/colors.dart';

class IssueDetailBottomSheet extends StatelessWidget {
  final int issueId;
  final VoidCallback onUpdate;
  final Company currentCompany;

  const IssueDetailBottomSheet({
    super.key,
    required this.issueId,
    required this.onUpdate,
    required this.currentCompany
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle (garis abu-abu di atas)
              Center(
                child: Container(
                  height: 5,
                  width: 40,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.grayLight,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              // Konten utama
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // FIX: Pass the required arguments to IssueDetailCard
                    IssueDetailCard(
                      currentCompany: currentCompany,
                      issueId: issueId,
                      onUpdate: onUpdate,
                      scaffoldContext: context,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
