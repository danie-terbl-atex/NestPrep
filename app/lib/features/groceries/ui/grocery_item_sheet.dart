import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/grocery_plan_copy.dart';
import '../model/grocery_item.dart';
import '../state/grocery_list_controller.dart';

/// Renames an item, changes how much of it is needed, or takes it off the list.
/// The rules allow the adder or an admin; a refusal comes back as copy on the
/// list behind this sheet (`FE-04`).
Future<void> showGroceryItemSheet({
  required BuildContext context,
  required GroceryItem item,
}) {
  final controller = context.read<GroceryListController>();
  return showNestSheet<void>(
    context: context,
    title: AppCopy.groceriesEditItem,
    builder: (sheetContext) =>
        _GroceryItemSheetBody(item: item, controller: controller),
  );
}

class _GroceryItemSheetBody extends StatefulWidget {
  const _GroceryItemSheetBody({required this.item, required this.controller});

  final GroceryItem item;
  final GroceryListController controller;

  @override
  State<_GroceryItemSheetBody> createState() => _GroceryItemSheetBodyState();
}

class _GroceryItemSheetBodyState extends State<_GroceryItemSheetBody> {
  late final _name = TextEditingController(text: widget.item.name);
  late final _quantity = TextEditingController(
    text: widget.item.quantity ?? '',
  );

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _name.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        NestTextField(
          label: AppCopy.groceriesAddHint,
          controller: _name,
          autofocus: true,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: NestSpace.lg),
        NestTextField(
          label: AppCopy.groceriesQuantityHint,
          controller: _quantity,
          textInputAction: TextInputAction.done,
        ),
        if (widget.item.isFromPlans) ...[
          const SizedBox(height: NestSpace.md),
          // Saving makes it the editor's (groceries ADR-0002); say so first.
          Text(
            GroceryPlanCopy.editAdopts,
            style: NestTheme.of(context).text.caption,
          ),
        ],
        const SizedBox(height: NestSpace.xxl),
        NestButton(
          label: AppCopy.householdSave,
          onPressed: canSave ? _save : null,
        ),
        const SizedBox(height: NestSpace.sm),
        NestButton(
          label: AppCopy.householdRemove,
          variant: NestButtonVariant.danger,
          onPressed: _remove,
        ),
      ],
    );
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    await widget.controller.rename(
      widget.item,
      name: _name.text,
      quantity: _quantity.text,
    );
    navigator.pop();
  }

  Future<void> _remove() async {
    final navigator = Navigator.of(context);
    await widget.controller.remove(widget.item);
    navigator.pop();
  }
}
