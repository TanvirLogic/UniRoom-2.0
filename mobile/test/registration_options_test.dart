import 'package:flutter_test/flutter_test.dart';
import 'package:uniroom_mobile/models/registration_options_model.dart';

void main() {
  group('RegistrationOptionsModel Tests', () {
    test('Fallback model contains expected Uttara University structure', () {
      final model = RegistrationOptionsModel.fallback();

      expect(model.universities.isNotEmpty, isTrue);
      final uu = model.universities.first;
      expect(uu.code, 'UU');
      expect(uu.name, 'Uttara University');
      expect(uu.domain, 'uttara.edu.bd');

      // Check departments
      expect(uu.departments.any((d) => d.code == 'CSE'), isTrue);
      final cse = uu.departments.firstWhere((d) => d.code == 'CSE');
      expect(cse.batches.any((b) => b.name == '68'), isTrue);
      final batch68 = cse.batches.firstWhere((b) => b.name == '68');
      expect(batch68.sections, containsAll(['A', 'B', 'C']));
    });

    test('Parses backend JSON response correctly', () {
      final sampleJson = {
        'universities': [
          {
            'id': 'UU',
            'code': 'UU',
            'name': 'Uttara University',
            'domain': 'uttara.edu.bd',
            'departments': [
              {
                'id': 'CSE',
                'code': 'CSE',
                'name': 'Computer Science & Engineering',
                'batches': [
                  {
                    'id': 'batch-1',
                    'name': '68',
                    'sections': ['A', 'B', 'C'],
                  },
                ],
              },
            ],
          },
        ],
      };

      final parsed = RegistrationOptionsModel.fromJson(sampleJson);
      expect(parsed.universities.length, 1);
      expect(parsed.universities.first.code, 'UU');
      expect(parsed.universities.first.departments.length, 1);
      expect(parsed.universities.first.departments.first.code, 'CSE');
      expect(parsed.universities.first.departments.first.batches.first.name, '68');
      expect(parsed.universities.first.departments.first.batches.first.sections, ['A', 'B', 'C']);
    });
  });
}
