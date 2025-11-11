import 'dart:math';

/// Abstract class for implementing reconnection strategies.
///
/// Reconnection strategies determine how and when to attempt reconnection
/// after a WebSocket connection is lost. Implementations can use different
/// algorithms such as exponential backoff, linear backoff, or fixed delays.
///
/// Example:
/// ```dart
/// class CustomStrategy implements ReconnectionStrategy {
///   @override
///   Duration calculateDelay(int attemptNumber) {
///     return Duration(seconds: attemptNumber * 2);
///   }
///
///   @override
///   bool shouldReconnect(int attemptNumber, int maxAttempts) {
///     return attemptNumber <= maxAttempts;
///   }
///
///   @override
///   void reset() {
///     // Reset strategy state
///   }
/// }
/// ```
abstract class ReconnectionStrategy {
  /// Calculates the delay before the next reconnection attempt.
  Duration calculateDelay(int attemptNumber);

  /// Determines if reconnection should be attempted.
  bool shouldReconnect(int attemptNumber, int maxAttempts);

  /// Resets the strategy state.
  void reset();
}

/// Exponential backoff reconnection strategy.
class ExponentialBackoffStrategy implements ReconnectionStrategy {
  /// Initial delay before first reconnection attempt.
  final Duration initialDelay;

  /// Maximum delay between reconnection attempts.
  final Duration maxDelay;

  /// Multiplier for exponential backoff.
  final double multiplier;

  /// Randomization factor to prevent thundering herd.
  final double randomizationFactor;

  /// Creates a new ExponentialBackoffStrategy.
  ExponentialBackoffStrategy({
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(minutes: 5),
    this.multiplier = 2.0,
    this.randomizationFactor = 0.1,
  });

  @override
  Duration calculateDelay(int attemptNumber) {
    // Calculate exponential delay
    final exponentialDelay =
        initialDelay.inMilliseconds *
        (pow(multiplier, attemptNumber - 1).toInt());

    // Apply maximum delay cap
    final cappedDelay = exponentialDelay.clamp(0, maxDelay.inMilliseconds);

    // Add randomization to prevent thundering herd
    final randomFactor =
        1.0 + (randomizationFactor * (Random().nextDouble() * 2 - 1));
    final finalDelay = (cappedDelay * randomFactor).round();

    return Duration(milliseconds: finalDelay);
  }

  @override
  bool shouldReconnect(int attemptNumber, int maxAttempts) {
    return attemptNumber <= maxAttempts;
  }

  @override
  void reset() {
    // No state to reset for exponential strategy
  }

  @override
  String toString() {
    return 'ExponentialBackoffStrategy(initialDelay: $initialDelay, maxDelay: $maxDelay, multiplier: $multiplier)';
  }
}

/// Linear backoff reconnection strategy.
class LinearBackoffStrategy implements ReconnectionStrategy {
  /// Initial delay before first reconnection attempt.
  final Duration initialDelay;

  /// Maximum delay between reconnection attempts.
  final Duration maxDelay;

  /// Linear increment per attempt.
  final Duration increment;

  /// Creates a new LinearBackoffStrategy.
  const LinearBackoffStrategy({
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(minutes: 5),
    this.increment = const Duration(seconds: 1),
  });

  @override
  Duration calculateDelay(int attemptNumber) {
    final linearDelay =
        initialDelay.inMilliseconds +
        (increment.inMilliseconds * (attemptNumber - 1));

    final cappedDelay = linearDelay.clamp(0, maxDelay.inMilliseconds);

    return Duration(milliseconds: cappedDelay);
  }

  @override
  bool shouldReconnect(int attemptNumber, int maxAttempts) {
    return attemptNumber <= maxAttempts;
  }

  @override
  void reset() {
    // No state to reset for linear strategy
  }

  @override
  String toString() {
    return 'LinearBackoffStrategy(initialDelay: $initialDelay, maxDelay: $maxDelay, increment: $increment)';
  }
}

/// Fixed delay reconnection strategy.
class FixedDelayStrategy implements ReconnectionStrategy {
  /// Fixed delay between reconnection attempts.
  final Duration delay;

  /// Creates a new FixedDelayStrategy.
  const FixedDelayStrategy({this.delay = const Duration(seconds: 5)});

  @override
  Duration calculateDelay(int attemptNumber) {
    return delay;
  }

  @override
  bool shouldReconnect(int attemptNumber, int maxAttempts) {
    return attemptNumber <= maxAttempts;
  }

  @override
  void reset() {
    // No state to reset for fixed strategy
  }

  @override
  String toString() {
    return 'FixedDelayStrategy(delay: $delay)';
  }
}

/// No reconnection strategy.
class NoReconnectionStrategy implements ReconnectionStrategy {
  /// Creates a new NoReconnectionStrategy.
  const NoReconnectionStrategy();

  @override
  Duration calculateDelay(int attemptNumber) {
    return Duration.zero;
  }

  @override
  bool shouldReconnect(int attemptNumber, int maxAttempts) {
    return false;
  }

  @override
  void reset() {
    // No state to reset
  }

  @override
  String toString() {
    return 'NoReconnectionStrategy()';
  }
}

/// Factory for creating reconnection strategies.
///
/// This factory provides a convenient way to create different types of
/// reconnection strategies with default or custom parameters.
///
/// Example:
/// ```dart
/// final strategy = ReconnectionStrategyFactory.create(
///   type: ReconnectionStrategyType.exponential,
///   initialDelay: Duration(seconds: 2),
///   maxDelay: Duration(minutes: 10),
/// );
/// ```
class ReconnectionStrategyFactory {
  /// Private constructor to prevent instantiation.
  ReconnectionStrategyFactory._();

  /// Creates a reconnection strategy based on the strategy type.
  static ReconnectionStrategy create({
    ReconnectionStrategyType type = ReconnectionStrategyType.exponential,
    Duration? initialDelay,
    Duration? maxDelay,
    double? multiplier,
    Duration? increment,
    double? randomizationFactor,
  }) {
    switch (type) {
      case ReconnectionStrategyType.exponential:
        return ExponentialBackoffStrategy(
          initialDelay: initialDelay ?? const Duration(seconds: 1),
          maxDelay: maxDelay ?? const Duration(minutes: 5),
          multiplier: multiplier ?? 2.0,
          randomizationFactor: randomizationFactor ?? 0.1,
        );
      case ReconnectionStrategyType.linear:
        return LinearBackoffStrategy(
          initialDelay: initialDelay ?? const Duration(seconds: 1),
          maxDelay: maxDelay ?? const Duration(minutes: 5),
          increment: increment ?? const Duration(seconds: 1),
        );
      case ReconnectionStrategyType.fixed:
        return FixedDelayStrategy(
          delay: initialDelay ?? const Duration(seconds: 5),
        );
      case ReconnectionStrategyType.none:
        return const NoReconnectionStrategy();
    }
  }
}

/// Enum for reconnection strategy types.
enum ReconnectionStrategyType {
  /// Exponential backoff strategy
  exponential,

  /// Linear backoff strategy
  linear,

  /// Fixed delay strategy
  fixed,

  /// No reconnection strategy
  none,
}
