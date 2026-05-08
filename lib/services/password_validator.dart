/// Password strength validation for sign-up.
class PasswordValidator {
  PasswordValidator._();

  static const int minLength = 8;

  static String? validate(String? password) {
    if (password == null || password.isEmpty) return 'Enter password';
    if (password.length < minLength) return 'At least $minLength characters';
    if (!password.contains(RegExp(r'[A-Z]'))) return 'Include an uppercase letter';
    if (!password.contains(RegExp(r'[a-z]'))) return 'Include a lowercase letter';
    if (!password.contains(RegExp(r'[0-9]'))) return 'Include a number';
    return null;
  }
}
