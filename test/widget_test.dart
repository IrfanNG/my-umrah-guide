import 'package:flutter_test/flutter_test.dart';
import 'package:my_umrah_guide/features/practice/domain/user_profile.dart';

void main() {
  test('maps user profile age into analytics age group', () {
    UserProfile profileWithAge(int age) {
      return UserProfile(
        uid: 'u1',
        email: 'user@example.com',
        role: UserRole.user,
        age: age,
        abilityLevel: AbilityLevel.medium,
        healthConditions: '',
      );
    }

    expect(profileWithAge(24).ageGroup, '18-29');
    expect(profileWithAge(36).ageGroup, '30-44');
    expect(profileWithAge(52).ageGroup, '45-59');
    expect(profileWithAge(67).ageGroup, '60+');
  });
}
