# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2024-12-19

### Added
- Initial stable release of flutter_websocket_plus package
- Example GIF demonstration in README
- Platform-specific WebSocket connection helpers (native vs web)
- Comprehensive message statistics (sent, received, errors, ping/pong counts)
- Heartbeat health metrics and latency tracking
- Heartbeat timeout detection and failure tracking
- Enhanced queue statistics (message type breakdown, utilization percentage)
- Batch message processing for improved performance
- Safe event and state controller helpers to prevent disposal errors
- Stream subscription tracking for proper resource cleanup
- Comprehensive example.dart demonstrating all features
- Funding information in pubspec.yaml
- Analysis options configuration for better code quality
- WebSocket connection management with automatic reconnection logic
- Message queuing system for reliable message delivery
- Support for all 6 platforms: iOS, Android, Web, Windows, macOS, Linux
- WASM compatibility for web platform
- Comprehensive error handling and connection state management
- Configurable reconnection strategies and timeouts
- Message serialization and deserialization support
- Event-driven architecture with stream-based communication
- Heartbeat support with ping/pong mechanism
- Comprehensive statistics and monitoring
- Platform-specific WebSocket implementation (native vs web)
- Priority-based message queuing
- Message deduplication support
- Complete documentation with examples
- Null safety support
- Platform-specific optimizations

### Changed
- Updated Dart SDK requirement to >=3.8.0
- Improved JSON serialization using jsonEncode instead of toString()
- Enhanced statistics with detailed connection and queue metrics
- Optimized message queue sorting algorithm
- Improved error handling with comprehensive error tracking
- Updated package topics to exactly 5 as per pub.dev requirements
- Enhanced CHANGELOG with detailed feature documentation
- Code quality improvements: Zero analysis issues in lib/ code
- Performance optimizations: Queue operations and batch processing
- Documentation improvements: Comprehensive example with all features demonstrated
- Error recovery improvements: Better error handling and retry mechanisms
- Resource management improvements: Proper stream subscription cancellation and disposal

### Fixed
- Fixed disposal error where stream controllers were closed while still receiving events
- Fixed JSON message serialization to properly encode JSON data
- Fixed code style issues (prefer_const_constructors, prefer_initializing_formals, prefer_interpolation_to_compose_strings)
- Fixed WebSocket connection headers support for native platforms
- Fixed heartbeat pong response handling
- Fixed message queue statistics calculation

## [0.0.1] - 2024-12-19

### Added
- Initial release of flutter_websocket_plus package
- WebSocket connection management with automatic reconnection logic
- Message queuing system for reliable message delivery
- Support for all 6 platforms: iOS, Android, Web, Windows, macOS, Linux
- WASM compatibility for web platform
- Comprehensive error handling and connection state management
- Configurable reconnection strategies and timeouts
- Message serialization and deserialization support
- Event-driven architecture with stream-based communication
- Heartbeat support with ping/pong mechanism
- Comprehensive statistics and monitoring
- Platform-specific WebSocket implementation (native vs web)
- Batch message processing for optimal performance
- Priority-based message queuing
- Message deduplication support
- Extensive test coverage for all platforms
- Complete documentation with examples
- Null safety support
- Platform-specific optimizations
- Built with Flutter 3.0+ compatibility
- Dart 3.8+ support with null safety
- Comprehensive platform support matrix
- Optimized for performance and memory usage
- Follows Flutter and Dart best practices
- Full test coverage with unit, integration, and platform tests
- Zero analysis issues in lib code
- Pana score optimized for pub.dev publishing

[Unreleased]: https://github.com/Dhia-Bechattaoui/flutter_websocket_plus/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Dhia-Bechattaoui/flutter_websocket_plus/releases/tag/v0.1.0
[0.0.1]: https://github.com/Dhia-Bechattaoui/flutter_websocket_plus/releases/tag/v0.0.1
