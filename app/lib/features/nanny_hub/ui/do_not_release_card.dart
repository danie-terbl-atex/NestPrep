import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/emergency_contact.dart';

/// How much the do-not-release block says. `full` stands alone, when nobody
/// may collect the child; `pinned` sits under the list of people, always on
/// screen, saying only the rule and the calls.
enum DoNotReleaseSize { full, pinned }

/// The one thing a carer must never get wrong at the door, in the danger
/// tone: somebody not on the list does not leave with the child. It says so
/// in words, with a stop icon, not only in red (`FE-13`), and puts a parent
/// one tap away.
class DoNotReleaseCard extends StatelessWidget {
  const DoNotReleaseCard({
    required this.childName,
    required this.size,
    required this.parents,
    required this.onCall,
    required this.onOpenEmergency,
    super.key,
  });

  final String childName;
  final DoNotReleaseSize size;

  /// The parents on the emergency sheet.
  final List<EmergencyContact> parents;
  final ValueChanged<EmergencyContact> onCall;
  final VoidCallback onOpenEmergency;

  bool get _isFull => size == DoNotReleaseSize.full;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final buttonSize = _isFull ? NestButtonSize.large : NestButtonSize.medium;
    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.dangerSoft,
          borderRadius: BorderRadius.circular(NestRadius.xl),
        ),
        child: Padding(
          padding: EdgeInsets.all(_isFull ? NestSpace.xl : NestSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.hand,
                    color: c.danger,
                    size: _isFull ? NestSize.iconMark : NestSize.iconLarge,
                  ),
                  const SizedBox(width: NestSpace.md),
                  Expanded(
                    child: Text(
                      _isFull
                          ? NannyPickupCopy.nobodyAllowedTitle(childName)
                          : NannyPickupCopy.notOnListTitle(childName),
                      style: (_isFull ? nest.text.headline : nest.text.title)
                          .copyWith(color: c.danger),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: NestSpace.xs),
              Text(
                _isFull
                    ? NannyPickupCopy.nobodyAllowedBody(childName)
                    : NannyPickupCopy.notOnListBody(childName),
                style: nest.text.body.copyWith(color: c.ink),
              ),
              const SizedBox(height: NestSpace.md),
              if (parents.isEmpty) ...[
                Text(
                  NannyPickupCopy.noParentNumber,
                  style: nest.text.bodySecondary,
                ),
                const SizedBox(height: NestSpace.sm),
                NestButton(
                  label: NannyPickupCopy.openEmergency,
                  icon: LucideIcons.siren,
                  variant: NestButtonVariant.danger,
                  size: buttonSize,
                  onPressed: onOpenEmergency,
                ),
              ],
              Wrap(
                spacing: NestSpace.sm,
                runSpacing: NestSpace.sm,
                children: [
                  for (final parent in parents)
                    NestButton(
                      key: ValueKey(parent.id),
                      label: NannyPickupCopy.callParent(parent.name),
                      icon: LucideIcons.phoneCall,
                      variant: NestButtonVariant.danger,
                      size: buttonSize,
                      isExpanded: _isFull,
                      onPressed: () => onCall(parent),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
