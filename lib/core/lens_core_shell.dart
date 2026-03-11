import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../app/session_controller.dart';
import '../branding/brand_context.dart';
import '../models/app_lens.dart';
import '../models/app_review.dart';
import '../models/lens_passport_data.dart';
import '../services/lens_parameter_info_service.dart';
import '../services/lens_service.dart';
import '../services/lens_pass_qr_parser.dart';
import '../services/review_service.dart';
import '../shared/app_widgets.dart';
import '../shared/validators.dart';

/// Main authenticated shell with bottom-tab navigation.
class LensCoreShell extends StatefulWidget {
  const LensCoreShell({super.key, required this.controller});

  final SessionController controller;

  @override
  State<LensCoreShell> createState() => _LensCoreShellState();
}

class _LensCoreShellState extends State<LensCoreShell> {
  static const _qrParser = LensPassQrParser();
  final _lensService = LensService(FirebaseFirestore.instance);
  final _reviewService = ReviewService(FirebaseFirestore.instance);

  int _index = 0;
  bool _loadingLenses = true;
  List<LensItem> _lenses = [];
  List<AppReview> _reviews = [];
  StreamSubscription<List<AppLens>>? _lensesSubscription;
  StreamSubscription<List<AppReview>>? _reviewsSubscription;

  @override
  void initState() {
    super.initState();
    _subscribeLenses();
    _subscribeReviews();
  }

  @override
  void didUpdateWidget(covariant LensCoreShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller.userId != widget.controller.userId) {
      _subscribeLenses();
      _subscribeReviews();
    }
  }

  @override
  void dispose() {
    _lensesSubscription?.cancel();
    _reviewsSubscription?.cancel();
    super.dispose();
  }

  void _subscribeLenses() {
    _lensesSubscription?.cancel();
    final uid = widget.controller.userId;
    if (uid == null) {
      setState(() {
        _lenses = [];
        _loadingLenses = false;
      });
      return;
    }
    setState(() => _loadingLenses = true);
    _lensesSubscription = _lensService
        .watchLenses(uid)
        .listen(
          (data) {
            if (!mounted) return;
            setState(() {
              _lenses = data.map(_toLensItem).toList();
              _loadingLenses = false;
            });
          },
          onError: (_) {
            if (!mounted) return;
            setState(() => _loadingLenses = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not load lenses from Firestore.'),
              ),
            );
          },
        );
  }

  void _subscribeReviews() {
    _reviewsSubscription?.cancel();
    final uid = widget.controller.userId;
    if (uid == null) {
      setState(() => _reviews = []);
      return;
    }
    _reviewsSubscription = _reviewService
        .watchReviews(uid)
        .listen(
          (data) {
            if (!mounted) return;
            setState(() => _reviews = data);
          },
          onError: (_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not load reviews from Firestore.'),
              ),
            );
          },
        );
  }

  LensItem _toLensItem(AppLens lens) {
    return LensItem(
      id: lens.id,
      name: lens.name,
      purchaseDate: lens.purchaseDate,
      optician: lens.optician,
      passportData: lens.passportData,
    );
  }

  Future<void> _addLens(LensItem lens) async {
    final uid = widget.controller.userId;
    if (uid == null) return;
    try {
      await _lensService.createLens(
        uid,
        AppLens(
          id: lens.id,
          name: lens.name,
          purchaseDate: lens.purchaseDate,
          optician: lens.optician,
          passportData: lens.passportData,
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final message = e.code == 'permission-denied'
          ? 'Saving lens failed: Firestore rules currently deny this write.'
          : 'Saving lens failed. Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saving lens failed. Please try again.')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _index = 1);
  }

  Future<void> _selectTab(int index) async {
    if (!mounted) return;
    setState(() => _index = index);
  }

  /// Returns to root shell and changes the selected tab.
  void _navigateFromOverlay(int index) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    if (!mounted) return;
    setState(() => _index = index);
  }

  /// Opens lens registration as a pushed detail screen.
  Future<void> _openRegisterLens() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterLensScreen(
          onRegisterLens: _addLens,
          qrParser: _qrParser,
          onTabSelected: _navigateFromOverlay,
        ),
      ),
    );
  }

  /// Opens passport details for the selected lens.
  Future<void> _openPassport(LensItem lens) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            LensPassportScreen(lens: lens, onTabSelected: _navigateFromOverlay),
      ),
    );
  }

  Future<void> _openRateLensForLens(LensItem lens) async {
    final uid = widget.controller.userId;
    if (uid == null) return;

    final reviewId = 'lens_${lens.id}';
    final existing = _firstReviewWhere((r) => r.id == reviewId);
    if (existing == null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RateLensScreen(
            title: 'Rate Your Lens',
            submitLabel: 'Submit Review',
            targetName: lens.name,
            targetSubtitle: 'Progressive Lenses',
            aspectLabels: const ['Clarity', 'Comfort', 'Durability'],
            onTabSelected: _navigateFromOverlay,
            onSubmit: (data) async {
              await _reviewService.upsertReview(
                uid,
                AppReview(
                  id: reviewId,
                  targetType: ReviewTargetType.lens,
                  targetId: lens.id,
                  targetName: lens.name,
                  targetSubtitle: 'Progressive Lenses',
                  overallRating: data.stars,
                  aspectRatings: data.aspectRatings,
                  comment: data.comment,
                ),
              );
            },
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditRatingScreen(
          title: 'Edit Your Review',
          targetName: existing.targetName,
          targetSubtitle: existing.targetSubtitle,
          aspectLabels: const ['Clarity', 'Comfort', 'Durability'],
          initialRating: RatingData(
            stars: existing.overallRating,
            comment: existing.comment,
            ratedAt: existing.updatedAt ?? DateTime.now(),
            aspectRatings: existing.aspectRatings,
          ),
          onTabSelected: _navigateFromOverlay,
          onUpdate: (data) async {
            await _reviewService.upsertReview(
              uid,
              AppReview(
                id: existing.id,
                targetType: existing.targetType,
                targetId: existing.targetId,
                targetName: existing.targetName,
                targetSubtitle: existing.targetSubtitle,
                overallRating: data.stars,
                aspectRatings: data.aspectRatings,
                comment: data.comment,
              ),
            );
          },
          onDelete: () => _reviewService.deleteReview(uid, existing.id),
        ),
      ),
    );
  }

  Future<LensItem?> _pickLensForRating() async {
    if (_lenses.isEmpty) {
      if (!mounted) return null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No lens registered.')));
      return null;
    }
    return showModalBottomSheet<LensItem>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final palette = context.brandPalette;
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _lenses.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: palette.border),
            itemBuilder: (context, index) {
              final lens = _lenses[index];
              return ListTile(
                leading: Icon(
                  Icons.remove_red_eye_outlined,
                  color: palette.primary,
                ),
                title: Text(lens.name),
                subtitle: Text('${lens.purchaseDate} • ${lens.optician}'),
                onTap: () => Navigator.of(context).pop(lens),
              );
            },
          ),
        );
      },
    );
  }

  /// Opens optician rating flow and stores latest result in memory.
  Future<void> _openRateOptician() async {
    final uid = widget.controller.userId;
    if (uid == null) return;
    final opticianName = _lenses.isNotEmpty
        ? _lenses.first.optician
        : 'Your Optician';
    final existing = _firstReviewWhere((r) => r.id == 'optician_primary');

    if (existing == null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RateLensScreen(
            title: 'Rate Your Optician',
            submitLabel: 'Submit Feedback',
            targetName: opticianName,
            targetSubtitle: 'Optician partner',
            aspectLabels: const [
              'Customer Service',
              'Expertise',
              'Store Experience',
            ],
            onTabSelected: _navigateFromOverlay,
            onSubmit: (data) async {
              await _reviewService.upsertReview(
                uid,
                AppReview(
                  id: 'optician_primary',
                  targetType: ReviewTargetType.optician,
                  targetId: 'primary',
                  targetName: opticianName,
                  targetSubtitle: 'Optician partner',
                  overallRating: data.stars,
                  aspectRatings: data.aspectRatings,
                  comment: data.comment,
                ),
              );
            },
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditRatingScreen(
          title: 'Edit Your Review',
          targetName: existing.targetName,
          targetSubtitle: existing.targetSubtitle,
          aspectLabels: const [
            'Customer Service',
            'Expertise',
            'Store Experience',
          ],
          initialRating: RatingData(
            stars: existing.overallRating,
            comment: existing.comment,
            ratedAt: existing.updatedAt ?? DateTime.now(),
            aspectRatings: existing.aspectRatings,
          ),
          onTabSelected: _navigateFromOverlay,
          onUpdate: (data) async {
            await _reviewService.upsertReview(
              uid,
              AppReview(
                id: existing.id,
                targetType: existing.targetType,
                targetId: existing.targetId,
                targetName: existing.targetName,
                targetSubtitle: existing.targetSubtitle,
                overallRating: data.stars,
                aspectRatings: data.aspectRatings,
                comment: data.comment,
              ),
            );
          },
          onDelete: () => _reviewService.deleteReview(uid, existing.id),
        ),
      ),
    );
  }

  Future<void> _openRateMenu() async {
    final palette = context.brandPalette;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.remove_red_eye_outlined,
                    color: palette.primary,
                  ),
                  title: const Text('Rate Lens'),
                  onTap: () => Navigator.of(context).pop('lens'),
                ),
                ListTile(
                  leading: Icon(
                    Icons.store_mall_directory_outlined,
                    color: palette.primary,
                  ),
                  title: const Text('Rate Optician'),
                  onTap: () => Navigator.of(context).pop('optician'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || choice == null) return;
    if (choice == 'lens') {
      final lens = await _pickLensForRating();
      if (lens == null) return;
      await _openRateLensForLens(lens);
    } else {
      await _openRateOptician();
    }
  }

  /// Opens profile notification settings screen.
  Future<void> _openNotificationSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            NotificationSettingsScreen(onTabSelected: _navigateFromOverlay),
      ),
    );
  }

  /// Opens profile privacy and data protection screen.
  Future<void> _openPrivacyDataProtection() async {
    final profile = widget.controller.profile;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrivacyDataProtectionScreen(
          onTabSelected: _navigateFromOverlay,
          onWithdrawConsent: _handleWithdrawConsent,
          consentActive: profile?.consentActive ?? true,
          shareWithOptician: profile?.shareWithOptician ?? false,
          shareWithCompany: profile?.shareWithCompany ?? false,
          onSavePreferences: ({
            required bool consentActive,
            required bool shareWithOptician,
            required bool shareWithCompany,
          }) {
            return widget.controller.updatePrivacyPreferences(
              consentActive: consentActive,
              shareWithOptician: shareWithOptician,
              shareWithCompany: shareWithCompany,
            );
          },
        ),
      ),
    );
  }

  /// Runs consent withdrawal process through session controller.
  Future<String?> _handleWithdrawConsent() async {
    final error = await widget.controller.withdrawConsentAndLogout();
    if (!mounted) return error;
    if (error != null) return error;

    // Ensure nested profile routes are removed so auth flow is visible.
    Navigator.of(
      context,
      rootNavigator: true,
    ).popUntil((route) => route.isFirst);
    return null;
  }

  Future<void> _deleteLens(LensItem lens) async {
    final uid = widget.controller.userId;
    if (uid == null) return;
    try {
      await _lensService.deleteLens(uid, lens.id);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final message = e.code == 'permission-denied'
          ? 'Delete failed: Firestore rules currently deny this delete.'
          : 'Delete failed. Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delete failed. Please try again.')),
      );
    }
  }

  Future<String?> _updateProfile({
    required String name,
    required String email,
  }) {
    return widget.controller.updateProfile(name: name, email: email);
  }

  String _formatLastRated(DateTime? ratedAt) {
    if (ratedAt == null) return '--';
    final days = DateTime.now().difference(ratedAt).inDays;
    if (days <= 0) return '0d';
    return '${days}d';
  }

  int _daysUntilCheckup(LensItem? lens) {
    if (lens == null) return 14;
    final purchase = DateTime.tryParse(lens.purchaseDate);
    if (purchase == null) return 14;
    final followUp = purchase.add(const Duration(days: 180));
    final days = followUp.difference(DateTime.now()).inDays;
    return days < 0 ? 0 : days;
  }

  int? _ratingForLens(LensItem? lens) {
    if (lens == null) return null;
    final review = _firstReviewWhere((r) => r.id == 'lens_${lens.id}');
    return review?.overallRating;
  }

  AppReview? _firstReviewWhere(bool Function(AppReview review) test) {
    for (final review in _reviews) {
      if (test(review)) return review;
    }
    return null;
  }

  AppReview? _reviewForLens(LensItem lens) {
    return _firstReviewWhere((r) => r.id == 'lens_${lens.id}');
  }

  String _formatMemberSince(DateTime? date) {
    final value = date ?? DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[value.month - 1]} ${value.year}';
  }

  double _averageRating() {
    if (_reviews.isEmpty) return 0;
    final total = _reviews.fold<int>(
      0,
      (runningTotal, review) => runningTotal + review.overallRating,
    );
    return total / _reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    final currentLens = _lenses.isEmpty ? null : _lenses.first;
    final latestReviewTime = _reviews.isEmpty ? null : _reviews.first.updatedAt;
    final pages = [
      DashboardScreen(
        userName: widget.controller.userName,
        lensesCount: _lenses.length,
        ratingsCount: _reviews.length,
        lastRatedLabel: _formatLastRated(latestReviewTime),
        currentLens: currentLens,
        currentLensRating: _ratingForLens(currentLens),
        daysUntilCheckup: _daysUntilCheckup(currentLens),
        onGoRegister: _openRegisterLens,
        onGoLenses: () => setState(() => _index = 1),
        onRate: _openRateMenu,
        onOpenPassport: () async {
          if (currentLens == null) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Register a lens first.')),
            );
            return;
          }
          await _openPassport(currentLens);
        },
      ),
      LensesListScreen(
        lenses: _lenses,
        loading: _loadingLenses,
        onOpenDetails: _openPassport,
        onDeleteLens: _deleteLens,
        onUpdateReview: _openRateLensForLens,
        reviewForLens: _reviewForLens,
      ),
      ProfileOverviewScreen(
        name: widget.controller.userName,
        email: widget.controller.userEmail,
        selectedOptician: _lenses.isEmpty
            ? 'No optician selected'
            : _lenses.first.optician,
        memberSince: _formatMemberSince(
          widget.controller.profile?.createdAt ??
              widget.controller.profile?.gdprConsentAt,
        ),
        lensCount: _lenses.length,
        reviewCount: _reviews.length,
        averageRating: _averageRating(),
        onUpdateProfile: _updateProfile,
        onNotificationSettings: _openNotificationSettings,
        onPrivacy: _openPrivacyDataProtection,
        onLogout: widget.controller.signOut,
      ),
    ];

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_index != 0) {
          setState(() => _index = 0);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: KeyedSubtree(
                  key: ValueKey(_index),
                  child: pages[_index],
                ),
              ),
            ),
            if (widget.controller.busy)
              Positioned.fill(
                child: ColoredBox(
                  color: palette.scaffoldBackground.withValues(alpha: 0.9),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
        bottomNavigationBar: AppBottomNavigation(
          selectedIndex: _index,
          onSelected: (index) {
            _selectTab(index);
          },
        ),
      ),
    );
  }
}

/// Dashboard screen under the Home tab.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.userName,
    required this.lensesCount,
    required this.ratingsCount,
    required this.lastRatedLabel,
    required this.currentLens,
    required this.currentLensRating,
    required this.daysUntilCheckup,
    required this.onGoRegister,
    required this.onGoLenses,
    required this.onRate,
    required this.onOpenPassport,
  });

  final String userName;
  final int lensesCount;
  final int ratingsCount;
  final String lastRatedLabel;
  final LensItem? currentLens;
  final int? currentLensRating;
  final int daysUntilCheckup;
  final Future<void> Function() onGoRegister;
  final VoidCallback onGoLenses;
  final Future<void> Function() onRate;
  final Future<void> Function() onOpenPassport;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    final firstName = userName
        .trim()
        .split(' ')
        .firstWhere((part) => part.isNotEmpty, orElse: () => 'User');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: [
        Text(
          'Welcome back, $firstName',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Here's your vision care overview",
          style: TextStyle(fontSize: 17, color: palette.textSecondary),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _statCard(context, value: '$lensesCount', label: 'Lenses'),
            const SizedBox(width: 10),
            _statCard(context, value: '$ratingsCount', label: 'Ratings'),
            const SizedBox(width: 10),
            _statCard(context, value: lastRatedLabel, label: 'Last rated'),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          'Latest Lens',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        _currentLensCard(context),
        const SizedBox(height: 20),
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _quickActionCard(
                context,
                icon: Icons.add,
                title: 'Register New Lens',
                emphasized: true,
                onTap: () => onGoRegister(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _quickActionCard(
                context,
                icon: Icons.shopping_bag_outlined,
                title: 'My Lenses',
                onTap: onGoLenses,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _quickActionCard(
                context,
                icon: Icons.star_border_rounded,
                title: 'Rate Experience',
                onTap: () => onRate(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _quickActionCard(
                context,
                icon: Icons.workspace_premium_outlined,
                title: 'Lens Passport',
                onTap: () => onOpenPassport(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.surfaceMuted,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: palette.surface,
                child: Icon(
                  Icons.calendar_month_outlined,
                  color: palette.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upcoming Check-up',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your next optician visit is in $daysUntilCheckup days',
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
        ),
      ],
    );
  }

  Widget _statCard(
    BuildContext context, {
    required String value,
    required String label,
  }) {
    final palette = context.brandPalette;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: palette.secondary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: palette.primary,
                fontSize: 30,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: palette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _currentLensCard(BuildContext context) {
    final palette = context.brandPalette;
    final lens = currentLens;
    if (lens == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'No lens registered yet.',
          style: TextStyle(fontSize: 15, color: palette.textSecondary),
        ),
      );
    }

    return InkWell(
      onTap: () => onOpenPassport(),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.border),
              ),
              child: Icon(
                Icons.accessibility_new_rounded,
                color: palette.iconMuted,
                size: 36,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lens.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Progressive Lenses',
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star, color: palette.primary, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        currentLensRating == null
                            ? 'No rating'
                            : currentLensRating!.toStringAsFixed(1),
                        style: TextStyle(
                          color: palette.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.remove_red_eye_outlined,
              color: palette.primary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool emphasized = false,
  }) {
    final palette = context.brandPalette;
    final background = emphasized ? palette.primary : palette.secondary;
    final foreground = emphasized ? palette.onPrimary : palette.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 132,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: foreground.withValues(
                alpha: emphasized ? 0.22 : 0.1,
              ),
              child: Icon(icon, color: foreground, size: 24),
            ),
            Text(
              title,
              style: TextStyle(
                color: foreground,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lens registration detail screen.
class RegisterLensScreen extends StatefulWidget {
  const RegisterLensScreen({
    super.key,
    required this.onRegisterLens,
    required this.qrParser,
    required this.onTabSelected,
  });

  final Future<void> Function(LensItem lens) onRegisterLens;
  final LensPassQrParser qrParser;
  final ValueChanged<int> onTabSelected;

  @override
  State<RegisterLensScreen> createState() => _RegisterLensScreenState();
}

class _RegisterLensScreenState extends State<RegisterLensScreen> {
  final _serial = TextEditingController();
  String? _selectedOptician;
  LensPassportData? _parsedPassport;

  Future<void> _scanQrCode() async {
    final scannedValue = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const QrScannerScreen()));
    if (!mounted || scannedValue == null || scannedValue.isEmpty) return;
    final parsed = widget.qrParser.parse(scannedValue);
    setState(() {
      _parsedPassport = parsed;
      _serial.text = parsed?.lensDesign != null && parsed!.lensDesign != '-'
          ? parsed.lensDesign
          : scannedValue;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          parsed == null
              ? 'QR code scanned. No passport fields found.'
              : 'QR code scanned and passport data extracted.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _serial.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Scaffold(
      appBar: const TopBackAppBar(title: 'Lens Registration'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        children: [
          Text(
            'NAME',
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _serial,
            style: TextStyle(fontSize: 20, color: palette.textPrimary),
            decoration: InputDecoration(
              hintText: 'ENTER NAME',
              hintStyle: TextStyle(color: palette.textSecondary),
              filled: true,
              fillColor: palette.surfaceMuted,
              suffixIcon: Icon(
                Icons.camera_alt_outlined,
                color: palette.iconMuted,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _scanQrCode,
            icon: Icon(Icons.qr_code_scanner, color: palette.textPrimary),
            label: Text(
              'Scan QR code',
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(58),
              side: BorderSide(color: palette.border, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'STORE',
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedOptician,
            decoration: InputDecoration(
              filled: true,
              fillColor: palette.surfaceMuted,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            hint: const Text('Select Optician'),
            items: const [
              DropdownMenuItem(value: 'Optician A', child: Text('Optician A')),
              DropdownMenuItem(value: 'Optician B', child: Text('Optician B')),
              DropdownMenuItem(value: 'Optician C', child: Text('Optician C')),
            ],
            onChanged: (value) => setState(() => _selectedOptician = value),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () async {
              final nowDate = DateTime.now().toIso8601String().split('T').first;
              final parsed = _parsedPassport;
              final optician = _selectedOptician ?? '';
              await widget.onRegisterLens(
                LensItem(
                  id: '',
                  name: _serial.text.trim().isEmpty
                      ? (parsed?.lensDesign != null && parsed!.lensDesign != '-'
                            ? parsed.lensDesign
                            : 'Lens Name')
                      : _serial.text.trim(),
                  purchaseDate:
                      parsed?.orderDate != null && parsed!.orderDate != '-'
                      ? parsed.orderDate
                      : nowDate,
                  optician: optician.isEmpty ? 'Unknown' : optician,
                  passportData: parsed,
                ),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lens registered successfully.')),
              );
              Navigator.of(context).pop();
            },
            icon: Icon(Icons.adjust_outlined, color: palette.primary),
            label: Text(
              'Register Lens',
              style: TextStyle(
                color: palette.primary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: palette.accentSoft,
              minimumSize: const Size.fromHeight(58),
              shape: const StadiumBorder(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: 0,
        onSelected: widget.onTabSelected,
      ),
    );
  }
}

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

class LensPassportScreen extends StatefulWidget {
  const LensPassportScreen({
    super.key,
    required this.lens,
    required this.onTabSelected,
  });

  final LensItem lens;
  final ValueChanged<int> onTabSelected;

  @override
  State<LensPassportScreen> createState() => _LensPassportScreenState();
}

enum _PassportTab { lensDetails, prescription, frameMeasurements }

class _LensPassportScreenState extends State<LensPassportScreen> {
  _PassportTab _tab = _PassportTab.lensDetails;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBackAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
        children: [
          Text(
            'My Vision Details',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: context.brandPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          _PassportSegmentControl(
            selected: _tab,
            onChanged: (tab) => setState(() => _tab = tab),
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: switch (_tab) {
              _PassportTab.lensDetails => _PassportLensDetails(
                key: const ValueKey('lens-details'),
                lens: widget.lens,
              ),
              _PassportTab.prescription => _PassportPrescription(
                key: const ValueKey('prescription'),
                lens: widget.lens,
              ),
              _PassportTab.frameMeasurements => _PassportFrameMeasurements(
                key: const ValueKey('frame-measurements'),
                lens: widget.lens,
              ),
            },
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

class _PassportSegmentControl extends StatelessWidget {
  const _PassportSegmentControl({
    required this.selected,
    required this.onChanged,
  });

  final _PassportTab selected;
  final ValueChanged<_PassportTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.segmentSelected),
      ),
      child: Row(
        children: [
          _segmentButton(
            context,
            tab: _PassportTab.lensDetails,
            label: 'Lens Details',
          ),
          _segmentButton(
            context,
            tab: _PassportTab.prescription,
            label: 'Prescription',
          ),
          _segmentButton(
            context,
            tab: _PassportTab.frameMeasurements,
            label: 'Frame Measurements',
          ),
        ],
      ),
    );
  }

  Widget _segmentButton(
    BuildContext context, {
    required _PassportTab tab,
    required String label,
  }) {
    final palette = context.brandPalette;
    final isSelected = selected == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? palette.segmentSelected : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? palette.onSegmentSelected
                  : palette.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PassportLensDetails extends StatelessWidget {
  const _PassportLensDetails({super.key, required this.lens});

  final LensItem lens;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    final passport = lens.passportData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _passportInfoRow(
          context,
          code: 'LC',
          label: 'Lens Design',
          value: passport?.lensDesign ?? 'Hoyalux iD MySense',
        ),
        _passportInfoRow(
          context,
          code: 'AC',
          label: 'Antireflex Coating',
          value: passport?.antiReflexCoating ?? 'Hi-Vision MEIRYO',
        ),
        _passportInfoRow(
          context,
          code: 'MC',
          label: 'Material',
          value: passport?.material ?? '1.60',
        ),
        _passportInfoRow(
          context,
          code: 'DVC',
          label: 'Design Variation Code',
          value: passport?.designVariationCode ?? '309',
        ),
        _passportInfoRow(
          context,
          code: 'MDS',
          label: 'My Design Selection',
          value: passport?.myDesignSelection ?? '000002',
        ),
        const SizedBox(height: 12),
        Text(
          'Registered Lens: ${lens.name} • ${lens.purchaseDate} • ${lens.optician}'
          '${passport != null ? ' • Order ${passport.orderNumber}' : ''}',
          style: TextStyle(color: palette.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _passportInfoRow(
    BuildContext context, {
    required String code,
    required String label,
    required String value,
  }) {
    final palette = context.brandPalette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _showInfoCard(context, code: code, fieldName: label),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: palette.textPrimary),
                ),
                const SizedBox(width: 6),
                Icon(Icons.info_rounded, color: palette.textPrimary, size: 16),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoCard(
    BuildContext context, {
    required String code,
    required String fieldName,
  }) {
    final palette = context.brandPalette;
    final info = LensParameterInfoService.explanationForCode(code);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: palette.surface,
      barrierColor: palette.overlay,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: palette.border)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 52,
                    height: 5,
                    decoration: BoxDecoration(
                      color: palette.iconMuted,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  fieldName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  info,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.35,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PassportPrescription extends StatelessWidget {
  const _PassportPrescription({super.key, required this.lens});

  final LensItem lens;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    final right = lens.passportData?.right;
    final left = lens.passportData?.left;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Container(height: 1, color: palette.border)),
            const SizedBox(width: 14),
            Expanded(child: Container(height: 1, color: palette.border)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Right Eye',
                style: TextStyle(color: palette.textSecondary),
              ),
            ),
            Expanded(
              child: Text(
                'Left Eye',
                textAlign: TextAlign.end,
                style: TextStyle(color: palette.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _PassportDualValueRow(
          parameterCodes: const ['SR', 'SL'],
          label: 'Sphere Power',
          rightValue: right?.spherePower ?? '-1.03',
          leftValue: left?.spherePower ?? '-2.52',
        ),
        _PassportDualValueRow(
          parameterCodes: const ['CR', 'CL'],
          label: 'Cylinder Power',
          rightValue: right?.cylinderPower ?? '-0.98',
          leftValue: left?.cylinderPower ?? '-0.76',
        ),
        _PassportDualValueRow(
          parameterCodes: const ['XR', 'XL'],
          label: 'Cylinder Axis (°)',
          rightValue: right?.cylinderAxis ?? '175',
          leftValue: left?.cylinderAxis ?? '45',
        ),
        _PassportDualValueRow(
          parameterCodes: const ['AR', 'AL'],
          label: 'Addition Power',
          rightValue: right?.additionPower ?? '2.01',
          leftValue: left?.additionPower ?? '2.01',
        ),
      ],
    );
  }
}

class _PassportFrameMeasurements extends StatelessWidget {
  const _PassportFrameMeasurements({super.key, required this.lens});

  final LensItem lens;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    final right = lens.passportData?.right;
    final left = lens.passportData?.left;
    final frameFaceAngle = lens.passportData?.frameFaceAngle;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Container(height: 1, color: palette.border)),
            const SizedBox(width: 14),
            Expanded(child: Container(height: 1, color: palette.border)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Right Eye',
                style: TextStyle(color: palette.textSecondary),
              ),
            ),
            Expanded(
              child: Text(
                'Left Eye',
                textAlign: TextAlign.end,
                style: TextStyle(color: palette.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _PassportDualValueRow(
          parameterCodes: const ['PDR', 'PDL'],
          label: 'Pupil Distance (mm)',
          rightValue: right?.pupilDistance ?? '32.0',
          leftValue: left?.pupilDistance ?? '32.0',
        ),
        _PassportDualValueRow(
          parameterCodes: const ['EPR', 'EPL'],
          label: 'Eyepoint Height (mm)',
          rightValue: right?.eyepointHeight ?? '25.0',
          leftValue: left?.eyepointHeight ?? '25.0',
        ),
        _PassportDualValueRow(
          parameterCodes: const ['IR', 'IL'],
          label: 'Inset (mm)',
          rightValue: right?.inset ?? '2.25',
          leftValue: left?.inset ?? '2.29',
        ),
        _PassportDualValueRow(
          parameterCodes: const ['RFC', 'LFC'],
          label: 'Cornea Vertex Distance (mm)',
          rightValue: right?.corneaVertexDistance ?? '16.50',
          leftValue: left?.corneaVertexDistance ?? '16.50',
        ),
        _PassportDualValueRow(
          parameterCodes: const ['ALR', 'ALL'],
          label: 'Axial Length (mm)',
          rightValue: right?.axialLength ?? '23',
          leftValue: left?.axialLength ?? '23',
        ),
        _PassportDualValueRow(
          parameterCodes: const ['RPA', 'LPA'],
          label: 'Pantoscopic Angle (°)',
          rightValue: right?.pantoscopicAngle ?? '5.15',
          leftValue: left?.pantoscopicAngle ?? '5.12',
        ),
        _PassportDualValueRow(
          parameterCodes: const ['FL', 'FL'],
          label: 'Frame or Lens Measurements',
          rightValue: right?.frameOrLensMeasurement ?? 'F',
          leftValue: left?.frameOrLensMeasurement ?? 'F',
        ),
        _PassportDualValueRow(
          parameterCodes: const ['FFA', 'FFA'],
          label: 'Frame Face Angle (°)',
          rightValue: frameFaceAngle ?? '7.1',
          leftValue: frameFaceAngle ?? '7.1',
        ),
      ],
    );
  }
}

class _PassportDualValueRow extends StatelessWidget {
  const _PassportDualValueRow({
    required this.parameterCodes,
    required this.label,
    required this.rightValue,
    required this.leftValue,
  });

  final List<String> parameterCodes;
  final String label;
  final String rightValue;
  final String leftValue;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              rightValue,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () => _showInfoCard(context),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.2,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.info_rounded,
                    color: palette.textPrimary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Text(
              leftValue,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoCard(BuildContext context) {
    final palette = context.brandPalette;
    final info = LensParameterInfoService.explanationForCode(
      parameterCodes.first,
    );
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: palette.surface,
      barrierColor: palette.overlay,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: palette.border)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 52,
                    height: 5,
                    decoration: BoxDecoration(
                      color: palette.iconMuted,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  info,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.35,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

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

/// Profile overview screen under the Profile tab.
class ProfileOverviewScreen extends StatelessWidget {
  const ProfileOverviewScreen({
    super.key,
    required this.name,
    required this.email,
    required this.selectedOptician,
    required this.memberSince,
    required this.lensCount,
    required this.reviewCount,
    required this.averageRating,
    required this.onUpdateProfile,
    required this.onNotificationSettings,
    required this.onPrivacy,
    required this.onLogout,
  });

  final String name;
  final String email;
  final String selectedOptician;
  final String memberSince;
  final int lensCount;
  final int reviewCount;
  final double averageRating;
  final Future<String?> Function({required String name, required String email})
  onUpdateProfile;
  final Future<void> Function() onNotificationSettings;
  final Future<void> Function() onPrivacy;
  final Future<void> Function() onLogout;

  Future<void> _editProfile(BuildContext context) async {
    final draft = await showDialog<_ProfileDraft>(
      context: context,
      builder: (context) =>
          _EditProfileDialog(initialName: name, initialEmail: email),
    );
    if (draft == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Profile Update'),
          content: const Text('Do you want to save these profile changes?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;

    final error = await onUpdateProfile(name: draft.name, email: draft.email);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Profile updated successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();
    final displayInitials = initials.isEmpty ? 'U' : initials;
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 210,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    palette.primary,
                    palette.primary.withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 34, 24, 0),
              child: Text(
                'Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: palette.onPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 82, 24, 0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            color: palette.secondary,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            displayInitials,
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: palette.primary,
                            ),
                          ),
                        ),
                        Positioned(
                          right: -10,
                          bottom: -10,
                          child: Material(
                            color: palette.primary,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {},
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  Icons.photo_camera_outlined,
                                  color: palette.onPrimary,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Member since $memberSince',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              color: palette.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: palette.secondary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.workspace_premium_outlined,
                                  size: 18,
                                  color: palette.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$lensCount Lenses',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: palette.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 152),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'ACCOUNT INFORMATION',
            style: TextStyle(
              fontSize: 18,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w700,
              color: palette.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              _ProfileInfoRowCard(
                icon: Icons.mail_outline,
                label: 'Email',
                value: email,
                trailingIcon: Icons.edit_outlined,
                onTap: () => _editProfile(context),
              ),
              const SizedBox(height: 14),
              _ProfileInfoRowCard(
                icon: Icons.location_on_outlined,
                label: 'Optician',
                value: selectedOptician,
                trailingIcon: Icons.chevron_right_rounded,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Change optician flow not implemented yet.',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'YOUR ACTIVITY',
            style: TextStyle(
              fontSize: 18,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w700,
              color: palette.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: _ProfileStatCard(
                  value: '$lensCount',
                  label: 'Lenses\nOwned',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ProfileStatCard(
                  value: '$reviewCount',
                  label: 'Reviews\nGiven',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ProfileStatCard(
                  value: averageRating == 0
                      ? '--'
                      : averageRating.toStringAsFixed(1),
                  label: 'Avg\nRating',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'SETTINGS',
            style: TextStyle(
              fontSize: 18,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w700,
              color: palette.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              _ProfileSettingsCard(
                icon: Icons.notifications_none_rounded,
                label: 'Notification Settings',
                onTap: () => onNotificationSettings(),
              ),
              const SizedBox(height: 14),
              _ProfileSettingsCard(
                icon: Icons.shield_outlined,
                label: 'Privacy & Data\nProtection',
                onTap: () => onPrivacy(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Confirm Logout'),
                      content: const Text(
                        'Do you really want to log out of your account?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Logout'),
                        ),
                      ],
                    );
                  },
                );
                if (confirmed == true) {
                  await onLogout();
                }
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text(
                'Log Out',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
                backgroundColor: palette.negativeAccent,
                foregroundColor: palette.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileDraft {
  const _ProfileDraft({required this.name, required this.email});

  final String name;
  final String email;
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({
    required this.initialName,
    required this.initialEmail,
  });

  final String initialName;
  final String initialEmail;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _save() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    Navigator.of(context).pop(
      _ProfileDraft(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter your name',
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) return 'Enter your name';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'name@example.com',
              ),
              validator: validateEmail,
              onFieldSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Continue')),
      ],
    );
  }
}

/// Notification settings detail screen.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key, required this.onTabSelected});

  final ValueChanged<int> onTabSelected;

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

/// State for notification toggles.
class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _ratingReminders = true;
  bool _serviceNotifications = true;
  bool _newLensAlerts = true;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
        children: [
          Container(
            height: 224,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [palette.primary, palette.primary.withValues(alpha: 0.9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 54, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.chevron_left_rounded,
                          color: palette.onPrimary,
                          size: 38,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Notification Settings',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: palette.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(
                      'Manage how you receive updates',
                      style: TextStyle(
                        fontSize: 16,
                        color: palette.onPrimary.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'NOTIFICATION CHANNELS',
              style: TextStyle(
                fontSize: 18,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
                color: palette.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _NotificationChannelCard(
                  icon: Icons.smartphone_outlined,
                  title: 'Push Notifications',
                  subtitle: 'Instant alerts on your\ndevice',
                  value: _pushNotifications,
                  emphasized: true,
                  onChanged: (value) =>
                      setState(() => _pushNotifications = value),
                ),
                const SizedBox(height: 14),
                _NotificationChannelCard(
                  icon: Icons.mail_outline,
                  title: 'Email Notifications',
                  subtitle: 'Weekly summary via\nemail',
                  value: _emailNotifications,
                  onChanged: (value) =>
                      setState(() => _emailNotifications = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'NOTIFICATION TYPES',
              style: TextStyle(
                fontSize: 18,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
                color: palette.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: palette.border),
              ),
              child: Column(
                children: [
                  _NotificationTypeRow(
                    icon: Icons.star_border_rounded,
                    title: 'Rating Reminders',
                    subtitle: 'Get reminded to rate\nyour lenses',
                    value: _ratingReminders,
                    onChanged: (value) =>
                        setState(() => _ratingReminders = value),
                  ),
                  Divider(height: 1, color: palette.border),
                  _NotificationTypeRow(
                    icon: Icons.notifications_none_rounded,
                    title: 'Service Notifications',
                    subtitle: 'Updates from your\noptician',
                    value: _serviceNotifications,
                    onChanged: (value) =>
                        setState(() => _serviceNotifications = value),
                  ),
                  Divider(height: 1, color: palette.border),
                  _NotificationTypeRow(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'New Lens Alerts',
                    subtitle: 'News about HOYA\nproducts',
                    value: _newLensAlerts,
                    onChanged: (value) =>
                        setState(() => _newLensAlerts = value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              decoration: BoxDecoration(
                color: palette.secondary,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: palette.surface,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: palette.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stay Updated',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Notifications help you stay informed about your lens care journey. You can adjust these settings anytime.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification settings saved.'),
                    ),
                  );
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(62),
                  backgroundColor: palette.primary,
                  foregroundColor: palette.onPrimary,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: 2,
        onSelected: widget.onTabSelected,
      ),
    );
  }
}

class _NotificationChannelCard extends StatelessWidget {
  const _NotificationChannelCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.emphasized = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: emphasized ? palette.border : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: palette.surface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: palette.primary, size: 30),
          ),
          const SizedBox(width: 16),
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
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: value,
            activeTrackColor: palette.primary,
            activeThumbColor: palette.onPrimary,
            inactiveTrackColor: palette.border,
            inactiveThumbColor: palette.surface,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _NotificationTypeRow extends StatelessWidget {
  const _NotificationTypeRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: palette.secondary,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: palette.primary, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: value,
            activeTrackColor: palette.primary,
            activeThumbColor: palette.onPrimary,
            inactiveTrackColor: palette.border,
            inactiveThumbColor: palette.surface,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Privacy and data protection detail screen.
class PrivacyDataProtectionScreen extends StatefulWidget {
  const PrivacyDataProtectionScreen({
    super.key,
    required this.onTabSelected,
    required this.onWithdrawConsent,
    required this.consentActive,
    required this.shareWithOptician,
    required this.shareWithCompany,
    required this.onSavePreferences,
  });

  final ValueChanged<int> onTabSelected;
  final Future<String?> Function() onWithdrawConsent;
  final bool consentActive;
  final bool shareWithOptician;
  final bool shareWithCompany;
  final Future<String?> Function({
    required bool consentActive,
    required bool shareWithOptician,
    required bool shareWithCompany,
  })
  onSavePreferences;

  @override
  State<PrivacyDataProtectionScreen> createState() =>
      _PrivacyDataProtectionScreenState();
}

/// State for privacy consent controls and withdrawal confirmation.
class _PrivacyDataProtectionScreenState
    extends State<PrivacyDataProtectionScreen> {
  late bool _consentActive;
  late bool _shareWithOptician;
  late bool _shareWithCompany;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _consentActive = widget.consentActive;
    _shareWithOptician = widget.shareWithOptician;
    _shareWithCompany = widget.shareWithCompany;
  }

  Future<void> _savePreferences() async {
    if (_saving) return;
    setState(() => _saving = true);
    final error = await widget.onSavePreferences(
      consentActive: _consentActive,
      shareWithOptician: _shareWithOptician,
      shareWithCompany: _shareWithCompany,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Privacy settings saved.'),
      ),
    );
  }

  /// Confirms account-data withdrawal before executing the action.
  Future<void> _handleWithdrawConsent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Withdrawal'),
          content: const Text(
            'Withdrawing consent will delete your account data, including registered lenses and feedback.\n\n'
            'To use the app again, you will need to create a new account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Withdraw Consent'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => _WithdrawalLoadingDialog(
        overlay: context.brandPalette.overlay,
        text: context.brandPalette.onPrimary,
      ),
    );

    final error = await widget.onWithdrawConsent();
    if (!mounted) return;

    final rootNavigator = Navigator.of(context, rootNavigator: true);
    if (rootNavigator.canPop()) {
      rootNavigator.pop();
    }

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
        children: [
          Container(
            height: 236,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [palette.primary, palette.primary.withValues(alpha: 0.9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 54, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.chevron_left_rounded,
                          color: palette.onPrimary,
                          size: 38,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Privacy & Data\nProtection',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: palette.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(
                      'Your data security matters\nto us',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: palette.onPrimary.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _PrivacyFeatureCard(
              icon: Icons.shield_outlined,
              title: 'GDPR\nCompliant',
              description:
                  'Your personal data is processed in accordance with the General Data Protection Regulation (GDPR).',
              selected: true,
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'DATA PROCESSING\nCONSENT',
              style: TextStyle(
                fontSize: 18,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
                color: palette.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _DataProcessingConsentCard(
              consentActive: _consentActive,
              onChanged: (value) => setState(() => _consentActive = value),
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'DATA SHARING',
              style: TextStyle(
                fontSize: 18,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
                color: palette.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _PrivacySharingCard(
                  icon: Icons.store_mall_directory_outlined,
                  title: 'Share with\nOptician',
                  description:
                      'Allow your optician to access your app data for support and follow-up care.',
                  value: _shareWithOptician,
                  onChanged: _consentActive
                      ? (value) => setState(() => _shareWithOptician = value)
                      : null,
                ),
                const SizedBox(height: 14),
                _PrivacySharingCard(
                  icon: Icons.business_outlined,
                  title: 'Share with\nCompany',
                  description:
                      'Allow the company to use your data for service quality, product improvement, and customer care.',
                  value: _shareWithCompany,
                  onChanged: _consentActive
                      ? (value) => setState(() => _shareWithCompany = value)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'DATA WE STORE',
              style: TextStyle(
                fontSize: 18,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
                color: palette.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: const [
                _PrivacyFeatureCard(
                  icon: Icons.description_outlined,
                  title: 'Lens\nregistrations',
                  description: 'Product details and purchase info',
                ),
                SizedBox(height: 14),
                _PrivacyFeatureCard(
                  icon: Icons.remove_red_eye_outlined,
                  title: 'Ratings and\nfeedback',
                  description: 'Your reviews and comments',
                ),
                SizedBox(height: 14),
                _PrivacyFeatureCard(
                  icon: Icons.shield_outlined,
                  title: 'Selected\noptician',
                  description: 'Your preferred vision care provider',
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'YOUR RIGHTS',
              style: TextStyle(
                fontSize: 18,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
                color: palette.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _PrivacyFeatureCard(
                  icon: Icons.download_rounded,
                  title: 'Download My\nData',
                  description: 'Get a copy of your personal data',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Data export flow not implemented yet.'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                _PrivacyFeatureCard(
                  icon: Icons.article_outlined,
                  title: 'View Privacy\nPolicy',
                  description: 'Read our full privacy policy',
                  selected: true,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Privacy policy link flow not implemented yet.',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _savePreferences,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _saving ? 'Saving...' : 'Save Privacy Settings',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(58),
                  backgroundColor: palette.primary,
                  foregroundColor: palette.onPrimary,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _WithdrawConsentCard(onTap: _handleWithdrawConsent),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: 2,
        onSelected: widget.onTabSelected,
      ),
    );
  }
}

class _PrivacyFeatureCard extends StatelessWidget {
  const _PrivacyFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: selected ? palette.secondary : palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: selected ? palette.primary : palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: selected ? palette.primary : palette.secondary,
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: selected ? palette.onPrimary : palette.primary,
              size: 34,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: content,
      ),
    );
  }
}

class _DataProcessingConsentCard extends StatelessWidget {
  const _DataProcessingConsentCard({
    required this.consentActive,
    required this.onChanged,
  });

  final bool consentActive;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: palette.secondary,
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: palette.primary,
                  size: 34,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data\nProcessing',
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Allow processing of personal data for app functionality',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: consentActive,
                activeTrackColor: palette.primary,
                activeThumbColor: palette.onPrimary,
                inactiveTrackColor: palette.border,
                inactiveThumbColor: palette.surface,
                onChanged: onChanged,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: consentActive
                    ? const Color(0xFFE0F3E6)
                    : const Color(0xFFF2ECE3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                consentActive
                    ? '✓ Active - Your data is being processed securely'
                    : 'Consent inactive - App data processing is disabled',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: consentActive
                      ? const Color(0xFF0A8A2A)
                      : const Color(0xFF8A6B00),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacySharingCard extends StatelessWidget {
  const _PrivacySharingCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Opacity(
      opacity: onChanged == null ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: palette.secondary,
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: palette.primary, size: 34),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              activeTrackColor: palette.primary,
              activeThumbColor: palette.onPrimary,
              inactiveTrackColor: palette.border,
              inactiveThumbColor: palette.surface,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _WithdrawConsentCard extends StatelessWidget {
  const _WithdrawConsentCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7B9B9), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.delete_outline, color: Color(0xFFE00000)),
              const SizedBox(width: 10),
              Text(
                'Danger Zone',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFE00000),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'This action cannot be undone. Your account and all data will be permanently deleted.',
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor: const Color(0xFFE00000),
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Withdraw\nConsent &\nDelete Data',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WithdrawalLoadingDialog extends StatelessWidget {
  const _WithdrawalLoadingDialog({required this.overlay, required this.text});

  final Color overlay;
  final Color text;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: ColoredBox(
        color: overlay,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Withdrawing consent and signing you out...',
                style: TextStyle(color: text),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Read-only profile info tile used on profile overview.
class _ProfileInfoRowCard extends StatelessWidget {
  const _ProfileInfoRowCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.trailingIcon,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final IconData trailingIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Material(
      color: palette.surfaceMuted,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: palette.surface,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: palette.primary, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(trailingIcon, color: palette.iconMuted, size: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  const _ProfileStatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
      decoration: BoxDecoration(
        color: palette.secondary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: palette.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: palette.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSettingsCard extends StatelessWidget {
  const _ProfileSettingsCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: palette.secondary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: palette.primary, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right_rounded,
                color: palette.iconMuted,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple in-memory lens model used by prototype flows.
class LensItem {
  const LensItem({
    required this.id,
    required this.name,
    required this.purchaseDate,
    required this.optician,
    this.passportData,
  });

  final String id;
  final String name;
  final String purchaseDate;
  final String optician;
  final LensPassportData? passportData;
}

/// In-memory rating payload used between rating screens.
class RatingData {
  const RatingData({
    required this.stars,
    required this.comment,
    required this.ratedAt,
    required this.aspectRatings,
  });

  final int stars;
  final String comment;
  final DateTime ratedAt;
  final Map<String, int> aspectRatings;
}

/// Full-screen QR scanner that returns the first detected raw value.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBackAppBar(title: 'Scan QR code'),
      body: MobileScanner(
        onDetect: (capture) {
          if (_handled) return;
          final barcodes = capture.barcodes;
          if (barcodes.isEmpty) return;
          final value = barcodes.first.rawValue;
          if (value == null || value.isEmpty) return;
          _handled = true;
          Navigator.of(context).pop(value);
        },
      ),
    );
  }
}
