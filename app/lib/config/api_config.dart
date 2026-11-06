/// Zentrale Server-Konfiguration der App.
///
/// Adresse und API-Key kommen beim Bauen aus `--dart-define=API_URL=...`
/// und `--dart-define=API_KEY=...` (z. B. `make app` gegen die lokale
/// Dev-API). Ohne Angabe gilt die Produktion. Später (#24) ersetzt die
/// Serverwahl im Onboarding die feste Adresse.
class ApiConfig {
  ApiConfig._();

  static const String _defaultUrl = 'https://manga-api.phudevelopement.xyz';

  static const String _fromEnvironment =
      String.fromEnvironment('API_URL', defaultValue: _defaultUrl);

  /// Basis-URL ohne abschließenden Schrägstrich, z. B. `https://host`.
  static final String baseUrl = _fromEnvironment.endsWith('/')
      ? _fromEnvironment.substring(0, _fromEnvironment.length - 1)
      : _fromEnvironment;

  /// API-Key für `/api/manga`. Steckt zwangsläufig in der App und ist damit
  /// kein Geheimnis; entfällt, sobald `/api/manga` nur noch Tokens nimmt (#6).
  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: 'NTfvGXfVZf3MEgyr56qQbk5Y3Zxfj6A/kI68GnD97hs=',
  );
}
