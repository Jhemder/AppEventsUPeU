import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:eventos/Admin/Logica/filiales_service.dart';
import 'package:eventos/Admin/Logica/gestion_criterios.dart';

class MockFilialesService extends Mock implements FilialesService {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFilialesService mockFiliales;
  late RubricasService service;

  final estructuraFiliales = {
    'lima': {
      'nombre': 'Campus Lima',
      'facultades': {
        'Facultad Ingeniería': {
          'id': 'fac_ing',
          'carreras': [
            {'id': 'c1', 'nombre': 'Sistemas'},
          ],
        },
      },
    },
    'juliaca': {
      'nombre': 'Campus Juliaca',
      'facultades': {},
    },
  };

  Criterio criterioSample({double peso = 5}) => Criterio(
        id: 'c1',
        descripcion: 'Criterio uno',
        peso: peso,
        puntajeObtenido: 3,
      );

  SeccionRubrica seccionSample({List<Criterio>? criterios}) => SeccionRubrica(
        id: 's1',
        nombre: 'Sección A',
        criterios: criterios ??
            [
              criterioSample(peso: 5),
              Criterio(id: 'c2', descripcion: 'Criterio dos', peso: 5),
            ],
        pesoTotal: 10,
      );

  Rubrica rubricaSample({
    String id = 'rub_1',
    String nombre = 'Rúbrica Test',
    List<SeccionRubrica>? secciones,
    DateTime? fechaCreacion,
    String filial = 'lima',
    String facultad = 'Facultad Ingeniería',
    String? carrera = 'Sistemas',
  }) =>
      Rubrica(
        id: id,
        nombre: nombre,
        descripcion: 'Descripción',
        secciones: secciones ?? [seccionSample()],
        juradosAsignados: const ['jurado_1'],
        fechaCreacion: fechaCreacion ?? DateTime(2024, 6, 1),
        puntajeMaximo: 20,
        filial: filial,
        facultad: facultad,
        carrera: carrera,
      );

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockFiliales = MockFilialesService();
    service = RubricasService(
      firestore: fakeFirestore,
      filialesService: mockFiliales,
    );

    when(() => mockFiliales.getEstructuraCompleta())
        .thenAnswer((_) async => estructuraFiliales);
    when(
      () => mockFiliales.getCarrerasByFacultad(any(), any()),
    ).thenAnswer(
      (_) async => [
        {'id': 'c1', 'nombre': 'Sistemas'},
      ],
    );
  });

  group('Criterio', () {
    test('toMap y fromMap conservan datos', () {
      final original = criterioSample();
      final restored = Criterio.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.descripcion, original.descripcion);
      expect(restored.peso, original.peso);
      expect(restored.puntajeObtenido, original.puntajeObtenido);
    });

    test('fromMap usa valores por defecto', () {
      final c = Criterio.fromMap({});

      expect(c.id, '');
      expect(c.descripcion, '');
      expect(c.peso, 0);
      expect(c.puntajeObtenido, 0);
    });

    test('copyWith actualiza solo campos indicados', () {
      final c = criterioSample().copyWith(descripcion: 'Nuevo', peso: 8);

      expect(c.descripcion, 'Nuevo');
      expect(c.peso, 8);
      expect(c.id, 'c1');
    });
  });

  group('SeccionRubrica', () {
    test('totalPesosCriterios suma pesos', () {
      final seccion = seccionSample();
      expect(seccion.totalPesosCriterios, 10);
    });

    test('pesosBalanceados es true cuando coincide con pesoTotal', () {
      expect(seccionSample().pesosBalanceados, isTrue);
    });

    test('pesosBalanceados es false cuando no coincide', () {
      final seccion = SeccionRubrica(
        id: 's1',
        nombre: 'S',
        criterios: [Criterio(id: 'c1', descripcion: 'x', peso: 3)],
        pesoTotal: 10,
      );
      expect(seccion.pesosBalanceados, isFalse);
    });

    test('toMap y fromMap con lista de criterios', () {
      final original = seccionSample();
      final restored = SeccionRubrica.fromMap(original.toMap());

      expect(restored.nombre, original.nombre);
      expect(restored.criterios.length, 2);
      expect(restored.pesoTotal, 10);
    });

    test('fromMap sin criterios devuelve lista vacía', () {
      final s = SeccionRubrica.fromMap({'id': 's', 'nombre': 'N'});
      expect(s.criterios, isEmpty);
      expect(s.pesoTotal, 10);
    });

    test('copyWith clona criterios por defecto', () {
      final copia = seccionSample().copyWith(nombre: 'Otra');
      expect(copia.nombre, 'Otra');
      expect(copia.criterios.length, 2);
      expect(copia.criterios.first.id, 'c1');
    });
  });

  group('Rubrica', () {
    test('totalCriterios y totalSecciones', () {
      final r = rubricaSample();
      expect(r.totalSecciones, 1);
      expect(r.totalCriterios, 2);
    });

    test('estaCompleta valida nombre, secciones y criterios', () {
      expect(rubricaSample().estaCompleta, isTrue);
      expect(rubricaSample(nombre: '').estaCompleta, isFalse);
      expect(rubricaSample(secciones: []).estaCompleta, isFalse);
      expect(
        rubricaSample(
          secciones: [
            SeccionRubrica(id: 's', nombre: 'V', criterios: []),
          ],
        ).estaCompleta,
        isFalse,
      );
    });

    test('toMap incluye Timestamp y campos de filial', () {
      final map = rubricaSample().toMap();

      expect(map['nombre'], 'Rúbrica Test');
      expect(map['filial'], 'lima');
      expect(map['facultad'], 'Facultad Ingeniería');
      expect(map['carrera'], 'Sistemas');
      expect(map['fechaCreacion'], isA<Timestamp>());
      expect((map['secciones'] as List).length, 1);
    });

    test('fromMap restaura rubrica con Timestamp', () {
      final fecha = DateTime(2023, 3, 15);
      final map = rubricaSample(fechaCreacion: fecha).toMap();
      map['id'] = 'rub_x';

      final r = Rubrica.fromMap(map);

      expect(r.id, 'rub_x');
      expect(r.fechaCreacion, fecha);
      expect(r.filial, 'lima');
      expect(r.secciones.length, 1);
    });

    test('fromMap usa defaults cuando faltan campos', () {
      final r = Rubrica.fromMap({});

      expect(r.id, '');
      expect(r.filial, 'lima');
      expect(r.puntajeMaximo, 20);
      expect(r.juradosAsignados, isEmpty);
      expect(r.secciones, isEmpty);
    });

    test('copyWith preserva y actualiza campos', () {
      final copia = rubricaSample().copyWith(
        nombre: 'Copia',
        filial: 'juliaca',
        facultad: 'Nueva Facultad',
        carrera: 'Ingeniería Civil',
      );

      expect(copia.nombre, 'Copia');
      expect(copia.filial, 'juliaca');
      expect(copia.facultad, 'Nueva Facultad');
      expect(copia.carrera, 'Ingeniería Civil');
      expect(copia.secciones.length, 1);
    });

    test('rubrica sin carrera opcional en toMap', () {
      final r = Rubrica(
        id: 'r0',
        nombre: 'General',
        descripcion: 'D',
        secciones: [seccionSample()],
        juradosAsignados: const [],
        fechaCreacion: DateTime(2024, 1, 1),
        filial: 'lima',
        facultad: 'FIA',
      );

      expect(r.carrera, isNull);
      expect(r.toMap()['carrera'], isNull);
    });
  });

  group('RubricasService — estructura filiales', () {
    test('getEstructuraCompleta usa caché en segunda llamada', () async {
      final a = await service.getEstructuraCompleta();
      final b = await service.getEstructuraCompleta();

      expect(a, estructuraFiliales);
      expect(b, estructuraFiliales);
      verify(() => mockFiliales.getEstructuraCompleta()).called(1);
    });

    test('getFiliales devuelve claves de estructura', () async {
      final filiales = await service.getFiliales();
      expect(filiales, containsAll(['lima', 'juliaca']));
    });

    test('getNombreFilial devuelve nombre o id si no existe', () async {
      expect(await service.getNombreFilial('lima'), 'Campus Lima');
      expect(await service.getNombreFilial('desconocida'), 'desconocida');
    });

    test('getFacultadesByFilial lista facultades', () async {
      final facs = await service.getFacultadesByFilial('lima');
      expect(facs, contains('Facultad Ingeniería'));
    });

    test('getFacultadesByFilial devuelve vacío si filial no existe', () async {
      expect(await service.getFacultadesByFilial('no_existe'), isEmpty);
    });

    test('getCarrerasByFacultad delega en FilialesService', () async {
      final carreras =
          await service.getCarrerasByFacultad('lima', 'Facultad Ingeniería');

      expect(carreras.first['nombre'], 'Sistemas');
      verify(
        () => mockFiliales.getCarrerasByFacultad('lima', 'Facultad Ingeniería'),
      ).called(1);
    });

    test('clearCache limpia estructura y permite recargar', () async {
      await service.getEstructuraCompleta();
      service.clearCache();
      await service.getEstructuraCompleta();

      verify(() => mockFiliales.getEstructuraCompleta()).called(2);
    });
  });

  group('RubricasService — CRUD rúbricas', () {
    test('crearRubrica guarda documento en Firestore', () async {
      final rubrica = rubricaSample();
      final ok = await service.crearRubrica(rubrica);

      expect(ok, isTrue);
      final doc = await fakeFirestore.collection('rubricas').doc('rub_1').get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['nombre'], 'Rúbrica Test');
    });

    test('obtenerRubricaPorId devuelve rubrica o null', () async {
      await service.crearRubrica(rubricaSample());

      final encontrada = await service.obtenerRubricaPorId('rub_1');
      final noExiste = await service.obtenerRubricaPorId('inexistente');

      expect(encontrada?.nombre, 'Rúbrica Test');
      expect(noExiste, isNull);
    });

    test('obtenerRubricas ordena por fecha descendente', () async {
      await service.crearRubrica(
        rubricaSample(
          id: 'vieja',
          fechaCreacion: DateTime(2020, 1, 1),
        ),
      );
      await service.crearRubrica(
        rubricaSample(
          id: 'nueva',
          fechaCreacion: DateTime(2025, 1, 1),
        ),
      );

      final lista = await service.obtenerRubricas();

      expect(lista.length, 2);
      expect(lista.first.id, 'nueva');
      expect(lista.last.id, 'vieja');
    });

    test('obtenerRubricasPorFilial filtra por filial', () async {
      await service.crearRubrica(rubricaSample(id: 'r1', filial: 'lima'));
      await service.crearRubrica(
        rubricaSample(id: 'r2', filial: 'juliaca'),
      );

      final lima = await service.obtenerRubricasPorFilial('lima');

      expect(lima.length, 1);
      expect(lima.first.filial, 'lima');
    });

    test('obtenerRubricasPorFilialYFacultad filtra ambos', () async {
      await service.crearRubrica(
        rubricaSample(id: 'r1', filial: 'lima', facultad: 'FIA'),
      );
      await service.crearRubrica(
        rubricaSample(id: 'r2', filial: 'lima', facultad: 'Otra'),
      );

      final lista = await service.obtenerRubricasPorFilialYFacultad('lima', 'FIA');

      expect(lista.length, 1);
      expect(lista.first.facultad, 'FIA');
    });

    test('actualizarRubrica modifica documento', () async {
      await service.crearRubrica(rubricaSample());
      final actualizada = rubricaSample(nombre: 'Actualizada');

      final ok = await service.actualizarRubrica(actualizada);

      expect(ok, isTrue);
      final doc = await fakeFirestore.collection('rubricas').doc('rub_1').get();
      expect(doc.data()!['nombre'], 'Actualizada');
    });

    test('eliminarRubrica borra documento', () async {
      await service.crearRubrica(rubricaSample());

      final ok = await service.eliminarRubrica('rub_1');

      expect(ok, isTrue);
      final doc = await fakeFirestore.collection('rubricas').doc('rub_1').get();
      expect(doc.exists, isFalse);
    });
  });

  group('RubricasService — jurados y evaluaciones', () {
    test('obtenerJurados filtra por tipo y campos opcionales', () async {
      await fakeFirestore.collection('users').add({
        'userType': 'jurado',
        'name': 'Ana Jurado',
        'usuario': 'ana.j',
        'filial': 'lima',
        'facultad': 'FIA',
        'carrera': 'Sistemas',
        'categoria': 'A',
      });
      await fakeFirestore.collection('users').add({
        'userType': 'estudiante',
        'name': 'No es jurado',
      });

      final jurados = await service.obtenerJurados(
        filial: 'lima',
        facultad: 'FIA',
        carrera: 'Sistemas',
      );

      expect(jurados.length, 1);
      expect(jurados.first['nombre'], 'Ana Jurado');
      expect(jurados.first['usuario'], 'ana.j');
    });

    test('obtenerJurados sin filtros devuelve todos los jurados', () async {
      await fakeFirestore.collection('users').add({
        'userType': 'jurado',
        'nombre': 'Pedro',
      });

      final jurados = await service.obtenerJurados();
      expect(jurados.length, 1);
      expect(jurados.first['nombre'], 'Pedro');
    });

    test('eliminarEvaluacionesDeJurados sin eventos no falla', () async {
      await expectLater(
        service.eliminarEvaluacionesDeJurados(
          rubricaId: 'rub_1',
          juradosIds: const ['j1'],
        ),
        completes,
      );
    });

    test('eliminarEvaluacionesDeJurados ignora evaluación sin rubricaId', () async {
      await fakeFirestore.collection('events').doc('ev1').set({});
      await fakeFirestore
          .collection('events')
          .doc('ev1')
          .collection('proyectos')
          .doc('p1')
          .set({});
      await fakeFirestore
          .collection('events')
          .doc('ev1')
          .collection('proyectos')
          .doc('p1')
          .collection('evaluaciones')
          .doc('jurado_1')
          .set({'puntaje': 10});

      await service.eliminarEvaluacionesDeJurados(
        rubricaId: 'rub_1',
        juradosIds: ['jurado_1'],
      );

      final doc = await fakeFirestore
          .collection('events')
          .doc('ev1')
          .collection('proyectos')
          .doc('p1')
          .collection('evaluaciones')
          .doc('jurado_1')
          .get();
      expect(doc.exists, isTrue);
    });

    test('eliminarEvaluacionesDeJurados borra evaluaciones de la rúbrica', () async {
      await fakeFirestore.collection('events').doc('ev1').set({'name': 'E'});
      await fakeFirestore
          .collection('events')
          .doc('ev1')
          .collection('proyectos')
          .doc('p1')
          .set({'Título': 'Proyecto'});
      await fakeFirestore
          .collection('events')
          .doc('ev1')
          .collection('proyectos')
          .doc('p1')
          .collection('evaluaciones')
          .doc('jurado_1')
          .set({'rubricaId': 'rub_1', 'puntaje': 15});
      await fakeFirestore
          .collection('events')
          .doc('ev1')
          .collection('proyectos')
          .doc('p1')
          .collection('evaluaciones')
          .doc('jurado_2')
          .set({'rubricaId': 'otra_rubrica'});

      await service.eliminarEvaluacionesDeJurados(
        rubricaId: 'rub_1',
        juradosIds: ['jurado_1', 'jurado_2'],
      );

      final ev1 = await fakeFirestore
          .collection('events')
          .doc('ev1')
          .collection('proyectos')
          .doc('p1')
          .collection('evaluaciones')
          .doc('jurado_1')
          .get();
      final ev2 = await fakeFirestore
          .collection('events')
          .doc('ev1')
          .collection('proyectos')
          .doc('p1')
          .collection('evaluaciones')
          .doc('jurado_2')
          .get();

      expect(ev1.exists, isFalse);
      expect(ev2.exists, isTrue);
    });
  });

  group('RubricasService — filtrarRubricas', () {
    late List<Rubrica> rubricas;

    setUp(() {
      rubricas = [
        rubricaSample(
          id: '1',
          filial: 'lima',
          facultad: 'FIA',
          carrera: 'Sistemas',
        ),
        rubricaSample(
          id: '2',
          filial: 'lima',
          facultad: 'Salud',
          carrera: 'Enfermería',
        ),
        rubricaSample(
          id: '3',
          filial: 'juliaca',
          facultad: 'FIA',
          carrera: 'Admin',
        ),
      ];
    });

    test('sin filtros devuelve todas', () {
      expect(service.filtrarRubricas(rubricas).length, 3);
    });

    test('filtra por filial', () {
      final r = service.filtrarRubricas(rubricas, filial: 'lima');
      expect(r.length, 2);
      expect(r.every((x) => x.filial == 'lima'), isTrue);
    });

    test('filtra por filial y facultad', () {
      final r = service.filtrarRubricas(
        rubricas,
        filial: 'lima',
        facultad: 'FIA',
      );
      expect(r.length, 1);
      expect(r.first.id, '1');
    });

    test('filtra por filial, facultad y carrera', () {
      final r = service.filtrarRubricas(
        rubricas,
        filial: 'lima',
        facultad: 'Salud',
        carrera: 'Enfermería',
      );
      expect(r.length, 1);
      expect(r.first.id, '2');
    });

    test('filtros vacíos no reducen lista', () {
      expect(
        service.filtrarRubricas(rubricas, filial: '', facultad: '').length,
        3,
      );
    });
  });
}
