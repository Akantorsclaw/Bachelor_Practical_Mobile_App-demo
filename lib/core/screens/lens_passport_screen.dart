import 'package:flutter/material.dart';

import '../../branding/brand_context.dart';
import '../../models/lens_item.dart';
import '../../services/lens_parameter_info_service.dart';
import '../../shared/app_widgets.dart';

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
