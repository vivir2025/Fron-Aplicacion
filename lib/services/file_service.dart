import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

class FileService {
  // ✅ URL BASE - Usar tu URL real
  static const String baseUrl = 'http://fnpvi.nacerparavivir.org/api';

  // Directorio base para archivos de la app
  static Future<Directory> get _appDirectory async {
    final directory = await getApplicationDocumentsDirectory();
    final appDir = Directory('${directory.path}/fnpv_files');
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return appDir;
  }

  // Directorio para fotos de riesgo
  static Future<Directory> get _photosDirectory async {
    final appDir = await _appDirectory;
    final photosDir = Directory('${appDir.path}/photos');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    return photosDir;
  }

  // Directorio para firmas
  static Future<Directory> get _signaturesDirectory async {
    final appDir = await _appDirectory;
    final signaturesDir = Directory('${appDir.path}/signatures');
    if (!await signaturesDir.exists()) {
      await signaturesDir.create(recursive: true);
    }
    return signaturesDir;
  }

  // Directorio para archivos adjuntos
  static Future<Directory> get _attachmentsDirectory async {
    final appDir = await _appDirectory;
    final attachmentsDir = Directory('${appDir.path}/attachments');
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }
    return attachmentsDir;
  }

  // Guardar foto de riesgo
  static Future<String?> saveRiskPhoto(File imageFile, String visitaId) async {
    try {
      final photosDir = await _photosDirectory;
      final fileName = 'risk_${visitaId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = File('${photosDir.path}/$fileName');
      
      await imageFile.copy(savedFile.path);
      
      debugPrint('✅ Foto de riesgo guardada: ${savedFile.path}');
      return savedFile.path;
    } catch (e) {
      debugPrint('❌ Error al guardar foto de riesgo: $e');
      return null;
    }
  }

  // Guardar foto general
  static Future<String?> savePhoto(File imageFile, String visitaId, {String prefix = 'photo'}) async {
    try {
      final photosDir = await _photosDirectory;
      final fileName = '${prefix}_${visitaId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = File('${photosDir.path}/$fileName');
      
      await imageFile.copy(savedFile.path);
      
      debugPrint('✅ Foto guardada: ${savedFile.path}');
      return savedFile.path;
    } catch (e) {
      debugPrint('❌ Error al guardar foto: $e');
      return null;
    }
  }

  // Guardar archivo adjunto
  static Future<String?> saveAttachment(File file, String visitaId) async {
    try {
      final attachmentsDir = await _attachmentsDirectory;
      final extension = path.extension(file.path);
      final fileName = 'attachment_${visitaId}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final savedFile = File('${attachmentsDir.path}/$fileName');
      
      await file.copy(savedFile.path);
      
      debugPrint('✅ Archivo adjunto guardado: ${savedFile.path}');
      return savedFile.path;
    } catch (e) {
      debugPrint('❌ Error al guardar archivo adjunto: $e');
      return null;
    }
  }

  // Guardar firma
  static Future<String?> saveSignature(Uint8List signatureBytes, String visitaId) async {
    try {
      final signaturesDir = await _signaturesDirectory;
      final fileName = 'signature_${visitaId}_${DateTime.now().millisecondsSinceEpoch}.png';
      final savedFile = File('${signaturesDir.path}/$fileName');
      
      await savedFile.writeAsBytes(signatureBytes);
      
      debugPrint('✅ Firma guardada: ${savedFile.path}');
      return savedFile.path;
    } catch (e) {
      debugPrint('❌ Error al guardar firma: $e');
      return null;
    }
  }

// ✅ MÉTODO PRINCIPAL - Crear visita completa con archivos (CORREGIDO)
static Future<Map<String, dynamic>?> createVisitaCompleta({
  required Map<String, String> visitaData,
  required String token,
  String? riskPhotoPath,
  String? signaturePath,
  List<Map<String, dynamic>>? medicamentosData,
}) async {
  try {
    debugPrint('📤 Creando visita completa con archivos');
    debugPrint('🔗 URL: $baseUrl/visitas');
    debugPrint('📋 Datos de visita: ${visitaData.keys.length} campos');
    debugPrint('📷 Foto de riesgo: ${riskPhotoPath != null ? "SÍ" : "NO"}');
    debugPrint('✍️ Firma: ${signaturePath != null ? "SÍ" : "NO"}');
    debugPrint('💊 Medicamentos: ${medicamentosData?.length ?? 0}');

    final request = http.MultipartRequest(
      'POST', 
      Uri.parse('$baseUrl/visitas')
    );
    
    // ✅ Headers correctos
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    
    // 🆕 VERIFICAR COORDENADAS ANTES DE AGREGAR CAMPOS
    debugPrint('🔍 VERIFICACIÓN PRE-AGREGAR:');
    debugPrint('   - visitaData contiene latitud: ${visitaData.containsKey('latitud')}');
    debugPrint('   - visitaData contiene longitud: ${visitaData.containsKey('longitud')}');
    debugPrint('   - visitaData[latitud]: "${visitaData['latitud']}"');
    debugPrint('   - visitaData[longitud]: "${visitaData['longitud']}"');
    
    // ✅ Agregar todos los campos de texto de la visita
    request.fields.addAll(visitaData);
    
    // 🆕 FORZAR COORDENADAS DESPUÉS DE addAll (CRÍTICO)
    if (visitaData.containsKey('latitud') && visitaData['latitud']!.isNotEmpty) {
      request.fields['latitud'] = visitaData['latitud']!;
      debugPrint('🔧 FORZANDO latitud: ${visitaData['latitud']}');
    }
    
    if (visitaData.containsKey('longitud') && visitaData['longitud']!.isNotEmpty) {
      request.fields['longitud'] = visitaData['longitud']!;
      debugPrint('🔧 FORZANDO longitud: ${visitaData['longitud']}');
    }
    
    // 🆕 VERIFICACIÓN POST-AGREGAR (CRÍTICA)
    debugPrint('🔍 VERIFICACIÓN POST-AGREGAR:');
    debugPrint('   - request.fields contiene latitud: ${request.fields.containsKey('latitud')}');
    debugPrint('   - request.fields contiene longitud: ${request.fields.containsKey('longitud')}');
    debugPrint('   - request.fields[latitud]: "${request.fields['latitud']}"');
    debugPrint('   - request.fields[longitud]: "${request.fields['longitud']}"');
    
    // 🆕 DEBUG: Mostrar todos los campos que se envían
    debugPrint('📋 Todos los campos en request.fields:');
    request.fields.forEach((key, value) {
      if (key == 'latitud' || key == 'longitud') {
        debugPrint('📍 $key: "$value"'); // Destacar coordenadas con comillas
      } else {
        debugPrint('  $key: $value');
      }
    });
    
    // ✅ CORREGIR ENVÍO DE MEDICAMENTOS - SOLO JSON STRING
    if (medicamentosData != null && medicamentosData.isNotEmpty) {
      debugPrint('💊 Procesando ${medicamentosData.length} medicamentos...');
      
      // ✅ SOLO enviar como JSON string (lo que espera el servidor)
      final medicamentosJson = json.encode(medicamentosData);
      request.fields['medicamentos'] = medicamentosJson;
      debugPrint('💊 Medicamentos como JSON: $medicamentosJson');
      
      debugPrint('💊 Medicamentos enviados como JSON string');
    }
    
    // ✅ Agregar foto de riesgo si existe
    if (riskPhotoPath != null && riskPhotoPath.isNotEmpty) {
      final riskFile = File(riskPhotoPath);
      if (await riskFile.exists()) {
        final multipartFile = await http.MultipartFile.fromPath(
          'riesgo_fotografico',
          riskPhotoPath,
          filename: path.basename(riskPhotoPath),
        );
        request.files.add(multipartFile);
        debugPrint('📷 Foto de riesgo agregada: ${path.basename(riskPhotoPath)}');
      } else {
        debugPrint('⚠️ Archivo de foto de riesgo no existe: $riskPhotoPath');
      }
    }
    
    // ✅ Agregar firma si existe
    if (signaturePath != null && signaturePath.isNotEmpty) {
      final signatureFile = File(signaturePath);
      if (await signatureFile.exists()) {
        final multipartFile = await http.MultipartFile.fromPath(
          'firma',
          signaturePath,
          filename: path.basename(signaturePath),
        );
        request.files.add(multipartFile);
        debugPrint('✍️ Firma agregada: ${path.basename(signaturePath)}');
      } else {
        debugPrint('⚠️ Archivo de firma no existe: $signaturePath');
      }
    }
    
    debugPrint('📤 Enviando request con ${request.files.length} archivos y ${request.fields.length} campos...');
    
    // ✅ AGREGAR TIMEOUT Y MEJOR MANEJO DE ERRORES
    final response = await request.send().timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        throw TimeoutException('Timeout al crear visita', const Duration(seconds: 60));
      },
    );
    
    debugPrint('📥 Respuesta recibida: ${response.statusCode}');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseBody = await response.stream.bytesToString();
      debugPrint('✅ Visita creada exitosamente');
      debugPrint('📄 Respuesta: $responseBody');
      
      try {
        final Map<String, dynamic> responseData = json.decode(responseBody);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final visitaCreada = responseData['data'];
          
          debugPrint('🆔 ID de visita creada: ${visitaCreada['id']}');
          debugPrint('🔗 Foto URL: ${visitaCreada['riesgo_fotografico_url']}');
          debugPrint('🔗 Firma URL: ${visitaCreada['firma_url']}');
        }
        
        return responseData;
      } catch (e) {
        debugPrint('⚠️ Error parseando respuesta JSON: $e');
        return {'success': true, 'raw_response': responseBody};
      }
    } else {
      final errorBody = await response.stream.bytesToString();
      debugPrint('❌ Error al crear visita: ${response.statusCode}');
      debugPrint('❌ Error body: $errorBody');
      
      // ✅ PARSEAR ERROR PARA MEJOR DEBUGGING
      try {
        final errorJson = json.decode(errorBody);
        if (errorJson['errors'] != null) {
          debugPrint('❌ Errores específicos: ${errorJson['errors']}');
        }
      } catch (e) {
        debugPrint('⚠️ No se pudo parsear error JSON');
      }
      
      return {
        'success': false, 
        'error': errorBody,
        'status_code': response.statusCode
      };
    }
  } on TimeoutException catch (e) {
    debugPrint('⏰ Timeout al crear visita: $e');
    return {
      'success': false,
      'error': 'Tiempo de espera agotado. Verifique su conexión a internet.',
    };
  } on SocketException catch (e) {
    debugPrint('🌐 Error de conexión: $e');
    return {
      'success': false,
      'error': 'Sin conexión a internet. La visita se guardó localmente.',
    };
  } catch (e) {
    debugPrint('❌ Error en createVisitaCompleta: $e');
    return {'success': false, 'error': e.toString()};
  }
}


// 🆕 MÉTODO ACTUALIZADO PARA ACTUALIZAR VISITA - CORREGIDO
static Future<Map<String, dynamic>?> updateVisitaCompleta({
  required String visitaId,
  required Map<String, String> visitaData,
  required String token,
  String? riskPhotoPath,
  String? signaturePath,
  List<Map<String, dynamic>>? medicamentosData,
}) async {
  try {
    debugPrint('📤 Actualizando visita con archivos: $visitaId');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/visitas/$visitaId')
    );
    
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.fields['_method'] = 'PUT';
    
    request.fields.addAll(visitaData);
    
    // 🆕 ENVÍO DE MEDICAMENTOS CORREGIDO PARA UPDATE
    if (medicamentosData != null && medicamentosData.isNotEmpty) {
      final medicamentosJson = json.encode(medicamentosData);
      request.fields['medicamentos'] = medicamentosJson;
      debugPrint('💊 Medicamentos para actualización: $medicamentosJson');
      // ❌ NO enviar como campos individuales
    }
    
    if (riskPhotoPath != null && riskPhotoPath.isNotEmpty) {
      final riskFile = File(riskPhotoPath);
      if (await riskFile.exists()) {
        final multipartFile = await http.MultipartFile.fromPath(
          'riesgo_fotografico',
          riskPhotoPath,
          filename: path.basename(riskPhotoPath),
        );
        request.files.add(multipartFile);
        debugPrint('📷 Nueva foto de riesgo agregada para actualización');
      }
    }
    
    if (signaturePath != null && signaturePath.isNotEmpty) {
      final signatureFile = File(signaturePath);
      if (await signatureFile.exists()) {
        final multipartFile = await http.MultipartFile.fromPath(
          'firma',
          signaturePath,
          filename: path.basename(signaturePath),
        );
        request.files.add(multipartFile);
        debugPrint('✍️ Nueva firma agregada para actualización');
      }
    }
    
     // 🆕 ASEGURAR QUE LAS COORDENADAS SE ENVÍEN
    if (visitaData.containsKey('latitud') && visitaData.containsKey('longitud')) {
      request.fields['latitud'] = visitaData['latitud'] ?? '';
      request.fields['longitud'] = visitaData['longitud'] ?? '';
      debugPrint('📍 Coordenadas incluidas en request: ${visitaData['latitud']}, ${visitaData['longitud']}');
    }
    
    final response = await request.send().timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        throw TimeoutException('Timeout al actualizar visita', const Duration(seconds: 60));
      },
    );
    
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      debugPrint('✅ Visita actualizada exitosamente: $responseBody');
      
      try {
        final Map<String, dynamic> responseData = json.decode(responseBody);
        return responseData;
      } catch (e) {
        debugPrint('⚠️ Error parseando respuesta: $e');
        return {'success': true, 'raw_response': responseBody};
      }
    } else {
      final errorBody = await response.stream.bytesToString();
      debugPrint('❌ Error al actualizar visita: ${response.statusCode} - $errorBody');
      return {
        'success': false, 
        'error': errorBody,
        'status_code': response.statusCode
      };
    }
  } on TimeoutException catch (e) {
    debugPrint('⏰ Timeout al actualizar visita: $e');
    return {
      'success': false,
      'error': 'Tiempo de espera agotado al actualizar.',
    };
  } on SocketException catch (e) {
    debugPrint('🌐 Error de conexión al actualizar: $e');
    return {
      'success': false,
      'error': 'Sin conexión a internet.',
    };
  } catch (e) {
    debugPrint('❌ Error en updateVisitaCompleta: $e');
    return {'success': false, 'error': e.toString()};
  }
}


  // ✅ MÉTODOS LEGACY CORREGIDOS (por si los sigues usando en algún lugar)
  static Future<String?> uploadRiskPhoto(String filePath, String token) async {
    debugPrint('⚠️ MÉTODO LEGACY: Usa createVisitaCompleta en su lugar');
    return null;
  }

  static Future<String?> uploadSignature(String filePath, String token) async {
    debugPrint('⚠️ MÉTODO LEGACY: Usa createVisitaCompleta en su lugar');
    return null;
  }

  static Future<String?> uploadPhoto(String filePath, String token) async {
    debugPrint('⚠️ MÉTODO LEGACY: Usa createVisitaCompleta en su lugar');
    return null;
  }

  // Eliminar archivo local
  static Future<bool> deleteLocalFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('✅ Archivo eliminado: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error al eliminar archivo: $e');
      return false;
    }
  }

  // Verificar si archivo existe
  static Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  // Obtener tamaño del archivo
  static Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // Obtener información del archivo
  static Future<Map<String, dynamic>> getFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final stat = await file.stat();
        return {
          'name': path.basename(filePath),
          'size': stat.size,
          'extension': path.extension(filePath),
          'modified': stat.modified,
          'type': _getFileType(path.extension(filePath)),
        };
      }
      return {};
    } catch (e) {
      debugPrint('❌ Error obteniendo info del archivo: $e');
      return {};
    }
  }

  // Determinar tipo de archivo
  static String _getFileType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.webp':
        return 'image';
      case '.pdf':
        return 'pdf';
      case '.doc':
      case '.docx':
        return 'document';
      case '.txt':
      case '.rtf':
        return 'text';
      case '.mp4':
      case '.avi':
      case '.mov':
        return 'video';
      case '.mp3':
      case '.wav':
        return 'audio';
      default:
        return 'file';
    }
  }

  // Obtener icono para tipo de archivo
  static String getFileIcon(String filePath) {
    final type = _getFileType(path.extension(filePath));
    switch (type) {
      case 'image':
        return '🖼️';
      case 'pdf':
        return '📄';
      case 'document':
        return '📝';
      case 'text':
        return '📃';
      case 'video':
        return '🎥';
      case 'audio':
        return '🎵';
      default:
        return '📎';
    }
  }

  // Limpiar archivos antiguos
  static Future<void> cleanOldFiles({int daysOld = 30}) async {
    try {
      final appDir = await _appDirectory;
      final now = DateTime.now();
      int deletedCount = 0;
      
      await for (final entity in appDir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          final age = now.difference(stat.modified).inDays;
          
          if (age > daysOld) {
            await entity.delete();
            deletedCount++;
            debugPrint('🗑️ Archivo antiguo eliminado: ${entity.path}');
          }
        }
      }
      
      debugPrint('✅ Limpieza completada: $deletedCount archivos eliminados');
    } catch (e) {
      debugPrint('❌ Error al limpiar archivos antiguos: $e');
    }
  }

  // Obtener todos los archivos de la app
  static Future<List<String>> getAllFiles() async {
    try {
      final appDir = await _appDirectory;
      final files = <String>[];
      
      await for (final entity in appDir.list(recursive: true)) {
        if (entity is File) {
          files.add(entity.path);
        }
      }
      
      return files;
    } catch (e) {
      debugPrint('❌ Error obteniendo archivos: $e');
      return [];
    }
  }

  // Calcular espacio usado por la app
  static Future<int> getTotalStorageUsed() async {
    try {
      final files = await getAllFiles();
      int totalSize = 0;
      
      for (final filePath in files) {
        totalSize += await getFileSize(filePath);
      }
      
      return totalSize;
    } catch (e) {
      debugPrint('❌ Error calculando espacio usado: $e');
      return 0;
    }
  }

  // Formatear tamaño de archivo
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // ✅ MÉTODO PARA SUBIR ARCHIVOS POR TIPO
static Future<Map<String, dynamic>?> uploadFileByType(String archivoPath, String token) async {
  try {
    final file = File(archivoPath);
    if (!file.existsSync()) {
      debugPrint('❌ Archivo no existe: $archivoPath');
      return {
        'success': false,
        'error': 'El archivo no existe',
      };
    }

    // Determinar el tipo de archivo basado en la extensión o nombre
    String endpoint;
    String fieldName;
    
    if (archivoPath.contains('signature') || archivoPath.contains('firma')) {
      endpoint = '$baseUrl/upload-signature';
      fieldName = 'signature';
    } else if (archivoPath.contains('risk') || archivoPath.contains('riesgo') || archivoPath.contains('photo')) {
      endpoint = '$baseUrl/upload-risk-photo';
      fieldName = 'risk_photo';
    } else {
      // Por defecto, tratarlo como foto de riesgo
      endpoint = '$baseUrl/upload-risk-photo';
      fieldName = 'risk_photo';
    }

    debugPrint('📤 Subiendo archivo: $archivoPath');
    debugPrint('🔗 Endpoint: $endpoint');
    debugPrint('📝 Field name: $fieldName');

    // Crear la petición multipart
    var request = http.MultipartRequest('POST', Uri.parse(endpoint));
    
    // Agregar headers
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    // Agregar el archivo
    final multipartFile = await http.MultipartFile.fromPath(
      fieldName,
      archivoPath,
      filename: path.basename(archivoPath),
    );
    request.files.add(multipartFile);

    debugPrint('📊 Tamaño del archivo: ${file.lengthSync()} bytes');

    // Enviar la petición
    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        throw TimeoutException('Timeout al subir archivo', const Duration(seconds: 60));
      },
    );

    // Convertir la respuesta
    final response = await http.Response.fromStream(streamedResponse);
    
    debugPrint('📊 Status code: ${response.statusCode}');
    debugPrint('📄 Response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = json.decode(response.body);
      
      return {
        'success': true,
        'data': responseData,
        'url': responseData['url'] ?? responseData['file_url'] ?? responseData['path'],
        'message': responseData['message'] ?? 'Archivo subido correctamente',
      };
    } else {
      final errorData = json.decode(response.body);
      return {
        'success': false,
        'error': errorData['message'] ?? errorData['error'] ?? 'Error al subir archivo',
        'status_code': response.statusCode,
      };
    }

  } on TimeoutException catch (e) {
    debugPrint('⏰ Timeout al subir archivo: $e');
    return {
      'success': false,
      'error': 'Tiempo de espera agotado al subir archivo',
    };
  } on SocketException catch (e) {
    debugPrint('🌐 Error de conexión al subir archivo: $e');
    return {
      'success': false,
      'error': 'Sin conexión a internet',
    };
  } catch (e) {
    debugPrint('💥 Error general al subir archivo: $e');
    return {
      'success': false,
      'error': 'Error inesperado: ${e.toString()}',
    };
  }
}

// ✅ MÉTODO AUXILIAR PARA SUBIR MÚLTIPLES ARCHIVOS
static Future<Map<String, dynamic>> uploadMultipleFiles(
  List<String> filePaths, 
  String token
) async {
  final results = <String, dynamic>{};
  final errors = <String>[];
  
  for (final filePath in filePaths) {
    if (filePath.isNotEmpty) {
      final result = await uploadFileByType(filePath, token);
      
      if (result != null && result['success'] == true) {
        // Determinar el tipo de archivo para la clave
        String key;
        if (filePath.contains('signature') || filePath.contains('firma')) {
          key = 'signature_url';
        } else {
          key = 'risk_photo_url';
        }
        
        results[key] = result['url'];
        debugPrint('✅ Archivo subido: $filePath -> ${result['url']}');
      } else {
        final error = result?['error'] ?? 'Error desconocido';
        errors.add('Error en $filePath: $error');
        debugPrint('❌ Error al subir $filePath: $error');
      }
    }
  }
  
  return {
    'success': errors.isEmpty,
    'results': results,
    'errors': errors,
    'uploaded_count': results.length,
    'error_count': errors.length,
  };
}

// ✅ MÉTODO PARA VERIFICAR SI UN ARCHIVO ES VÁLIDO
static bool isValidFile(String filePath) {
  try {
    final file = File(filePath);
    if (!file.existsSync()) {
      debugPrint('❌ Archivo no existe: $filePath');
      return false;
    }
    
    final fileSize = file.lengthSync();
    const maxSize = 10 * 1024 * 1024; // 10MB
    
    if (fileSize > maxSize) {
      debugPrint('❌ Archivo muy grande: ${fileSize / 1024 / 1024}MB');
      return false;
    }
    
    if (fileSize == 0) {
      debugPrint('❌ Archivo vacío: $filePath');
      return false;
    }
    
    return true;
  } catch (e) {
    debugPrint('❌ Error al validar archivo: $e');
    return false;
  }
}
}
