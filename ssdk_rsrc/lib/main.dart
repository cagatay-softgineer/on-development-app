import 'package:flutter/material.dart';
import 'button_customizer_app.dart';
import 'widgets/custom_button.dart'; // Import the CustomButton widget
import 'styles/button_styles.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'home_page.dart';
import 'app_links.dart';
import 'playlist_page.dart';

void main() {
  runApp(const MyApp());
  
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Button Customizer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Define the initial route for your app
      initialRoute: '/',

      // Define named routes in a map
      routes: {
        '/': (context) => const StartPage(),                // Home (default route)
        '/button_customizer': (context) => ButtonCustomizerApp(), 
        '/login_page': (context) => LoginPage(), 
        '/main': (context) => HomePage(), 
        '/applinks': (context) => AppLinks(), 
        '/register_page': (context) => RegisterPage(), 
        '/playlists': (context) => PlaylistPage(), 
      },
    );
  }
}



// A simple HomePage that navigates to the /button_customizer route
class StartPage extends StatelessWidget {
  const StartPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Page')),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter, // Aligns the button to the top center
            child: Padding(
              padding: const EdgeInsets.only(top: 50.0), // Adjust top padding as needed
              child: CustomButton(
                text: "Button Customizer", // Corrected typo
                onPressed: () {
                  Navigator.pushNamed(context, '/button_customizer');
                },
                buttonParams: mainButtonParams,
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter, // Aligns the button to the top center
            child: Padding(
              padding: const EdgeInsets.only(top: 50.0+150.0), // Adjust top padding as needed
              child: CustomButton(
                text: "Login Page", // Corrected typo
                onPressed: () {
                  Navigator.pushNamed(context, '/login_page');
                },
                buttonParams: mainButtonParams,
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter, // Aligns the button to the top center
            child: Padding(
              padding: const EdgeInsets.only(top: 50.0+300.0), // Adjust top padding as needed
              child: CustomButton(
                text: "Register Page", // Corrected typo
                onPressed: () {
                  Navigator.pushNamed(context, '/register_page');
                },
                buttonParams: mainButtonParams,
              ),
            ),
          ),
          // Add other widgets here if needed
        ],
      ),
    );
  }
}
