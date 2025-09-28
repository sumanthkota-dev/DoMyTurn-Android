import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

final Logger logger = Logger();
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration retryDelay;

  RetryInterceptor({required this.dio, this.maxRetries = 2, this.retryDelay = const Duration(seconds: 1)});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    const retryableStatusCodes = [408, 502, 503, 504];
    final options = err.requestOptions;
    final retryCount = options.extra['retryCount'] ?? 0;

    if (retryableStatusCodes.contains(err.response?.statusCode) && retryCount < maxRetries) {
      logger.w('Retrying request... Attempt: ${retryCount + 1}');
      options.extra['retryCount'] = retryCount + 1;
      await Future.delayed(retryDelay);

      try {
        final response = await dio.fetch(options);
        return handler.resolve(response);
      } catch (_) {
        // Fall through
      }
    }

    handler.next(err);
  }
}
