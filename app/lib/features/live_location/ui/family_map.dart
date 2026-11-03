import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/log/best_effort.dart';
import '../model/coordinates.dart';
import '../model/family_place.dart';
import '../model/located_member.dart';
import 'map_style.dart';
import 'member_marker_icons.dart';

LatLng latLngOf(Coordinates at) => LatLng(at.latitude, at.longitude);

/// The family on a map: a pin per person sharing, a circle per place, and
/// optionally one day's path (live-location ADR-0007).
class FamilyMap extends StatefulWidget {
  const FamilyMap({
    required this.members,
    required this.places,
    this.path = const [],
    this.onMemberTap,
    this.focus,
    super.key,
  });

  final List<LocatedMember> members;
  final List<FamilyPlace> places;
  final List<Coordinates> path;
  final ValueChanged<LocatedMember>? onMemberTap;

  /// Where to centre, when it is not everybody.
  final Coordinates? focus;

  @override
  State<FamilyMap> createState() => _FamilyMapState();
}

class _FamilyMapState extends State<FamilyMap> {
  final _icons = MemberMarkerIcons();
  final _controller = Completer<GoogleMapController>();
  Set<Marker> _markers = const {};
  bool _framed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(_buildMarkers());
  }

  @override
  void didUpdateWidget(FamilyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    unawaited(_buildMarkers());
    if (oldWidget.focus != widget.focus ||
        oldWidget.path.length != widget.path.length) {
      _framed = false;
      unawaited(_frame());
    }
  }

  Future<void> _buildMarkers() => bestEffort(
    'family map markers',
    code: 'map-markers-failed',
    run: _drawMarkers,
  );

  Future<void> _drawMarkers() async {
    final theme = NestTheme.of(context);
    final markers = <Marker>{};
    for (final located in widget.members) {
      final at = located.at;
      if (at == null) continue;
      final icon = await _icons.of(
        name: located.member.displayName,
        color: located.member.color,
        theme: theme,
      );
      markers.add(
        Marker(
          markerId: MarkerId(located.member.id),
          position: latLngOf(at),
          icon: icon,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(title: located.member.displayName),
          onTap: () => widget.onMemberTap?.call(located),
        ),
      );
    }
    if (!mounted) return;
    setState(() => _markers = markers);
    unawaited(_frame());
  }

  Future<void> _frame() => bestEffort(
    'family map framing',
    code: 'map-frame-failed',
    run: _moveCamera,
  );

  Future<void> _moveCamera() async {
    if (_framed || !_controller.isCompleted) return;
    final points = [
      ?widget.focus,
      if (widget.focus == null) ...[
        ...widget.path,
        for (final located in widget.members) ?located.at,
      ],
    ];
    if (points.isEmpty) return;
    _framed = true;
    final map = await _controller.future;
    if (points.length == 1) {
      await map.animateCamera(
        CameraUpdate.newLatLngZoom(latLngOf(points.single), 15),
      );
      return;
    }
    await map.animateCamera(
      CameraUpdate.newLatLngBounds(_boundsOf(points), NestSpace.huge),
    );
  }

  static LatLngBounds _boundsOf(List<Coordinates> points) {
    var south = points.first.latitude;
    var north = south;
    var west = points.first.longitude;
    var east = west;
    for (final point in points) {
      if (point.latitude < south) south = point.latitude;
      if (point.latitude > north) north = point.latitude;
      if (point.longitude < west) west = point.longitude;
      if (point.longitude > east) east = point.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final start = widget.focus ?? widget.members.firstOrNull?.at;
    return Semantics(
      label: LocationCopy.mapLabel(widget.members.length),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: start == null ? const LatLng(-26.2, 28.05) : latLngOf(start),
          zoom: start == null ? 5 : 14,
        ),
        style: MapStyle.of(nest.colors),
        markers: _markers,
        circles: {
          for (final place in widget.places)
            Circle(
              circleId: CircleId(place.id),
              center: latLngOf(place.centre),
              radius: place.radiusMetres.toDouble(),
              strokeWidth: 2,
              strokeColor: nest.colors.accent,
              fillColor: nest.colors.accent.withValues(alpha: 0.12),
            ),
        },
        polylines: {
          if (widget.path.length > 1)
            Polyline(
              polylineId: const PolylineId('day'),
              points: [for (final point in widget.path) latLngOf(point)],
              color: nest.colors.accent,
              width: 4,
            ),
        },
        myLocationButtonEnabled: false,
        mapToolbarEnabled: false,
        zoomControlsEnabled: false,
        onMapCreated: (map) {
          if (!_controller.isCompleted) _controller.complete(map);
          unawaited(_frame());
        },
      ),
    );
  }
}
