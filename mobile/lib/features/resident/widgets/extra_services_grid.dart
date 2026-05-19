import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import 'service_request_sheet.dart';

/// Service tiles in a fixed [Wrap] layout (reliable on web; no stacked hit targets).
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
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        const crossCount = 2;
        final cellWidth = (constraints.maxWidth - spacing) / crossCount;
        final cellHeight = compact ? 96.0 : 108.0;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: _services.map((s) {
            return SizedBox(
              width: cellWidth,
              height: cellHeight,
              child: Material(
                color: AppColors.surface1,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => showServiceRequestSheet(
                    context,
                    initialServiceType: s.$3,
                    propertyId: propertyId,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(s.$1,
                            color: AppColors.success, size: compact ? 26 : 30),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            s.$2,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: compact ? 11 : 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
