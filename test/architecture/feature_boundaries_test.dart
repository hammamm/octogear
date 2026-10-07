import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforce the API-feature boundaries without prescribing class/file counts.
void main() {
  final files = Directory('lib/features')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();
  final imports = RegExp(r'''(?:import|export)\s+['"]([^'"]+)['"]''');

  test('domain is independent of UI and feature data implementations', () {
    final violations = <String>[];
    for (final file in files) {
      if (!file.path.replaceAll('\\', '/').contains('/domain/')) continue;
      for (final match in imports.allMatches(file.readAsStringSync())) {
        final uri = match[1]!;
        if (uri.contains('/data/') ||
            uri.contains('/presentation/') ||
            uri.startsWith('package:flutter/') ||
            uri.contains('riverpod') ||
            uri.startsWith('package:dio/') ||
            uri.endsWith('/api_client.dart')) {
          violations.add('${file.path}: $uri');
        }
      }
    }
    expect(violations, isEmpty);
  });

  test('feature HTTP clients are restricted to remote data sources', () {
    final violations = <String>[];
    for (final file in files) {
      final path = file.path.replaceAll('\\', '/');
      for (final match in imports.allMatches(file.readAsStringSync())) {
        if (match[1]!.endsWith('/api_client.dart') &&
            !path.contains('/data/data_sources/')) {
          violations.add(path);
        }
      }
    }
    expect(violations, isEmpty);
  });

  test('repository contracts live in domain repositories', () {
    final violations = <String>[];
    for (final file in files) {
      final path = file.path.replaceAll('\\', '/');
      if (RegExp(
            r'abstract\s+(?:interface\s+)?class\s+\w*Repository\b',
          ).hasMatch(file.readAsStringSync()) &&
          !path.contains('/domain/repositories/')) {
        violations.add(path);
      }
    }
    expect(violations, isEmpty);
  });

  test('remote sources leave domain conversion to repositories and DTOs', () {
    final violations = files
        .where(
          (file) =>
              file.path.replaceAll('\\', '/').contains('/data/data_sources/') &&
              RegExp(r'\.toEntity\s*\(').hasMatch(file.readAsStringSync()),
        )
        .map((file) => file.path)
        .toList();
    expect(violations, isEmpty);
  });

  test('presentation queries and actions do not call repository providers', () {
    final violations = <String>[];
    final call = RegExp(
      r'ref\s*\.(?:read|watch)\(\w*RepositoryProvider\)\s*\.',
    );
    for (final file in files) {
      final path = file.path.replaceAll('\\', '/');
      if (!path.contains('/presentation/')) continue;
      final source = file.readAsStringSync();
      if (call.hasMatch(source)) violations.add(path);
      // A controller must not acquire a repository through a local alias either.
      final controller = RegExp(
        r'class \w+ extends (?:Async)?Notifier',
      ).firstMatch(source);
      if (controller != null &&
          RegExp(
            r'ref\s*\.(?:read|watch)\(\w*RepositoryProvider\)',
          ).hasMatch(source.substring(controller.start))) {
        violations.add(path);
      }
      if (path.contains('/screens/') || path.contains('/widgets/')) {
        for (final match in imports.allMatches(source)) {
          if (match[1]!.contains('/data/') ||
              match[1]!.contains('/domain/repositories/')) {
            violations.add('$path: ${match[1]}');
          }
        }
      }
    }
    expect(violations, isEmpty);
  });
}
