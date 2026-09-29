import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/home_care_product.dart';
import '../model/product_kind.dart';
import '../model/safety/job_safety.dart';
import 'product_kind_picker.dart';

/// What the product sheet came back with.
sealed class ProductSheetOutcome {
  const ProductSheetOutcome();
}

final class ProductSaved extends ProductSheetOutcome {
  const ProductSaved(this.product);

  /// With an empty id when it is new.
  final HomeCareProduct product;
}

final class ProductDeleted extends ProductSheetOutcome {
  const ProductDeleted();
}

/// Adds a product to the library, or changes one — its name, its kind, where
/// it is kept, and the household's own two cautions. The precautions the
/// kind carries are shown as it is chosen, so the parent sees what the
/// helper will be told.
Future<ProductSheetOutcome?> showProductSheet({
  required BuildContext context,
  HomeCareProduct? product,
}) => showNestSheet<ProductSheetOutcome>(
  context: context,
  title: product == null
      ? HomeCareLibraryCopy.addProduct
      : HomeCareLibraryCopy.editProduct,
  builder: (context) => _ProductBody(product: product),
);

class _ProductBody extends StatefulWidget {
  const _ProductBody({required this.product});

  final HomeCareProduct? product;

  @override
  State<_ProductBody> createState() => _ProductBodyState();
}

class _ProductBodyState extends State<_ProductBody> {
  late final _name = TextEditingController(text: widget.product?.name ?? '');
  late final _kept = TextEditingController(
    text: widget.product?.whereKept ?? '',
  );
  late final _note = TextEditingController(text: widget.product?.note ?? '');
  late ProductKind _kind = widget.product?.kind ?? ProductKind.allPurpose;
  late bool _fromChildren = widget.product?.keepFromChildren ?? false;
  late bool _fromPets = widget.product?.keepFromPets ?? false;

  @override
  void dispose() {
    _name.dispose();
    _kept.dispose();
    _note.dispose();
    super.dispose();
  }

  HomeCareProduct get _draft => HomeCareProduct(
    id: widget.product?.id ?? '',
    name: _name.text.trim(),
    kind: _kind,
    whereKept: _optional(_kept.text),
    note: _optional(_note.text),
    keepFromChildren: _fromChildren,
    keepFromPets: _fromPets,
    createdBy: widget.product?.createdBy ?? '',
  );

  static String? _optional(String text) =>
      text.trim().isEmpty ? null : text.trim();

  @override
  Widget build(BuildContext context) {
    final limit = [LengthLimitingTextInputFormatter(HomeCareProduct.textLimit)];
    final precautions = JobSafety.of([_draft]).precautions;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NestTextField(
            label: HomeCareLibraryCopy.productName,
            hint: HomeCareLibraryCopy.productNameHint,
            controller: _name,
            autofocus: widget.product == null,
            inputFormatters: [
              LengthLimitingTextInputFormatter(HomeCareProduct.nameLimit),
            ],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: NestSpace.lg),
          ProductKindPicker(
            selected: _kind,
            onChanged: (kind) => setState(() => _kind = kind),
          ),
          const SizedBox(height: NestSpace.lg),
          NestTextField(
            label: HomeCareLibraryCopy.whereKept,
            hint: HomeCareLibraryCopy.whereKeptHint,
            controller: _kept,
            inputFormatters: limit,
          ),
          const SizedBox(height: NestSpace.lg),
          NestTextField(
            label: HomeCareLibraryCopy.productNote,
            controller: _note,
            maxLines: 2,
            inputFormatters: limit,
          ),
          const SizedBox(height: NestSpace.lg),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              NestChip(
                label: HomeCareSafetyCopy.keepFromChildrenChoice,
                icon: Icons.child_care_outlined,
                isSelected: _fromChildren,
                onTap: () => setState(() => _fromChildren = !_fromChildren),
              ),
              NestChip(
                label: HomeCareSafetyCopy.keepFromPetsChoice,
                icon: Icons.pets_outlined,
                isSelected: _fromPets,
                onTap: () => setState(() => _fromPets = !_fromPets),
              ),
            ],
          ),
          if (precautions.isNotEmpty) ...[
            const SizedBox(height: NestSpace.lg),
            NestBanner(
              message: HomeCareSafetyCopy.helperWillBeTold(precautions),
              tone: NestBannerTone.warning,
            ),
          ],
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: AppCopy.householdSave,
            onPressed: _name.text.trim().isEmpty
                ? null
                : () => Navigator.of(context).pop(ProductSaved(_draft)),
          ),
          if (widget.product != null) ...[
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: HomeCareLibraryCopy.deleteProduct,
              variant: NestButtonVariant.ghost,
              icon: Icons.delete_outline,
              onPressed: () =>
                  Navigator.of(context).pop(const ProductDeleted()),
            ),
          ],
          const SizedBox(height: NestSpace.lg),
        ],
      ),
    );
  }
}
