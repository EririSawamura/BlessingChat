// Imports the Flutter Driver API
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('Chatapp', () {

    FlutterDriver driver;
    final MainPageFinder = find.byValueKey('MainPage');

    // Connect to the Flutter driver before running any tests
    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    test('starts at 0', () async {
      // Use the `driver.getText` method to verify the title of main page
      // is 'Chat application'.
      expect(await driver.getText(MainPageFinder), "Chat application");
    });

    // Close the connection to the driver after the tests have completed
    tearDownAll(() async {
      if (driver != null) {
        driver.close();
      }
    });
  });
}