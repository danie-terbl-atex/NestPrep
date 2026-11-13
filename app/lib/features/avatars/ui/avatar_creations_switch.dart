import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/avatar_routes.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../household/model/household_view.dart';
import '../data/avatar_repository.dart';

class AvatarCreationsSwitch extends StatefulWidget {
  const AvatarCreationsSwitch({
    this.padding = const EdgeInsets.only(top: NestSpace.xl),
    super.key,
  });

  final EdgeInsetsGeometry padding;

  @override
  State<AvatarCreationsSwitch> createState() => _AvatarCreationsSwitchState();
}

class _AvatarCreationsSwitchState extends State<AvatarCreationsSwitch> {
  bool? _pending;
  AppFailure? _failure;

  Future<void> _set(String householdId, bool isOn) async {
    final avatars = context.read<AvatarRepository>();
    setState(() {
      _pending = isOn;
      _failure = null;
    });
    try {
      await avatars.setCreations(householdId: householdId, isOn: isOn);
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _pending = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = context.watch<HouseholdView?>();
    if (view == null ||
        !AvatarRoute.creationsOn(context.watch<FeatureFlagsController?>()) ||
        !view.permissions.isFamily) {
      return const SizedBox.shrink();
    }
    final nest = NestTheme.of(context);
    final household = view.household;
    final isOn = _pending ?? household.avatarCreationsOn;
    final failure = _failure;
    return Padding(
      padding: widget.padding,
      child: NestCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NestListRow(
              title: AvatarCreationCopy.switchTitle,
              subtitle: AvatarCreationCopy.switchBody,
              leading: const NestIconTile(
                icon: LucideIcons.wandSparkles,
                tint: NestTileTint.lilac,
                size: NestSize.avatarMedium,
              ),
              trailing: Semantics(
                label: AvatarCreationCopy.switchTitle,
                child: Switch(
                  value: isOn,
                  onChanged: _pending == null
                      ? (value) => _set(household.id, value)
                      : null,
                ),
              ),
              onTap: _pending == null ? () => _set(household.id, !isOn) : null,
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
