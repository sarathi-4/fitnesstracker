/// Reusable input validators for JAIHIND Authentication
class AppValidators {
  /// Validates Full Name (Required, minimum 2 characters)
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  /// Validates Username:
  /// - Minimum 3 characters
  /// - Starts with a letter
  /// - Allows letters, numbers, and underscore
  /// Example: example_run
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a username';
    }
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return 'Username must be at least 3 characters';
    }
    final firstChar = trimmed[0];
    if (!RegExp(r'^[a-zA-Z]$').hasMatch(firstChar)) {
      return 'Username must start with a letter';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmed)) {
      return 'Only letters, numbers, and underscores allowed';
    }
    return null;
  }

  /// Validates Email Address:
  /// - Must be a valid email format
  /// Example: example@gmail.com
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }
    final trimmed = value.trim();
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates Password:
  /// - Minimum 6 characters
  /// - At least one uppercase letter
  /// - At least one lowercase letter
  /// - At least one number
  /// - At least one special character
  /// Example: Example@123
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Include at least one uppercase letter (A-Z)';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Include at least one lowercase letter (a-z)';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Include at least one number (0-9)';
    }
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-=+~/\\\[\]]').hasMatch(value)) {
      return 'Include at least one special character (!@#\$%^&*)';
    }
    return null;
  }

  /// Validates Confirm Password:
  /// - Must match password exactly
  static String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    if (confirmPassword != password) {
      return 'Passwords do not match';
    }
    return null;
  }
}
