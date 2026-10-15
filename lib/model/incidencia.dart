class Incidencia {
  String id;
  String titulo;
  String descripcion;
  String cliente;
  String categoria;
  String estado;
  String fecha;
  String prioridad; // <--- 1. Nuevo campo agregado para FEAT-001

  Incidencia({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.cliente,
    required this.categoria,
    required this.estado,
    required this.fecha,
    this.prioridad = 'Media', // <--- 2. Valor predeterminado
  });

  factory Incidencia.desdeJson(Map<String, dynamic> m) {
   // Definimos las prioridades válidas para evitar valores distintos (Criterio de aceptación)
    const prioridadesValidas = ['Baja', 'Media', 'Alta'];
    final p = m['prioridad']?.toString();

    return Incidencia(
      id: m['id']?.toString() ?? '',
      titulo: m['titulo']?.toString() ?? '',
      descripcion: m['descripcion']?.toString() ?? '',
      cliente: m['cliente']?.toString() ?? '',
      categoria: m['categoria']?.toString() ?? 'Software',
      estado: m['estado']?.toString() ?? 'Pendiente',
      fecha: m['fecha']?.toString() ?? '',
      // 3. Validación: si no existe el campo o es inválido, asigna 'Media' automáticamente (Registros antiguos)
      prioridad: (p != null && prioridadesValidas.contains(p)) ? p : 'Media',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'cliente': cliente,
      'categoria': categoria,
      'estado': estado,
      'fecha': fecha,
      'prioridad': prioridad, // <--- 4. Incluir en la serialización para persistencia
    };
  }
}
