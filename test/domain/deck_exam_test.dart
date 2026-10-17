import 'package:flashi_mobile/domain/models/deck_exam.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeckExam Model & Priority Boost', () {
    test('parses fromJson with title/examName and targetDate aliases', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'id': 'exam-123',
        'user_id': 'u1',
        'deck_id': 'd1',
        'title': 'ENEM 2026',
        'exam_date': '2026-11-05',
        'priority_level': 'high',
        'status': 'active',
        'usn': 42,
      };

      final DeckExam exam = DeckExam.fromJson(json);

      expect(exam.id, 'exam-123');
      expect(exam.title, 'ENEM 2026');
      expect(exam.examName, 'ENEM 2026');
      expect(exam.examDate, '2026-11-05');
      expect(exam.targetDate, '2026-11-05');
      expect(exam.priorityLevel, ExamPriority.high);
      expect(exam.priority, ExamPriority.high);
      expect(exam.status, ExamStatus.active);
      expect(exam.usn, 42);

      final Map<String, dynamic> serialized = exam.toJson();
      expect(serialized['title'], 'ENEM 2026');
      expect(serialized['exam_date'], '2026-11-05');
    });

    test('computes interval boost multipliers correctly based on days remaining', () {
      final DateTime now = DateTime.now();

      final DeckExam examIn5Days = DeckExam(
        id: 'e1',
        userId: 'u1',
        deckId: 'd1',
        title: 'Immediate Test',
        examDate: now.add(const Duration(days: 5)).toIso8601String().split('T').first,
      );

      final DeckExam examIn20Days = DeckExam(
        id: 'e2',
        userId: 'u1',
        deckId: 'd1',
        title: 'Monthly Test',
        examDate: now.add(const Duration(days: 20)).toIso8601String().split('T').first,
      );

      final DeckExam examIn60Days = DeckExam(
        id: 'e3',
        userId: 'u1',
        deckId: 'd1',
        title: 'Future Exam',
        examDate: now.add(const Duration(days: 60)).toIso8601String().split('T').first,
      );

      expect(examIn5Days.computeIntervalBoostMultiplier(), 1.5);
      expect(examIn20Days.computeIntervalBoostMultiplier(), 1.2);
      expect(examIn60Days.computeIntervalBoostMultiplier(), 1.0);
    });
  });
}
