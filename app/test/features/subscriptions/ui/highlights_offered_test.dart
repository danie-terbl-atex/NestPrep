import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/subscriptions/model/premium_highlight.dart';
import 'package:nestprep/features/subscriptions/ui/highlights_offered.dart';
import 'package:nestprep/shared/flags/feature_flags.dart';
import 'package:nestprep/shared/flags/feature_flags_controller.dart';
import 'package:provider/provider.dart';

import '../../../support/test_flags.dart';

/// What Premium is said to add follows what the build can deliver (shops
/// ADR-0003): with no shop offered, shops are not on the list.
void main() {
  Future<List<PremiumHighlight>> offeredWith(
    WidgetTester tester,
    FeatureFlags flags,
  ) async {
    late List<PremiumHighlight> offered;
    final controller = testFlagsController(flags);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<FeatureFlagsController>.value(
        value: controller,
        child: Builder(
          builder: (context) {
            offered = highlightsOffered(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pump();
    return offered;
  }

  testWidgets('every area is offered while a shop is', (tester) async {
    expect(await offeredWith(tester, TestFlags.on), PremiumHighlight.values);
  });

  testWidgets('shops are left out when no shop is offered', (tester) async {
    final offered = await offeredWith(
      tester,
      FeatureFlags.fromFields(const {
        'checkersShop': false,
        'pnpShop': false,
        'woolworthsShop': false,
      }, defaultOn: true),
    );
    expect(offered, isNot(contains(PremiumHighlight.shops)));
    expect(offered, hasLength(PremiumHighlight.values.length - 1));
  });
}
