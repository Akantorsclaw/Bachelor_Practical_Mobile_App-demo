import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../branding/brand_context.dart';
import '../../models/lens_item.dart';
import '../../models/lens_passport_data.dart';
import '../../services/lens_pass_qr_parser.dart';
import '../../shared/app_widgets.dart';

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
