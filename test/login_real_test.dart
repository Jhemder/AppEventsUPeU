import 'package:flutter_test/flutter_test.dart';
import 'package:eventos/prefs_helper.dart';

void main() {

  group('Pruebas Reales Login', () {

    test('Username generado correctamente', () {

      final username =
          PrefsHelper.generateUsername(
              'Kevin David Quispe');

      expect(username, 'kevin.quispe');
    });

    test('Admin email correcto', () {

      expect(
        PrefsHelper.adminEmail,
        'admin',
      );
    });

    test('Tipo de usuario admin', () {

      expect(
        PrefsHelper.userTypeAdmin,
        'admin',
      );
    });

    test('Tipo estudiante correcto', () {

      expect(
        PrefsHelper.userTypeStudent,
        'student',
      );
    });

  });

}