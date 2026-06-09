import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:eventos/Admin/Logica/crear_filiales.dart';
import 'package:eventos/Admin/Logica/filiales_service.dart';

class MockFilialesService extends Mock implements FilialesService {}

void main() {
  late MockFilialesService mockService;

  /// Una sola filial/facultad para evitar finders ambiguos en diálogos.
  Map<String, dynamic> estructuraMinima() => {
        'lima': {
          'nombre': 'Campus Lima',
          'ubicacion': 'Ñaña, Chosica',
          'facultades': {
            'Facultad Ingeniería': {
              'id': 'fac_ing',
              'carreras': [
                {'id': 'c1', 'nombre': 'Ingeniería de Sistemas'},
              ],
            },
          },
        },
      };

  Map<String, dynamic> estructuraMock() => {
        'lima': {
          'nombre': 'Campus Lima',
          'ubicacion': 'Ñaña, Chosica',
          'facultades': {
            'Facultad Ingeniería': {
              'id': 'fac_ing',
              'carreras': [
                {'id': 'c1', 'nombre': 'Ingeniería de Sistemas'},
                {'id': 'c2', 'nombre': 'Ingeniería Civil'},
              ],
            },
            'Facultad Vacía': {
              'id': 'fac_vacia',
              'carreras': <Map<String, dynamic>>[],
            },
            'Facultad Una': {
              'id': 'fac_una',
              'carreras': [
                {'id': 'c_solo', 'nombre': 'Enfermería'},
              ],
            },
            'Facultad Sin Nombre': {
              'id': 'fac_sn',
              'carreras': [
                {'id': 'c_noname'},
              ],
            },
          },
        },
        'juliaca': {
          'nombre': 'Campus Juliaca',
          'ubicacion': 'Juliaca, Puno',
          'facultades': {
            'Facultad Empresarial': {
              'id': 'fac_emp',
              'carreras': [
                {'id': 'c3', 'nombre': 'Administración'},
              ],
            },
          },
        },
      };

  void stubCargaExitosa({Map<String, dynamic>? estructura}) {
    when(() => mockService.inicializarSiEsNecesario())
        .thenAnswer((_) async => true);
    when(() => mockService.getEstructuraCompleta())
        .thenAnswer((_) async => estructura ?? estructuraMock());
    when(
      () => mockService.getEstructuraCompleta(forceRefresh: true),
    ).thenAnswer((_) async => estructura ?? estructuraMock());
  }

  /// Tile de facultad (no el ExpansionTile de la filial padre).
  Finder facultadTile(String nombre) => find
      .ancestor(
        of: find.text(nombre),
        matching: find.byType(ExpansionTile),
      )
      .last;

  Future<void> tapAgregarEnFacultad(
    WidgetTester tester,
    String nombre,
  ) async {
    await tester.tap(
      find.descendant(
        of: facultadTile(nombre),
        matching: find.byIcon(Icons.add_circle),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapEliminarCarrera(
    WidgetTester tester,
    String nombreCarrera,
  ) async {
    await tester.tap(
      find.descendant(
        of: find.ancestor(
          of: find.text(nombreCarrera),
          matching: find.byType(Row),
        ),
        matching: find.byIcon(Icons.delete_outline),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    Map<String, dynamic>? estructura,
    bool settle = true,
  }) async {
    stubCargaExitosa(estructura: estructura);
    await tester.pumpWidget(
      MaterialApp(
        home: CrearFilialesScreen(filialesService: mockService),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  Future<void> abrirFacultad(WidgetTester tester, String nombre) async {
    await tester.tap(find.text(nombre));
    await tester.pumpAndSettle();
  }

  setUp(() {
    mockService = MockFilialesService();
  });

  group('CrearFilialesScreen', () {
    testWidgets('muestra loading y luego la estructura cargada', (
      WidgetTester tester,
    ) async {
      when(() => mockService.inicializarSiEsNecesario())
          .thenAnswer((_) async => true);
      when(() => mockService.getEstructuraCompleta()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return estructuraMock();
      });
      when(
        () => mockService.getEstructuraCompleta(forceRefresh: true),
      ).thenAnswer((_) async => estructuraMock());

      await tester.pumpWidget(
        MaterialApp(
          home: CrearFilialesScreen(filialesService: mockService),
        ),
      );
      await tester.pump();

      expect(find.text('Cargando estructura...'), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('Carreras por Filial'), findsOneWidget);
      expect(find.text('Datos cargados'), findsOneWidget);
      expect(find.text('Campus Lima'), findsOneWidget);
    });

    testWidgets('muestra estado vacío y reintentar recarga', (
      WidgetTester tester,
    ) async {
      var llamadas = 0;
      when(() => mockService.inicializarSiEsNecesario())
          .thenAnswer((_) async => true);
      when(() => mockService.getEstructuraCompleta()).thenAnswer((_) async {
        llamadas++;
        return llamadas == 1 ? <String, dynamic>{} : estructuraMock();
      });
      when(
        () => mockService.getEstructuraCompleta(forceRefresh: true),
      ).thenAnswer((_) async => estructuraMock());

      await tester.pumpWidget(
        MaterialApp(
          home: CrearFilialesScreen(filialesService: mockService),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No se pudo cargar la estructura'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Carreras por Filial'), findsOneWidget);
    });

    testWidgets('error al cargar muestra snackbar rojo', (
      WidgetTester tester,
    ) async {
      when(() => mockService.inicializarSiEsNecesario())
          .thenAnswer((_) async => true);
      when(() => mockService.getEstructuraCompleta())
          .thenThrow(Exception('fallo carga'));

      await tester.pumpWidget(
        MaterialApp(
          home: CrearFilialesScreen(filialesService: mockService),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Error al cargar datos'), findsOneWidget);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.red);
    });

    testWidgets('refresh en header actualiza y muestra snackbar verde', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.byTooltip('Actualizar'));
      await tester.pumpAndSettle();

      expect(find.text('Datos actualizados'), findsOneWidget);
      verify(
        () => mockService.getEstructuraCompleta(forceRefresh: true),
      ).called(greaterThanOrEqualTo(1));
    });

    testWidgets('error al refrescar muestra snackbar de error', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      when(
        () => mockService.getEstructuraCompleta(forceRefresh: true),
      ).thenThrow(Exception('fallo refresh'));

      await tester.tap(find.byTooltip('Actualizar'));
      await tester.pumpAndSettle();

      expect(find.text('Error al actualizar'), findsOneWidget);
    });

    testWidgets('RefreshIndicator dispara actualización', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      await tester.fling(
        find.byType(RefreshIndicator),
        const Offset(0, 400),
        2000,
      );
      await tester.pumpAndSettle();

      verify(
        () => mockService.getEstructuraCompleta(forceRefresh: true),
      ).called(greaterThanOrEqualTo(1));
    });

    testWidgets('botón atrás hace pop', (WidgetTester tester) async {
      stubCargaExitosa();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CrearFilialesScreen(
                            filialesService: mockService,
                          ),
                        ),
                      );
                    },
                    child: const Text('Abrir'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Gestión de Carreras'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Gestión de Carreras'), findsNothing);
      expect(find.text('Abrir'), findsOneWidget);
    });

    testWidgets('expandir y colapsar filial juliaca', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      await tester.scrollUntilVisible(
        find.text('Campus Juliaca'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Campus Juliaca'));
      await tester.pumpAndSettle();

      expect(find.text('Facultad Empresarial'), findsOneWidget);

      await tester.tap(find.text('Campus Juliaca'));
      await tester.pumpAndSettle();
    });

    testWidgets('facultad vacía muestra mensaje informativo', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);
      await abrirFacultad(tester, 'Facultad Vacía');

      expect(
        find.text('No hay carreras en esta facultad'),
        findsOneWidget,
      );
    });

    testWidgets('facultad con una carrera usa texto singular', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);
      await abrirFacultad(tester, 'Facultad Una');

      expect(
        find.descendant(
          of: facultadTile('Facultad Una'),
          matching: find.text('1 carrera'),
        ),
        findsWidgets,
      );
    });

    testWidgets('facultad con varias carreras usa texto plural', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);
      await abrirFacultad(tester, 'Facultad Ingeniería');

      expect(
        find.descendant(
          of: facultadTile('Facultad Ingeniería'),
          matching: find.text('2 carreras'),
        ),
        findsWidgets,
      );
    });

    testWidgets('carrera sin nombre muestra Sin nombre', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);
      await abrirFacultad(tester, 'Facultad Sin Nombre');

      expect(find.text('Sin nombre'), findsOneWidget);
    });

    testWidgets('diálogo agregar: cancelar no llama al servicio', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, estructura: estructuraMinima());
      await abrirFacultad(tester, 'Facultad Ingeniería');

      await tapAgregarEnFacultad(tester, 'Facultad Ingeniería');

      expect(find.text('Agregar Nueva Carrera'), findsOneWidget);
      expect(find.text('Facultad: Facultad Ingeniería'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      verifyNever(
        () => mockService.agregarCarrera(
          filialId: any(named: 'filialId'),
          facultadId: any(named: 'facultadId'),
          nombreCarrera: any(named: 'nombreCarrera'),
        ),
      );
    });

    testWidgets('diálogo agregar: validaciones del formulario', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, estructura: estructuraMinima());
      await abrirFacultad(tester, 'Facultad Ingeniería');

      await tapAgregarEnFacultad(tester, 'Facultad Ingeniería');

      await tester.tap(find.text('Agregar'));
      await tester.pump();

      expect(find.text('Por favor ingrese un nombre'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'ab');
      await tester.tap(find.text('Agregar'));
      await tester.pump();

      expect(
        find.text('El nombre debe tener al menos 3 caracteres'),
        findsOneWidget,
      );
    });

    testWidgets('muestra diálogo de carga al agregar carrera', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, estructura: estructuraMinima());
      await abrirFacultad(tester, 'Facultad Ingeniería');

      when(
        () => mockService.agregarCarrera(
          filialId: any(named: 'filialId'),
          facultadId: any(named: 'facultadId'),
          nombreCarrera: any(named: 'nombreCarrera'),
        ),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(seconds: 1));
        return true;
      });

      await tapAgregarEnFacultad(tester, 'Facultad Ingeniería');
      await tester.enterText(find.byType(TextFormField), 'Carrera Larga');
      await tester.tap(find.text('Agregar'));
      await tester.pump();

      expect(find.text('Agregando carrera...'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('muestra diálogo de carga al agregar carrera', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, estructura: estructuraMinima());
      await abrirFacultad(tester, 'Facultad Ingeniería');

      when(
        () => mockService.agregarCarrera(
          filialId: any(named: 'filialId'),
          facultadId: any(named: 'facultadId'),
          nombreCarrera: any(named: 'nombreCarrera'),
        ),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return true;
      });

      await tapAgregarEnFacultad(tester, 'Facultad Ingeniería');
      await tester.enterText(find.byType(TextFormField), 'Carrera Lenta');
      await tester.tap(find.text('Agregar'));
      await tester.pump();

      expect(find.text('Agregando carrera...'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('agregar carrera exitosa refresca y muestra mensaje', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, estructura: estructuraMinima());
      await abrirFacultad(tester, 'Facultad Ingeniería');

      when(
        () => mockService.agregarCarrera(
          filialId: 'lima',
          facultadId: 'fac_ing',
          nombreCarrera: 'Nueva Carrera Test',
        ),
      ).thenAnswer((_) async => true);

      await tapAgregarEnFacultad(tester, 'Facultad Ingeniería');

      await tester.enterText(
        find.byType(TextFormField),
        'Nueva Carrera Test',
      );
      await tester.tap(find.text('Agregar'));
      await tester.pumpAndSettle();

      expect(find.text('Carrera agregada exitosamente'), findsOneWidget);
      verify(
        () => mockService.agregarCarrera(
          filialId: 'lima',
          facultadId: 'fac_ing',
          nombreCarrera: 'Nueva Carrera Test',
        ),
      ).called(1);
    });

    testWidgets('agregar carrera fallida muestra error', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, estructura: estructuraMinima());
      await abrirFacultad(tester, 'Facultad Ingeniería');

      when(
        () => mockService.agregarCarrera(
          filialId: any(named: 'filialId'),
          facultadId: any(named: 'facultadId'),
          nombreCarrera: any(named: 'nombreCarrera'),
        ),
      ).thenAnswer((_) async => false);

      await tapAgregarEnFacultad(tester, 'Facultad Ingeniería');

      await tester.enterText(find.byType(TextFormField), 'Carrera Duplicada');
      await tester.tap(find.text('Agregar'));
      await tester.pumpAndSettle();

      expect(
        find.text('Error: La carrera ya existe o hubo un problema'),
        findsOneWidget,
      );
    });

    testWidgets('eliminar carrera: cancelar no llama al servicio', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, estructura: estructuraMinima());
      await abrirFacultad(tester, 'Facultad Ingeniería');

      await tapEliminarCarrera(tester, 'Ingeniería de Sistemas');

      expect(find.text('Confirmar eliminación'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      verifyNever(
        () => mockService.eliminarCarrera(
          filialId: any(named: 'filialId'),
          facultadId: any(named: 'facultadId'),
          carreraId: any(named: 'carreraId'),
        ),
      );
    });

    testWidgets('muestra diálogo de carga al eliminar carrera', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, estructura: estructuraMinima());
      await abrirFacultad(tester, 'Facultad Ingeniería');

      when(
        () => mockService.eliminarCarrera(
          filialId: any(named: 'filialId'),
          facultadId: any(named: 'facultadId'),
          carreraId: any(named: 'carreraId'),
        ),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(seconds: 1));
        return true;
      });

      await tapEliminarCarrera(tester, 'Ingeniería de Sistemas');
      await tester.tap(find.text('Eliminar'));
      await tester.pump();

      expect(find.text('Eliminando carrera...'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('muestra diálogo de carga al eliminar carrera', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, estructura: estructuraMinima());
      await abrirFacultad(tester, 'Facultad Ingeniería');

      when(
        () => mockService.eliminarCarrera(
          filialId: any(named: 'filialId'),
          facultadId: any(named: 'facultadId'),
          carreraId: any(named: 'carreraId'),
        ),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return true;
      });

      await tapEliminarCarrera(tester, 'Ingeniería de Sistemas');
      await tester.tap(find.text('Eliminar'));
      await tester.pump();

      expect(find.text('Eliminando carrera...'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('eliminar carrera exitosa refresca y muestra mensaje', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, estructura: estructuraMinima());
      await abrirFacultad(tester, 'Facultad Ingeniería');

      when(
        () => mockService.eliminarCarrera(
          filialId: 'lima',
          facultadId: 'fac_ing',
          carreraId: 'c1',
        ),
      ).thenAnswer((_) async => true);

      await tapEliminarCarrera(tester, 'Ingeniería de Sistemas');

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(find.text('Carrera eliminada exitosamente'), findsOneWidget);
      verify(
        () => mockService.eliminarCarrera(
          filialId: 'lima',
          facultadId: 'fac_ing',
          carreraId: 'c1',
        ),
      ).called(1);
    });

    testWidgets('eliminar carrera fallida muestra error', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, estructura: estructuraMinima());
      await abrirFacultad(tester, 'Facultad Ingeniería');

      when(
        () => mockService.eliminarCarrera(
          filialId: any(named: 'filialId'),
          facultadId: any(named: 'facultadId'),
          carreraId: any(named: 'carreraId'),
        ),
      ).thenAnswer((_) async => false);

      await tapEliminarCarrera(tester, 'Ingeniería de Sistemas');

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(find.text('Error al eliminar la carrera'), findsOneWidget);
    });

    testWidgets('no muestra snackbar si se desmonta durante error de carga', (
      WidgetTester tester,
    ) async {
      when(() => mockService.inicializarSiEsNecesario())
          .thenAnswer((_) async => true);
      when(() => mockService.getEstructuraCompleta()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        throw Exception('fallo tardío');
      });

      await tester.pumpWidget(
        MaterialApp(
          home: CrearFilialesScreen(filialesService: mockService),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
