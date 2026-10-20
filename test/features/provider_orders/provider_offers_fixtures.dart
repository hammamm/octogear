import 'package:octogear/features/provider_orders/domain/entities/provider_offer.dart';
import 'package:octogear/features/provider_orders/domain/repositories/provider_offers_repository.dart';

ProviderOffer testOffer({
  int id = 11,
  int orderId = 1,
  int storeId = 1,
  int price = 12345,
  String status = 'pending',
  String orderStatus = 'pending',
  String? notes = 'Available',
}) => ProviderOffer(
  id: id,
  orderId: orderId,
  storeId: storeId,
  storeName: 'Al Faris Parts',
  price: price,
  status: status,
  orderStatus: orderStatus,
  createdAt: DateTime.utc(2026, 10, 15),
  canEdit: status == 'pending' && orderStatus == 'pending',
  canWithdraw: status == 'pending' && orderStatus == 'pending',
  notes: notes,
  partName: 'Front headlight',
);
Map<String, dynamic> offerJson() => {
  'id': 11,
  'order_id': 1,
  'store': {'id': 1, 'name': 'Al Faris Parts'},
  'price': 12345,
  'status': 'pending',
  'order_status': 'pending',
  'created_at': '2026-10-15T00:00:00Z',
  'can_edit': true,
  'can_withdraw': true,
  'images': [],
  'notes': 'Available',
};

class FakeOffers implements ProviderOffersRepository {
  final calls = <(int, int?)>[];
  final saves = <ProviderOfferCommand>[];
  final conversations = <int?>[];
  int withdrawals = 0;
  List<ProviderOffer> items = [];
  Future<ProviderOffer> Function(ProviderOfferCommand)? onSave;
  Future<ProviderOffersPage> Function(int, int?)? onList;
  Future<ProviderOffer> Function(int)? onGet;
  @override
  Future<ProviderOffersPage> list({
    int page = 1,
    int? orderId,
    int? conversationId,
  }) async {
    calls.add((page, orderId));
    conversations.add(conversationId);
    return onList?.call(page, orderId) ??
        ProviderOffersPage(
          List.of(
            items.where((offer) => orderId == null || offer.orderId == orderId),
          ),
          1,
          1,
          items.length,
        );
  }

  @override
  Future<ProviderOffer> get(int id) async =>
      onGet?.call(id) ?? items.firstWhere((e) => e.id == id);
  @override
  Future<ProviderOffer> save(ProviderOfferCommand command) async {
    saves.add(command);
    if (onSave != null) return onSave!(command);
    final offer = testOffer(
      id: command.offerId ?? 11,
      orderId: command.orderId,
      storeId: command.storeId,
      price: command.price,
      notes: command.notes,
    );
    items = [...items.where((e) => e.id != offer.id), offer];
    return offer;
  }

  @override
  Future<void> withdraw(ProviderOffer offer) async {
    withdrawals++;
    items.removeWhere((e) => e.id == offer.id);
  }
}
