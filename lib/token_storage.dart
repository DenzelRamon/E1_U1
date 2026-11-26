// Ejercicio 3.4 - Almacenamiento seguro de un token JWT (Flutter)
//
// pubspec.yaml:
//   dependencies:
//     flutter_secure_storage: ^9.2.0
//
// Qué hace por debajo:
//  - Android: cifra con una clave del Android Keystore (EncryptedSharedPreferences).
//  - iOS: guarda en Keychain Services.
//
// Android: minSdkVersion 23 o superior en android/app/build.gradle.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _jwtKey = 'jwt_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      // Disponible tras el primer desbloqueo; no se migra a otros dispositivos.
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  Future<void> saveToken(String jwt) => _storage.write(key: _jwtKey, value: jwt);

  Future<String?> readToken() => _storage.read(key: _jwtKey);

  Future<void> deleteToken() => _storage.delete(key: _jwtKey);
}

// Ejemplo de uso
Future<void> demo() async {
  final storage = TokenStorage();

  const jwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
      'eyJzdWIiOiIxMjM0NTYiLCJuYW1lIjoiRGVtbyJ9.'
      'firma_de_ejemplo';

  await storage.saveToken(jwt);
  final recuperado = await storage.readToken();
  print('Token recuperado: ${recuperado == jwt ? "OK" : "FALLÓ"}');

  await storage.deleteToken(); // al cerrar sesión
}

// -------------------------------------------------------------
// Equivalente nativo ANDROID (Kotlin) - EncryptedSharedPreferences
// implementation "androidx.security:security-crypto:1.1.0-alpha06"
//
// val masterKey = MasterKey.Builder(context)
//     .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
//     .build()
// val prefs = EncryptedSharedPreferences.create(
//     context, "secure_prefs", masterKey,
//     EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
//     EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
// )
// prefs.edit().putString("jwt_token", jwt).apply()
// val token = prefs.getString("jwt_token", null)
//
// -------------------------------------------------------------
// Equivalente nativo iOS (Swift) - Keychain Services
//
// func saveToken(_ jwt: String) -> Bool {
//     let data = Data(jwt.utf8)
//     let query: [String: Any] = [
//         kSecClass as String: kSecClassGenericPassword,
//         kSecAttrAccount as String: "jwt_token",
//         kSecValueData as String: data,
//         kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
//     ]
//     SecItemDelete(query as CFDictionary)           // evita duplicados
//     return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
// }
//
// func readToken() -> String? {
//     let query: [String: Any] = [
//         kSecClass as String: kSecClassGenericPassword,
//         kSecAttrAccount as String: "jwt_token",
//         kSecReturnData as String: true,
//         kSecMatchLimit as String: kSecMatchLimitOne
//     ]
//     var item: CFTypeRef?
//     guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
//           let data = item as? Data else { return nil }
//     return String(data: data, encoding: .utf8)
// }
