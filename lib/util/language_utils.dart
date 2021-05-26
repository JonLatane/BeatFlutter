import 'dart:math';

extension Iterables<E> on Iterable<E> {
  Map<K, List<E>> groupBy<K>(K Function(E) keyFunction) => fold(
      <K, List<E>>{},
      (Map<K, List<E>> map, E element) =>
          map..putIfAbsent(keyFunction(element), () => <E>[]).add(element));

  E maxBy(num Function(E) valueFunction) => (isEmpty)
      ? null
      : reduce((value, element) {
          if (value == null) {
            return element;
          }
          if (valueFunction(element) > valueFunction(value)) {
            return element;
          }
          return value;
        });

  E minBy(num Function(E) valueFunction) => reduce((value, element) {
        if (value == null) {
          return element;
        }
        if (valueFunction(element) < valueFunction(value)) {
          return element;
        }
        return value;
      });

  Iterable<Iterable<E>> chunked(int chunkSize) {
    return _chunkIterable(this, chunkSize);
  }
}

Iterable<Iterable<E>> _chunkIterable<E>(Iterable<E> iterable, int chunkSize) {
  if (iterable.isEmpty) {
    return [];
  }
  return [iterable.take(chunkSize)]
    ..addAll(_chunkIterable(iterable.skip(chunkSize).toList(), chunkSize));
}

extension FancyIterable on Iterable<int> {
  int get maximum => reduce(max);

  int get minimum => reduce(min);
}

extension ListDiff<T> on List<T> {
  List<T> listDiff(List<T> l2) => (this.toSet()..addAll(l2))
      .where((i) => !this.contains(i) || !l2.contains(i))
      .toList();
}

/// Generates enerates an [Iterable] of integers spanning a range
/// from [low] (inclusive) to [high] (exclusive).

Iterable<int> range(int low, int high) sync* {
  for (var i = low; i < high; ++i) {
    yield i;
  }
}

/// Generates a [List] of integers spanning a range
/// from [low] (inclusive) to [high] (exclusive).

List<int> rangeList(int low, int high) => range(low, high).toList();
