import 'download_task.dart';

class SmartRule {
  final String id;
  final String name;
  final String? domainPattern;
  final String? fileExtension;
  final DownloadCategory? targetCategory;
  final String? customSubfolder;
  final int? connections;
  final DownloadPriority? priority;
  final bool? wifiOnly;
  final bool isEnabled;

  SmartRule({
    required this.id,
    required this.name,
    this.domainPattern,
    this.fileExtension,
    this.targetCategory,
    this.customSubfolder,
    this.connections,
    this.priority,
    this.wifiOnly,
    this.isEnabled = true,
  });

  bool matches(String url, String filename) {
    if (!isEnabled) return false;

    if (domainPattern != null && domainPattern!.trim().isNotEmpty) {
      if (!url.toLowerCase().contains(domainPattern!.toLowerCase())) {
        return false;
      }
    }

    if (fileExtension != null && fileExtension!.trim().isNotEmpty) {
      final ext = fileExtension!.startsWith('.') ? fileExtension! : '.$fileExtension';
      if (!filename.toLowerCase().endsWith(ext.toLowerCase())) {
        return false;
      }
    }

    return true;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'domainPattern': domainPattern,
      'fileExtension': fileExtension,
      'targetCategory': targetCategory?.index,
      'customSubfolder': customSubfolder,
      'connections': connections,
      'priority': priority?.index,
      'wifiOnly': wifiOnly == null ? null : (wifiOnly! ? 1 : 0),
      'isEnabled': isEnabled ? 1 : 0,
    };
  }

  factory SmartRule.fromMap(Map<String, dynamic> map) {
    return SmartRule(
      id: map['id'] as String,
      name: map['name'] as String,
      domainPattern: map['domainPattern'] as String?,
      fileExtension: map['fileExtension'] as String?,
      targetCategory: map['targetCategory'] != null
          ? DownloadCategory.values[map['targetCategory'] as int]
          : null,
      customSubfolder: map['customSubfolder'] as String?,
      connections: map['connections'] as int?,
      priority: map['priority'] != null
          ? DownloadPriority.values[map['priority'] as int]
          : null,
      wifiOnly: map['wifiOnly'] != null ? (map['wifiOnly'] as int == 1) : null,
      isEnabled: (map['isEnabled'] as int? ?? 1) == 1,
    );
  }
}
