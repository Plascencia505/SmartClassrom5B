class SalonStatus {
  final String id;
  final double temperatura;
  final int luz; // Viene de 'iluminacion'
  final int humedad; // NUEVO: Viene de 'humedad'
  final bool sistemaActivo;

  // Actuadores Reales del JSON
  final bool ventiladorActivo; // Viene de 'ventilador_activo'
  final bool ventanaAbierta; // Viene de 'ventana_abierta'

  SalonStatus({
    required this.id,
    required this.temperatura,
    required this.luz,
    required this.humedad,
    required this.sistemaActivo,
    required this.ventiladorActivo,
    required this.ventanaAbierta,
  });

  factory SalonStatus.fromRealtime(String id, Map<dynamic, dynamic> data) {
    // Función auxiliar para evitar errores si llega un entero en vez de double
    double parseDouble(dynamic value) {
      if (value is int) return value.toDouble();
      if (value is double) return value;
      return 0.0;
    }

    return SalonStatus(
      id: id,
      temperatura: parseDouble(data['temperatura']),
      // Mapeamos las llaves exactas de tu JSON
      luz: (data['iluminacion'] ?? 0).toInt(),
      humedad: (data['humedad'] ?? 0).toInt(),
      sistemaActivo: data['sistema_activo'] ?? true,
      ventiladorActivo: data['ventilador_activo'] ?? false,
      ventanaAbierta: data['ventana_abierta'] ?? false,
    );
  }
}
