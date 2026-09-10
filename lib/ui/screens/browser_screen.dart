import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/download_task.dart';
import '../theme/app_theme.dart';
import '../widgets/add_download_dialog.dart';

class SniffedMedia {
  final String url;
  final String filename;
  final DownloadCategory category;

  SniffedMedia({
    required this.url,
    required this.filename,
    required this.category,
  });
}

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  late final WebViewController _controller;
  final TextEditingController _urlBarController = TextEditingController(text: 'https://archive.org');
  bool _isLoading = false;
  double _loadingProgress = 0.0;
  bool _isIncognito = false;
  final List<SniffedMedia> _sniffedItems = [];

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            setState(() {
              _loadingProgress = progress / 100.0;
            });
          },
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _urlBarController.text = url;
            });
            _sniffUrl(url);
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
              _loadingProgress = 0.0;
            });
          },
          onNavigationRequest: (request) {
            _sniffUrl(request.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://archive.org'));
  }

  void _sniffUrl(String url) {
    final lower = url.toLowerCase();
    final isMedia = lower.contains('.mp4') ||
        lower.contains('.mkv') ||
        lower.contains('.mp3') ||
        lower.contains('.pdf') ||
        lower.contains('.zip') ||
        lower.contains('.apk') ||
        lower.contains('.iso') ||
        lower.contains('.rar');

    if (isMedia) {
      final uri = Uri.tryParse(url);
      final filename = uri?.pathSegments.isNotEmpty == true ? uri!.pathSegments.last : 'media_download';
      final category = DownloadTask.detectCategory(filename);

      if (!_sniffedItems.any((item) => item.url == url)) {
        setState(() {
          _sniffedItems.insert(0, SniffedMedia(url: url, filename: filename, category: category));
        });
      }
    }
  }

  void _loadEnteredUrl() {
    var raw = _urlBarController.text.trim();
    if (raw.isEmpty) return;

    if (!raw.startsWith('http://') && !raw.startsWith('https://')) {
      if (raw.contains('.') && !raw.contains(' ')) {
        raw = 'https://$raw';
      } else {
        raw = 'https://duckduckgo.com/?q=${Uri.encodeComponent(raw)}';
      }
    }
    _controller.loadRequest(Uri.parse(raw));
  }

  void _showSnifferSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF192231),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.stream_rounded, color: AppTheme.neonGreen),
                      const SizedBox(width: 8),
                      Text(
                        'MEDIA SNIFFER (${_sniffedItems.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _sniffedItems.clear());
                      Navigator.pop(ctx);
                    },
                    child: const Text('Clear All', style: TextStyle(color: Colors.white54)),
                  ),
                ],
              ),
              const Divider(color: Colors.white12),
              if (_sniffedItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('No media links detected on this page.', style: TextStyle(color: Colors.white54)),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _sniffedItems.length,
                    itemBuilder: (context, index) {
                      final item = _sniffedItems[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: Colors.white10,
                          child: Icon(Icons.download, color: AppTheme.primaryCyan),
                        ),
                        title: Text(item.filename, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(item.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryCyan,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            showDialog(
                              context: context,
                              builder: (_) => AddDownloadDialog(initialUrl: item.url),
                            );
                          },
                          child: const Text('Download'),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
              onPressed: () => _controller.goBack(),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              onPressed: () => _controller.goForward(),
            ),
            Expanded(
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(
                    color: _isIncognito ? Colors.purpleAccent : Colors.white12,
                  ),
                ),
                child: TextField(
                  controller: _urlBarController,
                  onSubmitted: (_) => _loadEnteredUrl(),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    border: InputBorder.none,
                    hintText: 'Search or type URL...',
                    prefixIcon: Icon(
                      _isIncognito ? Icons.security : Icons.lock_outline,
                      size: 16,
                      color: _isIncognito ? Colors.purpleAccent : AppTheme.neonGreen,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(_isLoading ? Icons.close : Icons.refresh_rounded),
              onPressed: () {
                if (_isLoading) {
                  _controller.loadRequest(Uri.parse('about:blank'));
                } else {
                  _controller.reload();
                }
              },
            ),
            IconButton(
              icon: Icon(
                _isIncognito ? Icons.visibility_off : Icons.visibility_off_outlined,
                color: _isIncognito ? Colors.purpleAccent : Colors.white54,
              ),
              tooltip: 'Incognito Mode',
              onPressed: () {
                setState(() => _isIncognito = !_isIncognito);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_isIncognito ? 'Incognito Mode Activated' : 'Normal Browsing'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _loadingProgress,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryCyan),
                minHeight: 3,
              ),
            ),

          // Floating Media Sniffer Badge (Requirement #13)
          if (_sniffedItems.isNotEmpty)
            Positioned(
              bottom: 24,
              right: 20,
              child: FloatingActionButton.extended(
                backgroundColor: AppTheme.neonGreen,
                foregroundColor: Colors.black,
                onPressed: _showSnifferSheet,
                icon: const Icon(Icons.downloading_rounded),
                label: Text(
                  '${_sniffedItems.length} Media Detected',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
