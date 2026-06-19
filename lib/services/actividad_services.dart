import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class ActividadService {
  final String _url = 'https://script.google.com/macros/s/AKfycbzoiwip9PwE4n5Mt5ov5ODeAHWCb0PtWADoRl4ZhYk2ULrrcFdzK_7Xpkgzk1PNUT8L/exec';

  Future<Map<String, dynamic>> obtenerActividades() async {
    try {
      final respuesta = await http.get(Uri.parse(_url)).timeout(
        const Duration(seconds: 10),
      );

      if (respuesta.statusCode == 200) {
        final Map<String, dynamic> datosDecodificados = jsonDecode(respuesta.body);
        return datosDecodificados;
      } else if (respuesta.statusCode == 302) {
        final nuevaUrl = respuesta.headers['location'];
        if (nuevaUrl != null) {
          final segundaRespuesta = await http.get(Uri.parse(nuevaUrl)).timeout(
            const Duration(seconds: 10),
          );
          return jsonDecode(segundaRespuesta.body);
        }
        return {};
      } else {
        throw Exception('Servidor retornó código: ${respuesta.statusCode}');
      }
    } on TimeoutException {
      return {};
    } catch (e) {
      return {};
    }
  }
}