enum AppFailureKind {
  unauthorized,
  forbidden,
  validation,
  notFound,
  conflict,
  timeout,
  network,
  server,
  unknown,
}

class AppFailure {
  const AppFailure._({
    required this.kind,
    required this.userMessage,
    this.technicalMessage,
    this.statusCode,
    this.code,
  });

  const AppFailure.unauthorized({String? technicalMessage})
    : this._(
        kind: AppFailureKind.unauthorized,
        userMessage: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        technicalMessage: technicalMessage,
        statusCode: 401,
      );

  const AppFailure.forbidden({String? technicalMessage})
    : this._(
        kind: AppFailureKind.forbidden,
        userMessage: 'Bạn không có quyền thực hiện thao tác này.',
        technicalMessage: technicalMessage,
        statusCode: 403,
      );

  const AppFailure.validation({
    required String message,
    String? technicalMessage,
    String? code,
  }) : this._(
         kind: AppFailureKind.validation,
         userMessage: message,
         technicalMessage: technicalMessage,
         statusCode: 400,
         code: code,
       );

  const AppFailure.notFound({String? technicalMessage})
    : this._(
        kind: AppFailureKind.notFound,
        userMessage: 'Không tìm thấy nội dung yêu cầu.',
        technicalMessage: technicalMessage,
        statusCode: 404,
      );

  const AppFailure.conflict({String? message, String? technicalMessage})
    : this._(
        kind: AppFailureKind.conflict,
        userMessage: message ?? 'Dữ liệu đã thay đổi. Vui lòng tải lại.',
        technicalMessage: technicalMessage,
        statusCode: 409,
      );

  const AppFailure.timeout({String? technicalMessage})
    : this._(
        kind: AppFailureKind.timeout,
        userMessage: 'Yêu cầu mất quá nhiều thời gian. Vui lòng thử lại.',
        technicalMessage: technicalMessage,
      );

  const AppFailure.network({String? technicalMessage})
    : this._(
        kind: AppFailureKind.network,
        userMessage: 'Không thể kết nối. Vui lòng kiểm tra mạng và thử lại.',
        technicalMessage: technicalMessage,
      );

  const AppFailure.server({String? technicalMessage, int? statusCode})
    : this._(
        kind: AppFailureKind.server,
        userMessage: 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau.',
        technicalMessage: technicalMessage,
        statusCode: statusCode,
      );

  const AppFailure.unknown({String? technicalMessage})
    : this._(
        kind: AppFailureKind.unknown,
        userMessage: 'Đã xảy ra lỗi. Vui lòng thử lại.',
        technicalMessage: technicalMessage,
      );

  final AppFailureKind kind;
  final String userMessage;
  final String? technicalMessage;
  final int? statusCode;
  final String? code;
}
