// packages/mm_editor/lib/src/api/errors.dart

class MMEditorException implements Exception {
  final String code;
  final String message;
  final Map<String, dynamic>? details;

  MMEditorException({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() =>
      'MMEditorException(code: $code, message: $message, details: $details)';
}

class MMEditorErrorCodes {
  static const invalidArgument = 'INVALID_ARGUMENT';
  static const unsupportedMedia = 'UNSUPPORTED_MEDIA';
  static const permissionDenied = 'PERMISSION_DENIED';
  static const ioError = 'IO_ERROR';
  static const exportFailed = 'EXPORT_FAILED';
  static const exportCancelled = 'EXPORT_CANCELLED';
  static const outOfStorage = 'OUT_OF_STORAGE';
  static const internalError = 'INTERNAL_ERROR';
}
