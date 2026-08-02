import 'package:dio/dio.dart';

class CodeExecutionService {
  // Judge0 CE - Free, no auth required
  static const String _baseUrl = 'https://ce.judge0.com';
  final Dio _dio = Dio();

  // Judge0 language IDs
  static const Map<String, int> _languageIds = {
    'python':     71, // Python 3.8.1
    'java':       62, // Java (OpenJDK 13.0.1)
    'c':          50, // C (GCC 9.2.0)
    'c++':        54, // C++ (GCC 9.2.0)
    'javascript': 63, // JavaScript (Node.js 12.14.0)
    'sqlite3':    82, // SQL (SQLite 3.27.2)
  };

  Future<Map<String, dynamic>> executeCode(String language, String version, String code) async {
    final langId = _languageIds[language.toLowerCase()] ?? 71;

    try {
      // Step 1: Submit the code
      final submitResponse = await _dio.post(
        '$_baseUrl/submissions?base64_encoded=false&wait=true',
        data: {
          'source_code': code,
          'language_id': langId,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final data = submitResponse.data;
      final stdout = data['stdout'] ?? '';
      final stderr = data['stderr'] ?? '';
      final compileOutput = data['compile_output'] ?? '';
      final statusId = data['status']?['id'] ?? 0;

      final isSuccess = statusId == 3; // 3 = Accepted
      final output = stdout.isNotEmpty ? stdout : (stderr.isNotEmpty ? stderr : compileOutput);

      return {
        'success': isSuccess,
        'output': output.isEmpty ? '(No output)' : output,
        'code': isSuccess ? 0 : 1,
        'time': data['time'] ?? '0',
      };
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('INTERNET_REQUIRED');
      }
      return {'success': false, 'error': 'Request failed: ${e.message}'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
