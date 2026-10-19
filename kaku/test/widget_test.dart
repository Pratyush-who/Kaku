import 'package:flutter_test/flutter_test.dart';
import 'package:kaku/app.dart';
import 'package:kaku/core/common/widgets/app_brand_logo.dart';

void main() {
  testWidgets('KakuApp smoke test: loads splash screen and brand logo', (WidgetTester tester) async {
    await tester.pumpWidget(const KakuApp());
    await tester.pump();

    // Verify brand logo is displayed
    expect(find.byType(AppBrandLogo), findsOneWidget);
    expect(find.text('KAKU'), findsOneWidget);
  });
}
