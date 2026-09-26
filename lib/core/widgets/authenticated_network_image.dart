import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_providers.dart';

/// Renders a server image that requires the current in-memory bearer session.
///
/// Features pass Laravel's API-relative media URL. This widget resolves it
/// through the configured API host and attaches the token as a header rather
/// than exposing credentials in a URL.
class AuthenticatedNetworkImage extends ConsumerWidget {
  const AuthenticatedNetworkImage({
    required this.apiPath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.cacheWidth,
    this.cacheHeight,
    this.semanticLabel,
    this.loadingBuilder,
    this.errorBuilder,
    super.key,
  });

  final String apiPath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? cacheWidth;
  final int? cacheHeight;
  final String? semanticLabel;
  final ImageLoadingBuilder? loadingBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiClient = ref.watch(apiClientProvider);
    final imageUri = apiClient.resolveAuthenticatedApiUri(apiPath);

    if (imageUri == null) {
      return errorBuilder?.call(
            context,
            ArgumentError.value(apiPath, 'apiPath', 'Unsafe private media URL'),
            StackTrace.current,
          ) ??
          const SizedBox.shrink();
    }

    return Image.network(
      imageUri.toString(),
      headers: apiClient.authenticatedHeaders,
      fit: fit,
      width: width,
      height: height,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      semanticLabel: semanticLabel,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
    );
  }
}
