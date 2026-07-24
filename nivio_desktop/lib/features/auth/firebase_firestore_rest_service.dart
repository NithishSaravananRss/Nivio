import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_environment.dart';
import 'firebase_auth_rest_service.dart';

class FirebaseFirestoreRestService {
  FirebaseFirestoreRestService._();

  static final FirebaseFirestoreRestService instance =
      FirebaseFirestoreRestService._();

  final http.Client _client = http.Client();
  final FirebaseAuthRestService _auth = FirebaseAuthRestService.instance;

  bool get isConfigured =>
      AppEnvironment.firebaseProjectId.isNotEmpty &&
      AppEnvironment.firebaseWebApiKey.isNotEmpty;

  Future<void> setDocument(String path, Map<String, dynamic> data) async {
    final token = await _auth.idToken();
    if (token == null || !isConfigured) return;
    final response = await _client.patch(
      _documentUri(path),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'fields': _encodeFields(data)}),
    );
    _throwIfFailed(response);
  }

  Future<void> deleteDocument(String path) async {
    final token = await _auth.idToken();
    if (token == null || !isConfigured) return;
    final response = await _client.delete(
      _documentUri(path),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 404) return;
    _throwIfFailed(response);
  }

  Future<Map<String, dynamic>?> getDocument(String path) async {
    final token = await _auth.idToken();
    if (token == null || !isConfigured) return null;
    final response = await _client.get(
      _documentUri(path),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 404) return null;
    _throwIfFailed(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _decodeFields((json['fields'] as Map?) ?? const {});
  }

  Future<List<Map<String, dynamic>>> listDocuments(String path) async {
    final token = await _auth.idToken();
    if (token == null || !isConfigured) return const [];
    final response = await _client.get(
      _documentUri(path),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 404) return const [];
    _throwIfFailed(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final documents = json['documents'];
    if (documents is! List) return const [];
    return documents
        .whereType<Map>()
        .map((doc) => _decodeFields((doc['fields'] as Map?) ?? const {}))
        .toList(growable: false);
  }

  Uri _documentUri(String path) => Uri.https(
    'firestore.googleapis.com',
    '/v1/projects/${AppEnvironment.firebaseProjectId}/databases/(default)/documents/$path',
    {'key': AppEnvironment.firebaseWebApiKey},
  );

  static Map<String, dynamic> _encodeFields(Map<String, dynamic> data) {
    final fields = <String, dynamic>{};
    for (final entry in data.entries) {
      final value = _encodeValue(entry.value);
      if (value != null) fields[entry.key] = value;
    }
    return fields;
  }

  static Map<String, dynamic>? _encodeValue(Object? value) {
    if (value == null) return {'nullValue': null};
    if (value is bool) return {'booleanValue': value};
    if (value is int) return {'integerValue': value.toString()};
    if (value is double) return {'doubleValue': value};
    if (value is num) return {'doubleValue': value.toDouble()};
    if (value is DateTime) {
      return {'timestampValue': value.toUtc().toIso8601String()};
    }
    if (value is Iterable) {
      return {
        'arrayValue': {
          'values': [for (final item in value) ?_encodeValue(item)],
        },
      };
    }
    if (value is Map) {
      return {
        'mapValue': {
          'fields': _encodeFields(
            value.map((key, value) => MapEntry(key.toString(), value)),
          ),
        },
      };
    }
    return {'stringValue': value.toString()};
  }

  static Map<String, dynamic> _decodeFields(Map fields) {
    return fields.map(
      (key, value) => MapEntry(key.toString(), _decodeValue(value)),
    );
  }

  static Object? _decodeValue(Object? value) {
    if (value is! Map) return null;
    if (value.containsKey('nullValue')) return null;
    if (value.containsKey('booleanValue')) return value['booleanValue'] == true;
    if (value.containsKey('integerValue')) {
      return int.tryParse(value['integerValue'].toString());
    }
    if (value.containsKey('doubleValue')) {
      final raw = value['doubleValue'];
      return raw is num ? raw.toDouble() : double.tryParse(raw.toString());
    }
    if (value.containsKey('stringValue')) {
      return value['stringValue']?.toString();
    }
    if (value.containsKey('timestampValue')) {
      return DateTime.tryParse(
        value['timestampValue'].toString(),
      )?.millisecondsSinceEpoch;
    }
    if (value.containsKey('arrayValue')) {
      final values = value['arrayValue']?['values'];
      if (values is! List) return const [];
      return values.map(_decodeValue).toList(growable: false);
    }
    if (value.containsKey('mapValue')) {
      return _decodeFields((value['mapValue']?['fields'] as Map?) ?? const {});
    }
    return null;
  }

  static void _throwIfFailed(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    try {
      final json = jsonDecode(response.body);
      final message = json['error']?['message'];
      if (message != null) throw FirestoreFailure(message.toString());
    } catch (error) {
      if (error is FirestoreFailure) rethrow;
    }
    throw FirestoreFailure(response.body);
  }
}

class FirestoreFailure implements Exception {
  const FirestoreFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
