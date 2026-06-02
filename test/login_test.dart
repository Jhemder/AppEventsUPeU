import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pruebas de Login', () {

    test('Usuario vacío retorna error', () {
      String usuario = '';
      String password = '123456';

      bool resultado =
          usuario.trim().isNotEmpty &&
          password.isNotEmpty;

      expect(resultado, false);
    });

    test('Password vacío retorna error', () {
      String usuario = 'kevin';
      String password = '';

      bool resultado =
          usuario.trim().isNotEmpty &&
          password.isNotEmpty;

      expect(resultado, false);
    });

    test('Campos completos permiten login', () {
      String usuario = 'kevin';
      String password = '123456';

      bool resultado =
          usuario.trim().isNotEmpty &&
          password.isNotEmpty;

      expect(resultado, true);
    });

  });
}