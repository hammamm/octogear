import '../../../app/routing/app_routes.dart';
import '../../authentication/domain/entities/app_user.dart';
import '../domain/entities/app_notification.dart';

String? notificationDestination(AppNotification item, AppUserRole role) {
  if (!item.canOpen) return null;
  if (role == AppUserRole.provider) {
    return switch (item.kind) {
      NotificationKind.offerAccepted => ProviderOfferRoute(
        offerId: item.offerId!,
      ).location,
      NotificationKind.message => ProviderConversationRoute(
        conversationId: item.conversationId!,
      ).location,
      NotificationKind.orderPaid || NotificationKind.orderCompleted =>
        ProviderPaidOrderRoute(orderId: item.orderId!).location,
      NotificationKind.order => switch (item.orderType) {
        'general' => ProviderGeneralRequestRoute(
          orderId: item.orderId!,
        ).location,
        'specific' => ProviderDirectOrderRoute(orderId: item.orderId!).location,
        _ => null,
      },
      NotificationKind.storeApproved || NotificationKind.storeRejected =>
        ProviderStoreApplicationRoute(requestId: item.requestId!).location,
      _ => null,
    };
  }
  return switch (item.kind) {
    NotificationKind.offer => CustomerOfferDetailsRoute(
      orderId: item.orderId!,
      offerId: item.offerId!,
    ).location,
    NotificationKind.message => CustomerConversationRoute(
      conversationId: item.conversationId!,
    ).location,
    NotificationKind.orderPaid ||
    NotificationKind.orderCompleted ||
    NotificationKind.order => CustomerOrderDetailsRoute(
      orderId: item.orderId!,
    ).location,
    NotificationKind.storeApproved ||
    NotificationKind.storeRejected => const SellerRegistrationRoute().location,
    _ => null,
  };
}
