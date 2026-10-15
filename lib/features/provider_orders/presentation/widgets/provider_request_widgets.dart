import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/api/api_failure.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/provider_general_request.dart';

String providerRequestFailure(BuildContext context, Object error) =>
    context.tr(switch (error) {
      ApiFailure(type: ApiFailureType.noConnection) => 'errors.no_connection',
      ApiFailure(type: ApiFailureType.timeout) => 'errors.timeout',
      ApiFailure(type: ApiFailureType.unauthorized) =>
        'provider_requests.unauthorized',
      ApiFailure(type: ApiFailureType.forbidden || ApiFailureType.notFound) =>
        'provider_requests.unavailable',
      ApiFailure(type: ApiFailureType.validation) =>
        'provider_requests.invalid_filter',
      ApiFailure(type: ApiFailureType.rateLimited) => 'errors.rate_limited',
      _ => 'provider_requests.load_error',
    });

String requestVehicle(ProviderGeneralRequest request) => [
  request.companyName,
  request.carName,
  request.year?.toString(),
].whereType<String>().join(' · ');

class ProviderRequestError extends StatelessWidget {
  const ProviderRequestError({
    required this.error,
    required this.onRetry,
    super.key,
  });
  final Object error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(providerRequestFailure(context, error), textAlign: TextAlign.center),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: Text(context.tr('common.retry')),
      ),
    ],
  );
}

class ProviderRequestCard extends StatelessWidget {
  const ProviderRequestCard({
    required this.request,
    required this.onTap,
    super.key,
  });
  final ProviderGeneralRequest request;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: OctoGearSurfaceCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr(
                  'provider_requests.request_number',
                  args: ['${request.id}'],
                ),
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              Text(
                request.partName ?? context.tr('provider_requests.unnamed'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                requestVehicle(request).isEmpty
                    ? context.tr('provider_requests.vehicle_unknown')
                    : requestVehicle(request),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      request.cityName ??
                          context.tr('provider_requests.city_unknown'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat.yMMMd(
                  context.locale.toLanguageTag(),
                ).format(request.createdAt.toLocal()),
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('provider_requests.view_details'),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
