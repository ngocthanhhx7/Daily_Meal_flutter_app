import 'dart:convert';

enum SessionKind { user, admin }

class Session {
  const Session._({
    required this.kind,
    required this.token,
    required this.subjectId,
  });

  const Session.user({required String token, required String subjectId})
    : this._(kind: SessionKind.user, token: token, subjectId: subjectId);

  const Session.admin({required String token, required String subjectId})
    : this._(kind: SessionKind.admin, token: token, subjectId: subjectId);

  factory Session.fromJson(Map<String, dynamic> json) {
    final kind = SessionKind.values.byName(json['kind'] as String);
    return Session._(
      kind: kind,
      token: json['token'] as String,
      subjectId: json['subjectId'] as String,
    );
  }

  factory Session.decode(String value) =>
      Session.fromJson(jsonDecode(value) as Map<String, dynamic>);

  final SessionKind kind;
  final String token;
  final String subjectId;

  String encode() =>
      jsonEncode({'kind': kind.name, 'token': token, 'subjectId': subjectId});

  @override
  String toString() => 'Session(kind: ${kind.name}, subjectId: $subjectId)';

  @override
  bool operator ==(Object other) =>
      other is Session &&
      other.kind == kind &&
      other.token == token &&
      other.subjectId == subjectId;

  @override
  int get hashCode => Object.hash(kind, token, subjectId);
}
