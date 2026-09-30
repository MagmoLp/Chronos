import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Something outside a screen (a notification tap, a cold start from a
/// notification action) asks the UI to do.
enum AppRequestKind {
  /// Switch to the Today tab.
  showToday,

  /// Switch to the Today tab and open the "Schicht beenden" sheet.
  openFinishSheet,
}

/// One request; [serial] makes repeated requests of the same kind distinct.
@immutable
class AppRequest {
  /// Creates a request.
  const AppRequest(this.kind, this.serial);

  /// What to do.
  final AppRequestKind kind;

  /// Increasing number per request.
  final int serial;

  @override
  bool operator ==(Object other) =>
      other is AppRequest && other.kind == kind && other.serial == serial;

  @override
  int get hashCode => Object.hash(kind, serial);

  @override
  String toString() => 'AppRequest($kind, #$serial)';
}

/// The pending [AppRequest], or `null`. Producers call
/// `ref.read(appRequestProvider.notifier).request(kind)`; the screen that
/// handles a request listens and calls `consume(request)` once done.
final appRequestProvider = NotifierProvider<AppRequestController, AppRequest?>(
  AppRequestController.new,
  name: 'appRequestProvider',
);

/// Holds the pending [AppRequest].
class AppRequestController extends Notifier<AppRequest?> {
  int _serial = 0;

  @override
  AppRequest? build() => null;

  /// Posts a new request (replaces an unhandled one).
  void request(AppRequestKind kind) => state = AppRequest(kind, ++_serial);

  /// Marks [request] as handled (no-op if a newer one is pending).
  void consume(AppRequest request) {
    if (state == request) state = null;
  }
}
