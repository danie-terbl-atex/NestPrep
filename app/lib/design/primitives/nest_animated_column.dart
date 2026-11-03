import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../tokens/nest_motion.dart';

class NestAnimatedColumn<T> extends StatefulWidget {
  const NestAnimatedColumn({
    required this.items,
    required this.keyOf,
    required this.itemBuilder,
    super.key,
  });

  final List<T> items;
  final String Function(T item) keyOf;
  final Widget Function(BuildContext context, T item) itemBuilder;

  @override
  State<NestAnimatedColumn<T>> createState() => _NestAnimatedColumnState<T>();
}

class _Entry<T> {
  _Entry(this.key, this.item, this.controller)
    : curve = CurvedAnimation(
        parent: controller,
        curve: NestMotion.standardCurve,
      );

  final String key;
  T item;
  final AnimationController controller;
  final Animation<double> curve;
  bool isLeaving = false;
}

class _NestAnimatedColumnState<T> extends State<NestAnimatedColumn<T>>
    with TickerProviderStateMixin {
  late List<_Entry<T>> _entries = [
    for (final item in widget.items) _entry(item, value: 1),
  ];

  _Entry<T> _entry(T item, {required double value}) => _Entry(
    widget.keyOf(item),
    item,
    AnimationController(vsync: this, value: value),
  );

  @override
  void didUpdateWidget(NestAnimatedColumn<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final duration = NestMotion.of(context).standard;
    final animates = duration > Duration.zero;
    final byKey = {for (final entry in _entries) entry.key: entry};
    final present = <String>{};
    final next = <_Entry<T>>[];
    for (final item in widget.items) {
      final key = widget.keyOf(item);
      present.add(key);
      final existing = byKey[key];
      if (existing == null) {
        final arriving = _entry(item, value: animates ? 0 : 1);
        arriving.controller
          ..duration = duration
          ..forward();
        next.add(arriving);
        continue;
      }
      existing.item = item;
      if (existing.isLeaving) {
        existing.isLeaving = false;
        existing.controller.forward();
      }
      next.add(existing);
    }
    for (final (index, entry) in _entries.indexed) {
      if (present.contains(entry.key)) continue;
      if (!animates) {
        entry.controller.dispose();
        continue;
      }
      if (!entry.isLeaving) {
        entry.isLeaving = true;
        entry.controller.duration = duration;
        entry.controller.reverse().then((_) {
          if (entry.isLeaving) _drop(entry);
        });
      }
      next.insert(math.min(index, next.length), entry);
    }
    _entries = next;
  }

  void _drop(_Entry<T> entry) {
    if (!mounted) return;
    setState(() => _entries.remove(entry));
    entry.controller.dispose();
  }

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final entry in _entries)
        KeyedSubtree(
          key: ValueKey(entry.key),
          child: IgnorePointer(
            ignoring: entry.isLeaving,
            child: SizeTransition(
              sizeFactor: entry.curve,
              alignment: Alignment.topCenter,
              child: FadeTransition(
                opacity: entry.curve,
                child: widget.itemBuilder(context, entry.item),
              ),
            ),
          ),
        ),
    ],
  );
}
