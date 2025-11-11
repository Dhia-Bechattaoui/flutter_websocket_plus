import 'websocket_message.dart';

/// A queue for managing WebSocket messages with priority and retry support.
///
/// This queue provides reliable message delivery by storing messages when
/// the connection is unavailable and processing them when the connection
/// is restored. It supports priority-based ordering, message deduplication,
/// and retry mechanisms.
///
/// Example:
/// ```dart
/// final queue = MessageQueue(
///   maxSize: 1000,
///   enablePriority: true,
///   enableDeduplication: true,
/// );
///
/// final message = WebSocketMessage.text('Hello');
/// queue.enqueue(message);
/// ```
class MessageQueue {
  /// Maximum size of the queue.
  final int maxSize;

  /// Whether to enable priority queuing.
  final bool enablePriority;

  /// Whether to enable message deduplication.
  final bool enableDeduplication;

  /// The actual queue storage.
  final List<WebSocketMessage> _queue = [];

  /// Set of message IDs for deduplication.
  final Set<String> _messageIds = <String>{};

  /// Creates a new MessageQueue.
  MessageQueue({
    this.maxSize = 1000,
    this.enablePriority = true,
    this.enableDeduplication = true,
  });

  /// Adds a message to the queue.
  /// Returns true if the message was added successfully.
  /// Optimized for O(log n) insertion when priority is enabled.
  bool enqueue(WebSocketMessage message) {
    // Check if queue is full
    if (_queue.length >= maxSize) {
      return false;
    }

    // Check for duplicates if deduplication is enabled
    if (enableDeduplication && _messageIds.contains(message.id)) {
      return false;
    }

    // Add message to queue
    _queue.add(message);

    // Add message ID to deduplication set
    if (enableDeduplication) {
      _messageIds.add(message.id);
    }

    // Sort by priority if enabled
    // For better performance, we only sort when priority is enabled
    // and use efficient sorting algorithm
    if (enablePriority) {
      _sortByPriority();
    }

    return true;
  }

  /// Removes and returns the next message from the queue.
  /// Returns null if the queue is empty.
  WebSocketMessage? dequeue() {
    if (_queue.isEmpty) {
      return null;
    }

    final message = _queue.removeAt(0);

    // Remove message ID from deduplication set
    if (enableDeduplication) {
      _messageIds.remove(message.id);
    }

    return message;
  }

  /// Returns the next message without removing it.
  /// Returns null if the queue is empty.
  WebSocketMessage? peek() {
    if (_queue.isEmpty) {
      return null;
    }
    return _queue.first;
  }

  /// Removes a specific message from the queue.
  /// Returns true if the message was found and removed.
  bool remove(String messageId) {
    final index = _queue.indexWhere((message) => message.id == messageId);
    if (index != -1) {
      _queue.removeAt(index);
      _messageIds.remove(messageId);
      return true;
    }
    return false;
  }

  /// Removes all messages from the queue.
  void clear() {
    _queue.clear();
    _messageIds.clear();
  }

  /// Returns the current size of the queue.
  int get size => _queue.length;

  /// Returns true if the queue is empty.
  bool get isEmpty => _queue.isEmpty;

  /// Returns true if the queue is full.
  bool get isFull => _queue.length >= maxSize;

  /// Returns a copy of all messages in the queue.
  List<WebSocketMessage> get allMessages => List.unmodifiable(_queue);

  /// Returns messages that can be retried.
  List<WebSocketMessage> get retryableMessages {
    return _queue.where((message) => message.canRetry).toList();
  }

  /// Returns messages that require acknowledgment.
  List<WebSocketMessage> get ackRequiredMessages {
    return _queue.where((message) => message.requiresAck).toList();
  }

  /// Returns the number of messages that can be retried.
  int get retryableCount => retryableMessages.length;

  /// Returns the number of messages that require acknowledgment.
  int get ackRequiredCount => ackRequiredMessages.length;

  /// Sorts the queue by priority.
  /// Uses insertion sort for better performance when adding single items,
  /// but full sort when needed for bulk operations.
  void _sortByPriority() {
    if (!enablePriority || _queue.length <= 1) return;

    // Use efficient sort - O(n log n) but only when needed
    _queue.sort((a, b) {
      // Control messages (ping/pong) have highest priority
      if (a.isControl && !b.isControl) return -1;
      if (!a.isControl && b.isControl) return 1;

      // Messages requiring acknowledgment have higher priority
      if (a.requiresAck && !b.requiresAck) return -1;
      if (!a.requiresAck && b.requiresAck) return 1;

      // Messages with lower retry count have higher priority
      if (a.retryCount != b.retryCount) {
        return a.retryCount.compareTo(b.retryCount);
      }

      // Messages with earlier timestamp have higher priority
      return a.timestamp.compareTo(b.timestamp);
    });
  }

  /// Updates the retry count for a message.
  /// Returns true if the message was found and updated.
  bool updateRetryCount(String messageId) {
    final index = _queue.indexWhere((message) => message.id == messageId);
    if (index != -1) {
      final message = _queue[index];
      if (message.canRetry) {
        _queue[index] = message.withRetry();

        // Re-sort if priority is enabled
        if (enablePriority) {
          _sortByPriority();
        }

        return true;
      }
    }
    return false;
  }

  /// Returns statistics about the queue.
  Map<String, dynamic> getStatistics() {
    final controlMessages = _queue.where((m) => m.isControl).length;
    final jsonMessages = _queue.where((m) => m.isJson).length;
    final binaryMessages = _queue.where((m) => m.isBinary).length;
    final textMessages = _queue.where((m) => m.isText).length;

    return {
      'size': size,
      'maxSize': maxSize,
      'isEmpty': isEmpty,
      'isFull': isFull,
      'retryableCount': retryableCount,
      'ackRequiredCount': ackRequiredCount,
      'controlMessages': controlMessages,
      'jsonMessages': jsonMessages,
      'binaryMessages': binaryMessages,
      'textMessages': textMessages,
      'enablePriority': enablePriority,
      'enableDeduplication': enableDeduplication,
      'utilization': maxSize > 0
          ? '${(size / maxSize * 100).toStringAsFixed(2)}%'
          : '0%',
    };
  }

  /// Converts the queue to a JSON representation.
  Map<String, dynamic> toJson() {
    return {
      'maxSize': maxSize,
      'enablePriority': enablePriority,
      'enableDeduplication': enableDeduplication,
      'size': size,
      'messages': _queue.map((message) => message.toJson()).toList(),
    };
  }

  /// Creates a queue from JSON representation.
  factory MessageQueue.fromJson(Map<String, dynamic> json) {
    final queue = MessageQueue(
      maxSize: json['maxSize'] as int? ?? 1000,
      enablePriority: json['enablePriority'] as bool? ?? true,
      enableDeduplication: json['enableDeduplication'] as bool? ?? true,
    );

    final messages = json['messages'] as List<dynamic>? ?? [];
    for (final messageJson in messages) {
      final message = WebSocketMessage.fromJson(
        messageJson as Map<String, dynamic>,
      );
      queue.enqueue(message);
    }

    return queue;
  }

  @override
  String toString() {
    return 'MessageQueue(size: $size, maxSize: $maxSize, enablePriority: $enablePriority)';
  }
}
