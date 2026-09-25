import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/firebase_options.dart';

void main() {
  test('Android Firebase configuration targets OctoGear', () {
    const expectedProjectId = 'octogear-1d72b';
    const expectedAppId = '1:22022700786:android:5861d760336ec2205c5a6b';

    expect(DefaultFirebaseOptions.android.projectId, expectedProjectId);
    expect(DefaultFirebaseOptions.android.appId, expectedAppId);
    expect(DefaultFirebaseOptions.android.messagingSenderId, '22022700786');
  });
}
