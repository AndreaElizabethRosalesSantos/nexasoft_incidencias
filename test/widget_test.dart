import 'package:flutter_test/flutter_test.dart';
import 'package:nexasoft_incidencias/model/incidencia.dart';
import 'package:nexasoft_incidencias/services/gestor_incidencias.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Una incidencia antigua puede convertirse desde JSON', () {
    final registro = Incidencia.desdeJson({
      'id': 'INC-DEMO',
      'titulo': 'Prueba',
      'descripcion': 'Caso de ejemplo',
      'cliente': 'Cliente ficticio',
      'categoria': 'Redes',
      'estado': 'Pendiente',
      'fecha': '2026-10-12',
    });
    expect(registro.id, 'INC-DEMO');
    expect(registro.toJson()['estado'], 'Pendiente');
  });

  test('cambiarEstado actualiza el estado, los pendientes y guarda los cambios',
      () async {
    SharedPreferences.setMockInitialValues({});
    final gestor = GestorIncidencias()
      ..incidencias = [
        Incidencia(
          id: 'INC-DEMO',
          titulo: 'Prueba',
          descripcion: 'Caso de ejemplo',
          cliente: 'Cliente ficticio',
          categoria: 'Redes',
          estado: 'Pendiente',
          fecha: '2026-10-12',
        ),
      ]
      ..cantidadPendientes = 1;

    await gestor.cambiarEstado('INC-DEMO', 'Resuelta');

    expect(gestor.porId('INC-DEMO')?.estado, 'Resuelta');
    expect(gestor.cantidadPendientes, 0);

    final guardado =
        await SharedPreferencesAsync().getString('nexasoft_incidencias_v1');
    expect(guardado, contains('"estado":"Resuelta"'));
  });
}
