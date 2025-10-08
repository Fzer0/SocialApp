import 'package:app/screen/login_screen.dart';
import 'package:flutter/material.dart';
// **IMPORTANTE**: Necesitas importar el archivo de login para navegar directamente a él.
// He asumido la ruta más probable:



class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Función que se llama al presionar el botón de "Cerrar Sesión"
  void _logOutAndNavigateToLogin() {
    // 1. Lógica para cerrar la sesión (Firebase/Auth)
    // Authentication().signOut();

    // 2. NAVEGACIÓN SEGURA: Usa pushAndRemoveUntil para limpiar toda la pila 
    // y colocar la LoginScreen como la nueva pantalla raíz.
    // Esto garantiza que el usuario no pueda volver atrás al perfil o al home.
    Navigator.pushAndRemoveUntil(
      context,
      // Usamos MaterialPageRoute para crear la nueva ruta
      MaterialPageRoute(
        // Necesitas pasar la función 'show' al constructor del LoginScreen. 
        // He usado un callback vacío () {} como placeholder.
        builder: (context) => LoginScreen(() {}), 
      ),
      // Esta condición retorna 'false' siempre, lo que elimina TODAS las rutas anteriores.
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // NOTA: Con pushAndRemoveUntil, el botón de flecha del AppBar
      // ya no funcionará, porque la nueva ruta de Login no está en la pila anterior.
      // Puedes eliminar el AppBar si solo quieres el botón de "Cerrar Sesión".
      appBar: AppBar(
        title: const Text('Mi Perfil'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Profile Screen",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            
            // 2. Botón para ejecutar la acción de regreso/cerrar sesión.
            ElevatedButton(
              onPressed: _logOutAndNavigateToLogin, // Ahora usa el nuevo método seguro
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Color para simular 'Log Out'
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Cerrar Sesión / Ir a Login',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
