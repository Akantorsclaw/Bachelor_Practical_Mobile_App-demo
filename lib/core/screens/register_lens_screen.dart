import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../branding/brand_context.dart';
import '../../models/app_optician.dart';
import '../../models/lens_item.dart';
import '../../models/lens_passport_data.dart';
import '../../services/lens_pass_qr_parser.dart';
import '../../services/optician_service.dart';
import '../../shared/app_widgets.dart';

/// Lens registration detail screen.
class RegisterLensScreen extends StatefulWidget {
  const RegisterLensScreen({
    super.key,
    required this.onRegisterLens,
    required this.qrParser,
    required this.onTabSelected,
    required this.opticians,
  });

  final Future<void> Function(LensItem lens) onRegisterLens;
  final LensPassQrParser qrParser;
  final ValueChanged<int> onTabSelected;
  final List<AppOptician> opticians;

  @override
  State<RegisterLensScreen> createState() => _RegisterLensScreenState();
}

class _RegisterLensScreenState extends State<RegisterLensScreen> {
  final _serial = TextEditingController();
  LensPassportData? _parsedPassport;
  AppOptician? _selectedOptician;

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

  Future<void> _openOpticianPicker() async {
    final result = await showModalBottomSheet<AppOptician?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.brandPalette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _OpticianPickerSheet(opticians: widget.opticians),
    );
    // result == null means the sheet was dismissed via drag — do nothing.
    // result == _noOpticianSentinel means the user tapped "No optician".
    // result == an AppOptician means a real selection was made.
    if (!mounted) return;
    if (result == _noOpticianSentinel) {
      setState(() => _selectedOptician = null);
    } else if (result != null) {
      setState(() => _selectedOptician = result);
    }
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
          FilledButton.icon(
            onPressed: _scanQrCode,
            icon: Icon(Icons.qr_code_scanner, color: palette.onPrimary),
            label: Text(
              'Scan QR code',
              style: TextStyle(
                color: palette.onPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: palette.primary,
              minimumSize: const Size.fromHeight(58),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          if (_parsedPassport == null) ...[
            const SizedBox(height: 8),
            Text(
              'Scan a QR code to continue',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: palette.textSecondary),
            ),
          ],
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
          // Optician selector row
          Material(
            color: palette.surfaceMuted,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _openOpticianPicker,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedOptician != null
                          ? Icons.store_outlined
                          : Icons.search,
                      color: _selectedOptician != null
                          ? palette.primary
                          : palette.iconMuted,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _selectedOptician != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedOptician!.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: palette.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${_selectedOptician!.zipCode} ${_selectedOptician!.city}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: palette.textSecondary,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'No optician selected',
                              style: TextStyle(
                                fontSize: 16,
                                color: palette.textSecondary,
                              ),
                            ),
                    ),
                    if (_selectedOptician != null)
                      GestureDetector(
                        onTap: () =>
                            setState(() => _selectedOptician = null),
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: palette.iconMuted,
                        ),
                      )
                    else
                      Icon(
                        Icons.chevron_right_rounded,
                        color: palette.iconMuted,
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _parsedPassport == null
                ? null
                : () async {
                    final nowDate =
                        DateTime.now().toIso8601String().split('T').first;
                    final parsed = _parsedPassport;
                    await widget.onRegisterLens(
                      LensItem(
                        id: '',
                        name: _serial.text.trim().isEmpty
                            ? (parsed?.lensDesign != null &&
                                      parsed!.lensDesign != '-'
                                  ? parsed.lensDesign
                                  : 'Lens Name')
                            : _serial.text.trim(),
                        purchaseDate: parsed?.orderDate != null &&
                                parsed!.orderDate != '-'
                            ? parsed.orderDate
                            : nowDate,
                        optician: _selectedOptician?.name ?? '',
                        passportData: parsed,
                      ),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lens registered successfully.'),
                      ),
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

// ---------------------------------------------------------------------------
// Sentinel value returned when the user taps "No optician"
// ---------------------------------------------------------------------------

final _noOpticianSentinel = AppOptician(
  id: '__none__',
  externalId: '',
  name: '',
  address: '',
  zipCode: '',
  city: '',
  openingHours: const [],
  isPremium: false,
  campaigns: const [],
);

// ---------------------------------------------------------------------------
// Optician picker bottom sheet
// ---------------------------------------------------------------------------

class _OpticianPickerSheet extends StatefulWidget {
  const _OpticianPickerSheet({required this.opticians});

  final List<AppOptician> opticians;

  @override
  State<_OpticianPickerSheet> createState() => _OpticianPickerSheetState();
}

class _OpticianPickerSheetState extends State<_OpticianPickerSheet> {
  final _searchController = TextEditingController();
  late List<AppOptician> _filtered;
  double? _userLat;
  double? _userLng;
  bool _nearMe = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _filtered = widget.opticians;
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    var results = OpticianService.filterByQuery(
      widget.opticians,
      _searchController.text,
    );
    if (_nearMe && _userLat != null && _userLng != null) {
      results = OpticianService.sortByProximity(results, _userLat!, _userLng!);
    }
    if (!mounted) return;
    setState(() => _filtered = results);
  }

  Future<void> _toggleNearMe() async {
    if (_nearMe) {
      setState(() {
        _nearMe = false;
        _userLat = null;
        _userLng = null;
      });
      _applyFilters();
      return;
    }

    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied.')),
        );
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (!mounted) return;
      setState(() {
        _userLat = pos.latitude;
        _userLng = pos.longitude;
        _nearMe = true;
      });
      _applyFilters();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get location.')),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  String? _distanceLabel(AppOptician o) {
    if (_userLat == null || _userLng == null) return null;
    final km = OpticianService.distanceKm(o, _userLat!, _userLng!);
    if (km == double.infinity) return null;
    return km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Search row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search by name, city or postcode…',
                      hintStyle: TextStyle(color: palette.textSecondary),
                      prefixIcon:
                          Icon(Icons.search, color: palette.iconMuted),
                      filled: true,
                      fillColor: palette.surfaceMuted,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _locating
                    ? const SizedBox(
                        width: 40,
                        height: 40,
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : IconButton(
                        onPressed: _toggleNearMe,
                        tooltip: 'Near Me',
                        style: IconButton.styleFrom(
                          backgroundColor: _nearMe
                              ? palette.primary
                              : palette.surfaceMuted,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: Icon(
                          Icons.near_me_outlined,
                          color: _nearMe
                              ? palette.onPrimary
                              : palette.textSecondary,
                        ),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: palette.border),
          // List
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              itemCount: _filtered.length + 1, // +1 for "No optician" row
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: palette.border),
              itemBuilder: (_, index) {
                if (index == 0) {
                  // No optician option
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: palette.surfaceMuted,
                      child: Icon(
                        Icons.block_outlined,
                        color: palette.textSecondary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'No optician',
                      style: TextStyle(color: palette.textSecondary),
                    ),
                    subtitle: Text(
                      'Skip optician selection',
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.textSecondary,
                      ),
                    ),
                    onTap: () =>
                        Navigator.of(context).pop(_noOpticianSentinel),
                  );
                }
                final o = _filtered[index - 1];
                final dist = _distanceLabel(o);
                return _OpticianPickerTile(
                  optician: o,
                  distanceLabel: dist,
                  onTap: () => Navigator.of(context).pop(o),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Optician picker tile
// ---------------------------------------------------------------------------

class _OpticianPickerTile extends StatelessWidget {
  const _OpticianPickerTile({
    required this.optician,
    required this.onTap,
    this.distanceLabel,
  });

  final AppOptician optician;
  final VoidCallback onTap;
  final String? distanceLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: palette.secondary,
        child: Icon(
          Icons.store_outlined,
          color: palette.primary,
          size: 20,
        ),
      ),
      title: Text(
        optician.name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
        ),
      ),
      subtitle: Text(
        '${optician.zipCode} ${optician.city}',
        style: TextStyle(fontSize: 13, color: palette.textSecondary),
      ),
      trailing: distanceLabel != null
          ? Text(
              distanceLabel!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: palette.primary,
              ),
            )
          : Icon(Icons.chevron_right_rounded, color: palette.iconMuted),
      onTap: onTap,
    );
  }
}

// ---------------------------------------------------------------------------
// QR scanner screen
// ---------------------------------------------------------------------------

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
