import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ImageUploadService {
  static const String baseUrl = 'https://www.moreausoft.com/ReaderKM/fotos';
  
  /// Sube una imagen del viaje al servidor
  static Future<Map<String, dynamic>?> uploadTripImage({
    required String imagePath,
    required String email,
  }) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Archivo de imagen no encontrado');
      }

      final uri = Uri.parse('$baseUrl/upload_image.php');
      final request = http.MultipartRequest('POST', uri);
      
      // Añadir email
      request.fields['email'] = email;
      
      // Añadir archivo
      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        imagePath,
      );
      
      request.files.add(multipartFile);
      
      // Configurar timeout
      final client = http.Client();
      
      try {
        // Enviar request con timeout de 30 segundos
        final response = await client.send(request).timeout(
          const Duration(seconds: 30),
        );
        
        final responseBody = await response.stream.bytesToString();
        
        if (response.statusCode == 200) {
          final data = jsonDecode(responseBody);
          
          // Guardar token de acceso localmente
          if (data['access_token'] != null && data['filename'] != null) {
            await _saveImageToken(data['filename'], data['access_token']);
          }
          
          return data;
        } else {
          final error = jsonDecode(responseBody);
          throw Exception(error['error'] ?? 'Error al subir imagen');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      print('Error subiendo imagen: $e');
      return null;
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
      print('Error eliminando imagen: $e');
      return false;
    }
  }
  
  /// Obtiene la URL segura para acceder a una imagen
  static Future<String?> getSecureImageUrl(String filename) async {
    final token = await _getImageToken(filename);
    if (token == null) return null;
    
    return '$baseUrl/secure_image.php?token=$token&file=$filename';
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('img_token_$filename', token);
  }
  
  static Future<String?> _getImageToken(String filename) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('img_token_$filename');
    
    // Verificar si el token no ha expirado
    if (token != null && _isTokenExpired(token)) {
      await prefs.remove('img_token_$filename');
      return null;
    }
    
    return token;
  }
  
  static Future<void> _removeImageToken(String filename) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('img_token_$filename');
  }
  
  static bool _isTokenExpired(String token) {
    try {
      final tokenData = base64Decode(token);
      final parts = String.fromCharCodes(tokenData).split('|');
      
      if (parts.length < 3) return true;
      
      final expiration = int.tryParse(parts[2]);
      if (expiration == null) return true;
      
      return DateTime.now().millisecondsSinceEpoch ~/ 1000 > expiration;
    } catch (e) {
      return true;
    }
  }
}