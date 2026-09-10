import 'dart:convert';

class SiteProfile {
  final String id;
  final String domain;
  final int maxConnections;
  final Map<String, String> customHeaders;
  final String? cookies;
  final String? userAgent;

  SiteProfile({
    required this.id,
    required this.domain,
    this.maxConnections = 8,
    Map<String, String>? customHeaders,
    this.cookies,
    this.userAgent,
  }) : customHeaders = customHeaders ?? {};

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'domain': domain,
      'maxConnections': maxConnections,
      'customHeaders': jsonEncode(customHeaders),
      'cookies': cookies,
      'userAgent': userAgent,
    };
  }

  factory SiteProfile.fromMap(Map<String, dynamic> map) {
    Map<String, String> headers = {};
    if (map['customHeaders'] != null && map['customHeaders'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['customHeaders'] as String) as Map<String, dynamic>;
        headers = decoded.map((k, v) => MapEntry(k, v.toString()));
      } catch (_) {}
    }

    return SiteProfile(
      id: map['id'] as String,
      domain: map['domain'] as String,
      maxConnections: map['maxConnections'] as int? ?? 8,
      customHeaders: headers,
      cookies: map['cookies'] as String?,
      userAgent: map['userAgent'] as String?,
    );
  }
}
