import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../controllers/chat_providers.dart';
import '../widgets/chat_connection_status.dart';

class CustomerChatsScreen extends ConsumerStatefulWidget {
  const CustomerChatsScreen({super.key, this.provider = false});
  final bool provider;
  @override
  ConsumerState<CustomerChatsScreen> createState() =>
      _CustomerChatsScreenState();
}

class _CustomerChatsScreenState extends ConsumerState<CustomerChatsScreen> {
  bool _loadingMore = false;
  Object? _pageError;

  Future<void> _open(int id) async {
    if (widget.provider) {
      await ProviderConversationRoute(conversationId: id).push<void>(context);
    } else {
      await CustomerConversationRoute(conversationId: id).push<void>(context);
    }
    if (mounted) ref.invalidate(chatInboxProvider);
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(chatInboxProvider);
    final body = RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(chatInboxProvider);
        try {
          await ref.read(chatInboxProvider.future);
        } catch (_) {
          /* Rendered by the provider error state. */
        }
      },
      child: ListView(
        key: const PageStorageKey('customer-tab-chats'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('customer_chats.tab'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const AppLanguageToggleButton(compact: true),
            ],
          ),
          const SizedBox(height: 20),
          const ChatConnectionStatus(),
          ...data.when(
            loading: () => [const Center(child: CircularProgressIndicator())],
            error: (_, _) => [
              Text(context.tr('chat.load_error')),
              TextButton(
                onPressed: () => ref.invalidate(chatInboxProvider),
                child: Text(context.tr('common.retry')),
              ),
            ],
            data: (inbox) => [
              if (inbox.chats.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.forum_outlined,
                        size: 48,
                        color: OctoGearColors.structuralGray,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('chat.inbox_empty'),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              for (final chat in inbox.chats)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: const CircleAvatar(
                      backgroundColor: OctoGearColors.yellowSoft,
                      child: Icon(
                        Icons.storefront_outlined,
                        color: OctoGearColors.navy,
                      ),
                    ),
                    title: Text(
                      (widget.provider
                          ? chat.name
                          : chat.storeName ?? chat.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (chat.orderId != null)
                          Text(
                            context.tr(
                              'chat.request',
                              args: ['${chat.orderId}'],
                            ),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        Text(
                          chat.latestText ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (chat.updatedAt != null)
                          Text(
                            DateFormat.MMMd(
                              context.locale.languageCode,
                            ).add_jm().format(chat.updatedAt!.toLocal()),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                      ],
                    ),
                    trailing: chat.unread > 0
                        ? Badge(
                            label: Text('${chat.unread}'),
                            backgroundColor: OctoGearColors.navy,
                          )
                        : null,
                    onTap: () => unawaited(_open(chat.id)),
                  ),
                ),
              if (_pageError != null) Text(context.tr('chat.load_error')),
              if (inbox.page < inbox.lastPage)
                TextButton(
                  onPressed: _loadingMore
                      ? null
                      : () async {
                          setState(() {
                            _loadingMore = true;
                            _pageError = null;
                          });
                          try {
                            await ref
                                .read(chatInboxProvider.notifier)
                                .loadMore();
                          } catch (error) {
                            if (mounted) setState(() => _pageError = error);
                          } finally {
                            if (mounted) setState(() => _loadingMore = false);
                          }
                        },
                  child: Text(
                    context.tr(_loadingMore ? 'chat.loading' : 'chat.more'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
    return widget.provider
        ? Scaffold(
            appBar: AppBar(),
            body: SafeArea(child: body),
          )
        : body;
  }
}
