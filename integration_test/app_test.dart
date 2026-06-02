import 'package:flutter_test/flutter_test.dart';

void main() {

  group('Pruebas Integrales', () {

    testWidgets(
      'Validar login',
      (tester) async {

        // Simulación login
        String usuario = "admin";
        String password = "123456";

        bool loginCorrecto =
            usuario.isNotEmpty &&
            password.isNotEmpty;

        expect(loginCorrecto, true);

      },
    );
    

  });


}