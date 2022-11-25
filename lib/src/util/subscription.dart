import 'dart:async';

Future<bool> closeAllSubInMap<T>(Map<T, StreamSubscription> subMap) async {
  try {
    for (final e in subMap.entries) {
      await e.value.cancel();
    }
    return true;
  } catch (e) {
    return false;
  }
}

Future<bool> closeOneSubInMap<T>(
  Map<T, StreamSubscription> subMap,
  T value,
) async {
  try {
    await subMap[value]?.cancel();
    return true;
  } catch (e) {
    return false;
  }
}
