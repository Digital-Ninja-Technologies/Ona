import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_view.dart';

/// Renders an external link (Google Maps directions, a place's website, a
/// review page, …) inside the app instead of handing off to Safari/Chrome —
/// so the user never leaves Ọ̀nà for a link tapped inside it. [initialTitle]
/// shows in the app bar until the page's own `<title>` loads.
class InAppBrowserScreen extends StatefulWidget {
  const InAppBrowserScreen({super.key, required this.url, this.initialTitle});

  final String url;
  final String? initialTitle;

  @override
  State<InAppBrowserScreen> createState() => _InAppBrowserScreenState();
}

class _InAppBrowserScreenState extends State<InAppBrowserScreen> {
  late final WebViewController _controller;
  double _progress = 0;
  String? _title;
  bool _hasError = false;
  bool _canGoBack = false;

  @override
  void initState() {
    super.initState();
    _title = widget.initialTitle;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress / 100);
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _hasError = false);
          },
          onPageFinished: (_) async {
            final pageTitle = await _controller.getTitle();
            final canGoBack = await _controller.canGoBack();
            if (!mounted) return;
            setState(() {
              if (pageTitle != null && pageTitle.trim().isNotEmpty) {
                _title = pageTitle;
              }
              _canGoBack = canGoBack;
            });
          },
          onWebResourceError: (error) {
            // Sub-frame/asset errors (ads, trackers, etc.) shouldn't blank
            // the whole page — only treat a failed main-frame load as fatal.
            if (mounted && (error.isForMainFrame ?? true)) {
              setState(() => _hasError = true);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _openExternally() async {
    await launchUrl(Uri.parse(widget.url), mode: LaunchMode.externalApplication);
  }

  Future<bool> _handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_canGoBack,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _handleBack() && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () async {
              if (await _handleBack() && context.mounted) context.pop();
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _title?.trim().isNotEmpty == true ? _title! : 'Loading…',
                style: AppTheme.fredoka(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                Uri.tryParse(widget.url)?.host ?? widget.url,
                style: AppTheme.poppins(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.refreshCw),
              tooltip: 'Reload',
              onPressed: () => _controller.reload(),
            ),
            IconButton(
              icon: const Icon(LucideIcons.externalLink),
              tooltip: 'Open in browser',
              onPressed: _openExternally,
            ),
          ],
          bottom: _progress < 1
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 2,
                    backgroundColor: AppColors.surface,
                    valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                  ),
                )
              : null,
        ),
        body: _hasError
            ? ErrorView(
                message: "Couldn't load this page.",
                onRetry: () => _controller.reload(),
              )
            : WebViewWidget(controller: _controller),
      ),
    );
  }
}
