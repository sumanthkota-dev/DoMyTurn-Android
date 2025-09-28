class ErrorInfo {
  final String errorMessage;
  final int errorCode;

  ErrorInfo({required this.errorMessage, required this.errorCode});

  factory ErrorInfo.fromJson(Map<String, dynamic> json) {
    return ErrorInfo(
      errorMessage: json['errorMessage'] ?? 'Unknown error',
      errorCode: json['errorCode'] ?? -1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'errorMessage': errorMessage,
      'errorCode': errorCode,
    };
  }
}
