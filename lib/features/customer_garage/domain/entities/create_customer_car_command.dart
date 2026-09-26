import 'dart:typed_data';

/// One selected image ready to upload with a customer car.
///
/// It intentionally contains bytes and MIME data only, never a device path or
/// the source gallery file name. Laravel remains responsible for validating,
/// normalizing, and naming the final stored media.
class CustomerCarPhotoUpload {
  const CustomerCarPhotoUpload({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;
}

/// The customer-car write command passed from presentation through domain.
///
/// The same [idempotencyKey] is retained only for an explicit retry of this
/// exact submission, so an uncertain network result cannot create duplicates.
class CreateCustomerCarCommand {
  const CreateCustomerCarCommand({
    required this.carNameId,
    required this.manufacturingYear,
    required this.licensePlateNumber,
    required this.colorId,
    required this.fuelTypeId,
    required this.pictures,
    required this.idempotencyKey,
  });

  final int carNameId;
  final int manufacturingYear;
  final String licensePlateNumber;
  final int colorId;
  final int fuelTypeId;
  final List<CustomerCarPhotoUpload> pictures;
  final String idempotencyKey;
}
