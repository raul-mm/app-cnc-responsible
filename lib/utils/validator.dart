class Validator {
  static String? validateEmail(String value) {
    Pattern pattern = r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+';
    RegExp regex = RegExp(pattern as String);
    if (!regex.hasMatch(value)) {
      return 'Introduce un correo electrónico válido.';
    } else {
      return null;
    }
  }

  static String? validateDropDefaultData(value) {
    if (value == null) {
      return 'Please select an item.';
    } else {
      return null;
    }
  }

  static String? validatePassword(String value) {
    Pattern pattern = r'^.{6,}$';
    RegExp regex = RegExp(pattern as String);
    if (!regex.hasMatch(value)) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    } else {
      return null;
    }
  }

  static String? validateUserName(String value) {
    Pattern pattern = r'^.{6,}$';
    RegExp regex = RegExp(pattern as String);
    if (!regex.hasMatch(value)) {
      return 'Ingresa tu usuario';
    } else {
      return null;
    }
  }

  static String? validateName(String value) {
    if (value.length < 3) {
      return '🚩 Username is too short.';
    } else {
      return null;
    }
  }

  static String? validateText(String value) {
    if (value.isEmpty) {
      return '🚩 Ingrese un texto.';
    } else {
      return null;
    }
  }

  static String? validateDx(String value) {
    if (value.isEmpty) {
      return '🚩 Seleccione un diagnóstico.';
    } else {
      return null;
    }
  }

  static String? validatePhoneNumber(String value) {
    if (value.length != 11) {
      return '🚩 Phone number is not valid.';
    } else {
      return null;
    }
  }

  static String? validateOxigeno(String value) {
    if (value.isEmpty) {
      return '🚩 Ingresa el oxígeno.';
    } else {
      return null;
    }
  }
}
