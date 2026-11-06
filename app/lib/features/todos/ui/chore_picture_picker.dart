import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/chore_picture_copy.dart';
import '../model/chore_picture.dart';
import '../model/chore_picture_catalogue.dart';
import '../model/chore_picture_match.dart';

/// What the picker came back with: a picture's id, or null for "No picture".
/// Null from `showChorePicturePicker` itself means the sheet was closed.
final class ChorePictureChoice {
  const ChorePictureChoice(this.id);

  final String? id;
}

/// The whole library (todos ADR-0005): a search, what fits [title] first, then
/// every picture by category. Each is a labelled, selectable button; the
/// chosen one is ringed, bold and said to be selected, never shown by colour
/// alone (`FE-13`).
Future<ChorePictureChoice?> showChorePicturePicker({
  required BuildContext context,
  required String title,
  String? selected,
}) => showNestSheet<ChorePictureChoice>(
  context: context,
  title: ChorePictureCopy.pickerTitle,
  builder: (_) => _ChorePicturePicker(title: title, selected: selected),
);

class _ChorePicturePicker extends StatefulWidget {
  const _ChorePicturePicker({required this.title, required this.selected});

  final String title;
  final String? selected;

  @override
  State<_ChorePicturePicker> createState() => _ChorePicturePickerState();
}

class _ChorePicturePickerState extends State<_ChorePicturePicker> {
  final _search = TextEditingController();
  ChorePictureCategory? _category;

  static const _sheetShare = 0.8;
  static const _suggested = 8;

  late final _categories = [
    for (final category in ChorePictureCategory.values)
      if (chorePictureCatalogue.any((p) => p.category == category)) category,
  ];
  late final _suggestions = suggestChorePictures(
    widget.title,
    limit: _suggested,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _choose(String? id) => Navigator.of(context).pop(ChorePictureChoice(id));

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final query = _search.text.trim();
    final category = _category;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * _sheetShare,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NestTextField(
            label: ChorePictureCopy.searchLabel,
            hint: ChorePictureCopy.searchHint,
            prefixIcon: LucideIcons.search,
            controller: _search,
            textInputAction: TextInputAction.search,
            textCapitalization: TextCapitalization.none,
            onChanged: (_) => setState(() {}),
          ),
          if (query.isEmpty && _categories.length > 1) ...[
            const SizedBox(height: NestSpace.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: NestSpace.sm,
                children: [
                  NestChip(
                    label: ChorePictureCopy.all,
                    isSelected: category == null,
                    onTap: () => setState(() => _category = null),
                  ),
                  for (final option in _categories)
                    NestChip(
                      label: ChorePictureCopy.category(option),
                      isSelected: category == option,
                      onTap: () => setState(() => _category = option),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: NestSpace.lg),
          Expanded(
            child: CustomScrollView(
              slivers: [
                if (query.isNotEmpty)
                  ..._found(nest, searchChorePictures(query))
                else if (category != null)
                  _PictureGrid(
                    pictures: [
                      for (final picture in chorePictureCatalogue)
                        if (picture.category == category) picture,
                    ],
                    selected: widget.selected,
                    onChosen: _choose,
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: NestChip(
                        key: const ValueKey('chore-picture-none'),
                        label: ChorePictureCopy.noPicture,
                        icon: LucideIcons.imageOff,
                        isSelected: widget.selected == null,
                        onTap: () => _choose(null),
                      ),
                    ),
                  ),
                  if (_suggestions.isNotEmpty) ...[
                    const _Heading(ChorePictureCopy.suggested),
                    _PictureGrid(
                      pictures: _suggestions,
                      selected: widget.selected,
                      onChosen: _choose,
                    ),
                  ],
                  for (final section in _categories) ...[
                    _Heading(ChorePictureCopy.category(section)),
                    _PictureGrid(
                      pictures: [
                        for (final picture in chorePictureCatalogue)
                          if (picture.category == section) picture,
                      ],
                      selected: widget.selected,
                      onChosen: _choose,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _found(NestTheme nest, List<ChorePicture> found) => [
    if (found.isEmpty)
      SliverToBoxAdapter(
        child: Text(
          ChorePictureCopy.nothingFound,
          style: nest.text.bodySecondary,
        ),
      )
    else
      _PictureGrid(
        pictures: found,
        selected: widget.selected,
        onChosen: _choose,
      ),
  ];
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return SliverPadding(
      padding: const EdgeInsets.only(top: NestSpace.xl, bottom: NestSpace.sm),
      sliver: SliverToBoxAdapter(
        child: Semantics(
          header: true,
          child: Text(
            text,
            style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
          ),
        ),
      ),
    );
  }
}

/// Rows of tiles built as they scroll into view — the library is a couple of
/// hundred pictures — each row as tall as its longest label, so large text
/// wraps rather than overflows (`FE-14`).
class _PictureGrid extends StatelessWidget {
  const _PictureGrid({
    required this.pictures,
    required this.selected,
    required this.onChosen,
  });

  final List<ChorePicture> pictures;
  final String? selected;
  final ValueChanged<String> onChosen;

  static const _tileExtent = 104.0;

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) {
      final columns = math.max(
        3,
        (constraints.crossAxisExtent / _tileExtent).floor(),
      );
      final rows = (pictures.length / columns).ceil();
      return SliverList.builder(
        itemCount: rows,
        itemBuilder: (context, row) => Padding(
          padding: const EdgeInsets.only(bottom: NestSpace.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: NestSpace.sm,
            children: [
              for (var column = 0; column < columns; column++)
                Expanded(
                  child: switch (row * columns + column) {
                    final index when index < pictures.length => _PictureTile(
                      picture: pictures[index],
                      isSelected: pictures[index].id == selected,
                      onTap: () => onChosen(pictures[index].id),
                    ),
                    _ => const SizedBox.shrink(),
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _PictureTile extends StatelessWidget {
  const _PictureTile({
    required this.picture,
    required this.isSelected,
    required this.onTap,
  });

  final ChorePicture picture;
  final bool isSelected;
  final VoidCallback onTap;

  static const _ring = NestStroke.focus + NestSpace.xxs;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    return Semantics(
      button: true,
      selected: isSelected,
      label: picture.label,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('chore-picture-option-${picture.id}'),
        borderRadius: BorderRadius.circular(NestRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(NestSpace.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LayoutBuilder(
                builder: (context, constraints) => DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(NestRadius.xl + _ring),
                    border: Border.all(
                      color: isSelected ? c.accent : Colors.transparent,
                      width: NestStroke.focus,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(NestSpace.xxs),
                    child: NestSticker(
                      asset: picture.asset,
                      size: constraints.maxWidth - _ring * 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: NestSpace.xs),
              Text(
                picture.label,
                textAlign: TextAlign.center,
                style: isSelected
                    ? nest.text.label.copyWith(fontWeight: FontWeight.w700)
                    : nest.text.caption.copyWith(color: c.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
