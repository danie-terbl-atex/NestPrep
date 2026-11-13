import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/avatar_creation_copy.dart';
import '../model/avatar_buddy.dart';
import '../model/avatar_catalogue.g.dart';
import '../model/avatar_creation.dart';
import '../state/avatar_creation_controller.dart';
import 'buddy_sentence_card.dart';
import 'creation_disclosure.dart';
import 'creation_style_picker.dart';

class BuddyComposer extends StatefulWidget {
  const BuddyComposer({
    required this.onMake,
    required this.onBack,
    this.random,
    super.key,
  });

  final Future<void> Function(
    AvatarBuddy buddy,
    CreationStyle style,
    String extra,
  )
  onMake;
  final VoidCallback onBack;
  final math.Random? random;

  @override
  State<BuddyComposer> createState() => _BuddyComposerState();
}

class _BuddyComposerState extends State<BuddyComposer> {
  AvatarBuddy _buddy = const AvatarBuddy();
  CreationStyle _style = CreationStyle.plush;
  final _extra = TextEditingController();
  bool _isWorking = false;
  late final math.Random _random = widget.random ?? math.Random();

  @override
  void dispose() {
    _extra.dispose();
    super.dispose();
  }

  void _surprise() => setState(
    () => _buddy = AvatarBuddy({
      for (final kind in AvatarBuddyKind.values)
        if (avatarBuddy[kind] case final words? when words.isNotEmpty)
          kind: words[_random.nextInt(words.length)].id,
    }),
  );

  Future<void> _make() async {
    setState(() => _isWorking = true);
    try {
      await widget.onMake(_buddy, _style, _extra.text);
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: NestButton(
            label: AvatarCreationCopy.pickSomethingElse,
            icon: LucideIcons.arrowLeft,
            variant: NestButtonVariant.ghost,
            size: NestButtonSize.small,
            isExpanded: false,
            onPressed: _isWorking ? null : widget.onBack,
          ),
        ),
        const SizedBox(height: NestSpace.sm),
        Text(
          AvatarCreationCopy.recipeTitle(CreationRecipe.buddy),
          style: nest.text.title,
        ),
        const SizedBox(height: NestSpace.md),
        BuddySentenceCard(buddy: _buddy),
        const SizedBox(height: NestSpace.sm),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: NestButton(
            label: AvatarCreationCopy.surpriseMe,
            icon: LucideIcons.dices,
            variant: NestButtonVariant.tonal,
            size: NestButtonSize.small,
            isExpanded: false,
            onPressed: _isWorking ? null : _surprise,
          ),
        ),
        for (final kind in AvatarBuddyKind.values) ...[
          const SizedBox(height: NestSpace.xl),
          NestSectionHeader(title: AvatarCreationCopy.buddyQuestion(kind)),
          const SizedBox(height: NestSpace.sm),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              for (final word
                  in avatarBuddy[kind] ?? const <AvatarChoiceWord>[])
                NestChip(
                  key: ValueKey('buddy-${kind.name}-${word.id}'),
                  label: word.label,
                  isSelected: _buddy.picks[kind] == word.id,
                  onTap: _isWorking
                      ? null
                      : () => setState(
                          () => _buddy = _buddy.picking(kind, word.id),
                        ),
                ),
            ],
          ),
        ],
        const SizedBox(height: NestSpace.xl),
        CreationStylePicker(
          selected: _style,
          onPick: (style) => setState(() => _style = style),
        ),
        const SizedBox(height: NestSpace.xl),
        NestTextField(
          label: AvatarCreationCopy.oneMoreThing,
          hint: AvatarCreationCopy.oneMoreThingHint,
          controller: _extra,
          enabled: !_isWorking,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            LengthLimitingTextInputFormatter(
              AvatarCreationController.extraLength,
            ),
          ],
        ),
        const SizedBox(height: NestSpace.lg),
        const CreationDisclosure(message: AvatarCreationCopy.wordsDisclosure),
        const SizedBox(height: NestSpace.lg),
        NestButton(
          label: AvatarCreationCopy.hatchBuddy,
          icon: LucideIcons.egg,
          isLoading: _isWorking,
          onPressed: _buddy.isComplete && !_isWorking ? _make : null,
        ),
      ],
    );
  }
}
