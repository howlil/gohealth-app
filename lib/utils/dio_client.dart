import 'package:dio/dio.dart';
import 'package:shared_preferences.dart';

class DioClient {
  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'YOUR_API_BASE_URL', // Replace with your actual API base URL
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        contentType: 'application/json',
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('accessToken');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Token expired, try to refresh
            try {
              final prefs = await SharedPreferences.getInstance();
              final refreshToken = prefs.getString('refreshToken');
              
              if (refreshToken != null) {
                final response = await dio.post(
                  '/auth/refresh',
                  data: {'refreshToken': refreshToken},
                );

                if (response.statusCode == 200) {
                  // Save new tokens
                  await prefs.setString('accessToken', response.data['accessToken']);
                  await prefs.setString('refreshToken', response.data['refreshToken']);

                  // Retry original request
                  final opts = error.requestOptions;
                  opts.headers['Authorization'] = 'Bearer ${response.data['accessToken']}';
                  final retryResponse = await dio.fetch(opts);
                  return handler.resolve(retryResponse);
                }
              }
            } catch (e) {
              // Clear tokens on refresh failure
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('accessToken');
              await prefs.remove('refreshToken');
            }
          }
          return handler.next(error);
        },
      ),
    );

    return dio;
  }
} 