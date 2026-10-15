import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../domain/entities/provider_offer.dart';

class ProviderOfferDto {
  const ProviderOfferDto(this.value);
  final ProviderOffer value;
  ProviderOffer toEntity() => value;
  factory ProviderOfferDto.fromJson(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid offer.');
    }
    int id(Object? value) {
      if (value is! int || value < 1) {
        throw const FormatException('Invalid offer ID or amount.');
      }
      return value;
    }

    String? text(Object? value) {
      if (value == null) return null;
      if (value is! String) throw const FormatException('Invalid offer text.');
      return value.trim().isEmpty ? null : value;
    }

    final offerId = id(data['id']);
    final store = data['store'];
    final date = DateTime.tryParse(text(data['created_at']) ?? '');
    final status = text(data['status']);
    final orderStatus = text(data['order_status']);
    final images = data['images'];
    if (store is! Map ||
        date == null ||
        status == null ||
        orderStatus == null ||
        images is! List ||
        data['can_edit'] is! bool ||
        data['can_withdraw'] is! bool) {
      throw const FormatException('Incomplete provider offer.');
    }
    return ProviderOfferDto(
      ProviderOffer(
        id: offerId,
        orderId: id(data['order_id']),
        storeId: id(store['id']),
        storeName:
            text(store['name']) ??
            (throw const FormatException('Missing store name.')),
        price: id(data['price']),
        status: status,
        orderStatus: orderStatus,
        createdAt: date,
        canEdit:
            data['can_edit'] == true &&
            status == 'pending' &&
            orderStatus == 'pending',
        canWithdraw:
            data['can_withdraw'] == true &&
            status == 'pending' &&
            orderStatus == 'pending',
        partName: text(data['part_name']),
        notes: text(data['notes']),
        rejectionReason: text(data['rejection_reason']),
        imagePaths: List.unmodifiable(
          images.map((image) {
            final path = image is Map ? image['url'] : null;
            if (path is! String ||
                !RegExp(
                  '^/api/media/offers/$offerId/images/[1-9][0-9]*\$',
                ).hasMatch(path)) {
              throw const FormatException('Invalid private offer image.');
            }
            return path;
          }),
        ),
      ),
    );
  }
}

class ProviderOffersPageDto {
  const ProviderOffersPageDto(this.items, this.page, this.lastPage, this.total);
  final List<ProviderOfferDto> items;
  final int page, lastPage, total;
  ProviderOffersPage toEntity() => ProviderOffersPage(
    List.unmodifiable(items.map((e) => e.toEntity())),
    page,
    lastPage,
    total,
  );
}

FormData providerOfferForm(ProviderOfferCommand command) {
  final form = FormData.fromMap({
    if (command.offerId != null) '_method': 'PUT',
    if (command.offerId == null) 'store_id': command.storeId,
    'price': command.price,
    'notes': command.notes.trim(),
    if (command.photos != null && command.photos!.isEmpty) 'clear_images': '1',
  });
  for (var i = 0; i < (command.photos?.length ?? 0); i++) {
    final photo = command.photos![i];
    final extension = switch (photo.mimeType) {
      'image/jpeg' => 'jpg',
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => throw const FormatException('Invalid photo.'),
    };
    form.files.add(
      MapEntry(
        'images[]',
        MultipartFile.fromBytes(
          photo.bytes,
          filename: 'offer-${i + 1}.$extension',
          contentType: MediaType.parse(photo.mimeType),
        ),
      ),
    );
  }
  return form;
}
