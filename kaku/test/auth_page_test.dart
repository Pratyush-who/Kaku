import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaku/core/common/widgets/app_button.dart';
import 'package:kaku/core/common/widgets/app_text_field.dart';
import 'package:kaku/features/auth/presentation/cubit/auth_state.dart';
import 'package:kaku/features/auth/presentation/pages/auth_page.dart';
import 'package:kaku/features/auth/presentation/widgets/auth_header_hero.dart';
import 'package:kaku/features/auth/presentation/widgets/auth_tab_switcher.dart';
import 'package:kaku/features/auth/presentation/widgets/sign_in_form.dart';
import 'package:kaku/features/auth/presentation/widgets/sign_up_form.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AuthPage renders hero, tab switcher and sign in fields',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: AuthPage(initialMode: AuthMode.signIn),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Hero and Tab Switcher are present
    expect(find.byType(AuthHeaderHero), findsOneWidget);
    expect(find.byType(AuthTabSwitcher), findsOneWidget);

    // Verify Sign In elements
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign In to Workspace'), findsOneWidget);
    expect(find.text('Remember me'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);

    // Verify non-square pill/squircle input fields inside SignInForm
    expect(
      find.descendant(of: find.byType(SignInForm), matching: find.byType(AppTextField)),
      findsNWidgets(2),
    );
    expect(find.byType(AppButton), findsWidgets);

    // Switch to Sign Up tab
    await tester.tap(find.text('Create Account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Verify Sign Up elements
    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Create Free Workspace'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(SignUpForm), matching: find.byType(AppTextField)),
      findsNWidgets(3),
    );
  });
}
