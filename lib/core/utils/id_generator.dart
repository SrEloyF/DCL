class IdGenerator {
  int _counter = 0;

  String next(String prefix) => '${prefix}_${_counter++}';
}
