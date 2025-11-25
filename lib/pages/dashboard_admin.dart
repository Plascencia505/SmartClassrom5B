import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartclassrom/models/salon_status.dart'; // Verifica tu ruta de importación

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({super.key});

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  final Map<String, String> _mapaRealtimeFirestore = {
    'monitor': 'MONITOR',
    'salon1': 'S1',
    'salon2': 'S2',
    'salon3': 'S3',
  };

  final Map<String, String> _nombresSalones = {
    'monitor': 'Laboratorio IoT (Monitor)',
    'salon1': 'Aula 101 - Matematicas',
    'salon2': 'Aula 102 - Historia',
    'salon3': 'Aula 103 - Química',
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Lógica responsiva para el Grid
        int columnas = 2;
        double aspectRatio = 0.8;

        if (constraints.maxWidth > 1200) {
          columnas = 4;
          aspectRatio = 1.0;
        } else if (constraints.maxWidth > 800) {
          columnas = 3;
          aspectRatio = 0.9;
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF0F2F5),
          appBar: AppBar(
            backgroundColor: const Color(0xFF4E4D4D),
            title: const Text(
              "Panel General Administrativo",
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 10),
                  child: Text(
                    "Vista Global de Aulas",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF527630),
                    ),
                  ),
                ),

                Expanded(
                  child: StreamBuilder(
                    stream: _dbRef.onValue,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData ||
                          snapshot.data!.snapshot.value == null) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final data =
                          snapshot.data!.snapshot.value
                              as Map<dynamic, dynamic>;
                      final List<SalonStatus> listaSalones = [];

                      data.forEach((key, value) {
                        if (value is Map) {
                          try {
                            listaSalones.add(
                              SalonStatus.fromRealtime(key.toString(), value),
                            );
                          } catch (e) {
                            debugPrint("Error parseo: $e");
                          }
                        }
                      });

                      // Ordenar: Monitor primero
                      listaSalones.sort(
                        (a, b) => (a.id == 'monitor')
                            ? -1
                            : (b.id == 'monitor')
                            ? 1
                            : a.id.compareTo(b.id),
                      );

                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columnas,
                          childAspectRatio: aspectRatio,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: listaSalones.length,
                        itemBuilder: (context, index) {
                          return _buildSalonCard(listaSalones[index]);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSalonCard(SalonStatus salon) {
    final nombre = _nombresSalones[salon.id] ?? "Salón ${salon.id}";
    final firestoreId = _mapaRealtimeFirestore[salon.id];

    return InkWell(
      onTap: () =>
          _mostrarDetalleAsistencia(context, salon, nombre, firestoreId),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con nombre y bolita de estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.circle,
                    color: salon.sistemaActivo
                        ? const Color(0xFF64B32E)
                        : Colors.grey,
                    size: 12,
                  ),
                ],
              ),
              const Divider(),

              // INFO DE SENSORES (Ahora incluye Humedad)
              _infoRow(
                Icons.thermostat,
                "${salon.temperatura}°C",
                Colors.black87,
              ),
              const SizedBox(height: 5),
              _infoRow(Icons.wb_sunny, "${salon.luz} lx", Colors.black87),
              const SizedBox(height: 5),
              _infoRow(
                Icons.water_drop,
                "${salon.humedad}%",
                Colors.blueAccent,
              ), // <--- NUEVO

              const Spacer(),

              // ICONOS DE ACTUADORES (Actualizado al nuevo modelo)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Ventilador (antes AC)
                  _miniIcon(Icons.wind_power, salon.ventiladorActivo),
                  // Ventana
                  _miniIcon(Icons.window, salon.ventanaAbierta, alert: true),
                ],
              ),

              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Text(
                    "Ver Asistencia",
                    style: TextStyle(fontSize: 10, color: Colors.blueGrey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- MODAL DE DETALLE ---
  void _mostrarDetalleAsistencia(
    BuildContext context,
    SalonStatus salon,
    String nombre,
    String? firestoreId,
  ) {
    if (firestoreId == null) return;
    const String rfidRealAlumno = "CA 31 48 01";

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          nombre,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF527630),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(),

                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('salones')
                        .doc(firestoreId)
                        .get(),
                    builder: (context, snapSalon) {
                      if (!snapSalon.hasData) {
                        return const LinearProgressIndicator();
                      }

                      final salonData =
                          snapSalon.data!.data() as Map<String, dynamic>?;
                      if (salonData == null) {
                        return const Text("Datos no disponibles");
                      }

                      final grupo = salonData['grupo_actual'];
                      final materia = salonData['materia_actual'];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Materia: $materia",
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            "Grupo: $grupo",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),

                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('alumnos')
                                .where('grupo', isEqualTo: grupo)
                                .snapshots(),
                            builder: (context, snapAlumnos) {
                              if (snapAlumnos.connectionState ==
                                  ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              }
                              final docs = snapAlumnos.data?.docs ?? [];
                              if (docs.isEmpty) {
                                return const Text(
                                  "No hay alumnos en este grupo.",
                                );
                              }

                              int total = docs.length;
                              int presentes = 0;
                              for (var d in docs) {
                                if (d['rfid'] == rfidRealAlumno) presentes++;
                              }

                              return Card(
                                elevation: 0,
                                color: Colors.grey[100],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ExpansionTile(
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "$presentes / $total",
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4E4D4D),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        "Alumnos\nPresentes",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  children: [
                                    Container(
                                      height: 250,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      child: ListView.builder(
                                        itemCount: docs.length,
                                        itemBuilder: (context, i) {
                                          final alumno =
                                              docs[i].data()
                                                  as Map<String, dynamic>;
                                          final isPresente =
                                              (alumno['rfid'] ==
                                              rfidRealAlumno);

                                          return Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isPresente
                                                  ? const Color(0xFFE8F5E9)
                                                  : const Color(0xFFFFEBEE),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isPresente
                                                    ? const Color(0xFF64B32E)
                                                    : Colors.redAccent
                                                          .withOpacity(0.5),
                                              ),
                                            ),
                                            child: ListTile(
                                              leading: Icon(
                                                isPresente
                                                    ? Icons.check_circle
                                                    : Icons.cancel,
                                                color: isPresente
                                                    ? const Color(0xFF64B32E)
                                                    : Colors.red,
                                              ),
                                              title: Text(
                                                alumno['nombre'] ??
                                                    "Sin Nombre",
                                              ),
                                              trailing: Text(
                                                isPresente
                                                    ? "ASISTIÓ"
                                                    : "FALTA",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: isPresente
                                                      ? const Color(0xFF2E5B18)
                                                      : Colors.red[900],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData i, String t, Color c) => Row(
    children: [
      Icon(i, size: 16, color: Colors.grey),
      const SizedBox(width: 5),
      Text(
        t,
        style: TextStyle(fontWeight: FontWeight.w600, color: c),
      ),
    ],
  );

  Widget _miniIcon(IconData i, bool active, {bool alert = false}) => Icon(
    i,
    size: 22,
    color: !active
        ? Colors.grey[300]
        : (alert ? Colors.orange : const Color(0xFF64B32E)),
  );
}
