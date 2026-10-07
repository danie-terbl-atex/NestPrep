import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/family_profile.dart';

/// What the sizes sheet collected. A blank field is no size.
typedef SizesDraft = ({String clothingSize, String shoeSize});

Future<SizesDraft?> showSizesSheet({
  required BuildContext context,
  required FamilyProfile profile,
}) => showNestSheet<SizesDraft>(
  context: context,
  title: FamilyCopy.sectionSizes,
  builder: (_) => _SizesSheetBody(profile: profile),
);

class _SizesSheetBody extends StatefulWidget {
  const _SizesSheetBody({required this.profile});

  final FamilyProfile profile;

  @override
  State<_SizesSheetBody> createState() => _SizesSheetBodyState();
}

class _SizesSheetBodyState extends State<_SizesSheetBody> {
  late final _clothing = TextEditingController(
    text: widget.profile.clothingSize ?? '',
  );
  late final _shoes = TextEditingController(
    text: widget.profile.shoeSize ?? '',
  );

  @override
  void dispose() {
    _clothing.dispose();
    _shoes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NestTextField(
            label: FamilyCopy.clothingSize,
            hint: FamilyCopy.clothingSizeHint,
            controller: _clothing,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: NestSpace.lg),
          NestTextField(
            label: FamilyCopy.shoeSize,
            hint: FamilyCopy.shoeSizeHint,
            controller: _shoes,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: FamilyCopy.save,
            onPressed: () => Navigator.of(
              context,
            ).pop((clothingSize: _clothing.text, shoeSize: _shoes.text)),
          ),
        ],
      ),
    );
  }
}
