import 'package:butterfly/debug/performance/ring_buffer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ring buffer retains newest records and reports loss', () {
    final buffer = RingBuffer<int>(3)..add(1)..add(2)..add(3)..add(4);

    expect(buffer.records, [2, 3, 4]);
    expect(buffer.captured, 4);
    expect(buffer.dropped, 1);
  });

  test('clear resets records and counters', () {
    final buffer = RingBuffer<int>(1)..add(1)..add(2)..clear();

    expect(buffer.records, isEmpty);
    expect(buffer.captured, 0);
    expect(buffer.dropped, 0);
  });
}
