import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_app/src/features/goal_tracking/widgets/fullscreen_display.dart';

Widget createTestableFullscreenDisplay({
  required double currentAmount,
  required double goalAmount,
  required bool goalReached,
}) {
  return MaterialApp(
    home: FullscreenDisplay(
      currentAmount: currentAmount,
      goalAmount: goalAmount,
      goalReached: goalReached,
    ),
  );
}

void main() {
  group('FullscreenDisplay Widget Tests', () {
    testWidgets('Displays amounts with Euro symbol (€)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestableFullscreenDisplay(
          currentAmount: 125.50,
          goalAmount: 500.75,
          goalReached: false,
        ),
      );
      await tester.pumpAndSettle();

      // Check current amount display
      expect(
        find.textContaining('€126'),
        findsOneWidget,
      ); // toStringAsFixed(0) will round
      // Check target amount display
      expect(
        find.textContaining('of €501'),
        findsOneWidget,
      ); // toStringAsFixed(0) will round
    });

    testWidgets('Displays "GOAL ACHIEVED!" message when goalReached is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestableFullscreenDisplay(
          currentAmount: 1000,
          goalAmount: 1000,
          goalReached: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('GOAL ACHIEVED!'), findsOneWidget);
      // You could also check for specific styling/colors if they are distinct enough
      // and you have a reliable way to find them (e.g., by key or very specific text style).
    });

    testWidgets(
      'Does not display "GOAL ACHIEVED!" message when goalReached is false',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestableFullscreenDisplay(
            currentAmount: 50,
            goalAmount: 100,
            goalReached: false,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('GOAL ACHIEVED!'), findsNothing);
      },
    );

    testWidgets('Displays correct percentage', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableFullscreenDisplay(
          currentAmount: 50,
          goalAmount: 200,
          goalReached: false,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('25.0%'), findsOneWidget);

      await tester.pumpWidget(
        createTestableFullscreenDisplay(
          currentAmount: 200,
          goalAmount: 200,
          goalReached: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('100.0%'), findsOneWidget);

      await tester.pumpWidget(
        createTestableFullscreenDisplay(
          currentAmount: 0,
          goalAmount: 100,
          goalReached: false,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('0.0%'), findsOneWidget);
    });

    testWidgets('Clamps progress at 100% if currentAmount exceeds goalAmount', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestableFullscreenDisplay(
          currentAmount: 250,
          goalAmount: 200,
          goalReached: true, // Should be true if currentAmount > goalAmount
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('100.0%'), findsOneWidget);
    });

    testWidgets('Handles goalAmount of zero gracefully for percentage display', (
      WidgetTester tester,
    ) async {
      // The FullscreenDisplay widget itself should handle goalAmount <= 0 for progress calculation.
      // Assuming progress calculation in FullscreenDisplay is:
      // double progress = (widget.goalAmount > 0) ? (widget.currentAmount / widget.goalAmount).clamp(0.0, 1.0) : 0.0;

      await tester.pumpWidget(
        createTestableFullscreenDisplay(
          currentAmount: 50,
          goalAmount: 0, // Target is 0
          goalReached:
              true, // Or false, depending on how this edge case is defined for "reached"
        ),
      );
      await tester.pumpAndSettle();

      // Expect 0.0% or 100.0% depending on how goalReached is determined for 0 goal.
      // If goalAmount is 0, progress should be 0.0% as per typical implementation.
      // The isGoalAchieved logic in MoneyGoalTracker is `targetAmount > 0 && currentAmount >= targetAmount;`
      // So, if targetAmount is 0, isGoalAchieved will be false.
      expect(find.text('0.0%'), findsOneWidget);
      expect(
        find.text('GOAL ACHIEVED!'),
        findsNothing,
      ); // Since goalAmount is 0
    });
  });
}
