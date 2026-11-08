/// Strict whitelist input validation — same limits as the website.
/// Every user-facing field in the app must go through these validators.
class Validators {
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _nameRegex = RegExp(r"^[\p{L} .'\-]+$", unicode: true);
  static final RegExp _codeRegex = RegExp(r'^\d{6}$');

  static String? validateName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Name is required';
    if (v.length > 50) return 'Name must be 50 characters or less';
    if (!_nameRegex.hasMatch(v)) return 'Name may contain letters only';
    return null;
  }

  static String? validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (v.length > 150) return 'Email is too long';
    if (!_emailRegex.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  static String? validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    if (v.length > 72) return 'Password is too long';
    return null;
  }

  static String? validateCode(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Code is required';
    if (!_codeRegex.hasMatch(v)) return 'Enter the 6-digit code';
    return null;
  }
}
