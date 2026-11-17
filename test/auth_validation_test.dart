import 'package:flutter_test/flutter_test.dart';
import 'package:jaihind/core/services/auth_service.dart';
import 'package:jaihind/core/utils/validators.dart';

void main() {
  group('JAIHIND Authentication - Field & Rule Validation Suite', () {
    // 1. FULL NAME VALIDATION
    test('Full Name: Rejects empty or too short names', () {
      expect(AppValidators.validateFullName(null), 'Please enter your full name');
      expect(AppValidators.validateFullName(''), 'Please enter your full name');
      expect(AppValidators.validateFullName('   '), 'Please enter your full name');
      expect(AppValidators.validateFullName('A'), 'Name must be at least 2 characters');
      expect(AppValidators.validateFullName('Sarathi'), isNull);
      expect(AppValidators.validateFullName('Jane Doe'), isNull);
    });

    // 2. USERNAME VALIDATION (Requirement: min 3 chars, letters/nums/underscore, must start with letter)
    test('Username: Must start with a letter and have min 3 characters', () {
      expect(AppValidators.validateUsername(null), 'Please enter a username');
      expect(AppValidators.validateUsername(''), 'Please enter a username');
      expect(AppValidators.validateUsername('ab'), 'Username must be at least 3 characters');
      expect(AppValidators.validateUsername('1abc'), 'Username must start with a letter');
      expect(AppValidators.validateUsername('_abc'), 'Username must start with a letter');
      expect(AppValidators.validateUsername('user-name'), 'Only letters, numbers, and underscores allowed');
      expect(AppValidators.validateUsername('user name'), 'Only letters, numbers, and underscores allowed');
      expect(AppValidators.validateUsername('example_run'), isNull);
      expect(AppValidators.validateUsername('runner123'), isNull);
      expect(AppValidators.validateUsername('sarathi_2026'), isNull);
    });

    // 3. EMAIL VALIDATION (Requirement: Valid email format, reject invalid)
    test('Email: Validates format properly', () {
      expect(AppValidators.validateEmail(null), 'Please enter your email address');
      expect(AppValidators.validateEmail(''), 'Please enter your email address');
      expect(AppValidators.validateEmail('invalidemail'), 'Please enter a valid email address');
      expect(AppValidators.validateEmail('invalid@'), 'Please enter a valid email address');
      expect(AppValidators.validateEmail('invalid@domain'), 'Please enter a valid email address');
      expect(AppValidators.validateEmail('@domain.com'), 'Please enter a valid email address');
      expect(AppValidators.validateEmail('example@gmail.com'), isNull);
      expect(AppValidators.validateEmail('user.name+tag@sub.example.co.in'), isNull);
    });

    // 4. PASSWORD COMPLEXITY (Requirement: Min 6 chars, >= 1 uppercase, >= 1 lowercase, >= 1 number, >= 1 special char)
    test('Password: Enforces complexity (Example@123)', () {
      expect(AppValidators.validatePassword(null), 'Please enter a password');
      expect(AppValidators.validatePassword(''), 'Please enter a password');
      expect(AppValidators.validatePassword('Ex1!'), 'Password must be at least 6 characters');
      expect(AppValidators.validatePassword('example@123'), 'Include at least one uppercase letter (A-Z)');
      expect(AppValidators.validatePassword('EXAMPLE@123'), 'Include at least one lowercase letter (a-z)');
      expect(AppValidators.validatePassword('Example@abc'), 'Include at least one number (0-9)');
      expect(AppValidators.validatePassword('Example1234'), 'Include at least one special character (!@#\$%^&*)');
      expect(AppValidators.validatePassword('Example@123'), isNull);
      expect(AppValidators.validatePassword('Run#2026_Go'), isNull);
    });

    // 5. CONFIRM PASSWORD MATCH
    test('Confirm Password: Enforces exact match', () {
      expect(
        AppValidators.validateConfirmPassword('Example@123', null),
        'Please confirm your password',
      );
      expect(
        AppValidators.validateConfirmPassword('Example@123', ''),
        'Please confirm your password',
      );
      expect(
        AppValidators.validateConfirmPassword('Example@123', 'Different@123'),
        'Passwords do not match',
      );
      expect(
        AppValidators.validateConfirmPassword('Example@123', 'Example@123'),
        isNull,
      );
    });

    // 6. DEMO CREDENTIAL VALIDATION
    test('Demo Credentials: Correct credentials succeed, wrong password fails', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final validResult = await AuthService.instance.login(
        email: 'demo@jaihind.com',
        password: 'Jaihind@2026',
      );
      expect(validResult.success, isTrue);

      final invalidResult = await AuthService.instance.login(
        email: 'demo@jaihind.com',
        password: 'WrongPassword@123',
      );
      expect(invalidResult.success, isFalse);
      expect(invalidResult.errorMessage, 'Incorrect password. Please try again.');
    });
  });
}
