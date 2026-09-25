// Fixture: NOT the allowlisted caller, so this import should be flagged by
// AvoidDirectStorageImports. shared_preferences isn't a dependency of this
// lint package - the rule only checks the import URI's literal text, not
// whether it resolves, so that's fine here. Deliberately outside test/ (as
// a sibling test_fixtures/ dir) so the rule's own "exempt files under
// /test/" logic doesn't accidentally exempt this fixture too.
import 'package:shared_preferences/shared_preferences.dart';
