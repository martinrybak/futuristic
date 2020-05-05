enum Backoff {
  linear,
  exponential,
}

class Retry<T> {
  /// Number of times to retry. Defaults to 3.
  final int repeat;

  /// Time to wait before retrying. Defaults to 1 second. Increases according to [backoff].
  final Duration delay;

  /// How much to increase [delay] with every retry. Defaults to [Linear].
  final Backoff backoff;

  /// Whether to retry given the caught error (usually an [Error] or [Exception]). Defaults to true.
  final bool Function(Object) filter;

  Retry({
    this.repeat = 3,
    this.delay = const Duration(seconds: 1),
    this.backoff = Backoff.linear,
    bool Function(Object) filter,
  }) : filter = filter ?? ((e) => true);

  Retry copyWith({int repeat, Duration delay}) {
    return Retry(
      repeat: repeat ?? this.repeat,
      delay: delay ?? this.delay,
      backoff: backoff,
      filter: filter,
    );
  }

  /// Executes [future] and if an error is thrown, asks [retry].[filter] whether to continue.
  /// Retries [retry].[repeat] times after a [retry].[delay] increasing according to [retry].[backoff].
  /// If an exception is still caught at this point, rethrows.
  static Future<T> execute<T>(Future<T> future, Retry retry, Function(Object, Duration, int) onRetry) async {
    assert(future != null);

    try {
      return await future;
    } catch (e) {
      if (retry != null && retry.repeat > 0 && retry.filter(e)) {
        if (onRetry != null) {
          onRetry(e, retry.delay, retry.repeat - 1);
        }
        await Future.delayed(retry.delay);
        return await execute(
          future,
          retry.copyWith(
            repeat: retry.repeat - 1,
            delay: retry.backoff == Backoff.exponential ? retry.delay * 2 : retry.delay,
          ),
          onRetry,
        );
      } else {
        rethrow;
      }
    }
  }
}
