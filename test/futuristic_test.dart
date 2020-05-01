import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futuristic/futuristic.dart';

// ignore_for_file: missing_required_param

void main() {
  group('Constructor', () {
    testWidgets('throws assertion error if futureBuilder is null', (tester) async {
      expect(() => Futuristic(), throwsAssertionError);
    });

    testWidgets('throws assertion error if autoStart is true and initialBuilder is not null', (tester) async {
      expect(() => Futuristic(autoStart: true, initialBuilder: (_, __) => Container()), throwsAssertionError);
    });

    testWidgets('throws assertion error if autoStart is false and initialBuilder is null', (tester) async {
      expect(() => Futuristic(autoStart: false), throwsAssertionError);
    });
  });

  group('Builders', () {
    testWidgets('initially shows initialBuilder', (tester) async {
      final text = 'initial';
      final widget = MaterialApp(
        home: Futuristic(
          futureBuilder: () => goodFuture(),
          initialBuilder: (_, __) => Text(text),
        ),
      );
      await tester.pumpWidget(widget);
      expect(find.text(text), findsOneWidget);
    });

    testWidgets('shows busyBuilder after invoking start', (tester) async {
      final text = 'busy';
      final widget = MaterialApp(
        home: Futuristic(
          futureBuilder: () => goodFuture(),
          initialBuilder: (_, start) {
            WidgetsBinding.instance.addPostFrameCallback((_) => start());
            return Container();
          },
          busyBuilder: (_) => Text(text),
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pump();
      expect(find.text(text), findsOneWidget);
    });

    testWidgets('shows default busy widget after invoking start and busyBuilder is null', (tester) async {
      final widget = MaterialApp(
        home: Futuristic(
          futureBuilder: () => goodFuture(),
          initialBuilder: (_, start) {
            WidgetsBinding.instance.addPostFrameCallback((_) => start());
            return Container();
          },
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pump();
      expect(find.byWidgetPredicate((w) => w is CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows dataBuilder after future completes successfully', (tester) async {
      final text = '3';
      final widget = MaterialApp(
        home: Futuristic(
          futureBuilder: () => goodFuture(),
          initialBuilder: (_, start) {
            WidgetsBinding.instance.addPostFrameCallback((_) => start());
            return Container();
          },
          busyBuilder: (_) => CircularProgressIndicator(),
          dataBuilder: (_, data) => Text(text),
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pump();
      expect(find.text(text), findsOneWidget);
    });

    testWidgets('shows initialBuilder after future completes successfully and dataBuilder is null', (tester) async {
      final text = 'initial';
      final widget = MaterialApp(
        home: Futuristic(
          futureBuilder: () => goodFuture(),
          initialBuilder: (_, start) {
            WidgetsBinding.instance.addPostFrameCallback((_) => start());
            return Text(text);
          },
          busyBuilder: (_) => CircularProgressIndicator(),
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pump();
      expect(find.text(text), findsOneWidget);
    });

    testWidgets('shows errorBuilder after future fails with error', (tester) async {
      final text = 'Something happened';
      final widget = MaterialApp(
        home: Futuristic(
          futureBuilder: () => badFuture(text),
          initialBuilder: (_, start) {
            WidgetsBinding.instance.addPostFrameCallback((_) => start());
            return Container();
          },
          busyBuilder: (_) => CircularProgressIndicator(),
          errorBuilder: (_, e, __) => Text(e.toString()),
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pump();
      expect(find.text(text), findsOneWidget);
    });

    testWidgets('shows initialBuilder after future fails with error and errorBuilder is null', (tester) async {
      final text = 'foo';
      final widget = MaterialApp(
        home: Futuristic(
          futureBuilder: () => badFuture(text),
          initialBuilder: (_, start) {
            WidgetsBinding.instance.addPostFrameCallback((_) => start());
            return Text(text);
          },
          busyBuilder: (_) => CircularProgressIndicator(),
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pump();
      expect(find.text(text), findsOneWidget);
    });

    testWidgets('invoking retry in errorBuilder restarts future', (tester) async {
      final initial = 'initial';
      final error = 'error';
      final widget = MaterialApp(
        home: Futuristic(
          futureBuilder: () => badFuture(error),
          initialBuilder: (_, start) {
            WidgetsBinding.instance.addPostFrameCallback((_) => start());
            return Text(initial);
          },
          busyBuilder: (_) => CircularProgressIndicator(),
          errorBuilder: (_, e, retry) {
            WidgetsBinding.instance.addPostFrameCallback((_) => retry());
            return Text(e.toString());
          },
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pump();
      expect(find.text(error), findsOneWidget);
      await tester.pump();
      expect(find.byWidgetPredicate((w) => w is CircularProgressIndicator), findsOneWidget);
    });
  });

  group('Callbacks', () {
    testWidgets('onDone called after future completes successfully', (tester) async {
      final expected = 'data';
      String actual;
      final widget = MaterialApp(
        home: Futuristic(
          futureBuilder: () => goodFuture(expected),
          initialBuilder: (_, start) {
            WidgetsBinding.instance.addPostFrameCallback((_) => start());
            return Container();
          },
          onData: expectAsync1((data) => actual = data),
        ),
      );
      await tester.pumpWidget(widget);
      expectLater(actual, expected);
    });

    testWidgets('onError called after future fails with error', (tester) async {
      final expected = 'error';
      String actual;
      final widget = MaterialApp(
        home: Futuristic(
          futureBuilder: () => badFuture(expected),
          initialBuilder: (_, start) {
            WidgetsBinding.instance.addPostFrameCallback((_) => start());
            return Container();
          },
          onError: expectAsync2((error, _) => actual = error),
        ),
      );
      await tester.pumpWidget(widget);
      expectLater(actual, expected);
    });
  });
}

Future goodFuture([Object data]) async {
  return Future.value(data);
}

Future badFuture(String error) {
  return Future.error(error);
}
