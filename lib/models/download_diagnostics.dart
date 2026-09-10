class DiagnosticCheckItem {
  final String title;
  final bool passed;
  final String? details;

  DiagnosticCheckItem({
    required this.title,
    required this.passed,
    this.details,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'passed': passed,
    'details': details,
  };
}

class DownloadDiagnostics {
  final String taskId;
  final String url;
  final String reason;
  final String possibleCause;
  final List<DiagnosticCheckItem> checks;
  final List<String> suggestedActions;
  final int? httpStatusCode;

  DownloadDiagnostics({
    required this.taskId,
    required this.url,
    required this.reason,
    required this.possibleCause,
    required this.checks,
    required this.suggestedActions,
    this.httpStatusCode,
  });

  factory DownloadDiagnostics.fromError({
    required String taskId,
    required String url,
    required dynamic error,
    int? statusCode,
    bool hasInternet = true,
    bool dnsPassed = true,
    bool serverReachable = true,
    bool rangeSupported = true,
  }) {
    String reason = 'Unknown error';
    String cause = 'An unexpected error occurred during transfer.';
    List<String> actions = ['Retry the download'];
    List<DiagnosticCheckItem> items = [];

    items.add(DiagnosticCheckItem(
      title: 'Internet Connection',
      passed: hasInternet,
      details: hasInternet ? 'Connected to network' : 'No network access',
    ));
    items.add(DiagnosticCheckItem(
      title: 'DNS Resolution',
      passed: dnsPassed,
      details: dnsPassed ? 'Domain resolved successfully' : 'Failed to resolve server hostname',
    ));
    items.add(DiagnosticCheckItem(
      title: 'Server Reachable',
      passed: serverReachable,
      details: serverReachable ? 'Server responded' : 'Connection timed out or refused',
    ));

    if (statusCode != null) {
      if (statusCode == 403) {
        reason = 'HTTP 403 Forbidden';
        cause = 'Server denied access. Download link may have expired or requires cookies/authentication.';
        actions = ['Open link in built-in browser', 'Refresh download session', 'Check site profile credentials'];
        items.add(DiagnosticCheckItem(title: 'Authorization', passed: false, details: 'Credentials rejected'));
      } else if (statusCode == 401) {
        reason = 'HTTP 401 Unauthorized';
        cause = 'Basic or Bearer HTTP authentication credentials required.';
        actions = ['Add username/password in Site Profiles', 'Open in browser to login'];
        items.add(DiagnosticCheckItem(title: 'Authorization', passed: false, details: 'Login required'));
      } else if (statusCode == 404) {
        reason = 'HTTP 404 Not Found';
        cause = 'The requested file does not exist or has been removed by the host.';
        actions = ['Verify URL correctness', 'Search original page for updated mirror'];
        items.add(DiagnosticCheckItem(title: 'Resource Existence', passed: false, details: 'URL not found on server'));
      } else if (statusCode == 416) {
        reason = 'HTTP 416 Range Not Satisfiable';
        cause = 'Resumed byte range exceeds server file size or file was updated.';
        actions = ['Redownload from start', 'Check if file was modified on server'];
        items.add(DiagnosticCheckItem(title: 'Range Request', passed: false, details: 'Invalid byte offset'));
      } else if (statusCode == 429) {
        reason = 'HTTP 429 Too Many Requests';
        cause = 'Server rate limit exceeded. Too many concurrent connections.';
        actions = ['Reduce connection count to 1 or 2', 'Wait for rate limit window to expire'];
        items.add(DiagnosticCheckItem(title: 'Rate Limit', passed: false, details: 'Throttled by server'));
      } else if (statusCode >= 500) {
        reason = 'HTTP $statusCode Internal Server Error';
        cause = 'Target server is experiencing technical difficulties or overload.';
        actions = ['Retry in a few minutes', 'Try another mirror if available'];
        items.add(DiagnosticCheckItem(title: 'Server Health', passed: false, details: 'Server reported error'));
      }
    } else {
      final errStr = error.toString().toLowerCase();
      if (errStr.contains('socketexception') || errStr.contains('connection refused')) {
        reason = 'Connection Refused';
        cause = 'Target host rejected network connection or port is blocked.';
        actions = ['Check proxy/VPN settings', 'Verify server is online'];
      } else if (errStr.contains('timeout')) {
        reason = 'Connection Timed Out';
        cause = 'Network latency is too high or server did not respond in time.';
        actions = ['Switch between Wi-Fi and Mobile Data', 'Retry in Turbo Mode with fewer connections'];
      } else if (errStr.contains('nospace') || errStr.contains('disk full')) {
        reason = 'Storage Space Exhausted';
        cause = 'Device storage does not have sufficient space to save chunk.';
        actions = ['Free up storage space on device', 'Change download destination in Settings'];
      } else {
        reason = 'Network Transfer Error: ${error.toString()}';
      }
    }

    return DownloadDiagnostics(
      taskId: taskId,
      url: url,
      reason: reason,
      possibleCause: cause,
      checks: items,
      suggestedActions: actions,
      httpStatusCode: statusCode,
    );
  }
}
