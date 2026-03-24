import 'package:flutter/material.dart';

import '../../branding/brand_context.dart';
import '../../models/app_review.dart';
import '../../models/lens_item.dart';

/// Lens list screen under the Lenses tab.
class LensesListScreen extends StatelessWidget {
  const LensesListScreen({
    super.key,
    required this.lenses,
    required this.loading,
    required this.onOpenDetails,
    required this.onDeleteLens,
    required this.onUpdateReview,
    required this.reviewForLens,
  });

  final List<LensItem> lenses;
  final bool loading;
  final void Function(LensItem lens) onOpenDetails;
  final Future<void> Function(LensItem lens) onDeleteLens;
  final Future<void> Function(LensItem lens) onUpdateReview;
  final AppReview? Function(LensItem lens) reviewForLens;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (lenses.isEmpty) {
      return Center(
        child: Text(
          'No registered lenses yet.',
          style: TextStyle(color: palette.textSecondary),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      itemCount: lenses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final lens = lenses[index];
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(
                builder: (context) {
                  final review = reviewForLens(lens);
                  final rated = review != null;
                  final badgeText = rated
                      ? 'Rated ${review.overallRating}/5'
                      : 'Not rated yet';
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: rated ? palette.accentSoft : palette.surfaceMuted,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: rated ? palette.primary : palette.border,
                      ),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: rated ? palette.primary : palette.textSecondary,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: palette.accentSoft,
                    child: Icon(
                      Icons.person_outline,
                      color: palette.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      lens.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete lens',
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Lens'),
                          content: Text(
                            'Delete "${lens.name}" from saved lenses?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      await onDeleteLens(lens);
                    },
                    icon: Icon(
                      Icons.delete_outline,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Lens Info',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Lens Name: ${lens.name}',
                style: TextStyle(fontSize: 15, color: palette.textSecondary),
              ),
              Text(
                'Purchase Date: ${lens.purchaseDate}',
                style: TextStyle(fontSize: 15, color: palette.textSecondary),
              ),
              Text(
                'Optician: ${lens.optician}',
                style: TextStyle(fontSize: 15, color: palette.textSecondary),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => onOpenDetails(lens),
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.primary,
                    foregroundColor: palette.onPrimary,
                    minimumSize: const Size.fromHeight(54),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => onUpdateReview(lens),
                  icon: const Icon(Icons.edit_outlined),
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.secondary,
                    foregroundColor: palette.primary,
                    minimumSize: const Size.fromHeight(50),
                    shape: const StadiumBorder(),
                  ),
                  label: const Text(
                    'Rate / Update Review',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
