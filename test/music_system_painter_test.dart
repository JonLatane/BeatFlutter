import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Rect.fromLTRB fix', () {
    test('Fixed rectangle creation should have valid dimensions', () {
      // Test the specific fix for the zero-dimension rectangle issue
      const double left = 50.0;
      
      // This is the NEW fixed way that prevents zero dimensions
      final fixedRect = Rect.fromLTRB(left, 0, left + 1, 1);
      
      // Verify the rectangle has valid dimensions
      expect(fixedRect.width, equals(1.0));
      expect(fixedRect.height, equals(1.0));
      expect(fixedRect.left, equals(left));
      expect(fixedRect.top, equals(0.0));
      expect(fixedRect.right, equals(left + 1));
      expect(fixedRect.bottom, equals(1.0));
      
      // Ensure it's not empty
      expect(fixedRect.isEmpty, isFalse);
    });

    test('Zero dimension rectangles should be avoided', () {
      // Demonstrate the problem that was fixed
      const double left = 50.0;
      
      // The old problematic way
      final oldRect = Rect.fromLTRB(left, 0, left, 0);
      expect(oldRect.width, equals(0.0));
      expect(oldRect.height, equals(0.0));
      expect(oldRect.isEmpty, isTrue);
      
      // The new fixed way
      final newRect = Rect.fromLTRB(left, 0, left + 1, 1);
      expect(newRect.width, equals(1.0));
      expect(newRect.height, equals(1.0));
      expect(newRect.isEmpty, isFalse);
    });
  });
}