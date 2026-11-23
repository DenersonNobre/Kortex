/// Dados da sessão do usuário.
///
/// Os identificadores Dart seguem o padrão em inglês, mas as **chaves de
/// serialização** (`nome`, `tipoToken`, `expiraEm`) são um contrato congelado
/// de API/persistência legada e permanecem em português — renomeá-las
/// quebraria a desserialização de sessões já gravadas, silenciosamente.
class UserSessionData {
  final int id;
  final String name;
  final String email;
  final String token;
  final String tokenType;

  /// Instante de expiração em epoch millis; `<= 0` significa sem expiração.
  final int expiresAt;

  const UserSessionData({
    required this.id,
    required this.name,
    required this.email,
    this.token = '',
    this.tokenType = '',
    this.expiresAt = 0,
  });

  factory UserSessionData.fromMap(Map<String, dynamic> map) {
    return UserSessionData(
      id: _asInt(map['id']),
      name: map['nome']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      token: map['token']?.toString() ?? '',
      tokenType: map['tipoToken']?.toString() ?? '',
      expiresAt: _asInt(map['expiraEm']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'nome': name,
    'email': email,
    'token': token,
    'tipoToken': tokenType,
    'expiraEm': expiresAt,
  };

  UserSessionData copyWith({
    int? id,
    String? name,
    String? email,
    String? token,
    String? tokenType,
    int? expiresAt,
  }) {
    return UserSessionData(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      token: token ?? this.token,
      tokenType: tokenType ?? this.tokenType,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  static int _asInt(Object? value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '0') ?? 0;
}

abstract class IUserSession {
  UserSessionData? get currentUser;
  bool get isAuthenticated;

  void startSession(UserSessionData user);
  void update(Map<String, dynamic> map);
  void clearSession();
  Map<String, dynamic> toMap();
}

class InMemoryUserSession implements IUserSession {
  InMemoryUserSession({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  UserSessionData? _currentUser;

  @override
  UserSessionData? get currentUser => _currentUser;

  @override
  bool get isAuthenticated {
    final user = _currentUser;
    if (user == null || user.id <= 0) return false;
    // expiresAt <= 0 means "no expiry" (backward compatible default).
    // expiresAt > 0 is treated as epoch milliseconds.
    if (user.expiresAt <= 0) return true;
    return _now().millisecondsSinceEpoch < user.expiresAt;
  }

  @override
  void startSession(UserSessionData user) {
    _currentUser = user;
  }

  @override
  void update(Map<String, dynamic> map) {
    _currentUser = UserSessionData.fromMap(map);
  }

  @override
  void clearSession() {
    _currentUser = null;
  }

  @override
  Map<String, dynamic> toMap() {
    return _currentUser?.toMap() ??
        {
          'id': 0,
          'nome': '',
          'email': '',
          'token': '',
          'tipoToken': '',
          'expiraEm': 0,
        };
  }
}
