import 'package:flutter/material.dart';
import 'package:secpanel/theme/colors.dart';

class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final List<String> chips;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onChipDeleted;
  
  final ValueChanged<String> onChanged;

  const SearchField({
    super.key,
    required this.controller,
    required this.chips,
    required this.onSubmitted,
    required this.onChipDeleted,
    required this.onChanged, 
  });

  Widget _buildSearchChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(right: 8, top: 8), 
      decoration: BoxDecoration(
        color: AppColors.schneiderGreen.withOpacity(0.08),
        border: Border.all(color: AppColors.schneiderGreen),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.black,
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => onChipDeleted(label),
            child: const Icon(
              Icons.close,
              size: 16,
              color: AppColors.schneiderGreen,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        TextField(
          controller: controller,
          cursorColor: AppColors.schneiderGreen,
          style: const TextStyle(
            color: AppColors.black,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            hintText: 'Cari & Enter PP/WBS/Panel/Project...',
            hintStyle: const TextStyle(
              color: AppColors.gray,
              fontSize: 12,
              fontWeight: FontWeight.w300,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: AppColors.gray,
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.grayLight,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.schneiderGreen,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.grayLight,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: onChanged, 
          onSubmitted: onSubmitted,
        ),

        
        if (chips.isNotEmpty)
          Wrap(children: chips.map((chip) => _buildSearchChip(chip)).toList()),
      ],
    );
  }
}
