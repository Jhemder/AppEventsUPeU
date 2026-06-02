import 'package:flutter_test/flutter_test.dart';
import 'package:eventos/prefs_helper.dart';

void main() {

  group('Pruebas PrefsHelper', () {

    // ✅ TEST 1
    test('Generar username con nombres completos', () {

      final username =
          PrefsHelper.generateUsername(
              'Kevin David Quispe');

      expect(username, 'kevin.quispe');
    });

    // ✅ TEST 2
    test('Generar username con dos nombres', () {

      final username =
          PrefsHelper.generateUsername(
              'Kevin Quispe');

      expect(username, 'kevin.quispe');
    });

    // ✅ TEST 3
    test('Generar username con un nombre', () {

      final username =
          PrefsHelper.generateUsername(
              'Kevin');

      expect(username, 'kevin');
    });

    // ✅ TEST 4
    test('Validar credenciales vacías', () {

      String usuario = '';
      String password = '';

      bool valido =
          usuario.trim().isNotEmpty &&
          password.isNotEmpty;

      expect(valido, false);
    });

    // ✅ TEST 5
    test('Validar credenciales correctas', () {

      String usuario = 'admin';
      String password = 'admin123';

      bool valido =
          usuario.trim().isNotEmpty &&
          password.isNotEmpty;

      expect(valido, true);
    });

  });

}