import 'package:flutter/material.dart';
import '../model/incidencia.dart';
import '../services/gestor_incidencias.dart';
import 'pantalla_detalle.dart';
import 'pantalla_nueva.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  final GestorIncidencias g = GestorIncidencias();
  bool cargando = true;
  String? error;
  String busqueda = '';
  // Variables para los filtros
   String estadoSeleccionado = 'Todos';
   String prioridadSeleccionada = 'Todas';


  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    setState(() {
      cargando = true;
      error = null;
    });
    try {
      await g.iniciar();
    } catch (e) {
      error = 'No se pudieron cargar las incidencias: $e';
    }
    if (mounted) setState(() => cargando = false);
  }

// Metodo para aplicar busqueda y filtros combinados (Texto, Estado y Prioridad)
  List<Incidencia> get _itemsFiltrados {
    // Obtenemos primero los elementos que coinciden con el texto de búsqueda del gestor
    final baseItems = g.buscar(busqueda);

    return baseItems.where((item) {
      final coincideEstado = estadoSeleccionado == 'Todos' || item.estado == estadoSeleccionado;
      final coincidePrioridad = prioridadSeleccionada == 'Todas' || item.prioridad == prioridadSeleccionada;
      return coincideEstado && coincidePrioridad;
    }).toList();
  }

  // Metodo para restablecer los filtros y la consulta de bsqueda
  void _restablecerFiltros() {
    setState(() {
      busqueda = '';
      estadoSeleccionado = 'Todos';
      prioridadSeleccionada = 'Todas';
    });
  }
  Color colorEstado(String estado) {
    if (estado == 'Resuelta') return const Color(0xFF147D64);
    if (estado == 'En proceso') return const Color(0xFFB56B13);
    return const Color(0xFFAC4052);
  }

  Widget resumen(String etiqueta, String valor, IconData icono) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icono, size: 19, color: const Color(0xFF174C83)),
              const SizedBox(height: 4),
              Text(valor, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(etiqueta, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> abrirDetalle(Incidencia item) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => PantallaDetalle(gestor: g, id: item.id)),
    );
    if (mounted) setState(() {});
  }

  Future<void> abrirFormulario() async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PantallaNueva(gestor: g)),
    );
    if (guardado == true && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incidencia registrada')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _itemsFiltrados;
    return Scaffold(
      appBar: AppBar(
        title: const Text('NexaSoft | Incidencias'),
        actions: [
          IconButton(
            tooltip: 'Restablecer datos de demostración',
            onPressed: () async {
              final aceptar = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Restablecer demostración'),
                  content: const Text('Se descartarán los cambios locales y se cargarán las incidencias iniciales.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restablecer')),
                  ],
                ),
              );
              if (aceptar != true) return;
              try {
                await g.reiniciarDemo();
                if (mounted) setState(() {});
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al reiniciar: $e')));
                }
              }
            },
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      floatingActionButton: cargando || error != null
          ? null
          : FloatingActionButton.extended(
              onPressed: abrirFormulario,
              label: const Text('Nueva incidencia'),
              icon: const Icon(Icons.add),
            ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: cargar, child: const Text('Reintentar')),
                  ]),
                ))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                          child: Row(children: [
                            resumen('Pendientes', '${g.contar('Pendiente')}', Icons.pending_actions),
                            resumen('En proceso', '${g.contar('En proceso')}', Icons.build_outlined),
                            resumen('Resueltas', '${g.contar('Resuelta')}', Icons.check_circle_outline),
                          ]),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 5),
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Buscar incidencias',
                              hintText: 'Ejemplo: WiFi, correo, pantalla',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (texto) => setState(() => busqueda = texto),
                            controller: TextEditingController.fromValue(
                              TextEditingValue(
                                text: busqueda,
                                selection: TextSelection.collapsed(offset: busqueda.length),
                              ),
                            ),
                          ),
                        ),

                        // FILTROS COMBINABLES (Estado y Prioridad) + BOTÓN RESTABLECER
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 5),
                          child: Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: estadoSeleccionado,
                                  decoration: const InputDecoration(
                                    labelText: 'Estado',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  ),
                                  items: ['Todos', 'Pendiente', 'En proceso', 'Resuelta']
                                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                      .toList(),
                                  onChanged: (val) => setState(() => estadoSeleccionado = val!),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: prioridadSeleccionada,
                                  decoration: const InputDecoration(
                                    labelText: 'Prioridad',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  ),
                                  items: ['Todas', 'Baja', 'Media', 'Alta']
                                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                                      .toList(),
                                  onChanged: (val) => setState(() => prioridadSeleccionada = val!),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                ),
                                onPressed: _restablecerFiltros,
                                icon: const Icon(Icons.clear_all, size: 18),
                                label: const Text('Limpiar'),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text('${items.length} registros', style: const TextStyle(color: Colors.black54)),
                          ),
                        ),
                        Expanded(
                          child: items.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.search_off, size: 48, color: Colors.grey),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'No se encontraron incidencias con los filtros aplicados.',
                                          style: TextStyle(fontSize: 16, color: Colors.grey),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 12),
                                        OutlinedButton.icon(
                                          onPressed: _restablecerFiltros,
                                          icon: const Icon(Icons.refresh),
                                          label: const Text('Restablecer búsqueda y filtros'),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.only(left: 12, right: 12, bottom: 100),
                                  itemCount: items.length,
                                  itemBuilder: (context, i) {
                                    final item = items[i];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        title: Text(item.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('${item.id}  ·  ${item.cliente}  ·  ${item.prioridad}'),
                                              const SizedBox(height: 6),
                                              Text(item.estado, style: TextStyle(
                                                color: colorEstado(item.estado), fontWeight: FontWeight.bold,
                                              )),
                                            ],
                                          ),
                                        ),
                                        trailing: const Icon(Icons.chevron_right),
                                        onTap: () => abrirDetalle(item),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
