import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../branding/brand_context.dart';
import '../../models/rating_data.dart';
import '../../shared/app_widgets.dart';

/// Rating creation screen for lens/optician.
class RateLensScreen extends StatefulWidget {
  const RateLensScreen({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.targetName,
    required this.targetSubtitle,
    required this.aspectLabels,
    required this.onSubmit,
    required this.onTabSelected,
  });

  final String title;
  final String submitLabel;
  final String targetName;
  final String targetSubtitle;
  final List<String> aspectLabels;
  final Future<void> Function(RatingData data) onSubmit;
  final ValueChanged<int> onTabSelected;

  @override
  State<RateLensScreen> createState() => _RateLensScreenState();
}

class _RateLensScreenState extends State<RateLensScreen> {
  late final TextEditingController _commentController;
  late final Map<String, int> _aspectRatings;
  int _rating = 0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _aspectRatings = {for (final label in widget.aspectLabels) label: 5};
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final rating = _rating == 0 ? 5 : _rating;
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(
        RatingData(
          stars: rating,
          comment: _commentController.text.trim(),
          ratedAt: DateTime.now(),
          aspectRatings: _aspectRatings,
        ),
      );
      if (!mounted) return;
      widget.onTabSelected(0);
      return;
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final message = e.code == 'permission-denied'
          ? 'Could not save review: missing Firestore permission.'
          : 'Could not save review. Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save review. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    final darkChrome = palette.scaffoldBackground.computeLuminance() < 0.08;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkChrome ? palette.surfaceStrong : palette.surface,
        foregroundColor: darkChrome ? palette.onSurface : palette.textPrimary,
        surfaceTintColor: Colors.transparent,
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        children: [
          _RatingHeaderCard(
            title: widget.targetName,
            subtitle: widget.targetSubtitle,
            overallLabel: 'How was your experience?',
            rating: _rating,
            onSelected: (value) => setState(() => _rating = value),
          ),
          const SizedBox(height: 18),
          Text(
            'Rate specific aspects',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...widget.aspectLabels.map(
            (label) => _AspectRatingRow(
              label: label,
              value: _aspectRatings[label] ?? 5,
              onChanged: (value) =>
                  setState(() => _aspectRatings[label] = value),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Share your feedback',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            onChanged: (_) => setState(() {}),
            minLines: 4,
            maxLines: 4,
            style: TextStyle(fontSize: 16, color: palette.textPrimary),
            decoration: InputDecoration(
              hintText: 'Tell us about your experience...',
              hintStyle: TextStyle(color: palette.textSecondary),
              filled: true,
              fillColor: palette.surfaceMuted,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_commentController.text.length}/500 characters',
            style: TextStyle(fontSize: 13, color: palette.textSecondary),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(
                _submitting ? 'Saving...' : widget.submitLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: palette.onPrimary,
                minimumSize: const Size.fromHeight(52),
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: 1,
        onSelected: widget.onTabSelected,
      ),
    );
  }
}

class EditRatingScreen extends StatefulWidget {
  const EditRatingScreen({
    super.key,
    required this.title,
    required this.targetName,
    required this.targetSubtitle,
    required this.aspectLabels,
    required this.initialRating,
    required this.onUpdate,
    required this.onDelete,
    required this.onTabSelected,
  });

  final String title;
  final String targetName;
  final String targetSubtitle;
  final List<String> aspectLabels;
  final RatingData initialRating;
  final Future<void> Function(RatingData data) onUpdate;
  final Future<void> Function() onDelete;
  final ValueChanged<int> onTabSelected;

  @override
  State<EditRatingScreen> createState() => _EditRatingScreenState();
}

class _EditRatingScreenState extends State<EditRatingScreen> {
  late final TextEditingController _commentController;
  late final Map<String, int> _aspectRatings;
  late int _rating;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating.stars;
    _commentController = TextEditingController(
      text: widget.initialRating.comment,
    );
    _aspectRatings = {
      for (final label in widget.aspectLabels)
        label: widget.initialRating.aspectRatings[label] ?? 5,
    };
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    if (_updating) return;
    setState(() => _updating = true);
    try {
      await widget.onUpdate(
        RatingData(
          stars: _rating == 0 ? 5 : _rating,
          comment: _commentController.text.trim(),
          ratedAt: DateTime.now(),
          aspectRatings: _aspectRatings,
        ),
      );
      if (!mounted) return;
      widget.onTabSelected(0);
      return;
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final message = e.code == 'permission-denied'
          ? 'Could not update review: missing Firestore permission.'
          : 'Could not update review. Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update review. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _delete() async {
    await widget.onDelete();
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Review deleted.')));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    final darkChrome = palette.scaffoldBackground.computeLuminance() < 0.08;
    final submittedOn =
        '${widget.initialRating.ratedAt.year}-${widget.initialRating.ratedAt.month.toString().padLeft(2, '0')}-${widget.initialRating.ratedAt.day.toString().padLeft(2, '0')}';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkChrome ? palette.surfaceStrong : palette.surface,
        foregroundColor: darkChrome ? palette.onSurface : palette.textPrimary,
        surfaceTintColor: Colors.transparent,
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: palette.secondary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Review submitted: $submittedOn',
              style: TextStyle(
                fontSize: 14,
                color: palette.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _RatingHeaderCard(
            title: widget.targetName,
            subtitle: widget.targetSubtitle,
            overallLabel: 'Update your rating',
            rating: _rating,
            onSelected: (value) => setState(() => _rating = value),
          ),
          const SizedBox(height: 18),
          Text(
            'Rate specific aspects',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...widget.aspectLabels.map(
            (label) => _AspectRatingRow(
              label: label,
              value: _aspectRatings[label] ?? 5,
              onChanged: (value) =>
                  setState(() => _aspectRatings[label] = value),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Update your review',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            onChanged: (_) => setState(() {}),
            minLines: 4,
            maxLines: 4,
            style: TextStyle(fontSize: 16, color: palette.textPrimary),
            decoration: InputDecoration(
              hintText: 'Tell us about your experience...',
              hintStyle: TextStyle(color: palette.textSecondary),
              filled: true,
              fillColor: palette.surfaceMuted,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_commentController.text.length}/500 characters',
            style: TextStyle(fontSize: 13, color: palette.textSecondary),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _update,
              icon: _updating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(
                _updating ? 'Saving...' : 'Update Review',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: palette.onPrimary,
                minimumSize: const Size.fromHeight(52),
                shape: const StadiumBorder(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
              label: const Text(
                'Delete Review',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: palette.negativeAccent,
                foregroundColor: palette.onPrimary,
                minimumSize: const Size.fromHeight(52),
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: 1,
        onSelected: widget.onTabSelected,
      ),
    );
  }
}

class _RatingHeaderCard extends StatelessWidget {
  const _RatingHeaderCard({
    required this.title,
    required this.subtitle,
    required this.overallLabel,
    required this.rating,
    required this.onSelected,
  });

  final String title;
  final String subtitle;
  final String overallLabel;
  final int rating;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.secondary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: palette.border),
                ),
                child: Icon(
                  Icons.accessibility_new_rounded,
                  color: palette.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 15,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            overallLabel,
            style: TextStyle(fontSize: 16, color: palette.textSecondary),
          ),
          const SizedBox(height: 8),
          _RatingStars(rating: rating, onSelected: onSelected),
        ],
      ),
    );
  }
}

class _AspectRatingRow extends StatelessWidget {
  const _AspectRatingRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 17,
                color: palette.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _MiniStars(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _MiniStars extends StatelessWidget {
  const _MiniStars({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final number = index + 1;
        final selected = number <= value;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onChanged(number),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? palette.primary.withValues(alpha: 0.16)
                      : palette.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected ? palette.primary : palette.border,
                    width: 1.4,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  selected ? Icons.star_rounded : Icons.star_border_rounded,
                  color: palette.primary,
                  size: 24,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _RatingStars extends StatelessWidget {
  const _RatingStars({required this.rating, required this.onSelected});

  final int rating;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final number = index + 1;
        final isSelected = number <= rating;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onSelected(number),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isSelected
                      ? palette.primary.withValues(alpha: 0.16)
                      : palette.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected ? palette.primary : palette.border,
                    width: 1.8,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: palette.primary.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Icon(
                  isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                  color: palette.primary,
                  size: 30,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
