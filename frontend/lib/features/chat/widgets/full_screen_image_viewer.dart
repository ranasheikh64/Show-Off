import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

class FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final bool isLocalFile;

  const FullScreenImageViewer({
    Key? key,
    required this.imageUrl,
    this.isLocalFile = false,
  }) : super(key: key);

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  bool _isDownloading = false;

  Future<void> _downloadImage() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }
      
      if (widget.isLocalFile) {
        // Already local, just save to gallery
        await Gal.putImage(widget.imageUrl);
        _showSnackbar('Image saved to gallery!');
      } else {
        // Download from network
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Dio().download(widget.imageUrl, path);
        await Gal.putImage(path);
        _showSnackbar('Image saved to gallery!');
      }
    } on GalException catch (e) {
      print('Gal error: ${e.type.toString()}');
      _showSnackbar('Failed to save image: permissions or storage issue.');
    } catch (e) {
      print('Download error: $e');
      _showSnackbar('Error downloading image.');
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          _isDownloading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: _downloadImage,
                ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag: widget.imageUrl,
            child: widget.isLocalFile
                ? Image.file(
                    File(widget.imageUrl),
                    fit: BoxFit.contain,
                  )
                : Image.network(
                    widget.imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
