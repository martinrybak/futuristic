import 'package:flutter/material.dart';
import 'package:futuristic/futuristic.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const Home(),
      routes: {
        GoodScreen.routeName: (_) => const GoodScreen(),
        BadScreen.routeName: (_) => const BadScreen(),
      },
    );
  }
}

/// A future that completes successfully.
Future<int> goodFuture(int first, int second) async {
  await Future.delayed(const Duration(seconds: 1));
  return first + second;
}

// A future that completes with an exception.
Future<int> badFuture(int first, int second) async {
  await Future.delayed(const Duration(seconds: 1));
  throw Exception('Something happened');
}

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 50, child: Center(child: GoodButton())),
            const SizedBox(height: 50, child: Center(child: BadButton())),
            TextButton(
              child: const Text('Good screen example'),
              onPressed: () {
                Navigator.of(context).pushNamed(GoodScreen.routeName);
              },
            ),
            TextButton(
              child: const Text('Bad screen example'),
              onPressed: () {
                Navigator.of(context).pushNamed(BadScreen.routeName);
              },
            )
          ],
        ),
      ),
    );
  }
}

class GoodButton extends StatelessWidget {
  const GoodButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Futuristic<int>(
      futureBuilder: () => goodFuture(1, 2),
      initialBuilder: (_, start) => TextButton(onPressed: start, child: const Text('Good button example')),
      busyBuilder: (_) => const CircularProgressIndicator(),
      dataBuilder: (_, data) => Text(data.toString()),
    );
  }
}

class BadButton extends StatelessWidget {
  const BadButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Futuristic<int>(
      futureBuilder: () => badFuture(1, 2),
      initialBuilder: (_, start) => TextButton(onPressed: start, child: const Text('Bad button example')),
      busyBuilder: (_) => const CircularProgressIndicator(),
      errorBuilder: (_, error, retry) => TextButton(onPressed: retry, child: const Text('Sorry! Try again')),
    );
  }
}

class GoodScreen extends StatelessWidget {
  static const routeName = '/good';

  const GoodScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Good screen')),
      body: Center(
        child: Futuristic<int>(
          autoStart: true,
          futureBuilder: () => goodFuture(1, 2),
          busyBuilder: (_) => const CircularProgressIndicator(),
          dataBuilder: (_, data) => Text('Data is $data'),
        ),
      ),
    );
  }
}

class BadScreen extends StatelessWidget {
  static const routeName = '/bad';

  const BadScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bad screen')),
      body: Center(
        child: Futuristic<int>(
          autoStart: true,
          futureBuilder: () => badFuture(1, 2),
          busyBuilder: (_) => const CircularProgressIndicator(),
          onError: (error, retry) async {
            await showDialog(
              context: context,
              builder: (innerContext) {
                return AlertDialog(
                  content: const Text('Sorry! Try again'),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('RETRY'),
                      onPressed: () {
                        Navigator.of(innerContext).pop();
                        retry();
                      },
                    )
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
