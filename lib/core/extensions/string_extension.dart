import 'dart:convert';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:sahala/core/extensions/date_format.dart';

/// String helpers ported from the iOS codebase's `String+Extension.swift`.
extension StringExtension on String {
  /// Decodes this string as base64-encoded image data.
  ///
  /// Swift's `getImageFromBase64` returned a `UIImage?`; Flutter has no
  /// equivalent eager image-decoding type on a String extension, so this
  /// returns the raw decoded bytes instead - pass them to `Image.memory`
  /// to render them (e.g. `Image.memory(text.imageBytesFromBase64!)`).
  Uint8List? get imageBytesFromBase64 {
    try {
      return base64Decode(this);
    } on FormatException {
      return null;
    }
  }

  /// Whether this string is a valid email address.
  bool get isValidEmail => RegExp(
    r'^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$',
  ).hasMatch(this);

  /// Validates this string as a Saudi mobile number and normalizes it to
  /// its 9-digit form (without a leading `0`).
  ///
  /// Accepts either the 9-digit form (`5XXXXXXXX`) or the 10-digit form
  /// with a leading `0` (`05XXXXXXXX`); the second digit must be anything
  /// but `2` (i.e. `50`, `51`, `53`-`59`), matching Saudi mobile prefixes.
  ///
  /// Mirrors Swift's `mutating func isValidMobile() -> Bool`, which
  /// validated `self` and, for the 10-digit form, mutated `self` in place
  /// by stripping the leading `0`. Dart strings are immutable, so instead
  /// of mutating the receiver this returns both the validity and the
  /// normalized number.
  ({bool isValid, String normalized}) get validatedSaudiMobile {
    final nineDigitPattern = RegExp(r'^5[013456789][0-9]{7}$');
    if (length == 9) {
      return (isValid: nineDigitPattern.hasMatch(this), normalized: this);
    }
    if (length == 10 && startsWith('0')) {
      final withoutLeadingZero = substring(1);
      final isValid = nineDigitPattern.hasMatch(withoutLeadingZero);
      return (
        isValid: isValid,
        normalized: isValid ? withoutLeadingZero : this,
      );
    }
    return (isValid: false, normalized: this);
  }

  /// Whether this string is a valid (Saudi) national/resident ID (exactly
  /// 10 digits).
  bool get isValidId => RegExp(r'^[0-9]{10}$').hasMatch(this);

  /// Parses this string as a date using [receivedFormat] and re-formats it
  /// using [targetFormat].
  ///
  /// Mirrors Swift's
  /// `getDate(targetFormate:receivedFormate:local:) -> String?`.
  ///
  /// - Parameters:
  ///   - targetFormat: the format the result should be in.
  ///   - receivedFormat: the format this string is currently in. Defaults
  ///     to [AppDateFormat.backendFormat] ("yyyy-MM-dd HH:mm:ss"), the
  ///     app's standard backend date format.
  ///   - locale: locale used to parse/format month & day names (e.g.
  ///     "en_US"/"ar_SA"). Defaults to `package:intl`'s
  ///     `Intl.defaultLocale`, which easy_localization keeps in sync with
  ///     the app's active language - pass an explicit locale to override.
  /// - Returns: the reformatted date string, or `null` if this string
  ///   doesn't match [receivedFormat].
  String? formattedDate({
    required AppDateFormat targetFormat,
    AppDateFormat receivedFormat = AppDateFormat.backendFormat,
    String? locale,
  }) {
    final effectiveLocale = locale ?? Intl.defaultLocale ?? 'en';
    try {
      final date = DateFormat(
        receivedFormat.pattern,
        effectiveLocale,
      ).parse(this);
      return DateFormat(targetFormat.pattern, effectiveLocale).format(date);
    } on FormatException {
      return null;
    }
  }

  /// Parses this string as a [DateTime] using [receivedFormat].
  ///
  /// Mirrors Swift's `getDate(receivedFormate:) -> Date?`. Named `toDate`
  /// rather than a second `getDate` overload since Dart doesn't support
  /// overloading by return type, matching the [toDouble]/[toDecimal]
  /// naming convention above.
  ///
  /// - Parameters:
  ///   - receivedFormat: the format this string is currently in. Defaults
  ///     to [AppDateFormat.backendFormat].
  ///   - locale: see [formattedDate].
  /// - Returns: the parsed date, or `null` if this string doesn't match
  ///   [receivedFormat].
  DateTime? toDate({
    AppDateFormat receivedFormat = AppDateFormat.backendFormat,
    String? locale,
  }) {
    final effectiveLocale = locale ?? Intl.defaultLocale ?? 'en';
    try {
      return DateFormat(receivedFormat.pattern, effectiveLocale).parse(this);
    } on FormatException {
      return null;
    }
  }

  /// Strips HTML tags and decodes common HTML entities, returning plain
  /// text. Intended for CMS content (privacy policy, terms & conditions,
  /// etc.) where only readable text is needed.
  ///
  /// This is a lightweight stripper, not a full HTML parser - it does not
  /// preserve formatting (bold, links, paragraphs, ...). If rich rendering
  /// is ever needed, use an HTML-rendering widget in the UI layer instead
  /// of extending this property; see the `htmlToAttributedString` note at
  /// the top of this file for why that isn't done here.
  ///
  /// Replaces Swift's `htmlToString` (via `htmlToAttributedString`).
  String get htmlToPlainText {
    final withoutTags = replaceAll(RegExp('<[^>]*>'), ' ');
    // `&amp;` is decoded last so an already-escaped entity like `&amp;lt;`
    // (literal text "&lt;") isn't double-unescaped into "<".
    final withoutEntities = withoutTags
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&');
    return withoutEntities.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
