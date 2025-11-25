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

/// ---------------------------------------------------------------------------
/// Hash SHA256 de la contraseña ingresada
/// Se utiliza para comparar con el hash almacenado en Firestore, evitando
/// el uso de contraseñas en texto plano.
/// ---------------------------------------------------------------------------
String hashPassword(String password) {
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  // Controladores del formulario
  final _formKey = GlobalKey<FormState>();
  final _workerController = TextEditingController();
  final _passwordController = TextEditingController();

  // Estado del botón y campo de contraseña
  bool _isLoading = false;
  bool _isVisible = false;

  // Animaciones de entrada para el card
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    /// Configuración inicial de animaciones del login
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0.2), // ligeramente abajo
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward(); // iniciar animación al montar pantalla
  }

  @override
  void dispose() {
    // Liberar controladores para evitar fugas de memoria
    _animationController.dispose();
    _workerController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// ---------------------------------------------------------------------------
  /// Lógica de inicio de sesión
  /// 1. Valida formulario
  /// 2. Calcula hash de la contraseña ingresada
  /// 3. Busca usuario en Firestore (documento con su número de trabajador)
  /// 4. Compara el hash ingresado vs el almacenado
  /// 5. Redirige según tipo de usuario ("administrativo" / "docente")
  /// ---------------------------------------------------------------------------
  Future<void> _onLoginPressed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final noTrabajador = _workerController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final hashedInput = hashPassword(password);

      // Firestore: búsqueda por documentId (número de trabajador)
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

      // Usuario no encontrado
      if (userData == null) {
        if (mounted) _showSnackBar("Credenciales inválidas");
        setState(() => _isLoading = false);
        return;
      }

      // Comparación del hash
      if (userData['contrasena_hash'] == hashedInput) {
        if (!mounted) return;

        _showSnackBar("Inicio de sesión exitoso");

        // Tipo de usuario para ruteo: administrativo / docente
        final tipo = userData['tipo'];

        if (tipo == 'administrativo') {
          Navigator.pushReplacementNamed(
            context,
            '/dashboard_admin',
            arguments: userData, // pasa el mapa completo
          );
        } else if (tipo == 'docente') {
          Navigator.pushReplacementNamed(
            context,
            '/dashboard_maestro',
            arguments: userData,
          );
        }
      } else {
        if (mounted) _showSnackBar("Credenciales inválidas");
      }
    } catch (e) {
      if (mounted) _showSnackBar("Error al conectar con el servidor");
      debugPrint("Error en login: $e");
    }

    if (mounted) setState(() => _isLoading = false);
  }

  /// ---------------------------------------------------------------------------
  /// Utilidad para mostrar snackbars estilizados.
  /// ---------------------------------------------------------------------------
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

  /// ---------------------------------------------------------------------------
  /// Construcción de UI del login:
  /// - Fondo con gradiente institucional
  /// - Card centrado con animación
  /// - Campos con validación
  /// - Diseño responsivo con LayoutBuilder
  /// ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Fondo con gradiente
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
              final bool isWide = constraints.maxWidth > 600; // Responsivo

              return FadeTransition(
                opacity: _fadeAnimation, // efecto fade
                child: SlideTransition(
                  position: _slideAnimation, // entrada vertical suave
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    width: isWide ? 400 : 320, // tamaño adaptable
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

                    // Formulario principal
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

                          /// ---------------------------------------------------
                          /// Campo: número de trabajador
                          /// ---------------------------------------------------
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

                          /// ---------------------------------------------------
                          /// Campo: contraseña con opción de mostrar/ocultar
                          /// ---------------------------------------------------
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

                          /// ---------------------------------------------------
                          /// Botón principal del login
                          /// ---------------------------------------------------
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

                          /// Footer institucional
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
