class AppAccountInfo {
  AppAccountInfo({required this.userid, required this.isAdmin});

  final String userid;
  final bool isAdmin;

  factory AppAccountInfo.fromJson(Map<String, dynamic> json) {
    return AppAccountInfo(
      userid: (json['userid'] ?? '').toString(),
      isAdmin: json['is_admin'] == true,
    );
  }
}

class AppFileSummary {
  AppFileSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.attachmentCount,
    required this.hasUploadedFile,
  });

  final int id;
  final String title;
  final String description;
  final String createdAt;
  final String updatedAt;
  final int attachmentCount;
  final bool hasUploadedFile;

  factory AppFileSummary.fromJson(Map<String, dynamic> json) {
    return AppFileSummary(
      id: (json['id'] as num).toInt(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
      attachmentCount: (json['attachment_count'] as num? ?? 0).toInt(),
      hasUploadedFile: json['has_uploaded_file'] == true,
    );
  }
}

class AppAttachmentSummary {
  AppAttachmentSummary({
    required this.attachmentId,
    required this.name,
    required this.mime,
    required this.size,
  });

  final int? attachmentId;
  final String name;
  final String mime;
  final int size;

  factory AppAttachmentSummary.fromJson(Map<String, dynamic> json) {
    return AppAttachmentSummary(
      attachmentId: json['attachment_id'] is num ? (json['attachment_id'] as num).toInt() : null,
      name: (json['uploaded_file_name'] ?? '').toString(),
      mime: (json['uploaded_file_mime'] ?? '').toString(),
      size: (json['uploaded_file_size'] as num? ?? 0).toInt(),
    );
  }
}

class AppFileDetails {
  AppFileDetails({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.attachments,
  });

  final int id;
  final String title;
  final String description;
  final String content;
  final String createdAt;
  final String updatedAt;
  final List<AppAttachmentSummary> attachments;

  factory AppFileDetails.fromJson(Map<String, dynamic> json) {
    return AppFileDetails(
      id: (json['id'] as num).toInt(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
      attachments: (json['attachments'] as List<dynamic>? ?? const [])
          .map((entry) => AppAttachmentSummary.fromJson(Map<String, dynamic>.from(entry as Map)))
          .toList(),
    );
  }
}

class ForgotContextInfo {
  ForgotContextInfo({
    required this.userid,
    required this.backupQuestion,
    required this.hasWebauthn,
    required this.hasPasscode,
  });

  final String userid;
  final String backupQuestion;
  final bool hasWebauthn;
  final bool hasPasscode;

  factory ForgotContextInfo.fromJson(Map<String, dynamic> json) {
    return ForgotContextInfo(
      userid: (json['userid'] ?? '').toString(),
      backupQuestion: (json['backup_question'] ?? '').toString(),
      hasWebauthn: json['has_webauthn'] == true,
      hasPasscode: json['has_passcode'] == true,
    );
  }
}

enum AuthStatus { success, biometricRequired, error }

class AuthResult {
  AuthResult.success({this.message = '', this.redirect = '/dashboard.html'})
      : status = AuthStatus.success;

  AuthResult.biometricRequired({this.message = '', this.redirect = '/biometric.html'})
      : status = AuthStatus.biometricRequired;

  AuthResult.error(this.message)
      : status = AuthStatus.error,
        redirect = null;

  final AuthStatus status;
  final String? message;
  final String? redirect;

  bool get isSuccess => status == AuthStatus.success;
}
