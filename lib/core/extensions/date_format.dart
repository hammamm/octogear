/// Date/time pattern presets used across the app, ported from the Swift
/// `DateFormat` enum (see `lib/core/extensions/string_extension.dart` for
/// the extension that consumes these).
///
/// Named `AppDateFormat` (not `DateFormat`) to avoid colliding with
/// `package:intl`'s own `DateFormat` class, which each [pattern] is fed
/// into for actual parsing/formatting.
///
/// You can add as many formats as you want. If you're not familiar with a
/// format pattern, see http://nsdateformatter.com or
/// https://pub.dev/documentation/intl/latest/intl/DateFormat-class.html.
enum AppDateFormat {
  /// 23/10/2019 at 12:32 am
  ddMmYyyyWithTime("dd/MM/yyyy 'at' h:mm a"),

  /// 12:32 am
  timeFormat("h:mm a"),

  /// 2019-09-15 11:26:22
  requestDateFormat("dd-MM-yyyy hh:mm:ss.SSSSS"),

  /// "yyyy-MM-dd'T'HH:mm:Ss.SSSZ" (time zone date).
  dateWithTimeZone("yyyy-MM-dd'T'HH:mm:Ss.SSSZ"),

  /// , e.g. "Jan 2024".
  mmmYyy("MMM yyy"),

  /// "yyyy-MM-dd HH:mm:ss" - the app's standard backend date format.
  /// example: 2023-09-15 12:30:00
  backendFormat("yyyy-MM-dd HH:mm:ss"),

  /// "15/09/2023"
  dateFormat("dd/MM/yyyy"),

  /// "EEEE", e.g. "Monday".
  dayName("EEEE"),

  /// "ccc", e.g. "Mon".
  shortDayName("ccc"),

  /// "dd"
  /// example: 04 for 4th of the month
  dayNumber("dd"),

  /// "MMMM"
  /// example: November
  monthName("MMMM"),

  /// "dd MMMM"
  /// example: 04 November
  dayNumberAndMonthName("dd MMMM"),

  /// 4 Nov 2021
  dayWithNameMonth("d MMM yyyy"),

  /// time slot format "hh:mm:ss"
  /// example: 12:30:00
  timeSlot("hh:mm:ss");

  const AppDateFormat(this.pattern);

  /// The ICU/CLDR date pattern passed to `package:intl`'s `DateFormat`.
  final String pattern;
}
