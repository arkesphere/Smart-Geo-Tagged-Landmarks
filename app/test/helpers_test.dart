import 'package:flutter_test/flutter_test.dart';
import 'package:geotaggedlandmark/ui/helpers.dart';

void main() {
  test('formatDistance switches to km past 1000 m', () {
    expect(formatDistance(250), '250.0 m');
    expect(formatDistance(2806877.83), '2806.88 km');
  });

  test('scoreColor handles the case where every score is the same', () {
    // Must not divide by zero.
    expect(scoreColor(5, 5, 5), isNotNull);
  });
}
