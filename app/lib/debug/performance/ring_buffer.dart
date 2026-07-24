class RingBuffer<T> {
  final int capacity;
  final List<T> _records = [];
  int dropped = 0;
  int captured = 0;

  RingBuffer(this.capacity) : assert(capacity > 0);

  List<T> get records => List.unmodifiable(_records);
  int get length => _records.length;

  void add(T value) {
    captured++;
    if (_records.length == capacity) {
      _records.removeAt(0);
      dropped++;
    }
    _records.add(value);
  }

  void clear() {
    _records.clear();
    dropped = 0;
    captured = 0;
  }
}
