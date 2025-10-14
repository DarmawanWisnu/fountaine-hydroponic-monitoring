class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }

    final re = RegExp(r"^[\w\.-]+@[\w\.-]+\.\w+$");
    if (!re.hasMatch(value)) {
      return 'Format email tidak valid';
    }

    return null; // ✅ valid
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }

    if (value.length < 8) {
      return 'Password minimal 8 karakter';
    }

    return null; // ✅ valid
  }
}

bool isValidEmail(String email) => Validators.email(email) == null;
bool isStrongPassword(String pw) => Validators.password(pw) == null;
