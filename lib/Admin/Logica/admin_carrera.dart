// lib/admin/admin_carrera.dart
//
// Lógica pura del panel de administrador de carrera.
// Sin imports de Flutter widgets — solo dart:core y dependencias de datos.

import 'package:flutter/foundation.dart';
import '/prefs_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Modelo de datos
// ─────────────────────────────────────────────────────────────────────────────

class AdminCarreraData {
  final String adminName;
  final String carrera;
  final String facultad;
  final String sede;
  final List<String> permisos;

  const AdminCarreraData({
    required this.adminName,
    required this.carrera,
    required this.facultad,
    required this.sede,
    required this.permisos,
  });

  factory AdminCarreraData.empty() => const AdminCarreraData(
        adminName: 'Administrador',
        carrera: '',
        facultad: '',
        sede: '',
        permisos: [],
      );

  factory AdminCarreraData.fromMap(Map<String, dynamic> map) => AdminCarreraData(
        adminName: map['userName'] as String? ?? 'Administrador',
        carrera: map['carrera'] as String? ?? '',
        facultad: map['facultad'] as String? ?? '',
        sede: map['filialNombre'] as String? ?? '',
        permisos: List<String>.from(map['permisos'] as List? ?? []),
      );

  /// Devuelve true si el administrador posee el permiso indicado.
  bool tienePermiso(String permiso) => permisos.contains(permiso);

  /// Texto informativo que se muestra en el pie del panel.
  String get notaInformativa =>
      'Solo puedes gestionar datos de $carrera. '
      'Todos los filtros se aplican automáticamente.';

  @override
  String toString() =>
      'AdminCarreraData(adminName: $adminName, carrera: $carrera, '
      'facultad: $facultad, sede: $sede, permisos: $permisos)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminCarreraData &&
          runtimeType == other.runtimeType &&
          adminName == other.adminName &&
          carrera == other.carrera &&
          facultad == other.facultad &&
          sede == other.sede &&
          _listEquals(permisos, other.permisos);

  @override
  int get hashCode =>
      adminName.hashCode ^
      carrera.hashCode ^
      facultad.hashCode ^
      sede.hashCode ^
      permisos.hashCode;

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lógica del controlador (sin estado de UI)
// ─────────────────────────────────────────────────────────────────────────────

class AdminCarreraLogic {
  /// Carga los datos del administrador desde SharedPreferences.
  /// Devuelve [AdminCarreraData.empty()] si no hay datos guardados.
  static Future<AdminCarreraData> cargarDatos() async {
    try {
      final raw = await PrefsHelper.getAdminCarreraData();
      if (raw != null) return AdminCarreraData.fromMap(raw);
    } catch (e) {
      debugPrint('AdminCarreraLogic.cargarDatos — error: $e');
    }
    return AdminCarreraData.empty();
  }

  /// Cierra la sesión del administrador borrando las preferencias locales.
  static Future<void> cerrarSesion() async {
    await PrefsHelper.logout();
  }

  /// Devuelve la lista de ítems de menú que deben mostrarse,
  /// filtrados según los permisos del administrador.
  static List<MenuItemConfig> itemsVisibles(AdminCarreraData data) {
    return allMenuItems
        .where((item) =>
            item.permiso == null || data.tienePermiso(item.permiso!))
        .toList();
  }

  /// Catálogo completo de ítems del menú con su permiso requerido.
  static const List<MenuItemConfig> allMenuItems = [
    MenuItemConfig(
      id: 'estudiantes',
      imagePath: 'assets/icons/usuario.png',
      title: 'Registrar\nEstudiantes',
      subtitle: 'Crear cuentas de estudiantes',
      permiso: 'estudiantes',
    ),
    MenuItemConfig(
      id: 'grupos',
      imagePath: 'assets/icons/reunion.png',
      title: 'Gestión de\nGrupos',
      subtitle: 'Organizar estudiantes en grupos',
      permiso: 'grupos',
    ),
    MenuItemConfig(
      id: 'jurados',
      imagePath: 'assets/icons/jurado.png',
      title: 'Gestión de\nJurados',
      subtitle: 'Ver y gestionar jurados',
      permiso: 'proyectos',
    ),
    MenuItemConfig(
      id: 'proyectos',
      imagePath: 'assets/icons/notas.png',
      title: 'Asignar\nProyectos',
      subtitle: 'Asignar proyectos a jurados',
      permiso: 'proyectos',
    ),
    MenuItemConfig(
      id: 'rubricas',
      imagePath: 'assets/icons/criterios.png',
      title: 'Gestión de\nRúbricas',
      subtitle: 'Crear y editar rúbricas',
      permiso: 'proyectos',
    ),
    MenuItemConfig(
      id: 'evaluaciones',
      imagePath: 'assets/icons/evaluaciones.png',
      title: 'Ver\nEvaluaciones',
      subtitle: 'Revisar evaluaciones de jurados',
      permiso: 'evaluaciones',
    ),
    // Sin permiso requerido — siempre visible
    MenuItemConfig(
      id: 'sesiones',
      imagePath: 'assets/icons/sesion.png',
      title: 'Gestión de\nSesiones',
      subtitle: 'Controlar sesiones de estudiantes',
      permiso: null,
    ),
    MenuItemConfig(
      id: 'eventos',
      imagePath: 'assets/icons/evento.png',
      title: 'Gestión de\nEventos',
      subtitle: 'Crear y ver eventos',
      permiso: 'eventos',
    ),
    MenuItemConfig(
      id: 'certificados',
      imagePath: 'assets/icons/certificado.png',
      title: 'Generar\nCertificados',
      subtitle: 'Emitir certificados PDF',
      permiso: null,
    ),
    MenuItemConfig(
      id: 'reportes',
      imagePath: 'assets/icons/reporte.png',
      title: 'Reportes',
      subtitle: 'Ver estadísticas y reportes',
      permiso: 'reportes',
    ),
    MenuItemConfig(
      id: 'pagos',
      imagePath: 'assets/icons/pagos.png',
      title: 'Gestión de\nPagos',
      subtitle: 'Controlar acceso por pago',
      permiso: null,
    ),
    MenuItemConfig(
      id: 'cuenta',
      imagePath: 'assets/icons/admin.png',
      title: 'Editar\nCuenta',
      subtitle: 'Modificar datos personales',
      permiso: null,
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Value object para cada ítem del menú
// ─────────────────────────────────────────────────────────────────────────────

class MenuItemConfig {
  final String id;
  final String imagePath;
  final String title;
  final String subtitle;

  /// Permiso requerido para que el ítem sea visible.
  /// null → siempre visible.
  final String? permiso;

  const MenuItemConfig({
    required this.id,
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.permiso,
  });

  bool get siempreVisible => permiso == null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuItemConfig &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          permiso == other.permiso;

  @override
  int get hashCode => id.hashCode ^ permiso.hashCode;

  @override
  String toString() => 'MenuItemConfig(id: $id, permiso: $permiso)';
}