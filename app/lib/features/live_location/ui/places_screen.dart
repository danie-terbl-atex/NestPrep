import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/household_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/ui/premium_gate.dart';
import '../../subscriptions/ui/premium_mark.dart';
import '../model/family_place.dart';
import '../state/places_controller.dart';
import 'place_look.dart';

/// The household's places, and the way to add one (live-location ADR-0006).
class PlacesScreen extends StatelessWidget {
  const PlacesScreen({super.key});

  static const routeName = 'location-places';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlacesController>();
    final canEdit = context.watch<HouseholdView>().permissions.canEdit(
      HouseholdArea.location,
    );
    return NestScaffold(
      title: LocationCopy.places,
      subtitle: LocationCopy.placesBody,
      leading: context.canPop()
          ? NestIconButton(
              icon: LucideIcons.arrowLeft,
              label: AppCopy.back,
              variant: NestIconButtonVariant.plain,
              onPressed: context.pop,
            )
          : null,
      body: NestAsyncView<List<FamilyPlace>>(
        state: controller.view,
        isEmpty: (_) => false,
        onRetry: controller.retry,
        emptyBuilder: (_) => const SizedBox.shrink(),
        dataBuilder: (context, places) => ListView(
          padding: const EdgeInsets.only(bottom: NestSpace.huge),
          children: [
            if (places.isEmpty)
              const NestEmptyView(
                title: LocationCopy.noPlacesTitle,
                message: LocationCopy.noPlacesBody,
                icon: LucideIcons.mapPinned,
              ),
            for (final place in places)
              Padding(
                padding: const EdgeInsets.only(bottom: NestSpace.sm),
                child: NestListRow(
                  key: ValueKey(place.id),
                  leading: NestIconTile(
                    icon: PlaceLook.icon(place.icon),
                    tint: NestTileTint.lilac,
                  ),
                  title: place.name,
                  subtitle: LocationCopy.radius(place.radiusMetres),
                  onTap: canEdit ? () => _open(context, place.id) : null,
                ),
              ),
            if (canEdit) ...[
              const SizedBox(height: NestSpace.lg),
              if (controller.isFull)
                Text(
                  LocationCopy.placesFull,
                  style: NestTheme.of(context).text.caption,
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: NestButton(
                        label: LocationCopy.addPlace,
                        icon: LucideIcons.plus,
                        onPressed: () =>
                            _open(context, HouseholdRoute.newPlaceId),
                      ),
                    ),
                    const SizedBox(width: NestSpace.sm),
                    const PremiumMark(),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, String placeId) async {
    if (placeId == HouseholdRoute.newPlaceId &&
        !await ensurePremium(context, feature: PremiumFeature.familyLocation)) {
      return;
    }
    if (!context.mounted) return;
    await context.push(
      HouseholdRoute.placePathFor(
        context.read<PlacesController>().householdId,
        placeId,
      ),
    );
  }
}
