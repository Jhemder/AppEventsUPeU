// lib/Admin/Interfaz/admin_carrera_screen.dart
//
// Pantalla del panel de administrador de carrera.
// Toda la lógica vive en admin_carrera.dart — aquí solo hay widgets.

import 'package:flutter/material.dart';
import '../Logica/admin_carrera.dart'; // ← CORRECCIÓN: ruta relativa correcta
import '/login.dart';

// Rutas — importa las pantallas destino según tu estructura real
import '/admin/logica/registro_estudiantes.dart';
// import 'editar_admin_carrera.dart';
// import 'crear_eventos_carrera_screen.dart';
// import 'gestion_grupos_carrera_screen.dart';
// import 'asignar_proyectos_carrera_screen.dart';
// import 'gestion_rubricas_carrera_screen.dart';
// import 'gestion_jurados_carrera_screen.dart';
// import 'gestion_pagos_screen.dart';
// import 'generar_certificados_screen.dart';
// import 'gestion_sesiones_screen.dart';

class AdminCarreraScreen extends StatefulWidget {
  const AdminCarreraScreen({super.key});

  @override
  State<AdminCarreraScreen> createState() => _AdminCarreraScreenState();
}

class _AdminCarreraScreenState extends State<AdminCarreraScreen> {
  AdminCarreraData _data = AdminCarreraData.empty();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await AdminCarreraLogic.cargarDatos();
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await AdminCarreraLogic.cerrarSesion();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  /// Mapea el id del ítem a la pantalla destino.
  void _navegar(String id) {
    final Widget? destino = switch (id) {
      'estudiantes'  => const RegistroEstudiantesScreen(),
      // 'grupos'       => const GestionGruposCarreraScreen(),
      // 'jurados'      => const GestionJuradosCarreraScreen(),
      // 'proyectos'    => const AsignarProyectosCarreraScreen(),
      // 'rubricas'     => const GestionRubricasCarreraScreen(),
      // 'evaluaciones' => const EvaluacionesScreen(),
      // 'sesiones'     => const GestionSesionesScreen(),
      // 'eventos'      => const CrearEventosCarreraScreen(),
      // 'certificados' => const GenerarCertificadosScreen(),
      // 'reportes'     => const ReportesScreen(),
      // 'pagos'        => const GestionPagosScreen(),
      // 'cuenta'       => const EditarAdminCarreraScreen(),
      _              => null,
    };
    if (destino != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => destino));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E3A5F),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final items = AdminCarreraLogic.itemsVisibles(_data);

    return Scaffold(
      backgroundColor: const Color(0xFF1E3A5F),
      body: SafeArea(
        child: Column(
          children: [
            _Header(data: _data, onLogout: _logout),
            Expanded(
              child: _ContentArea(
                data: _data,
                items: items,
                onItemTap: _navegar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets privados
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.data, required this.onLogout});

  final AdminCarreraData data;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.school,
                    color: Color(0xFF1E3A5F),
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Panel de Administrador',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      data.adminName,
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white, size: 28),
                onPressed: onLogout,
                tooltip: 'Cerrar Sesión',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _CarreraInfoCard(data: data),
        ],
      ),
    );
  }
}

class _CarreraInfoCard extends StatelessWidget {
  const _CarreraInfoCard({required this.data});

  final AdminCarreraData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(icon: Icons.business, text: data.facultad, small: true),
          const SizedBox(height: 6),
          _InfoRow(icon: Icons.school, text: data.carrera, bold: true),
          const SizedBox(height: 6),
          _InfoRow(icon: Icons.location_on, text: data.sede, small: true),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    this.small = false,
    this.bold = false,
  });

  final IconData icon;
  final String text;
  final bool small;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            color: bold ? Colors.white : Colors.white70,
            size: small ? 16 : 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: bold ? Colors.white : Colors.white70,
              fontSize: small ? 12 : 14,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}

class _ContentArea extends StatelessWidget {
  const _ContentArea({
    required this.data,
    required this.items,
    required this.onItemTap,
  });

  final AdminCarreraData data;
  final List<MenuItemConfig> items;
  final void Function(String id) onItemTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFE8EDF2),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestión de Carrera',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A5F),
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.80,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: items
                  .map((item) => _MenuCard(item: item, onTap: onItemTap))
                  .toList(),
            ),
            const SizedBox(height: 24),
            _NotaInformativa(nota: data.notaInformativa),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.item, required this.onTap});

  final MenuItemConfig item;
  final void Function(String id) onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: InkWell(
        onTap: () => onTap(item.id),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 65,
                height: 65,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(13),
                child: Image.asset(
                  item.imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.image_not_supported,
                    size: 32,
                    color: Colors.grey[400],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3A5F),
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
              const SizedBox(height: 4),
              Text(
                item.subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF64748B),
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotaInformativa extends StatelessWidget {
  const _NotaInformativa({required this.nota});

  final String nota;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700], size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              nota,
              style: TextStyle(color: Colors.blue[700], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}