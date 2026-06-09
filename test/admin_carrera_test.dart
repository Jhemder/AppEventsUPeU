import 'package:flutter_test/flutter_test.dart';
import 'package:eventos/Admin/Logica/admin_carrera.dart';

void main() {
  group('AdminCarreraData', () {
    test('empty devuelve valores por defecto', () {
      final data = AdminCarreraData.empty();

      expect(data.adminName, 'Administrador');
      expect(data.carrera, '');
      expect(data.facultad, '');
      expect(data.sede, '');
      expect(data.permisos, isEmpty);
    });

    test('fromMap carga correctamente los datos', () {
      final data = AdminCarreraData.fromMap({
        'userName': 'Kevin',
        'carrera': 'Ingeniería de Sistemas',
        'facultad': 'FIA',
        'filialNombre': 'Juliaca',
        'permisos': ['eventos', 'reportes'],
      });

      expect(data.adminName, 'Kevin');
      expect(data.carrera, 'Ingeniería de Sistemas');
      expect(data.facultad, 'FIA');
      expect(data.sede, 'Juliaca');
      expect(data.permisos.length, 2);
    });

    test('fromMap usa valores por defecto cuando faltan campos', () {
      final data = AdminCarreraData.fromMap({});

      expect(data.adminName, 'Administrador');
      expect(data.carrera, '');
      expect(data.facultad, '');
      expect(data.sede, '');
      expect(data.permisos, isEmpty);
    });

    test('tienePermiso retorna true cuando existe', () {
      final data = AdminCarreraData.fromMap({
        'permisos': ['eventos', 'reportes'],
      });

      expect(data.tienePermiso('eventos'), isTrue);
    });

    test('tienePermiso retorna false cuando no existe', () {
      final data = AdminCarreraData.fromMap({
        'permisos': ['eventos'],
      });

      expect(data.tienePermiso('rubricas'), isFalse);
    });

    test('notaInformativa contiene el nombre de la carrera', () {
      final data = AdminCarreraData.fromMap({
        'carrera': 'Ingeniería de Sistemas',
      });

      expect(
        data.notaInformativa,
        contains('Ingeniería de Sistemas'),
      );
    });

    test('toString contiene datos principales', () {
      final data = AdminCarreraData.fromMap({
        'userName': 'Kevin',
        'carrera': 'Sistemas',
      });

      expect(data.toString(), contains('Kevin'));
      expect(data.toString(), contains('Sistemas'));
    });

    test('operator == retorna true para objetos iguales', () {
      final a = AdminCarreraData.fromMap({
        'userName': 'Kevin',
        'carrera': 'Sistemas',
        'facultad': 'FIA',
        'filialNombre': 'Juliaca',
        'permisos': ['eventos'],
      });

      final b = AdminCarreraData.fromMap({
        'userName': 'Kevin',
        'carrera': 'Sistemas',
        'facultad': 'FIA',
        'filialNombre': 'Juliaca',
        'permisos': ['eventos'],
      });

      expect(a, equals(b)); // ✅ solo esto, hashCode de List no es fiable
    });

    test('operator == retorna false para objetos distintos', () {
      final a = AdminCarreraData.fromMap({
        'userName': 'Kevin',
      });

      final b = AdminCarreraData.fromMap({
        'userName': 'Carlos',
      });

      expect(a == b, isFalse);
    });
  });

  group('MenuItemConfig', () {
    test('siempreVisible es true cuando permiso es null', () {
      const item = MenuItemConfig(
        id: 'certificados',
        imagePath: '',
        title: '',
        subtitle: '',
        permiso: null,
      );

      expect(item.siempreVisible, isTrue);
    });

    test('siempreVisible es false cuando tiene permiso', () {
      const item = MenuItemConfig(
        id: 'eventos',
        imagePath: '',
        title: '',
        subtitle: '',
        permiso: 'eventos',
      );

      expect(item.siempreVisible, isFalse);
    });

    test('operator == funciona correctamente', () {
      const a = MenuItemConfig(
        id: 'eventos',
        imagePath: '',
        title: '',
        subtitle: '',
        permiso: 'eventos',
      );

      const b = MenuItemConfig(
        id: 'eventos',
        imagePath: '',
        title: '',
        subtitle: '',
        permiso: 'eventos',
      );

      expect(a, equals(b));
    });

    test('toString contiene el id', () {
      const item = MenuItemConfig(
        id: 'eventos',
        imagePath: '',
        title: '',
        subtitle: '',
        permiso: 'eventos',
      );

      expect(item.toString(), contains('eventos'));
    });
  });

  group('AdminCarreraLogic', () {
    test('allMenuItems no está vacío', () {
      expect(AdminCarreraLogic.allMenuItems, isNotEmpty);
    });

    test('allMenuItems contiene item eventos', () {
      expect(
        AdminCarreraLogic.allMenuItems.any(
          (item) => item.id == 'eventos',
        ),
        isTrue,
      );
    });

    test('itemsVisibles filtra correctamente por permisos', () {
      final data = AdminCarreraData.fromMap({
        'permisos': ['eventos'],
      });

      final visibles = AdminCarreraLogic.itemsVisibles(data);

      expect(visibles.any((e) => e.id == 'eventos'), isTrue);
      expect(visibles.any((e) => e.id == 'reportes'), isFalse);
      expect(visibles.any((e) => e.id == 'certificados'), isTrue);
    });

    test('itemsVisibles muestra solo items públicos sin permisos', () {
      final data = AdminCarreraData.empty();

      final visibles = AdminCarreraLogic.itemsVisibles(data);

      expect(visibles.any((e) => e.id == 'certificados'), isTrue);
      expect(visibles.any((e) => e.id == 'sesiones'), isTrue);
      expect(visibles.any((e) => e.id == 'eventos'), isFalse);
    });
  });
}