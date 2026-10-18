/// Shared client constraints. Keep aligned with the API's config/images.php.
/// The server validates the uploaded content and remains authoritative.
abstract final class ImageUploadPolicy {
  static const maxFiles = 5;
  static const maxBytes = 5 * 1024 * 1024;
  static const maxDimension = 4096;
  static const mimeTypes = <String>{'image/jpeg', 'image/png', 'image/webp'};
}
