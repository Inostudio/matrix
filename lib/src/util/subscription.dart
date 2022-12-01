import 'dart:async';

bool doAllSubInMap<T, E>(
  Map<T, E> subMap,
  void Function(MapEntry<T, E>) action,
) {
  try {
    subMap.entries.forEach(action);
    return true;
  } catch (e) {
    return false;
  }
}

Future<bool> doAsyncAllSubInMap<T, E>(
  Map<T, E> subMap,
  Future<void> Function(MapEntry<T, E>) action,
) async {
  try {
    final futureList = subMap.entries.map((e) => action(e));
    await Future.wait(futureList);
    return true;
  } catch (e) {
    return false;
  }
}

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
