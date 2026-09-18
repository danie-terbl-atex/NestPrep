import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/household.dart';

/// What the household settings sheet came back with.
class HouseholdSettings {
  const HouseholdSettings({required this.name, required this.timeZone});

  final String name;
  final String timeZone;
}

/// The household's own name and the zone its days are counted in.
///
/// The zone is not cosmetic: every due date, every all-day event and every
/// occurrence key is a day in *this* zone (`ENG-21`, foundation ADR-0007), so a
/// household that moves country changes it here and the whole week moves with
/// it. It is typed rather than picked from a list because the server checks the
/// shape and not the membership, so a zone added to tzdata later still works
/// without a redeploy.
Future<HouseholdSettings?> showHouseholdSettingsSheet({
  required BuildContext context,
  required Household household,
}) => showNestSheet<HouseholdSettings>(
  context: context,
  title: AppCopy.householdEditHousehold,
  builder: (sheetContext) => _SettingsBody(household: household),
);

class _SettingsBody extends StatefulWidget {
  const _SettingsBody({required this.household});

  final Household household;

  @override
  State<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<_SettingsBody> {
  late final _name = TextEditingController(text: widget.household.name);
  late final _zone = TextEditingController(text: widget.household.timeZone);

  @override
  void dispose() {
    _name.dispose();
    _zone.dispose();
    super.dispose();
  }

  bool get _changed =>
      _name.text.trim() != widget.household.name ||
      _zone.text.trim() != widget.household.timeZone;

  @override
  Widget build(BuildContext context) {
    final canSave =
        _name.text.trim().isNotEmpty &&
        _zone.text.trim().isNotEmpty &&
        _changed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        NestTextField(
          label: AppCopy.householdNameLabel,
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: NestSpace.xl),
        NestTextField(
          label: AppCopy.householdTimeZoneLabel,
          controller: _zone,
          helperText: AppCopy.householdTimeZoneHint,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: NestSpace.xxl),
        NestButton(
          label: AppCopy.householdSave,
          onPressed: canSave
              ? () => Navigator.of(context).pop(
                  HouseholdSettings(
                    name: _name.text.trim(),
                    timeZone: _zone.text.trim(),
                  ),
                )
              : null,
        ),
      ],
    );
  }
}
