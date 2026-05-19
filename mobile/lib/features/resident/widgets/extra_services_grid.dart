import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import 'service_request_sheet.dart';

/// Fixed-height service grid (avoids unbounded GridView glitches in ListView / tab switches).
class ExtraServicesGrid extends StatelessWidget {
  const ExtraServicesGrid({
    super.key,
    required this.propertyId,
    this.compact = false,
  });

  final String? propertyId;
  final bool compact;

  static const _services = [
    (Icons.local_shipping_outlined, 'Moving Service', 'Moving Service'),
    (Icons.cleaning_services_outlined, 'Maid Service', 'Maid Service'),
    (Icons.delete_outline, 'Bulk Trash Pickup', 'Bulk Trash Pickup'),
    (Icons.chair_outlined, 'Carpet Cleaning', 'Carpet Cleaning'),
    (Icons.more_horiz, 'More Services', 'Other'),
  ];

  @override
  Widget build(BuildContext context) {
    final crossCount = 2;
    final rows = (_services.length / crossCount).ceil();
    final aspect = compact ? 1.45 : 1.2;
    final rowHeight = compact ? 100.0 : 110.0;
    final gridHeight = rows * rowHeight + (rows - 1) * 10;

    return SizedBox(
      height: gridHeight,
      child: GridView.count(
        crossAxisCount: crossCount,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: aspect,
        physics: const NeverScrollableScrollPhysics(),
        children: _services.map((s) {
          return InkWell(
            onTap: () => showServiceRequestSheet(
              context,
              initialServiceType: s.$3,
              propertyId: propertyId,
            ),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface1,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(s.$1, color: AppColors.success, size: compact ? 26 : 32),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      s.$2,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: compact ? 11 : 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
