import 'dart:typed_data';

typedef PartRequestKey = ({int storeId, int carId, int componentId});

class PartRequestPhoto {
  PartRequestPhoto({required Uint8List bytes, required this.mimeType})
    : bytes = Uint8List.fromList(bytes).asUnmodifiableView();
  final Uint8List bytes;
  final String mimeType;
}

class PartRequestCommand {
  const PartRequestCommand({
    required this.componentId,
    required this.quantity,
    required this.notes,
    required this.idempotencyKey,
    this.photo,
  });
  final int componentId;
  final int quantity;
  final String notes;
  final String idempotencyKey;
  final PartRequestPhoto? photo;
}

class PartRequestReceipt {
  const PartRequestReceipt({required this.id, required this.quantity});
  final int id;
  final int quantity;
}
