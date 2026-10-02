import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_providers.dart';
import '../../../../core/localization/app_locale_controller.dart';
import '../../data/data_sources/customer_orders_remote_data_source.dart';
import '../../data/repositories/customer_orders_repository_impl.dart';
import '../../domain/entities/customer_order.dart';
import '../../domain/repositories/customer_orders_repository.dart';
import '../../domain/use_cases/get_customer_orders.dart';

final customerOrdersRepositoryProvider = Provider<CustomerOrdersRepository>(
  (ref) => CustomerOrdersRepositoryImpl(
    CustomerOrdersRemoteDataSource(ref.watch(apiClientProvider)),
  ),
);
final getCustomerOrdersProvider = Provider(
  (ref) => GetCustomerOrders(ref.watch(customerOrdersRepositoryProvider)),
);
final getCustomerOrderProvider = Provider(
  (ref) => GetCustomerOrder(ref.watch(customerOrdersRepositoryProvider)),
);
final customerOrderProvider = FutureProvider.autoDispose
    .family<CustomerOrder, int>((ref, id) {
      ref.watch(appLocaleProvider);
      return ref.watch(getCustomerOrderProvider).call(id);
    }, retry: (_, _) => null);

class CustomerOrdersState {
  const CustomerOrdersState({
    required this.page,
    this.loadingMore = false,
    this.nextPageError,
  });
  final CustomerOrdersPage page;
  final bool loadingMore;
  final Object? nextPageError;
}

final customerOrdersProvider = AsyncNotifierProvider.autoDispose
    .family<CustomerOrdersController, CustomerOrdersState, CustomerOrderFilter>(
      CustomerOrdersController.new,
      retry: (_, _) => null,
    );

class CustomerOrdersController extends AsyncNotifier<CustomerOrdersState> {
  CustomerOrdersController(this.filter);
  final CustomerOrderFilter filter;
  int _generation = 0;
  @override
  Future<CustomerOrdersState> build() async {
    ref.watch(appLocaleProvider);
    ++_generation;
    ref.onDispose(() => ++_generation);
    return CustomerOrdersState(
      page: await ref.watch(getCustomerOrdersProvider).call(filter),
    );
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || current.loadingMore || !current.page.hasMore) return;
    final generation = _generation;
    final get = ref.read(getCustomerOrdersProvider);
    state = AsyncData(
      CustomerOrdersState(page: current.page, loadingMore: true),
    );
    try {
      final next = await get(filter, page: current.page.currentPage + 1);
      if (!ref.mounted || generation != _generation) return;
      final merged = {
        for (final order in current.page.orders) order.id: order,
        for (final order in next.orders) order.id: order,
      };
      state = AsyncData(
        CustomerOrdersState(
          page: CustomerOrdersPage(
            orders: List.unmodifiable(merged.values),
            currentPage: next.currentPage,
            lastPage: next.lastPage,
            total: next.total,
          ),
        ),
      );
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = AsyncData(
        CustomerOrdersState(page: current.page, nextPageError: error),
      );
    }
  }
}
