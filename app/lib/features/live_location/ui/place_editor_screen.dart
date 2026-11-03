import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/log/best_effort.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/ui/premium_gate.dart';
import '../model/coordinates.dart';
import '../model/family_place.dart';
import '../state/place_editor_controller.dart';
import 'family_map.dart';
import 'map_style.dart';
import 'maps_enabled.dart';
import 'place_look.dart';

class PlaceEditorScreen extends StatefulWidget {
  const PlaceEditorScreen({this.showMap = mapsEnabled, super.key});

  static const routeName = 'location-place';

  final bool showMap;

  @override
  State<PlaceEditorScreen> createState() => _PlaceEditorScreenState();
}

class _PlaceEditorScreenState extends State<PlaceEditorScreen> {
  late final _name = TextEditingController(
    text: context.read<PlaceEditorController>().draft.name,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlaceEditorController>();
    final nest = NestTheme.of(context);
    final draft = controller.draft;
    final failure = controller.actionFailure;
    return NestScaffold(
      title: controller.isNew ? LocationCopy.addPlace : LocationCopy.editPlace,
      leading: context.canPop()
          ? NestIconButton(
              icon: LucideIcons.arrowLeft,
              label: AppCopy.back,
              variant: NestIconButtonVariant.plain,
              onPressed: context.pop,
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.only(bottom: NestSpace.huge),
        children: [
          if (failure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.md),
              child: NestBanner(
                message: AppCopy.failure(failure),
                tone: NestBannerTone.danger,
                actionLabel: AppCopy.back,
                onAction: controller.dismissActionFailure,
              ),
            ),
          if (widget.showMap) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(NestRadius.lg),
              child: SizedBox(
                height: 260,
                child: _PinMap(controller: controller),
              ),
            ),
            const SizedBox(height: NestSpace.xs),
            Text(LocationCopy.dragToPlace, style: nest.text.caption),
            const SizedBox(height: NestSpace.md),
          ],
          NestButton(
            label: LocationCopy.useWhereIAm,
            variant: NestButtonVariant.outline,
            icon: LucideIcons.locateFixed,
            onPressed: controller.useWhereIAm,
          ),
          if (!controller.hasCentre) ...[
            const SizedBox(height: NestSpace.xs),
            Text(LocationCopy.noCentreYet, style: nest.text.caption),
          ],
          const SizedBox(height: NestSpace.lg),
          NestTextField(
            label: LocationCopy.placeName,
            hint: LocationCopy.placeNameHint,
            controller: _name,
            onChanged: controller.rename,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              LengthLimitingTextInputFormatter(FamilyPlace.longestName),
            ],
          ),
          const SizedBox(height: NestSpace.lg),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              for (final icon in PlaceIcon.values)
                NestChip(
                  label: LocationCopy.icon(icon),
                  icon: PlaceLook.icon(icon),
                  isSelected: draft.icon == icon,
                  onTap: () => controller.chooseIcon(icon),
                ),
            ],
          ),
          const SizedBox(height: NestSpace.lg),
          Text(LocationCopy.radius(draft.radiusMetres), style: nest.text.label),
          Slider(
            value: draft.radiusMetres.toDouble(),
            min: FamilyPlace.smallestRadius.toDouble(),
            max: FamilyPlace.largestRadius.toDouble(),
            divisions: 17,
            label: LocationCopy.radius(draft.radiusMetres),
            semanticFormatterCallback: (value) =>
                LocationCopy.radius(value.round()),
            onChanged: (value) => controller.resize(value.round()),
          ),
          NestCheckRow(
            label: LocationCopy.alertArrive,
            value: draft.alertOnArrive,
            onChanged: (on) => controller.alertOnArrive(on: on),
          ),
          NestCheckRow(
            label: LocationCopy.alertLeave,
            value: draft.alertOnLeave,
            onChanged: (on) => controller.alertOnLeave(on: on),
          ),
          const SizedBox(height: NestSpace.xl),
          NestButton(
            label: LocationCopy.save,
            isLoading: controller.saving,
            onPressed: controller.canSave ? () => _save(context) : null,
          ),
          if (!controller.isNew) ...[
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: LocationCopy.deletePlace,
              variant: NestButtonVariant.danger,
              icon: LucideIcons.trash2,
              onPressed: () => _delete(context),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final controller = context.read<PlaceEditorController>();
    if (!await ensurePremium(context, feature: PremiumFeature.familyLocation)) {
      return;
    }
    if (await controller.save() && context.mounted && context.canPop()) {
      context.pop();
    }
  }

  Future<void> _delete(BuildContext context) async {
    final controller = context.read<PlaceEditorController>();
    final sure = await showNestConfirm(
      context: context,
      title: LocationCopy.deletePlace,
      confirmLabel: LocationCopy.deletePlace,
      cancelLabel: LocationCopy.cancel,
    );
    if (sure != true) return;
    if (await controller.delete() && context.mounted && context.canPop()) {
      context.pop();
    }
  }
}

/// The pin stays in the middle; the map moves under it. "Use where I am"
/// moves the map too, so the next pan starts from there.
class _PinMap extends StatefulWidget {
  const _PinMap({required this.controller});

  final PlaceEditorController controller;

  @override
  State<_PinMap> createState() => _PinMapState();
}

class _PinMapState extends State<_PinMap> {
  GoogleMapController? _map;
  int _seenJumps = 0;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = widget.controller;
    final draft = controller.draft;
    final centre = controller.hasCentre ? draft.centre : null;
    if (controller.jumps != _seenJumps && centre != null) {
      _seenJumps = controller.jumps;
      unawaited(
        bestEffort(
          'place editor camera',
          code: 'place-camera-failed',
          run: () async => _map?.animateCamera(
            CameraUpdate.newLatLngZoom(latLngOf(centre), 16),
          ),
        ),
      );
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: centre == null
                ? const LatLng(-26.2, 28.05)
                : latLngOf(centre),
            zoom: centre == null ? 5 : 16,
          ),
          style: MapStyle.of(nest.colors),
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          onMapCreated: (map) => _map = map,
          circles: {
            if (centre != null)
              Circle(
                circleId: const CircleId('place'),
                center: latLngOf(centre),
                radius: draft.radiusMetres.toDouble(),
                strokeWidth: 2,
                strokeColor: nest.colors.accent,
                fillColor: nest.colors.accent.withValues(alpha: 0.12),
              ),
          },
          onCameraMove: (camera) => controller.moveTo(
            Coordinates(
              latitude: camera.target.latitude,
              longitude: camera.target.longitude,
            ),
          ),
        ),
        IgnorePointer(
          child: Icon(LucideIcons.mapPin, size: 40, color: nest.colors.accent),
        ),
      ],
    );
  }
}
