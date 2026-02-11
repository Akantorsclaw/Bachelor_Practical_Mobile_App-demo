/// Validates an email text field.
String? validateEmail(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Enter your email';
  if (!text.contains('@') || !text.contains('.')) return 'Enter a valid email';
  return null;
}

/// Validates a password text field.
String? validatePassword(String? value) {
  final text = value ?? '';
  if (text.isEmpty) return 'Enter your password';
  if (text.length < 6) return 'Minimum 6 characters';
  return null;
}
