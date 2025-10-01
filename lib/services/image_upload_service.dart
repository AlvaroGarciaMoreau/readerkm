import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ImageUploadService {
  static const String baseUrl = 'https://www.moreausoft.com/ReaderKM/fotos';
  
  /// Sube una imagen del viaje al servidor
  static Future<Map<String, dynamic>?> uploadTripImage({
    required String imagePath,
    required String email,
  }) async {
    http.Client? client;
    
    try {
      
      final file = File(imagePath);
      if (!await file.exists()) {
        return null;
      }

      final fileSize = await file.length();
      
      // Verificar que el archivo no esté vacío
      if (fileSize == 0) {
        return null;
      }
      
      // Verificar que el archivo no sea demasiado grande (10MB)
      if (fileSize > 10 * 1024 * 1024) {
        return null;
      }

      final uri = Uri.parse('$baseUrl/upload_image_simple.php');
      
      client = http.Client();
      final request = http.MultipartRequest('POST', uri);
      
      // Configurar headers
      request.headers.addAll({
        'Accept': 'application/json',
        'User-Agent': 'ReaderKM/1.0',
      });
      
            // Añadir archivo con tipo MIME correcto (ya no enviamos email) (ya no enviamos email)
      String? mimeType;
      final extension = imagePath.toLowerCase().split('.').last;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        default:
          mimeType = 'image/jpeg'; // Fallback
      }
      
      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        imagePath,
        contentType: http_parser.MediaType.parse(mimeType),
      );
      
      request.files.add(multipartFile);
      
      
      // Enviar request con timeout
      final streamedResponse = await client.send(request).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout al subir imagen');
        },
      );
      
      final responseBody = await streamedResponse.stream.bytesToString();
      
      if (streamedResponse.statusCode == 200) {
        try {
          final data = jsonDecode(responseBody) as Map<String, dynamic>;
          
          // Verificar que la respuesta tenga los campos esperados
          if (data['success'] == true) {
            // Guardar token de acceso localmente si existe
            if (data['token'] != null && data['filename'] != null) {
              await _saveImageToken(data['filename'], data['token']);
            }
            
            return data;
          } else {
            return null;
          }
        } catch (e) {
          return null;
        }
      } else {
        try {
          final error = jsonDecode(responseBody);
          final errorMsg = error['error'] ?? 'Error desconocido del servidor';
          throw Exception(errorMsg);
        } catch (e) {
          throw Exception('Error del servidor (${streamedResponse.statusCode})');
        }
      }
    } on SocketException {
      return null;
    } on FormatException {
      return null;
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    } finally {
      client?.close();
    }
  }
  
  /// Elimina una imagen del servidor
  static Future<bool> deleteImage(String filename, String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/delete_image.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'filename': filename,
          'email': email,
        }),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Eliminar token local
          await _removeImageToken(filename);
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Obtiene la URL segura para acceder a una imagen
  static Future<String?> getSecureImageUrl(String filename, {String? token}) async {
    
    if (filename.isEmpty) {
      return null;
    }
    
    // Usar el token proporcionado o intentar obtener uno guardado
    String? accessToken = token;
    
    if (accessToken == null) {
      accessToken = await _getImageToken(filename);
    } else {
    }
    
    // Si no hay token, generar uno temporal (el servidor lo validará)
    if (accessToken == null) {
      accessToken = _generateTemporaryToken();
      await _saveImageToken(filename, accessToken);
    }
    
    final url = '$baseUrl/secure_image.php?token=$accessToken&file=${Uri.encodeComponent(filename)}';
    return url;
  }
  
  /// Genera un token temporal para acceso a imágenes
  static String _generateTemporaryToken() {
    // Generar un token temporal que el servidor puede aceptar
    // En el futuro podríamos implementar un endpoint para renovar tokens
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'temp_${timestamp.toRadixString(16)}';
  }
  
  /// Verifica si una imagen existe en el servidor
  static Future<bool> checkImageExists(String filename) async {
    try {
      final url = await getSecureImageUrl(filename);
      if (url == null) return false;
      
      final response = await http.head(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// Limpia tokens de imágenes expirados
  static Future<void> cleanExpiredTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('img_token_'));
    
    for (final key in keys) {
      final token = prefs.getString(key);
      if (token != null && _isTokenExpired(token)) {
        await prefs.remove(key);
      }
    }
  }
  
  // Métodos privados para manejo de tokens
  static Future<void> _saveImageToken(String filename, String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('img_token_$filename', token);
    } catch (e) {
      // Ignore errors when saving token
    }
  }
  
  static Future<String?> _getImageToken(String filename) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('img_token_$filename');
      
      if (token != null) {
        return token;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
  
  static Future<void> _removeImageToken(String filename) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('img_token_$filename');
    } catch (e) {
      // Ignore errors when removing token
    }
  }
  
  static bool _isTokenExpired(String token) {
    // Por ahora, no verificamos expiración ya que los tokens del PHP 
    // son simples strings hexadecimales sin información de tiempo
    // El servidor manejará la expiración
    return false;
  }
}