import '../data/almacen_local.dart';
import '../model/incidencia.dart';

class GestorIncidencias {
  final AlmacenLocal datos = AlmacenLocal();
  List<Incidencia> incidencias = [];
  int cantidadPendientes = 0;

  Future<void> iniciar() async {
    incidencias = await datos.leer();
    cantidadPendientes =
        incidencias.where((x) => x.estado == 'Pendiente').length;
  }

  List<Incidencia> buscar(String texto) {
    // Limpiamos los espacios sobrantes y pasamos la consulta a minúsculas
    final query = texto.trim().toLowerCase();
    if (query.isEmpty) return incidencias;

    // Buscamos tanto en el título como en la descripción, ignorando mayúsculas/minúsculas
    return incidencias.where((x) {
      final tituloLower = x.titulo.toLowerCase();
      final descripcionLower = x.descripcion.toLowerCase();

      return tituloLower.contains(query) || descripcionLower.contains(query);
    }).toList();
  }

  Incidencia? porId(String id) {
    for (var x in incidencias) {
      if (x.id == id) return x;
    }
    return null;
  }

  int contar(String estado) {
    // Recorremos la lista completa para contar de forma dinámica y exacta según el estado solicitado
    return incidencias.where((x) => x.estado == estado).length;
  }

  Future<void> cambiarEstado(String id, String nuevoEstado) async {
    const estadosValidos = ['Pendiente', 'En proceso', 'Resuelta'];
    if (!estadosValidos.contains(nuevoEstado)) {
      throw ArgumentError.value(nuevoEstado, 'nuevoEstado', 'Estado no válido');
    }

    final incidencia = porId(id);
    if (incidencia == null) {
      throw StateError('No se encontró la incidencia $id');
    }

    final estadoAnterior = incidencia.estado;
    if (estadoAnterior == nuevoEstado) return;

    incidencia.estado = nuevoEstado;
    try {
      await datos.guardar(incidencias);
    } catch (error) {
      incidencia.estado = estadoAnterior;
      rethrow;
    }
    cantidadPendientes = contar('Pendiente');
  }

// 2. Nuevo metodo para cambiar y guardar la prioridad desde la pantalla de detalle
Future<void> cambiarPrioridad(String id, String nuevaPrioridad) async {
    for (var i = 0; i < incidencias.length; i++) {
      if (incidencias[i].id == id) {
        incidencias[i].prioridad = nuevaPrioridad;
        break;
      }
    }
    // Guardar cambios en el almacenamiento local
    await datos.guardar(incidencias);
  }

// 1. Actualizar el metodo crear para incluir la prioridad seleccionada
  Future<void> crear(String titulo, String descripcion, String cliente,
      String categoria, String prioridad) async { // <--- Añadir parametro prioridad
    final nuevo = Incidencia(
      id: 'INC-${DateTime.now().microsecondsSinceEpoch}',
      titulo: titulo,
      descripcion: descripcion,
      cliente: cliente,
      categoria: categoria,
      estado: 'Pendiente',
      fecha: DateTime.now().toIso8601String().split('T').first,
      prioridad: prioridad, // <--- Asigno la prioridad aqui
    );
    incidencias.insert(0, nuevo);
    if (nuevo.estado == 'Pendiente') {
      cantidadPendientes++;
    }
    await datos.guardar(incidencias);
  }

  Future<void> reiniciarDemo() async {
    await datos.restaurarDatosDeEjemplo();
    await iniciar();
  }
}
