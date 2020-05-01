# futuristic

Makes it possible to safely execute and retry a `Future` inside a StatelessWidget.

![](screenshot.png)

## Problem

If you've ever tried to use the `FutureBuilder` widget in Flutter, you've probably been surprised by its behavior. When used inside a `StatelessWidget`, **it will re-execute its `Future` every time it is rebuilt**. Since a widget can be rebuilt many times in Flutter (including due to hot reload), this can be undesirable if our `Future` calls a non-idempotent REST API endpoint, for example.

```
class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: myExpensiveFuture(),  //Will be executed every time Home is rebuilt
      builder: (_context, snapshot) {
        ...
      },
    );
  }
}
```

To only execute our `Future` only once, we could use a `StatefulWidget`, but now we have the extra boilerplate of using a `StatefulWidget` and holding onto our `Future` in a state variable.

```
class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Future _future;

  @override
  void initState() {
    super.initState();
    _future = myExpensiveFuture();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,  // Will be executed only once
      builder: (_context, snapshot) {
        ...
      },
    );
  }
}
```

## Solution

The problem with `FutureBuilder` is, ironically, that it takes a `Future` instance as its input. Instead, the `Futuristic` widget takes a `Function` that *returns* a `Future`. This means:

* It can be used in a `StatelessWidget`.
* It can let child widgets **start** or **retry** a `Future`.

Additionally, `Futuristic` provides:

* Multiple builder callbacks to provide `initial/busy/data/error` widget states.
* `onData/onError` callbacks to perform additional actions when a `Future` completes.

You can use the `Futuristic` widget to wrap a single component like a button, or an entire screen. Note that the `futureBuilder` parameter takes a `Function` that *returns* a `Future`. This give us the ability to start (or retry) our future as needed. Best of all, we can go back to using a regular `StatelessWidget`.

## Usage

### Button example

To start executing a `Future` in response to a button press, call the `start` parameter in the `initialBuilder` callback. For example, in a button widget's `onPressed` handler:

```
Future<int> myFuture(int first, int second) async {
  await Future.delayed(const Duration(seconds: 1));
  return first + second;
}

class MyButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Futuristic<int>(
      futureBuilder: () => myFuture(1, 2),
      initialBuilder: (context, start) => RaisedButton(child: Text('Go'), onPressed: start),
      busyBuilder: (context) => CircularProgressIndicator(),
      errorBuilder: (context, error, retry) => RaisedButton(child: Text('Oops'), onPressed: retry),
      dataBuilder: (context, data) => Text(data.toString()),
    );
  }
}
```

The optional `busyBuilder` displays a widget when the `Future` is busy executing. By default, it shows a `CircularProgressIndicator`. By displaying this, we inform the user that the operation is in progress and also prevent the `Future` from being triggered twice accidentally. 

The optional `errorBuilder` displays a widget when the `Future` has failed with an `Error` or `Exception`. This is provided as a parameter, together with a `retry` function that can be called to "retry" the `Future`.

The optional `dataBuilder` displays a widget when the `Future` has succeded. The resulting value of the `Future` is provided as a parameter to the callback. Note that this will be `null` in the case of a `Future<void>`.

### Screen example

To automatically start executing a `Future` upon navigating to a screen, set the `autoStart` parameter to `true` instead of providing an `initialBuilder`. The `busyBuilder` will immediately display.

```
Future<int> myFuture(int first, int second) async {
  await Future.delayed(const Duration(seconds: 1));
  throw Exception('some shit happened');
  return first + second;
}

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Futuristic<int>(
      autoStart: true,
      futureBuilder: () => myFuture(1, 2),
      busyBuilder: (context) => CircularProgressIndicator(),
      onError: (error, retry) => showDialog(...),
      onData: (data) => showDialog(...),
    );
  }
}
```

The optional `onError` callback can be used to handle the error event, such as displaying an alert dialog or sending to a logging provider. It can be used in place of or together with the `errorBuilder`. A `retry` function is provided as a parameter that can be called to "retry" the `Future`. 

The optional `onData` callback can be used to handle a successful result, such as displaying an alert dialog or performing navigation. This can be used in place of or together with the `dataBuilder`.
