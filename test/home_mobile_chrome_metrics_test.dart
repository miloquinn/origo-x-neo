import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/pages/home/home_mobile_chrome.dart';

void main() {
  group('HomeMobileChromeMetrics', () {
    test(
      'inline tablet controls share a center with custom navigation heights',
      () {
        for (final height in [52.0, 60.0, 72.0]) {
          final metrics = HomeMobileChromeMetrics.fromMediaQuery(
            const MediaQueryData(
              viewPadding: EdgeInsets.only(top: 24, bottom: 20),
            ),
            navigationAtTop: true,
            tabletToolbarInline: true,
            floatingNavHeight: height,
          );
          expect(
            metrics.navigationTopInset + height / 2,
            metrics.toolbarTopInset + metrics.topBarContentHeight / 2,
          );
          expect(
            metrics.pageTopPadding,
            greaterThan(metrics.navigationTopInset + height),
          );
          expect(
            metrics.pageTopPadding,
            greaterThan(metrics.toolbarTopInset + metrics.topBarContentHeight),
          );
        }
      },
    );
    test('keeps floating chrome clear of iPhone system insets', () {
      final metrics = HomeMobileChromeMetrics.fromMediaQuery(
        const MediaQueryData(
          size: Size(393, 852),
          viewPadding: EdgeInsets.only(top: 59, bottom: 34),
        ),
        platform: TargetPlatform.iOS,
      );

      expect(metrics.systemTopInset, 59);
      expect(metrics.systemBottomInset, 34);
      expect(metrics.floatingNavHeight, 56);
      expect(metrics.topBarHeight, 119);
      expect(metrics.pageTopPadding, 127);
      expect(metrics.navBottomInset, 36);
      expect(metrics.navContainerHeight, 92);
      expect(metrics.pageBottomPadding, 102);
      expect(metrics.floatingActionBottomMargin, 107);
    });

    test('iOS gap preserves safe area across keyboards and custom heights', () {
      for (final inset in [20.0, 34.0, 60.0]) {
        for (final height in [52.0, 60.0, 72.0]) {
          for (final keyboard in [0.0, 300.0]) {
            final metrics = HomeMobileChromeMetrics.fromMediaQuery(
              MediaQueryData(
                viewPadding: EdgeInsets.only(bottom: inset),
                viewInsets: EdgeInsets.only(bottom: keyboard),
              ),
              platform: TargetPlatform.iOS,
              floatingNavHeight: height,
            );
            expect(metrics.navBottomInset, inset + 2);
            expect(metrics.pageBottomPadding, height + inset + 12);
            expect(metrics.floatingActionBottomMargin, height + inset + 17);
            expect(metrics.keyboardVisible, keyboard > 0);
          }
        }
      }
    });

    test('iPhones without a home indicator retain the existing edge gap', () {
      final metrics = HomeMobileChromeMetrics.fromMediaQuery(
        const MediaQueryData(),
        platform: TargetPlatform.iOS,
      );
      expect(metrics.navBottomInset, 10);
    });

    test(
      'keeps the floating navigation compact with deliberate side margins',
      () {
        expect(
          homeMobileFloatingNavWidthFor(screenWidth: 320, itemCount: 4),
          284,
        );
        expect(
          homeMobileFloatingNavWidthFor(screenWidth: 360, itemCount: 4),
          324,
        );
        expect(
          homeMobileFloatingNavWidthFor(screenWidth: 393, itemCount: 4),
          357,
        );
        expect(
          homeMobileFloatingNavWidthFor(screenWidth: 405, itemCount: 4),
          368,
        );
        expect(
          homeMobileFloatingNavWidthFor(screenWidth: 600, itemCount: 4),
          368,
        );

        expect(
          homeMobileFloatingNavItemWidthFor(screenWidth: 320, itemCount: 4),
          69,
        );
        expect(
          homeMobileFloatingNavItemWidthFor(screenWidth: 393, itemCount: 4),
          closeTo(87.25, 0.001),
        );
        expect(
          homeMobileFloatingNavItemWidthFor(screenWidth: 405, itemCount: 4),
          90,
        );
      },
    );

    test('adapts the automatic shape for an iPhone 16 Pro', () {
      final dimensions = homeMobileFloatingNavDimensionsFor(
        screenWidth: 402,
        itemCount: 5,
        platform: TargetPlatform.iOS,
        systemBottomInset: 34,
      );

      expect(dimensions.height, 60);
      expect(dimensions.horizontalMargin, closeTo(24.12, 0.01));
      expect(dimensions.width, closeTo(353.76, 0.01));
    });

    test('keeps Android automatic dimensions unchanged', () {
      final dimensions = homeMobileFloatingNavDimensionsFor(
        screenWidth: 412,
        itemCount: 4,
        platform: TargetPlatform.android,
        systemBottomInset: 24,
      );

      expect(dimensions.height, 56);
      expect(dimensions.horizontalMargin, 22);
      expect(dimensions.width, 368);
    });

    test('custom dimensions override the automatic shape safely', () {
      final dimensions = homeMobileFloatingNavDimensionsFor(
        screenWidth: 402,
        itemCount: 5,
        platform: TargetPlatform.iOS,
        systemBottomInset: 34,
        customHeight: 66,
        customHorizontalMargin: 30,
      );

      expect(dimensions.height, 66);
      expect(dimensions.horizontalMargin, 30);
      expect(dimensions.width, 342);
    });

    test('uses Android system insets without platform-specific branches', () {
      final metrics = HomeMobileChromeMetrics.fromMediaQuery(
        const MediaQueryData(
          size: Size(412, 915),
          viewPadding: EdgeInsets.only(top: 24, bottom: 24),
        ),
        platform: TargetPlatform.android,
      );

      expect(metrics.topBarHeight, 84);
      expect(metrics.pageTopPadding, 92);
      expect(metrics.navBottomInset, 34);
      expect(metrics.navContainerHeight, 90);
      expect(metrics.pageBottomPadding, 100);
      expect(metrics.floatingActionBottomMargin, 105);
    });

    test('preserves large system insets instead of clamping them', () {
      final metrics = HomeMobileChromeMetrics.fromMediaQuery(
        const MediaQueryData(
          size: Size(320, 568),
          viewPadding: EdgeInsets.only(top: 20, bottom: 60),
        ),
      );

      expect(metrics.systemBottomInset, 60);
      expect(metrics.navBottomInset, 70);
      expect(metrics.pageBottomPadding, 136);
    });

    test('locks system insets while an immersive reader route is active', () {
      final stabilizer = HomeMobileSystemInsetsStabilizer();
      final homeInsets = stabilizer.resolve(
        const MediaQueryData(
          size: Size(412, 915),
          viewPadding: EdgeInsets.only(top: 24, bottom: 24),
        ),
        lockForReaderTransition: false,
      );

      final hiddenBarInsets = stabilizer.resolve(
        const MediaQueryData(size: Size(412, 915)),
        lockForReaderTransition: true,
      );
      final transientGestureInsets = stabilizer.resolve(
        const MediaQueryData(
          size: Size(412, 915),
          viewPadding: EdgeInsets.only(bottom: 48),
        ),
        lockForReaderTransition: true,
      );

      expect(homeInsets, const EdgeInsets.only(top: 24, bottom: 24));
      expect(hiddenBarInsets, homeInsets);
      expect(transientGestureInsets, homeInsets);

      final restoredInsets = stabilizer.resolve(
        const MediaQueryData(
          size: Size(412, 915),
          viewPadding: EdgeInsets.only(top: 24, bottom: 32),
        ),
        lockForReaderTransition: false,
      );
      expect(restoredInsets, const EdgeInsets.only(top: 24, bottom: 32));
    });
  });
}
