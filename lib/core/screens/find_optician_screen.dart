import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../branding/brand_context.dart';
import '../../models/app_optician.dart';
import '../../services/optician_service.dart';
import '../../shared/app_widgets.dart';

class FindOpticianScreen extends StatefulWidget {
  const FindOpticianScreen({
    super.key,
    required this.opticians,
    required this.onTabSelected,
  });

  final List<AppOptician> opticians;
  final void Function(int) onTabSelected;

  @override
  State<FindOpticianScreen> createState() => _FindOpticianScreenState();
}

class _FindOpticianScreenState extends State<FindOpticianScreen> {
  final _searchController = TextEditingController();
  final _mapController = MapController();

  bool _showMap = false;
  bool _nearMe = false;
  double? _userLat;
  double? _userLng;
  List<AppOptician> _filtered = [];

  // Germany centre — fallback when no GPS
  static const _defaultCenter = LatLng(51.1657, 10.4515);
  static const _defaultZoom = 6.0;
  static const _nearMeZoom = 11.0;

  @override
  void initState() {
    super.initState();
    _filtered = widget.opticians;
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ── Filtering ──────────────────────────────────────────────────────────────

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

  // ── Location ───────────────────────────────────────────────────────────────

  Future<void> _toggleNearMe() async {
    if (_nearMe) {
      setState(() {
        _nearMe = false;
        _applyFilters();
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission is required for Near Me.'),
        ),
      );
      return;
    }

    try {
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
      if (_showMap) {
        _mapController.move(LatLng(pos.latitude, pos.longitude), _nearMeZoom);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not determine your location.')),
      );
    }
  }

  // ── Bottom sheet ───────────────────────────────────────────────────────────

  void _showOpticianSheet(AppOptician optician) {
    final palette = context.brandPalette;
    final distanceText = (_userLat != null && _userLng != null)
        ? _formatDistance(
            OpticianService.distanceKm(optician, _userLat!, _userLng!),
          )
        : null;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _OpticianSheet(
        optician: optician,
        distanceText: distanceText,
        palette: palette,
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatDistance(double km) {
    if (km == double.infinity) return '';
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Scaffold(
      backgroundColor: palette.surface,
      appBar: TopBackAppBar(title: 'Find Optician'),
      body: Column(
        children: [
          _buildSearchRow(palette),
          _buildToggleRow(palette),
          Expanded(
            child: _showMap ? _buildMap(palette) : _buildList(palette),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchRow(dynamic palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, city or postcode…',
                hintStyle:
                    TextStyle(color: palette.onSurface.withOpacity(0.4)),
                prefixIcon: Icon(Icons.search,
                    color: palette.onSurface.withOpacity(0.5)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
                filled: true,
                fillColor: palette.secondary.withOpacity(0.12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _NearMeButton(
            active: _nearMe,
            palette: palette,
            onTap: _toggleNearMe,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(dynamic palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          Text(
            '${_filtered.length} opticians',
            style: TextStyle(
              fontSize: 13,
              color: palette.onSurface.withOpacity(0.55),
            ),
          ),
          const Spacer(),
          _ViewToggle(
            showMap: _showMap,
            palette: palette,
            onToggle: (v) => setState(() => _showMap = v),
          ),
        ],
      ),
    );
  }

  Widget _buildList(dynamic palette) {
    if (_filtered.isEmpty) {
      return Center(
        child: Text(
          'No opticians found.',
          style: TextStyle(color: palette.onSurface.withOpacity(0.5)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: _filtered.length,
      itemBuilder: (_, i) {
        final o = _filtered[i];
        return _OpticianCard(
          optician: o,
          distanceText: (_userLat != null && _userLng != null)
              ? _formatDistance(
                  OpticianService.distanceKm(o, _userLat!, _userLng!))
              : null,
          palette: palette,
          onTap: () => _showOpticianSheet(o),
        );
      },
    );
  }

  Widget _buildMap(dynamic palette) {
    final center = (_userLat != null && _userLng != null)
        ? LatLng(_userLat!, _userLng!)
        : _defaultCenter;
    final zoom = _nearMe ? _nearMeZoom : _defaultZoom;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(initialCenter: center, initialZoom: zoom),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.bachelor_practical_mobile_app',
        ),
        MarkerLayer(
          markers: _filtered
              .where((o) => o.location != null)
              .map(
                (o) => Marker(
                  point: LatLng(o.location!.latitude, o.location!.longitude),
                  width: 36,
                  height: 36,
                  child: GestureDetector(
                    onTap: () => _showOpticianSheet(o),
                    child: Icon(
                      Icons.location_pin,
                      color: palette.primary,
                      size: 36,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _NearMeButton extends StatelessWidget {
  const _NearMeButton({
    required this.active,
    required this.palette,
    required this.onTap,
  });

  final bool active;
  final dynamic palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? palette.primary
              : palette.secondary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.my_location,
              size: 16,
              color: active ? palette.onPrimary : palette.onSurface,
            ),
            const SizedBox(width: 4),
            Text(
              'Near me',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: active ? palette.onPrimary : palette.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({
    required this.showMap,
    required this.palette,
    required this.onToggle,
  });

  final bool showMap;
  final dynamic palette;
  final void Function(bool) onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.secondary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _ToggleChip(
            label: 'List',
            icon: Icons.list,
            selected: !showMap,
            palette: palette,
            onTap: () => onToggle(false),
          ),
          _ToggleChip(
            label: 'Map',
            icon: Icons.map_outlined,
            selected: showMap,
            palette: palette,
            onTap: () => onToggle(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final dynamic palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? palette.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 14,
                color: selected ? palette.onPrimary : palette.onSurface),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? palette.onPrimary : palette.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpticianCard extends StatelessWidget {
  const _OpticianCard({
    required this.optician,
    required this.distanceText,
    required this.palette,
    required this.onTap,
  });

  final AppOptician optician;
  final String? distanceText;
  final dynamic palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      color: palette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: palette.onSurface.withOpacity(0.1)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            optician.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: palette.onSurface,
                            ),
                          ),
                        ),
                        if (optician.isPremium)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: palette.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Premium',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: palette.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${optician.zipCode} ${optician.city}',
                      style: TextStyle(
                        fontSize: 13,
                        color: palette.onSurface.withOpacity(0.6),
                      ),
                    ),
                    if (distanceText != null && distanceText!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        distanceText!,
                        style: TextStyle(
                          fontSize: 12,
                          color: palette.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: palette.onSurface.withOpacity(0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpticianSheet extends StatelessWidget {
  const _OpticianSheet({
    required this.optician,
    required this.distanceText,
    required this.palette,
  });

  final AppOptician optician;
  final String? distanceText;
  final dynamic palette;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    optician.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: palette.onSurface,
                    ),
                  ),
                ),
                if (optician.isPremium)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: palette.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Premium',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _SheetRow(
              icon: Icons.location_on_outlined,
              text:
                  '${optician.address}, ${optician.zipCode} ${optician.city}',
              palette: palette,
            ),
            if (distanceText != null && distanceText!.isNotEmpty)
              _SheetRow(
                icon: Icons.near_me_outlined,
                text: distanceText!,
                palette: palette,
                highlight: true,
              ),
            if (optician.phone != null)
              _SheetRow(
                icon: Icons.phone_outlined,
                text: optician.phone!,
                palette: palette,
              ),
            if (optician.openingHours.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Opening hours',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: palette.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              ...optician.openingHours.map(
                (h) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    h,
                    style: TextStyle(
                      fontSize: 13,
                      color: palette.onSurface.withOpacity(0.75),
                    ),
                  ),
                ),
              ),
            ],
            if (optician.campaigns.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: optician.campaigns
                    .map(
                      (c) => Chip(
                        label: Text(
                          c,
                          style: TextStyle(
                              fontSize: 11, color: palette.onSurface),
                        ),
                        backgroundColor:
                            palette.secondary.withOpacity(0.12),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.icon,
    required this.text,
    required this.palette,
    this.highlight = false,
  });

  final IconData icon;
  final String text;
  final dynamic palette;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: highlight
                ? palette.primary
                : palette.onSurface.withOpacity(0.5),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: highlight
                    ? palette.primary
                    : palette.onSurface.withOpacity(0.8),
                fontWeight:
                    highlight ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
