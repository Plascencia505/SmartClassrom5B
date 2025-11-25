class SalonStatus {
  // ID del salón en Realtime Database (monitor, salon1, etc.)
  final String id;

  // Sensores
  final double temperatura; // Valor de temperatura reportado
  final int luz; // Nivel de iluminación (llave: 'iluminacion')
  final int humedad; // Porcentaje de humedad (llave: 'humedad')
  final bool sistemaActivo; // Estado general del sistema IoT

  // Actuadores (según estructura del JSON recibido)
  final bool ventiladorActivo; // Llave: 'ventilador_activo'
  final bool ventanaAbierta; // Llave: 'ventana_abierta'

  // Constructor principal del modelo
  SalonStatus({
    required this.id,
    required this.temperatura,
    required this.luz,
    required this.humedad,
    required this.sistemaActivo,
    required this.ventiladorActivo,
    required this.ventanaAbierta,
  });

  // Fábrica que construye un objeto desde los datos del Realtime Database
  factory SalonStatus.fromRealtime(String id, Map<dynamic, dynamic> data) {
    // Conversión segura a double para evitar errores si llega entero desde Firebase
    double parseDouble(dynamic value) {
      if (value is int) return value.toDouble();
      if (value is double) return value;
      return 0.0; // Valor por defecto si viene nulo o no válido
    }

    return SalonStatus(
      id: id,

      // Conversión segura de temperatura
      temperatura: parseDouble(data['temperatura']),

      // Sensores en el JSON (con fallback a 0 si no existe)
      luz: (data['iluminacion'] ?? 0).toInt(),
      humedad: (data['humedad'] ?? 0).toInt(),

      // Estado del sistema (true por defecto)
      sistemaActivo: data['sistema_activo'] ?? true,

      // Actuadores recibidos desde el nodo Realtime
      ventiladorActivo: data['ventilador_activo'] ?? false,
      ventanaAbierta: data['ventana_abierta'] ?? false,
    );
  }
}
