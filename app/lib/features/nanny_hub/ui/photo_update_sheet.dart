import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../household/model/member.dart';
import '../model/nanny_limits.dart';
import 'child_choice.dart';

/// What the send sheet decided: a caption, and which children the photo is
/// of. Null means the carer changed their mind.
typedef PhotoUpdateChoice = ({String? caption, List<String> childIds});

/// The picture just taken, big, with an optional caption and the children in
/// it — every child chosen already, because most photos are of all of them.
/// One tap sends it.
Future<PhotoUpdateChoice?> showPhotoUpdateSheet({
  required BuildContext context,
  required Uint8List photo,
  required List<Member> children,
}) => showNestSheet<PhotoUpdateChoice>(
  context: context,
  title: NannyPhotoCopy.sheetTitle,
  builder: (_) => _PhotoUpdateBody(photo: photo, children: children),
);

class _PhotoUpdateBody extends StatefulWidget {
  const _PhotoUpdateBody({required this.photo, required this.children});

  final Uint8List photo;
  final List<Member> children;

  @override
  State<_PhotoUpdateBody> createState() => _PhotoUpdateBodyState();
}

class _PhotoUpdateBodyState extends State<_PhotoUpdateBody> {
  final _caption = TextEditingController();
  late Set<String> _childIds = {for (final child in widget.children) child.id};

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  void _send() {
    final text = _caption.text.trim();
    Navigator.of(context).pop((
      caption: text.isEmpty ? null : text,
      childIds: [
        for (final child in widget.children)
          if (_childIds.contains(child.id)) child.id,
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(NestRadius.lg),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Semantics(
                image: true,
                label: NannyPhotoCopy.photoLabel,
                child: Image.memory(
                  widget.photo,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: NestSpace.lg),
          NestTextField(
            label: NannyPhotoCopy.caption,
            hint: NannyPhotoCopy.captionHint,
            controller: _caption,
            maxLines: 2,
            inputFormatters: [
              LengthLimitingTextInputFormatter(NannyLimits.photoCaption),
            ],
          ),
          if (widget.children.isNotEmpty) ...[
            const SizedBox(height: NestSpace.lg),
            ChildChoice(
              children: widget.children,
              chosen: _childIds,
              onChanged: (ids) => setState(() => _childIds = ids),
            ),
          ],
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: NannyPhotoCopy.send,
            icon: Icons.send_rounded,
            onPressed: _send,
          ),
        ],
      ),
    );
  }
}
