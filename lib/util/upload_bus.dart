import 'dart:async';

class UploadBus {
  // Emite URLs de imágenes subidas exitosamente
  static final StreamController<String> controller = StreamController<String>.broadcast();
}
