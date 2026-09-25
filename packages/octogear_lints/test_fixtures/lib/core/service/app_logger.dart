// Fixture: its path ends in lib/core/service/app_logger.dart, matching the
// AvoidDebugPrint rule's allowlisted caller, so its debugPrint() call
// should NOT be flagged.
void debugPrint(String message) {}

void useIt() {
  debugPrint('should not be flagged');
}
