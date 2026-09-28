import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Standard decision-support disclaimer shown with every AI result.
const aiDecisionSupportNotice =
    'AI-generated analysis is decision-support information only and does not '
    'constitute a final diagnosis.';

/// Highlighted clinical notice, e.g. the AI decision-support disclaimer.
class ClinicalNotice extends StatelessWidget {
  const ClinicalNotice({super.key, this.text = aiDecisionSupportNotice});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: DecoratedBox(
        // A one-sided border cannot be combined with a border radius.
        decoration: const BoxDecoration(
          color: AppColors.infoSurface,
          border: Border(left: BorderSide(color: AppColors.navy, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 20, color: AppColors.navy),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
