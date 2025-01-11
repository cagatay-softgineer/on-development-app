import 'package:flutter/material.dart';
import 'widgets/custom_button.dart'; // Ensure the correct path
import 'styles/button_styles.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome'),
        automaticallyImplyLeading: false, // Removes the back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Adds padding around the content
        child: Center(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // Centers horizontally
          children: [
            SizedBox(height: 40), // Adds space from the top
            // Welcome Message
            Text(
              'Welcome to the App!',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20), // Adds vertical spacing
            // CustomButton to Navigate to Button Customizer
            CustomButton(
              text: "Navigate To\nButton Customizer",
              onPressed: () {
                Navigator.pushNamed(context, '/button_customizer');
              },
              buttonParams: navigateButtonParams,
            ),
            SizedBox(height: 20), // Adds vertical spacing
            // CustomButton for Logout
            CustomButton(
              text: "Logout",
              onPressed: () {
                // Implement your logout logic here
                // For example, navigate back to the login page
                Navigator.pushNamedAndRemoveUntil(
                    context, '/', (Route<dynamic> route) => false);
              },
              buttonParams: logoutButtonParams,
            ),
            SizedBox(height: 20), // Adds vertical spacing
            // CustomButton for Logout
            CustomButton(
              text: "Linked Apps",
              onPressed: () {
                // Implement your logout logic here
                // For example, navigate back to the login page
                Navigator.pushNamed(
                    context, '/applinks');
              },
              buttonParams: mainButtonParams,
            ),
            SizedBox(height: 20), // Adds vertical spacing
            // CustomButton for Logout
            CustomButton(
              text: "Playlists",
              onPressed: () {
                // Implement your logout logic here
                // For example, navigate back to the login page
                Navigator.pushNamed(
                    context, '/playlists');
              },
              buttonParams: mainButtonParams,
            ),
            // Add more widgets or buttons as needed
          ],
        ),
        ),
      ),
    );
  }
}
