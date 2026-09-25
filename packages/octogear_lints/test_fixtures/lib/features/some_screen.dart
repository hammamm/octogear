// Fixture: NOT the allowlisted caller, so its debugPrint() call should be
// flagged by AvoidDebugPrint. A locally-declared `debugPrint` stands in for
// Flutter's real one so this fixture doesn't need a Flutter dependency -
// the rule only looks at the call's method name, not where it resolves to.
void debugPrint(String message) {}

void useIt() {
  debugPrint('should be flagged');
}
