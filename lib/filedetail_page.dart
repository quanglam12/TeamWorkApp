import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'l10n/app_localizations.dart';

class FileDetailPage extends StatefulWidget {
  final String fileUrl;
  final String name;

  const FileDetailPage({super.key, required this.fileUrl, required this.name});

  @override
  State<FileDetailPage> createState() => _FileDetailPageState();
}

class _FileDetailPageState extends State<FileDetailPage> {
  late final WebViewController _webViewController;
  bool? _fileExists;
  bool _isLoading = true;
  double downloadProgress = 0.0;
  bool isDownloading = false;

  bool get isPdf => widget.fileUrl.toLowerCase().endsWith('.pdf');

  bool get isOfficeFile {
    final lower = widget.fileUrl.toLowerCase();
    return lower.endsWith('.doc') ||
        lower.endsWith('.docx') ||
        lower.endsWith('.ppt') ||
        lower.endsWith('.pptx') ||
        lower.endsWith('.xls') ||
        lower.endsWith('.xlsx');
  }
  bool get isImage {
    final lower = widget.fileUrl.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif');
  }


  @override
  void initState() {
    super.initState();
    _checkFileExists();

    // khởi tạo controller webview cho file office
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _isLoading = false),
        ),
      );
  }

  Future<void> _checkFileExists() async {
    try {
      final response = await http.head(Uri.parse(widget.fileUrl));
      if (response.statusCode == 200) {
        _fileExists = true;
        if (isOfficeFile) {
          _webViewController.loadRequest(Uri.parse(
              'https://docs.google.com/gview?embedded=true&url=${Uri.encodeFull(widget.fileUrl)}'));
        }
      } else {
        _fileExists = false;
      }
    } on SocketException {
      _fileExists = false;
    } catch (e) {
      _fileExists = false;
      //debugPrint('Lỗi check file: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _downloadFile() async {
    try {

      final fileName = widget.name;

      // Xin quyền lưu trữ
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.storage_permission_denied)),
          );
        }
        return;
      }

      // Thư mục lưu Downloads
      Directory downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }
      final savePath = '${downloadsDir.path}/$fileName';

      final dio = Dio();

      double lastPercent = 0;

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.download_start}: $fileName')));
      }

      await dio.download(
        widget.fileUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final percent = (received / total * 100);
            // Chỉ cập nhật khi % thay đổi
            if (percent != lastPercent) {
              lastPercent = percent;
              //debugPrint('Tiến trình: ${percent.toInt()}%');
              if (mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${AppLocalizations.of(context)!.downloading}: ${percent.toInt()}%'),
                    duration: const Duration(milliseconds: 1),
                  ),
                );
              }
            }
          }
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.download_completed}: $savePath')),
        );
      }
    } catch (e) {
      debugPrint('Download error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.download_failed}: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    Widget body;

    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_fileExists == false) {
      body = Center(child: Text(AppLocalizations.of(context)!.file_not_found));
    } else if (isImage) {
      body = Center(
        child: Image.network(
          widget.fileUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Text(AppLocalizations.of(context)!.image_not_displayed);
          },
        ),
      );
    }
    else if (isPdf) {
      body = SfPdfViewer.network(widget.fileUrl);
    } /*else if (isOfficeFile) {
      debugPrint('Displaying Office file in WebView: ${widget.fileUrl}');
      body = Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              color: Colors.white70,
              padding: const EdgeInsets.all(4),
              child: Text(
                'URL: ${widget.fileUrl}',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
        ],
      );
    }*/ else {
      body = Center(child: Text(AppLocalizations.of(context)!.file_type_not_supported));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _fileExists == true && !isDownloading ? _downloadFile : null,
          ),
        ],
      ),
      body: Column(
        children: [
          if (isDownloading)
            Column(
              children: [
                LinearProgressIndicator(value: downloadProgress),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '${AppLocalizations.of(context)!.loading}: ${(downloadProgress * 100).toStringAsFixed(0)}%',
                  ),
                ),
              ],
            ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
