import 'package:dio/dio.dart';

class DioFactory {
  static Dio create() {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 10),
        headers: const {'accept': 'application/json'},
      ),
    );
  }
}
