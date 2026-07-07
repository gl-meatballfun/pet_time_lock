import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_time_lock/bloc/content_cubit.dart';
import 'package:pet_time_lock/models/app_models.dart';
import 'package:pet_time_lock/screens/content_card_dialog.dart';

import '../fake_database_helper.dart';
import '../test_helper.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  group('ContentCardDialog', () {
    late FakeDatabaseHelper fakeDb;

    setUp(() {
      fakeDb = FakeDatabaseHelper();
      fakeDb.seedPetState(PetState(currentGrade: 5));
    });

    Widget buildTestableDialog(ContentCubit cubit) {
      return BlocProvider.value(
        value: cubit,
        child: const MaterialApp(
          home: Material(child: ContentCardDialog()),
        ),
      );
    }

    ContentCubit createCubitWithContent() {
      final cubit = ContentCubit(fakeDb);
      cubit.emit(ContentState(
        status: ContentStatus.showingContent,
        currentContent: EducationalContent(
          id: 'math_001',
          type: ContentType.math,
          title: '测试题目',
          content: '请计算以下算式',
          question: '2 + 3 = ?',
          options: const ['3', '4', '5', '6'],
          correctAnswer: '5',
          explanation: '2 加 3 等于 5',
          grade: 5,
          subject: '数学',
          requiresInteraction: true,
        ),
      ));
      return cubit;
    }

    testWidgets('默认显示专注模式入口与关闭按钮', (tester) async {
      final cubit = createCubitWithContent();
      await tester.pumpWidget(buildTestableDialog(cubit));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.center_focus_strong), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.text('测试题目'), findsOneWidget);
    });

    testWidgets('开启专注模式后隐藏关闭按钮并显示退出入口', (tester) async {
      final cubit = createCubitWithContent();
      await tester.pumpWidget(buildTestableDialog(cubit));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.center_focus_strong));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.text('退出专注'), findsOneWidget);
    });
  });
}
