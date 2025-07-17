import 'package:uuid/uuid.dart';

class VisitaService {
  static const _uuid = Uuid();
  
  // Método para generar ID compatible con Laravel
  static String generateId() {
    return _uuid.v4(); // Genera UUID v4 compatible con Laravel
  }
}