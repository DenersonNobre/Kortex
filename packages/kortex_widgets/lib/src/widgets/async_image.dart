import 'package:flutter/material.dart';

class AsyncImage extends StatelessWidget {
  const AsyncImage({
    super.key,
    required this.url,
    this.fit,
    this.width,
    this.height,
    this.errorBuilder,
    this.loadingBuilder,
    this.onRetry,
    this.retryLabel,
  });

  final String url;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final ImageErrorWidgetBuilder? errorBuilder;
  final WidgetBuilder? loadingBuilder;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        final customBuilder = loadingBuilder;
        if (customBuilder != null) return customBuilder(context);
        final totalBytes = progress.expectedTotalBytes;
        return Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              value: totalBytes == null
                  ? null
                  : progress.cumulativeBytesLoaded / totalBytes,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        final customBuilder = errorBuilder;
        if (customBuilder != null) {
          return customBuilder(context, error, stackTrace);
        }
        final retry = onRetry;
        final label = retryLabel;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.error,
            ),
            if (retry != null && label != null) ...[
              const SizedBox(height: 4),
              TextButton(onPressed: retry, child: Text(label)),
            ],
          ],
        );
      },
    );
  }
}
