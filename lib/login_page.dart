import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

/// Función auxiliar para obtener el hash SHA256 de la contraseña ingresada.
/// Esto garantiza que la contraseña se valide sin almacenarse en texto plano.
String hashPassword(String password) {
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _workerController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isVisible = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Animaciones iniciales de entrada
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _workerController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Lógica principal del inicio de sesión.
  /// Valida formulario, busca usuario en Firestore, compara hash y redirige.
  Future<void> _onLoginPressed() async {
    if (!_formKey.currentState!.validate()) return; // Validar formulario

    setState(() => _isLoading = true);

    final noTrabajador = _workerController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // Generar el hash local de la contraseña ingresada
      final hashedInput = hashPassword(password);

      // Buscar en la colección "usuarios" por el número de trabajador (documentId)
      final usuariosSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where(FieldPath.documentId, isEqualTo: noTrabajador)
          .get();

      Map<String, dynamic>? userData;
      if (usuariosSnapshot.docs.isNotEmpty) {
        userData = usuariosSnapshot.docs.first.data();
      } else {
        userData = null;
      }

      // Si no se encontró usuario
      if (userData == null) {
        if (mounted) _showSnackBar("Credenciales inválidas");
        setState(() => _isLoading = false);
        return;
      }

      // Verificar hash de contraseña
      if (userData['contrasena_hash'] == hashedInput) {
        if (!mounted) return;

        _showSnackBar("Inicio de sesión exitoso");

        // Si el documento tiene campo 'tipo', se usa para decidir destino.
        // Si no existe, se conserva compatibilidad con el campo 'materia'.
        final tipo = userData['tipo']; // "administrativo" o "docente"

        if (tipo == 'administrativo') {
          Navigator.pushReplacementNamed(context, '/dashboard_admin');
        } else if (tipo == 'docente') {
          Navigator.pushReplacementNamed(context, '/dashboard_maestro');
        } /*else if (userData.containsKey('materia')) {
          // Caso alternativo: si el usuario tiene una materia, es maestro.
          Navigator.pushReplacementNamed(context, '/dashboard_maestro');
        } else {
          // Si no hay rol ni materia, redirige por defecto al panel admin
          Navigator.pushReplacementNamed(context, '/dashboard_admin');
        }*/
      } else {
        // Contraseña incorrecta
        if (mounted) _showSnackBar("Credenciales inválidas");
      }
    } catch (e) {
      // Manejo de error general de conexión o Firestore
      if (mounted) _showSnackBar("Error al conectar con el servidor");
      debugPrint("Error en login: $e");
    }

    if (mounted) setState(() => _isLoading = false);
  }

  /// Muestra mensajes informativos (snackbars) al usuario.
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF527630),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Construcción de la interfaz de inicio de sesión.
  /// Incluye animaciones, validaciones y diseño responsive.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF527630), Color(0xFF4E4D4D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth > 600;

              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    width: isWide ? 400 : 320,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'SmartClass, Inc.',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64B32E),
                            ),
                          ),
                          const SizedBox(height: 25),
                          // Campo número de trabajador
                          TextFormField(
                            controller: _workerController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Número de trabajador',
                              prefixIcon: const Icon(
                                Icons.badge_outlined,
                                color: Color(0xFF527630),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            maxLength: 4,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Campo requerido";
                              }
                              if (!RegExp(r'^\d{4}$').hasMatch(value)) {
                                return "Debe tener exactamente 4 dígitos";
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 15),
                          // Campo contraseña
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isVisible,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: Color(0xFF527630),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: const Color(0xFF8E8E8E),
                                ),
                                onPressed: () =>
                                    setState(() => _isVisible = !_isVisible),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Campo requerido';
                              }
                              if (value.length < 8) {
                                return 'Mínimo 8 caracteres';
                              }
                              if (value.length > 16) {
                                return 'Máximo 16 caracteres';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 25),
                          // Botón principal
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF64B32E),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _isLoading ? null : _onLoginPressed,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Iniciar sesión',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),
                          // Pie de página
                          const Text(
                            '© 2025 SmartClass, Inc.',
                            style: TextStyle(
                              color: Color(0xFF8E8E8E),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
