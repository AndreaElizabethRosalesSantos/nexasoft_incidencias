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

  Future<void> cambiarEstado(String id, String estado) async {
    for (var i = 0; i < incidencias.length; i++) {
      if (incidencias[i].id == id) {
        incidencias[i].estado = estado;
        break;
      }
    }
    // Actualizamos el contador de pendientes y guardamos para que no se borre al reiniciar
    cantidadPendientes =
        incidencias.where((x) => x.estado == 'Pendiente').length;
    await datos.guardar(incidencias);
  }

  Future<void> crear(String titulo, String descripcion, String cliente,
      String categoria) async {
    final nuevo = Incidencia(
      id: 'INC-${DateTime.now().microsecondsSinceEpoch}',
      titulo: titulo,
      descripcion: descripcion,
      cliente: cliente,
      categoria: categoria,
      estado: 'Pendiente',
      fecha: DateTime.now().toIso8601String().split('T').first,
    );
    incidencias.insert(0, nuevo);
    cantidadPendientes++;
    await datos.guardar(incidencias);
  }

  Future<void> reiniciarDemo() async {
    await datos.restaurarDatosDeEjemplo();
    await iniciar();
  }
}
