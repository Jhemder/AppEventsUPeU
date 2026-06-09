import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventos/prefs_helper.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeFirestore = FakeFirebaseFirestore();
    // Inyectar el firestore falso en PrefsHelper
    PrefsHelper.setFirestoreForTesting(fakeFirestore);
  });

  // ── generateUsername ─────────────────────────────────────────────────────
  group('generateUsername', () {
    test('tres palabras → primer nombre + tercer nombre', () {
      expect(PrefsHelper.generateUsername('Kevin Rodrigo Mamani'), 'kevin.mamani');
    });

    test('dos palabras → ambas con punto', () {
      expect(PrefsHelper.generateUsername('Kevin Mamani'), 'kevin.mamani');
    });

    test('una palabra → solo esa', () {
      expect(PrefsHelper.generateUsername('Kevin'), 'kevin');
    });

    test('convierte a minúsculas', () {
      expect(PrefsHelper.generateUsername('JUAN CARLOS FLORES'), 'juan.flores');
    });

    test('recorta espacios', () {
      expect(PrefsHelper.generateUsername('  Ana Torres  '), 'ana.torres');
    });

    test('cuatro palabras → primera y tercera', () {
      expect(PrefsHelper.generateUsername('Maria del Carmen Quispe'), 'maria.carmen');
    });
  });

  // ── Sesión básica (solo SharedPreferences) ───────────────────────────────
  group('sesión básica', () {
    test('isLoggedIn false sin sesión', () async {
      expect(await PrefsHelper.isLoggedIn(), isFalse);
    });

    test('saveUserData persiste tipo, nombre e id', () async {
      await PrefsHelper.saveUserData(
        userType: PrefsHelper.userTypeAdmin,
        userName: 'Administrador',
        userId: 'abc123',
      );

      expect(await PrefsHelper.getUserType(), PrefsHelper.userTypeAdmin);
      expect(await PrefsHelper.getUserName(), 'Administrador');
      expect(await PrefsHelper.getCurrentUserId(), 'abc123');
      expect(await PrefsHelper.isLoggedIn(), isTrue);
    });

    test('logout limpia todos los campos', () async {
      await PrefsHelper.saveUserData(
        userType: PrefsHelper.userTypeAdmin,
        userName: 'Administrador',
        userId: 'abc123',
      );
      await PrefsHelper.logout();

      expect(await PrefsHelper.isLoggedIn(), isFalse);
      expect(await PrefsHelper.getUserType(), isNull);
      expect(await PrefsHelper.getCurrentUserId(), isNull);
    });

    test('saveAdminCarreraData persiste todos los campos', () async {
      await PrefsHelper.saveAdminCarreraData(
        userId: 'uid-01',
        userName: 'Kevin',
        filial: 'filial-01',
        filialNombre: 'Juliaca',
        facultad: 'FIA',
        carrera: 'Ingeniería de Sistemas',
        carreraId: 'carrera-01',
        permisos: ['eventos', 'reportes'],
      );

      expect(await PrefsHelper.getAdminCarreraFilial(), 'filial-01');
      expect(await PrefsHelper.getAdminCarreraFilialNombre(), 'Juliaca');
      expect(await PrefsHelper.getAdminCarreraFacultad(), 'FIA');
      expect(await PrefsHelper.getAdminCarreraCarrera(), 'Ingeniería de Sistemas');
      expect(await PrefsHelper.getAdminCarreraCarreraId(), 'carrera-01');
    });

    test('getAdminCarreraPermisos deserializa lista', () async {
      await PrefsHelper.saveAdminCarreraData(
        userId: 'uid-01', userName: 'Kevin',
        filial: 'f-01', filialNombre: 'Juliaca',
        facultad: 'FIA', carrera: 'Sistemas',
        carreraId: 'c-01', permisos: ['eventos', 'reportes', 'rubricas'],
      );

      expect(
        await PrefsHelper.getAdminCarreraPermisos(),
        equals(['eventos', 'reportes', 'rubricas']),
      );
    });

    test('getAdminCarreraPermisos vacía si no hay nada', () async {
      expect(await PrefsHelper.getAdminCarreraPermisos(), isEmpty);
    });

    test('tienePermiso true cuando existe', () async {
      await PrefsHelper.saveAdminCarreraData(
        userId: 'uid-01', userName: 'Kevin',
        filial: 'f-01', filialNombre: 'Juliaca',
        facultad: 'FIA', carrera: 'Sistemas',
        carreraId: 'c-01', permisos: ['eventos', 'reportes'],
      );

      expect(await PrefsHelper.tienePermiso('eventos'), isTrue);
    });

    test('tienePermiso false cuando no existe', () async {
      await PrefsHelper.saveAdminCarreraData(
        userId: 'uid-01', userName: 'Kevin',
        filial: 'f-01', filialNombre: 'Juliaca',
        facultad: 'FIA', carrera: 'Sistemas',
        carreraId: 'c-01', permisos: ['eventos'],
      );

      expect(await PrefsHelper.tienePermiso('rubricas'), isFalse);
    });

    test('isAdminCarrera true solo para admin_carrera', () async {
      await PrefsHelper.saveAdminCarreraData(
        userId: 'uid-01', userName: 'Kevin',
        filial: 'f-01', filialNombre: 'Juliaca',
        facultad: 'FIA', carrera: 'Sistemas',
        carreraId: 'c-01', permisos: [],
      );

      expect(await PrefsHelper.isAdminCarrera(), isTrue);
    });

    test('isAdminCarrera false para admin normal', () async {
      await PrefsHelper.saveUserData(
        userType: PrefsHelper.userTypeAdmin,
        userName: 'Administrador',
        userId: 'abc',
      );

      expect(await PrefsHelper.isAdminCarrera(), isFalse);
    });

    test('getAdminCarreraData null si no es admin_carrera', () async {
      await PrefsHelper.saveUserData(
        userType: PrefsHelper.userTypeAdmin,
        userName: 'Administrador',
        userId: 'abc',
      );

      expect(await PrefsHelper.getAdminCarreraData(), isNull);
    });

    test('getAdminCarreraData mapa completo si es admin_carrera', () async {
      await PrefsHelper.saveAdminCarreraData(
        userId: 'uid-01', userName: 'Kevin',
        filial: 'f-01', filialNombre: 'Juliaca',
        facultad: 'FIA', carrera: 'Sistemas',
        carreraId: 'c-01', permisos: ['eventos'],
      );

      final data = await PrefsHelper.getAdminCarreraData();

      expect(data, isNotNull);
      expect(data!['filial'], 'f-01');
      expect(data['filialNombre'], 'Juliaca');
      expect(data['facultad'], 'FIA');
      expect(data['permisos'], equals(['eventos']));
    });

    test('debemostrarAdvertenciaPrimeraVez false sin activar', () async {
      expect(await PrefsHelper.debemostrarAdvertenciaPrimeraVez(), isFalse);
    });

    test('debemostrarAdvertenciaPrimeraVez true una vez y luego false', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('es_primera_vez_advertencia', true);

      expect(await PrefsHelper.debemostrarAdvertenciaPrimeraVez(), isTrue);
      expect(await PrefsHelper.debemostrarAdvertenciaPrimeraVez(), isFalse);
    });
  });

  // ── loginAdmin con Firestore falso ───────────────────────────────────────
  group('loginAdmin', () {
    test('crea admin nuevo si no existe y contraseña cualquiera', () async {
      final result = await PrefsHelper.loginAdmin('admin', 'admin_2025*.');
      expect(result, isTrue);
      expect(await PrefsHelper.getUserType(), PrefsHelper.userTypeAdmin);
    });

    test('login correcto con contraseña que coincide en Firestore', () async {
      // Crear el doc admin manualmente en el fake
      await fakeFirestore.collection('users').add({
        'email': 'admin',
        'password': 'pass123',
        'userType': 'admin',
        'name': 'Administrador',
      });

      final result = await PrefsHelper.loginAdmin('admin', 'pass123');
      expect(result, isTrue);
    });

    test('login falla si contraseña no coincide', () async {
      await fakeFirestore.collection('users').add({
        'email': 'admin',
        'password': 'pass123',
        'userType': 'admin',
        'name': 'Administrador',
      });

      final result = await PrefsHelper.loginAdmin('admin', 'incorrecta');
      expect(result, isFalse);
    });

    test('usuario no reconocido retorna false', () async {
      final result = await PrefsHelper.loginAdmin('desconocido', '1234');
      expect(result, isFalse);
    });

    test('crea asistente nuevo si no existe', () async {
      final result = await PrefsHelper.loginAdmin('society', 'society@2025');
      expect(result, isTrue);
      expect(await PrefsHelper.getUserType(), PrefsHelper.userTypeAsistente);
    });

    test('login asistente falla si contraseña no coincide', () async {
      await fakeFirestore.collection('users').add({
        'email': 'society',
        'password': 'society@2025',
        'userType': 'asistente',
        'name': 'Asistente',
      });

      final result = await PrefsHelper.loginAdmin('society', 'incorrecta');
      expect(result, isFalse);
    });
  });

  // ── loginJurado con Firestore falso ──────────────────────────────────────
  group('loginJurado', () {
    test('login con credenciales hardcoded crea jurado si no existe', () async {
      final result = await PrefsHelper.loginJurado('jurado', 'jurado123');
      expect(result, isTrue);
      expect(await PrefsHelper.getUserType(), PrefsHelper.userTypeJurado);
    });

    test('login jurado correcto con doc en Firestore', () async {
      await fakeFirestore.collection('users').add({
        'usuario': 'jurado.test',
        'password': 'clave456',
        'userType': 'jurado',
        'name': 'Jurado Test',
      });

      final result = await PrefsHelper.loginJurado('jurado.test', 'clave456');
      expect(result, isTrue);
    });

    test('login jurado falla con contraseña incorrecta', () async {
      await fakeFirestore.collection('users').add({
        'usuario': 'jurado.test',
        'password': 'clave456',
        'userType': 'jurado',
        'name': 'Jurado Test',
      });

      final result = await PrefsHelper.loginJurado('jurado.test', 'mala');
      expect(result, isFalse);
    });

    test('login jurado falla si usuario no existe', () async {
      final result = await PrefsHelper.loginJurado('noexiste', '1234');
      expect(result, isFalse);
    });
  });

  // ── createJuradoAccount ──────────────────────────────────────────────────
  group('createJuradoAccount', () {
    test('crea jurado exitosamente', () async {
      final result = await PrefsHelper.createJuradoAccount(
        nombre: 'Juan Pérez',
        usuario: 'juan.perez',
        password: 'pass123',
        facultad: 'FIA',
        carrera: 'Sistemas',
        categoria: 'SW',
      );

      expect(result, isTrue);

      final query = await fakeFirestore
          .collection('users')
          .where('usuario', isEqualTo: 'juan.perez')
          .get();
      expect(query.docs.length, 1);
    });

    test('falla si el usuario ya existe', () async {
      await fakeFirestore.collection('users').add({
        'usuario': 'juan.perez',
        'userType': 'jurado',
        'password': 'abc',
      });

      final result = await PrefsHelper.createJuradoAccount(
        nombre: 'Juan Pérez',
        usuario: 'juan.perez',
        password: 'pass123',
        facultad: 'FIA',
        carrera: 'Sistemas',
        categoria: 'SW',
      );

      expect(result, isFalse);
    });
  });

  // ── loginStudent ─────────────────────────────────────────────────────────
  group('loginStudent', () {
    test('login correcto con índice existente', () async {
      // Crear el estudiante en Firestore
      final studentRef = await fakeFirestore
          .collection('users')
          .doc('Sistemas')
          .collection('students')
          .add({
        'username': 'kevin.mamani',
        'dni': '12345678',
        'name': 'Kevin Mamani',
        'userType': 'student',
      });

      // Crear el índice
      await fakeFirestore
          .collection('student_index')
          .doc('kevin.mamani')
          .set({
        'username': 'kevin.mamani',
        'carreraPath': 'Sistemas',
        'studentId': studentRef.id,
      });

      final result = await PrefsHelper.loginStudent('kevin.mamani', '12345678');
      expect(result, isTrue);
      expect(await PrefsHelper.getUserType(), PrefsHelper.userTypeStudent);
    });

    test('login falla con contraseña incorrecta', () async {
      final studentRef = await fakeFirestore
          .collection('users')
          .doc('Sistemas')
          .collection('students')
          .add({
        'username': 'kevin.mamani',
        'dni': '12345678',
        'name': 'Kevin Mamani',
        'userType': 'student',
      });

      await fakeFirestore
          .collection('student_index')
          .doc('kevin.mamani')
          .set({
        'username': 'kevin.mamani',
        'carreraPath': 'Sistemas',
        'studentId': studentRef.id,
      });

      final result = await PrefsHelper.loginStudent('kevin.mamani', 'mala');
      expect(result, isFalse);
    });

    test('login falla si usuario no existe', () async {
      final result = await PrefsHelper.loginStudent('noexiste', '12345678');
      expect(result, isFalse);
    });

    test('login por fallback si no hay índice', () async {
      await fakeFirestore
          .collection('users')
          .doc('Sistemas')
          .collection('students')
          .add({
        'username': 'ana.torres',
        'dni': '87654321',
        'name': 'Ana Torres',
        'userType': 'student',
      });

      final result = await PrefsHelper.loginStudent('ana.torres', '87654321');
      expect(result, isTrue);
    });
  });

  // ── deleteStudent ────────────────────────────────────────────────────────
  group('deleteStudent', () {
    test('elimina estudiante y su índice', () async {
      final studentRef = await fakeFirestore
          .collection('users')
          .doc('Sistemas')
          .collection('students')
          .add({
        'username': 'kevin.mamani',
        'dni': '12345678',
        'name': 'Kevin Mamani',
      });

      await fakeFirestore
          .collection('student_index')
          .doc('kevin.mamani')
          .set({'username': 'kevin.mamani'});

      final result = await PrefsHelper.deleteStudent('Sistemas', studentRef.id);

      expect(result, isTrue);

      final doc = await fakeFirestore
          .collection('users')
          .doc('Sistemas')
          .collection('students')
          .doc(studentRef.id)
          .get();
      expect(doc.exists, isFalse);

      final index = await fakeFirestore
          .collection('student_index')
          .doc('kevin.mamani')
          .get();
      expect(index.exists, isFalse);
    });
  });

  // ── createStudentAccountWithUsername ────────────────────────────────────
  group('createStudentAccountWithUsername', () {
    test('crea estudiante exitosamente', () async {
      final result = await PrefsHelper.createStudentAccountWithUsername(
        email: 'kevin@upeu.edu.pe',
        name: 'Kevin Mamani',
        username: 'kevin.mamani',
        codigoUniversitario: 'UP202301',
        dni: '12345678',
        facultad: 'FIA',
        carrera: 'Sistemas',
      );

      expect(result, isTrue);

      final index = await fakeFirestore
          .collection('student_index')
          .doc('kevin.mamani')
          .get();
      expect(index.exists, isTrue);
    });

    test('falla si username ya está en índice', () async {
      await fakeFirestore
          .collection('student_index')
          .doc('kevin.mamani')
          .set({'username': 'kevin.mamani'});

      final result = await PrefsHelper.createStudentAccountWithUsername(
        email: 'otro@upeu.edu.pe',
        name: 'Otro',
        username: 'kevin.mamani',
        codigoUniversitario: 'UP999',
        dni: '99999999',
        facultad: 'FIA',
        carrera: 'Sistemas',
      );

      expect(result, isFalse);
    });

    test('falla si DNI ya existe en la carrera', () async {
      await fakeFirestore
          .collection('users')
          .doc('Sistemas')
          .collection('students')
          .add({
        'username': 'otro.usuario',
        'dni': '12345678',
        'name': 'Otro',
      });

      final result = await PrefsHelper.createStudentAccountWithUsername(
        email: 'nuevo@upeu.edu.pe',
        name: 'Nuevo',
        username: 'nuevo.usuario',
        codigoUniversitario: 'UP111',
        dni: '12345678', // mismo DNI
        facultad: 'FIA',
        carrera: 'Sistemas',
      );

      expect(result, isFalse);
    });
  });

  // ── Constantes ───────────────────────────────────────────────────────────
  group('constantes de tipo de usuario', () {
    test('valores son los esperados', () {
      expect(PrefsHelper.userTypeAdmin, 'admin');
      expect(PrefsHelper.userTypeStudent, 'student');
      expect(PrefsHelper.userTypeAsistente, 'asistente');
      expect(PrefsHelper.userTypeJurado, 'jurado');
      expect(PrefsHelper.userTypeAdminCarrera, 'admin_carrera');
    });
  });
}