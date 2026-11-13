import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/avatar_routes.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../household/model/household_view.dart';
import '../data/avatar_repository.dart';

class AvatarShopSwitch extends StatefulWidget {
  const AvatarShopSwitch({super.key});

  @override
  State<AvatarShopSwitch> createState() => _AvatarShopSwitchState();
}

class _AvatarShopSwitchState extends State<AvatarShopSwitch> {
  bool? _pending;
  AppFailure? _failure;

  Future<void> _set(String householdId, bool isOpen) async {
    final avatars = context.read<AvatarRepository>();
    setState(() {
      _pending = isOpen;
      _failure = null;
    });
    try {
      await avatars.setShop(householdId: householdId, isOpen: isOpen);
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _pending = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = context.watch<HouseholdView>();
    if (!AvatarRoute.isOn(context.watch<FeatureFlagsController?>()) ||
        !view.permissions.isFamily) {
      return const SizedBox.shrink();
    }
    final nest = NestTheme.of(context);
    final household = view.household;
    final isOpen = _pending ?? household.avatarShop;
    final failure = _failure;
    return Padding(
      padding: const EdgeInsets.only(top: NestSpace.xl),
      child: NestCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NestListRow(
              title: AvatarCopy.shopSwitchTitle,
              subtitle: AvatarCopy.shopSwitchBody,
              leading: const NestIconTile(
                icon: LucideIcons.shirt,
                tint: NestTileTint.guava,
                size: NestSize.avatarMedium,
              ),
              trailing: Semantics(
                label: AvatarCopy.shopSwitchTitle,
                child: Switch(
                  value: isOpen,
                  onChanged: _pending == null
                      ? (value) => _set(household.id, value)
                      : null,
                ),
              ),
              onTap: _pending == null
                  ? () => _set(household.id, !isOpen)
                  : null,
            ),
            if (failure != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  NestSpace.lg,
                  0,
                  NestSpace.lg,
                  NestSpace.md,
                ),
                child: Text(
                  AppCopy.failure(failure),
                  style: nest.text.caption.copyWith(color: nest.colors.danger),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
