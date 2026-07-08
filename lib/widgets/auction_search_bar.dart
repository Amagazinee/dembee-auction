import 'package:flutter/material.dart';

import '../core/auction_filter.dart';
import '../core/constants/auction_categories.dart';
import '../theme/app_theme.dart';

class AuctionSearchBar extends StatelessWidget {
  const AuctionSearchBar({
    super.key,
    required this.searchController,
    required this.statusFilter,
    required this.categoryFilter,
    required this.onStatusChanged,
    required this.onCategoryChanged,
    required this.resultCount,
    required this.totalCount,
  });

  final TextEditingController searchController;
  final AuctionStatusFilter statusFilter;
  final String? categoryFilter;
  final ValueChanged<AuctionStatusFilter> onStatusChanged;
  final ValueChanged<String?> onCategoryChanged;
  final int resultCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: searchController,
            builder: (context, value, _) {
              return TextField(
                controller: searchController,
                textInputAction: TextInputAction.search,
                cursorColor: AppTheme.primary,
                style: AppTheme.bodyStyle.copyWith(
                  color: AppTheme.foreground,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Дуудлага хайх (нэр, ангилал, ялагч)...',
                  hintStyle: AppTheme.bodyStyle.copyWith(
                    color: AppTheme.mutedForeground,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: AppTheme.mutedForeground,
                  ),
                  suffixIcon: value.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          color: AppTheme.mutedForeground,
                          onPressed: () {
                            searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.inputBackground,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(
                      color: AppTheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in AuctionStatusFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter.label),
                      selected: statusFilter == filter,
                      onSelected: (_) => onStatusChanged(filter),
                      selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                      checkmarkColor: AppTheme.primary,
                      labelStyle: AppTheme.bodyStyle.copyWith(
                        fontSize: 12,
                        color: statusFilter == filter
                            ? AppTheme.primary
                            : AppTheme.mutedForeground,
                      ),
                      side: const BorderSide(color: AppTheme.border),
                      backgroundColor: AppTheme.card,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Бүх ангилал'),
                    selected: categoryFilter == null,
                    onSelected: (_) => onCategoryChanged(null),
                    selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primary,
                    labelStyle: AppTheme.bodyStyle.copyWith(
                      fontSize: 12,
                      color: categoryFilter == null
                          ? AppTheme.primary
                          : AppTheme.mutedForeground,
                    ),
                    side: const BorderSide(color: AppTheme.border),
                    backgroundColor: AppTheme.card,
                  ),
                ),
                for (final category in AuctionCategories.all)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: categoryFilter == category,
                      onSelected: (_) => onCategoryChanged(category),
                      selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                      checkmarkColor: AppTheme.primary,
                      labelStyle: AppTheme.bodyStyle.copyWith(
                        fontSize: 12,
                        color: categoryFilter == category
                            ? AppTheme.primary
                            : AppTheme.mutedForeground,
                      ),
                      side: const BorderSide(color: AppTheme.border),
                      backgroundColor: AppTheme.card,
                    ),
                  ),
              ],
            ),
          ),
          if (searchController.text.isNotEmpty ||
              statusFilter != AuctionStatusFilter.all ||
              categoryFilter != null) ...[
            const SizedBox(height: 8),
            Text(
              '$resultCount / $totalCount дуудлага',
              style: AppTheme.bodyStyle.copyWith(
                fontSize: 11,
                color: AppTheme.mutedForeground,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
