import '../../../part_requests/domain/entities/part_request.dart';

class ProviderOffer {
  const ProviderOffer({
    required this.id,
    required this.orderId,
    required this.storeId,
    required this.storeName,
    required this.price,
    required this.status,
    required this.orderStatus,
    required this.createdAt,
    required this.canEdit,
    required this.canWithdraw,
    this.partName,
    this.notes,
    this.rejectionReason,
    this.imagePaths = const [],
  });
  final int id, orderId, storeId, price;
  final String storeName, status, orderStatus;
  final DateTime createdAt;
  final bool canEdit, canWithdraw;
  final String? partName, notes, rejectionReason;
  final List<String> imagePaths;
}

class ProviderOffersPage {
  const ProviderOffersPage(this.items, this.page, this.lastPage, this.total);
  final List<ProviderOffer> items;
  final int page, lastPage, total;
  bool get hasMore => page < lastPage;
}

class ProviderOfferCommand {
  ProviderOfferCommand({
    required this.orderId,
    required this.storeId,
    required this.price,
    required this.notes,
    this.offerId,
    List<PartRequestPhoto>? photos,
  }) : photos = photos == null ? null : List.unmodifiable(photos);
  final int orderId, storeId, price;
  final int? offerId;
  final String notes;
  // Null preserves existing images on edit; a list replaces them.
  final List<PartRequestPhoto>? photos;
}

/// Parse riyals without floating-point rounding; accept Arabic and Persian digits.
int? providerOfferPrice(String input) {
  var text = input.trim().replaceAll('٫', '.');
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  for (var i = 0; i < 10; i++) {
    text = text.replaceAll(arabic[i], '$i').replaceAll(persian[i], '$i');
  }
  if (!RegExp(r'^\d{1,8}(\.\d{1,2})?$').hasMatch(text)) return null;
  final parts = text.split('.');
  final minor =
      int.parse(parts[0]) * 100 +
      int.parse(parts.length == 1 ? '0' : parts[1].padRight(2, '0'));
  return minor > 0 && minor <= 2147483647 ? minor : null;
}
