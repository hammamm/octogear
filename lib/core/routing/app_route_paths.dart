/// Stable, semantic locations for the OctoGear app.
///
/// Keep paths about a product capability, not a widget class. Screens navigate
/// with the generated typed route helpers in `app/routing/app_routes.dart`;
/// these constants are only the router's central URL contract.
abstract final class AppRoutePath {
  static const sessionLoading = '/';
  static const phoneSignIn = '/auth/phone';
  static const otpVerification = '/auth/otp';
  static const registration = '/auth/register';
  static const sessionUnavailable = '/session-unavailable';
  static const customerHome = '/customer';
  static const customerStores = '/customer/stores';
  static const customerStoreDetailsSegment = ':storeId';
  static const customerStoreCarSegment = 'cars/:carId';
  static const customerPartRequestSegment = 'components/:componentId/request';
  static const customerOrders = '/customer/orders';
  static const customerOrderDetailsSegment = ':orderId';
  static const customerAccount = '/customer/account';
  static const customerChats = '/customer/chats';
  static const customerMore = '/customer/more';
  static const customerCars = '/customer/more/cars';
  static const customerCarsAdd = '/customer/more/cars/add';
  static const customerCarsAddSegment = 'add';
  static const customerCarsDetailsSegment = ':carId';
  static const customerCarsEditSegment = 'edit';
  static const providerHome = '/provider';
}
