// This is a basic Flutter widget test.
import 'package:flutter_test/flutter_test.dart';
import 'package:chatapp/login.dart';

void main() {
  testWidgets('Tests for login & main screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(new MyApp());
    
    //Unit test
    final loginScreen = LoginScreenState();
    
    //Verify that some attributes are found
    expect(loginScreen.isLoading, false);
    expect(loginScreen.isLoggedIn, false);
    
    //Widget test
    final titleFinder = find.text("Chat application");
    
    //Verify that a widget is found.
    expect(titleFinder, findsOneWidget);

  });
}

