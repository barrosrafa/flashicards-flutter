import 'package:flashi_mobile/domain/models/occlusion_mask.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OcclusionMask', () {
    test('normalizes drag coordinates into [0..100] percentage bounds', () {
      final OcclusionMask mask = OcclusionMask.fromNormalizedDrag(
        id: 'm1',
        startXPercent: -10.0,
        startYPercent: 80.0,
        endXPercent: 45.0,
        endYPercent: 20.0,
        label: 'Aorta',
      );

      expect(mask.x, 0.0);
      expect(mask.y, 20.0);
      expect(mask.width, 45.0);
      expect(mask.height, 60.0);
      expect(mask.hasMinimumArea, isTrue);
    });
  });
}
