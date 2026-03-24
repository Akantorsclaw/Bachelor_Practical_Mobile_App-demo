import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../app/session_controller.dart';
import '../branding/brand_context.dart';
import '../models/app_lens.dart';
import '../models/app_review.dart';
import '../models/lens_item.dart';
import '../models/rating_data.dart';
import '../services/lens_pass_qr_parser.dart';
import '../services/lens_service.dart';
import '../services/review_service.dart';
import '../shared/app_widgets.dart';
import 'screens/dashboard_screen.dart';
import 'screens/lens_passport_screen.dart';
import 'screens/lenses_list_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'screens/privacy_data_protection_screen.dart';
import 'screens/profile_overview_screen.dart';
import 'screens/rate_lens_screen.dart';
import 'screens/register_lens_screen.dart';

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
