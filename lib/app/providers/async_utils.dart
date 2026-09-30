import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Combines two async values synchronously: an error of either wins, data
/// needs both, anything else is loading. Keeps derived providers free of
/// loading flicker when one source emits.
AsyncValue<R> combineAsync2<A, B, R>(
  AsyncValue<A> a,
  AsyncValue<B> b,
  R Function(A a, B b) combine,
) {
  if (a.hasError) {
    return AsyncError<R>(a.error!, a.stackTrace ?? StackTrace.empty);
  }
  if (b.hasError) {
    return AsyncError<R>(b.error!, b.stackTrace ?? StackTrace.empty);
  }
  if (a.hasValue && b.hasValue) {
    return AsyncData<R>(combine(a.requireValue, b.requireValue));
  }
  return AsyncLoading<R>();
}

/// Three-way variant of [combineAsync2].
AsyncValue<R> combineAsync3<A, B, C, R>(
  AsyncValue<A> a,
  AsyncValue<B> b,
  AsyncValue<C> c,
  R Function(A a, B b, C c) combine,
) => combineAsync2<(A, B), C, R>(
  combineAsync2<A, B, (A, B)>(a, b, (x, y) => (x, y)),
  c,
  (ab, z) => combine(ab.$1, ab.$2, z),
);
