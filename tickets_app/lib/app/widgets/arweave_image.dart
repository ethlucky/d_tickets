import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:typed_data';
import '../services/arweave_service.dart';

/// 从 Arweave 显示图片的自定义 Widget
class ArweaveImage extends StatefulWidget {
  final String? imageHash;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const ArweaveImage({
    Key? key,
    required this.imageHash,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<ArweaveImage> createState() => _ArweaveImageState();
}

class _ArweaveImageState extends State<ArweaveImage> {
  final ArweaveService _arweaveService = Get.find<ArweaveService>();
  Uint8List? _imageData;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(ArweaveImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageHash != widget.imageHash) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.imageHash == null || widget.imageHash!.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _imageData = null;
    });

    try {
      final imageData = await _arweaveService.getImageData(widget.imageHash!);

      if (mounted) {
        setState(() {
          _imageData = imageData;
          _isLoading = false;
          _hasError = imageData == null;
        });
      }
    } catch (e) {
      print('加载 Arweave 图片失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Widget _buildImage() {
    return Container(
      width: widget.width,
      height: widget.height,
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: Image.memory(
          _imageData!,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          errorBuilder: (context, error, stackTrace) {
            print('图片显示错误: $error');
            return _buildErrorWidget();
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return widget.placeholder ??
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: widget.borderRadius,
          ),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        );
  }

  Widget _buildErrorWidget() {
    return widget.errorWidget ??
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: widget.borderRadius,
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  color: Colors.grey,
                  size: 32,
                ),
                SizedBox(height: 4),
                Text(
                  '图片加载失败',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildPlaceholder();
    }

    if (_hasError || _imageData == null) {
      return _buildErrorWidget();
    }

    return _buildImage();
  }
}

/// 带重试功能的 ArweaveImage
class ArweaveImageWithRetry extends StatefulWidget {
  final String? imageHash;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final BorderRadius? borderRadius;
  final int maxRetries;

  const ArweaveImageWithRetry({
    Key? key,
    required this.imageHash,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.borderRadius,
    this.maxRetries = 3,
  }) : super(key: key);

  @override
  State<ArweaveImageWithRetry> createState() => _ArweaveImageWithRetryState();
}

class _ArweaveImageWithRetryState extends State<ArweaveImageWithRetry> {
  int _retryCount = 0;

  Widget _buildErrorWidgetWithRetry() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: widget.borderRadius,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.broken_image,
              color: Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 4),
            if (_retryCount < widget.maxRetries)
              TextButton(
                onPressed: () {
                  setState(() {
                    _retryCount++;
                  });
                },
                child: const Text(
                  '重试',
                  style: TextStyle(fontSize: 12),
                ),
              )
            else
              const Text(
                '图片加载失败',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ArweaveImage(
      key: ValueKey('${widget.imageHash}_$_retryCount'),
      imageHash: widget.imageHash,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      placeholder: widget.placeholder,
      borderRadius: widget.borderRadius,
      errorWidget: _buildErrorWidgetWithRetry(),
    );
  }
}
