import 'dart:developer';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_volume/flutter_volume.dart';

void main() {
  test('flutter volume ...', () async {
    try {
      await FlutterVolumeController.setVolume(0.5);
      await FlutterVolumeController.setSystemUI();
      log('Sucess');
    } on Exception catch (_, __) {
      log(_.toString());
    }
  });
}
