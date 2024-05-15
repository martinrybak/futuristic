import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futuristic/futuristic.dart';

void main() {
  group('Builders', () {
    testWidgets('initially shows initialBuilder', (tester) async {
      const text = 'initial';
      final widget = MaterialApp(
        home: Futuristic(
          futureBuilder: () => goodFuture(),
          initialBuilder: (_, __) => const Text(text),
        ),
      );
      await tester.pumpWidget(widget);
      expect(find.text(text), findsOneWidget);
    });

    testWidgets('shows busyBuilder after invoking start', (tester) async {
      const text = 'busy';
      final widget = MaterialApp(
        home: Futuristic(
          futureBuilder: () => goodFuture(),
          initialBuilder: (_, start) {
            WidgetsBinding.instance.addPostFrameCallback((_) => start());
            return Container();
          },
          busyBuilder: (_) => const Text(text),
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
      const text = '3';
      final widget = MaterialApp(
        home: Futuristic<void>(
          futureBuilder: () => goodFuture(),
          initialBuilder: (_, start) {
            WidgetsBinding.instance.addPostFrameCallback((_) => start());
            return Container();
          },
          busyBuilder: (_) => const CircularProgressIndicator(),
          dataBuilder: (_, data) => const Text(text),
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pump();
      expect(find.text(text), findsOneWidget);
    });

    testWidgets('shows initialBuilder after future completes successfully and dataBuilder is null', (tester) async {
      const text = 'initial';
      final widget = MaterialApp(
        home: Futuristic(
          futureBuilder: () => goodFuture(),
          initialBuilder: (_, start) {
            WidgetsBinding.instance.addPostFrameCallback((_) => start());
            return const Text(text);
          },
          busyBuilder: (_) => const CircularProgressIndicator(),
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pump();
      expect(find.text(text), findsOneWidget);
    });

    testWidgets('shows errorBuilder after future fails with error', (tester) async {
      const text = 'Something happened';
      final widget = MaterialApp(
        home: Futuristic(
          futureBuilder: () => badFuture(text),
          initialBuilder: (_, start) {
            WidgetsBinding.instance.addPostFrameCallback((_) => start());
            return Container();
          },
          busyBuilder: (_) => const CircularProgressIndicator(),
          errorBuilder: (_, e, __) => Text(e.toString()),
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pump();
      expect(find.text(text), findsOneWidget);
    });

    testWidgets('shows initialBuilder after future fails with error and errorBuilder is null', (tester) async {
      const text = 'foo';
      final widget = MaterialApp(
        home: Futuristic(
          futureBuilder: () => badFuture(text),
          initialBuilder: (_, start) {
            WidgetsBinding.instance.addPostFrameCallback((_) => start());
            return const Text(text);
          },
          busyBuilder: (_) => const CircularProgressIndicator(),
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pump();
      expect(find.text(text), findsOneWidget);
    });

    testWidgets('invoking retry in errorBuilder restarts future', (tester) async {
      const initial = 'initial';
      const error = 'error';
      final widget = MaterialApp(
        home: Futuristic(
          futureBuilder: () => badFuture(error),
          initialBuilder: (_, start) {
            WidgetsBinding.instance.addPostFrameCallback((_) => start());
            return const Text(initial);
          },
          busyBuilder: (_) => const CircularProgressIndicator(),
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
      const expected = 'data';
      final widget = MaterialApp(
        home: Futuristic(
          futureBuilder: () => goodFuture(expected),
          initialBuilder: (_, start) {
            WidgetsBinding.instance.addPostFrameCallback((_) => start());
            return Container();
          },
          onData: expectAsync1((data) => expect(data, expected)),
        ),
      );
      await tester.pumpWidget(widget);
    });

    testWidgets('onError called after future fails with error', (tester) async {
      const expected = 'error';
      final widget = MaterialApp(
        home: Futuristic(
          futureBuilder: () => badFuture(expected),
          initialBuilder: (_, start) {
            WidgetsBinding.instance.addPostFrameCallback((_) => start());
            return Container();
          },
          onError: expectAsync2((error, _) => expect(error, expected)),
        ),
      );
      await tester.pumpWidget(widget);
    });
  });
}

Future goodFuture([Object? data]) async {
  return Future.value(data);
}

Future badFuture(String error) {
  return Future.error(error);
}
