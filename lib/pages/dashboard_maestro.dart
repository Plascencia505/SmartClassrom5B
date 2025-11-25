import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartclassrom/models/salon_status.dart';

class DashboardMaestro extends StatefulWidget {
  const DashboardMaestro({super.key});

  @override
  State<DashboardMaestro> createState() => _DashboardMaestroState();
}

class _DashboardMaestroState extends State<DashboardMaestro> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Map<String, dynamic>? userData;
  String? salonId; // ID para Realtime (ej: salon1)
  String? salonNombre; // Nombre para mostrar (ej: S1)
  String? grupoActual;

  final String _rfidRealAlumno = "CA 31 48 01";

  // TRADUCTOR: Firestore (Corto) -> Realtime (Largo)
  final Map<String, String> _mapaIds = {
    'monitor': 'monitor',
    's1': 'salon1',
    's2': 'salon2',
    's3': 'salon3',
  };

  final Map<String, String> _nombresBonitos = {
    'monitor': 'Lab. IoT (Real)',
    'salon1': 'Aula 101',
    'salon2': 'Aula 102',
    'salon3': 'Aula 103',
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      userData = args;

      // 1. Obtenemos el ID que viene de Firestore (Ej: "S1" o "MONITOR")
      String firestoreId =
          userData?['salon_asignado']?.toString().toLowerCase() ?? '';
      salonNombre = firestoreId.toUpperCase();

      // 2. Lo traducimos a la llave de Realtime (Ej: "salon1")
      // Si no encuentra traducción, usa el mismo ID (fallback)
      salonId = _mapaIds[firestoreId] ?? firestoreId;

      // 3. Obtener grupo
      if (userData!['grupos'] is List &&
          (userData!['grupos'] as List).isNotEmpty) {
        grupoActual = userData!['grupos'][0];
      } else if (userData!['grupos'] is String) {
        grupoActual = userData!['grupos'];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null || salonId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF527630),
        title: const Text(
          "Monitor Docente",
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return _buildWebLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );
  }

  // --- LAYOUTS ---

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 20),
          Text(
            "MI AULA ACTUAL ($salonNombre)",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          _buildCurrentClassSection(),
          const SizedBox(height: 30),
          const Text(
            "OTRAS AULAS",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          _buildNeighborsSection(),
        ],
      ),
    );
  }

  Widget _buildWebLayout() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // COLUMNA PRINCIPAL
          Expanded(
            flex: 7,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeCard(),
                  const SizedBox(height: 25),
                  Text(
                    "MI AULA ACTUAL ($salonNombre)",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF527630),
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildCurrentClassSection(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          // COLUMNA LATERAL
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Campus en Vivo",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Monitoreo de aulas vecinas",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  _buildNeighborsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- SECCIÓN CLASE ACTUAL ---
  Widget _buildCurrentClassSection() {
    return StreamBuilder(
      stream: _dbRef.child(salonId!).onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text("Conectando con el aula..."),
            ),
          );
        }

        final dataMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        final status = SalonStatus.fromRealtime(salonId!, dataMap);

        return Column(
          children: [
            _buildStatusCard(status),
            const SizedBox(height: 15),
            _buildSensorsGrid(status),
            const SizedBox(height: 15),
            _buildActuatorsGrid(status),
            const SizedBox(height: 25),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Asistencia - Grupo $grupoActual",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "En vivo",
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  _buildListaAsistencia(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // --- SECCIÓN VECINOS ---
  Widget _buildNeighborsSection() {
    return StreamBuilder(
      stream: _dbRef.onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(child: LinearProgressIndicator());
        }

        final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        final List<SalonStatus> vecinos = [];

        data.forEach((key, value) {
          // Filtro: Mostrar todos MENOS el que estoy viendo actualmente
          if (key.toString() != salonId && value is Map) {
            try {
              vecinos.add(SalonStatus.fromRealtime(key.toString(), value));
            } catch (e) {}
          }
        });

        vecinos.sort((a, b) => a.id.compareTo(b.id));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: vecinos.length,
          itemBuilder: (context, index) {
            final vecino = vecinos[index];
            final nombre = _nombresBonitos[vecino.id] ?? vecino.id;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: vecino.sistemaActivo
                        ? const Color(0xFFE8F5E9)
                        : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.meeting_room,
                    color: vecino.sistemaActivo
                        ? const Color(0xFF64B32E)
                        : Colors.grey,
                  ),
                ),
                title: Text(
                  nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Row(
                  children: [
                    Icon(Icons.thermostat, size: 14, color: Colors.orange[800]),
                    Text(
                      "${vecino.temperatura}°C  ",
                      style: const TextStyle(fontSize: 12),
                    ),
                    Icon(Icons.wb_sunny, size: 14, color: Colors.amber[800]),
                    Text(
                      "${vecino.luz}lx",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF527630), Color(0xFF64B32E)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            child: Text(
              userData!['nombre'].substring(0, 1),
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFF527630),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hola, ${userData!['nombre']}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Materia: ${userData!['materia']}",
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(SalonStatus status) {
    bool activo = status.sistemaActivo;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: activo ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: activo ? const Color(0xFF64B32E) : Colors.red,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              activo ? Icons.sensors : Icons.sensors_off,
              color: activo ? const Color(0xFF527630) : Colors.red,
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activo ? "MONITOREO ACTIVO" : "SISTEMA INACTIVO",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: activo ? const Color(0xFF2E5B18) : Colors.red[900],
                ),
              ),
              Text(
                "Estás viendo: ${_nombresBonitos[salonId] ?? salonId}",
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSensorsGrid(SalonStatus status) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            Icons.thermostat,
            "${status.temperatura}°C",
            "Temp",
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            Icons.wb_sunny,
            "${status.luz} lx",
            "Luz",
            Colors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            Icons.water_drop,
            "${status.humedad}%",
            "Hum",
            Colors.blueAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildActuatorsGrid(SalonStatus status) {
    return Row(
      children: [
        Expanded(child: _buildStateChip("Ventilador", status.ventiladorActivo)),
        const SizedBox(width: 12),
        Expanded(child: _buildStateChip("Ventana", status.ventanaAbierta)),
      ],
    );
  }

  Widget _buildListaAsistencia() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('alumnos')
          .where('grupo', isEqualTo: grupoActual)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const Center(child: Text("Lista vacía"));
        final docs = snapshot.data!.docs;
        int presentes = 0;
        List<Widget> listaVisual = [];
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          // Nota: Aquí se usa el RFID Real. Como es una Demo, en los salones falsos nadie tendrá ese rfid, así que saldrán ausentes.
          // Es el comportamiento correcto para la maqueta.
          bool isPresente = (data['rfid'] == _rfidRealAlumno);
          if (isPresente) presentes++;
          listaVisual.add(
            _buildAlumnoRow(data['nombre'] ?? 'Alumno', isPresente),
          );
        }
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSimpleCounter("Total", "${docs.length}"),
                _buildSimpleCounter(
                  "Presentes",
                  "$presentes",
                  color: const Color(0xFF64B32E),
                ),
                _buildSimpleCounter(
                  "Faltas",
                  "${docs.length - presentes}",
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: listaVisual,
            ),
          ],
        );
      },
    );
  }

  // --- UI MICRO ---
  Widget _buildInfoCard(IconData i, String v, String l, Color c) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
      ],
    ),
    child: Column(
      children: [
        Icon(i, color: c, size: 28),
        const SizedBox(height: 8),
        Text(
          v,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(l, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    ),
  );
  Widget _buildStateChip(String l, bool on) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: on ? const Color(0xFF64B32E) : Colors.transparent,
      ),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
      ],
    ),
    child: Column(
      children: [
        Text(
          l,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: on ? const Color(0xFF64B32E) : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            on ? "ENCENDIDO" : "APAGADO",
            style: TextStyle(
              color: on ? Colors.white : Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
  Widget _buildSimpleCounter(
    String l,
    String v, {
    Color color = Colors.black87,
  }) => Column(
    children: [
      Text(
        v,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      Text(l, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ],
  );
  Widget _buildAlumnoRow(String n, bool p) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(
          p ? Icons.check_circle : Icons.cancel,
          color: p ? const Color(0xFF64B32E) : Colors.red[200],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(n, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        Text(
          p ? "Presente" : "Falta",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: p ? const Color(0xFF527630) : Colors.red[300],
          ),
        ),
      ],
    ),
  );
}
