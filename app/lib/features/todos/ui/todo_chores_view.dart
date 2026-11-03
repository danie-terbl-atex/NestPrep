import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../household/model/household_view.dart';
import '../../household/model/member.dart';
import '../model/kid_chores.dart';
import '../model/task_occurrence.dart';
import '../model/todo_board.dart';
import 'chore_celebration.dart';
import 'task_occurrence_row.dart';

class TodoChoresView extends StatelessWidget {
  const TodoChoresView({
    required this.board,
    required this.onCompleted,
    super.key,
  });

  final TodoBoard board;
  final ValueChanged<TaskOccurrence> onCompleted;

  @override
  Widget build(BuildContext context) {
    final view = context.read<HouseholdView>();
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSize.bottomBarHeight * 2),
      children: [
        for (final section in board.chores)
          if (view.memberById(section.kidId) case final kid?)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.xxl),
              child: _KidSection(
                kid: kid,
                section: section,
                board: board,
                onCompleted: (chore) {
                  onCompleted(chore);
                  celebrateChore(
                    context,
                    kidName: kid.displayName,
                    chore: chore,
                    finishesTheDay: section.isLastOpen(chore),
                  );
                },
              ),
            ),
      ],
    );
  }
}

class _KidSection extends StatelessWidget {
  const _KidSection({
    required this.kid,
    required this.section,
    required this.board,
    required this.onCompleted,
  });

  final Member kid;
  final KidChores section;
  final TodoBoard board;
  final ValueChanged<TaskOccurrence> onCompleted;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _KidHeader(kid: kid, section: section),
      const SizedBox(height: NestSpace.sm),
      if (section.chores.isEmpty)
        const _NoChores()
      else
        for (final chore in section.chores)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: TaskOccurrenceRow(
              key: ValueKey('${kid.id}:${chore.key}'),
              rowId: '${kid.id}:${chore.key}',
              occurrence: chore,
              today: board.today,
              creditTo: kid,
              onCompleted: onCompleted,
            ),
          ),
    ],
  );
}

class _KidHeader extends StatelessWidget {
  const _KidHeader({required this.kid, required this.section});

  final Member kid;
  final KidChores section;

  static const _tint = 0.3;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final swatch = nest.members.of(kid.color);
    final total = section.chores.length;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.lerp(c.canvas, swatch.fill, _tint),
        borderRadius: BorderRadius.circular(NestRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(NestSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                NestAvatar(
                  name: kid.displayName,
                  color: kid.color,
                  size: NestSize.avatarLarge,
                ),
                const SizedBox(width: NestSpace.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(kid.displayName, style: nest.text.title),
                      Text(
                        total == 0
                            ? AppCopy.todosNoChores
                            : AppCopy.todosChoresProgress(
                                section.doneCount,
                                total,
                              ),
                        style: nest.text.label.copyWith(color: c.inkSecondary),
                      ),
                    ],
                  ),
                ),
                if (section.carriesStars) ...[
                  const SizedBox(width: NestSpace.sm),
                  NestTag(
                    label: AppCopy.todosStarsToday(section.starsToday),
                    tone: NestTagTone.warning,
                    icon: LucideIcons.star,
                  ),
                ],
              ],
            ),
            if (total > 0) ...[
              const SizedBox(height: NestSpace.md),
              _Progress(
                fraction: section.doneCount / total,
                color: swatch.fill,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  static const _height = 10.0;

  @override
  Widget build(BuildContext context) {
    final c = NestTheme.of(context).colors;
    final radius = BorderRadius.circular(NestRadius.pill);
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: radius,
        child: ColoredBox(
          color: c.surface,
          child: SizedBox(
            height: _height,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: AnimatedFractionallySizedBox(
                duration: NestMotion.of(context).slow,
                curve: NestMotion.emphasized,
                widthFactor: fraction,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: color, borderRadius: radius),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoChores extends StatelessWidget {
  const _NoChores();

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return NestCard(
      variant: NestCardVariant.flat,
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Row(
        children: [
          Icon(
            LucideIcons.sun,
            size: NestSize.iconMedium,
            color: nest.colors.inkSecondary,
          ),
          const SizedBox(width: NestSpace.md),
          Expanded(
            child: Text(
              AppCopy.todosNoChoresBody,
              style: nest.text.bodySecondary,
            ),
          ),
        ],
      ),
    );
  }
}
