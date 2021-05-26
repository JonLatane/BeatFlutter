class MethodCache<KeyType, ResultType> {
  bool enable = true;
  Map<KeyType, ResultType> _data = Map();

  ResultType putIfAbsent(KeyType key, ResultType Function() computation) {
    if (!enable) {
      return computation();
    }
    return _data.putIfAbsent(key, () => computation());
  }

  clear() {
    _data.clear();
  }
}

/// Wrapper around [List<dynamic>] that calculates == and hashCode.
class ArgumentList {
  final List<dynamic> arguments;

  ArgumentList(this.arguments);

  @override
  bool operator ==(other) =>
      other is ArgumentList &&
      arguments.length == other.arguments.length &&
      !arguments
          .asMap()
          .entries
          .any((entry) => other.arguments[entry.key] != entry.value);

  @override
  int get hashCode {
    int result;
    arguments.forEach((arg) {
      if (result == null) {
        result = arg.hashCode;
      } else {
        result = result ^ arg.hashCode;
      }
    });
    return result ?? 0;
  }
}
