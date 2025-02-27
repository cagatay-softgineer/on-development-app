import '/models/button_params.dart'; // Ensure the correct path

Map<String, dynamic> mainButton = {
  "backgroundColor": "Color(0xFF0000FF)", // Blue
  "textColor": "Color(0xFFFFFFFF)",       // White
  "borderRadius": 20.0,
  "padding": "EdgeInsets(12.0, 24.0, 12.0, 24.0)",
  "textStyle": "TextStyle(fontSize: 22.0, color: Color(0xFFFFFFFF))",
  "elevation": 20.0,
  "buttonWidth": 300.0,
  "buttonHeight": 100.0,
  "borderColor": "Color(0x00000000)",      // Transparent
  "letterSpacing": 8.0,
  "blurAmount": 5.0,
  "useGradient": true,
  "gradientStartColor": "Color(0xFF00AAAA)", // Blue
  "gradientEndColor": "Color(0x66FF00FF)",   // Purple
  "leadingIcon": "",
  "trailingIcon": "Icons.arrow_forward_ios",
  "textAlign": "TextAlign.center",
  "isEnabled": true,
  "shape": "BoxShape.rectangle",
  "hoverColor": "Color(0xFF1E88E5)",
  "focusColor": "Color(0xFF42A5F5)",
  "shadowColor": "Color(0x66000000)",
  "shadowOffset": "Offset(2.0, 2.0)",
  "isLoading": false,
  "fontFamily": "Roboto",
  "backgroundAlpha": 0.9,
  "iconSize" : 36,
};

Map<String, dynamic> playlistButton = {
  "backgroundColor": "Color(0xFF0000FF)", // Blue
  "textColor": "Color(0xFFFFFFFF)",       // White
  "borderRadius": 20.0,
  "padding": "EdgeInsets(12.0, 24.0, 12.0, 24.0)",
  "textStyle": "TextStyle(fontSize: 22.0, color: Color(0xFFFFFFFF))",
  "elevation": 20.0,
  "buttonWidth": 300.0,
  "buttonHeight": 100.0,
  "borderColor": "Color(0x00000000)",      // Transparent
  "letterSpacing": 8.0,
  "blurAmount": 5.0,
  "useGradient": true,
  "gradientStartColor": "Color(0xFFad5389)", // Blue
  "gradientEndColor": "Color(0xFF3c1053)",   // Purple
  "leadingIcon": "",
  "trailingIcon": "Icons.arrow_forward_ios",
  "textAlign": "TextAlign.center",
  "isEnabled": true,
  "shape": "BoxShape.rectangle",
  "hoverColor": "Color(0xFF1E88E5)",
  "focusColor": "Color(0xFF42A5F5)",
  "shadowColor": "Color(0x66000000)",
  "shadowOffset": "Offset(2.0, 2.0)",
  "isLoading": false,
  "fontFamily": "Roboto",
  "backgroundAlpha": 0.9,
  "iconSize" : 36,
};

Map<String, dynamic> linkedApps = {
  "backgroundColor": "Color(0xFF0000FF)", // Blue
  "textColor": "Color(0xFFFFFFFF)",       // White
  "borderRadius": 20.0,
  "padding": "EdgeInsets(12.0, 24.0, 12.0, 24.0)",
  "textStyle": "TextStyle(fontSize: 22.0, color: Color(0xFFFFFFFF))",
  "elevation": 20.0,
  "buttonWidth": 300.0,
  "buttonHeight": 100.0,
  "borderColor": "Color(0x00000000)",      // Transparent
  "letterSpacing": 8.0,
  "blurAmount": 5.0,
  "useGradient": true,
  "gradientStartColor": "Color(0xFF948E99)",
  "gradientEndColor": "Color(0xFF2E1437)",
  "leadingIcon": "",
  "trailingIcon": "Icons.arrow_forward_ios",
  "textAlign": "TextAlign.center",
  "isEnabled": true,
  "shape": "BoxShape.rectangle",
  "hoverColor": "Color(0xFF1E88E5)",
  "focusColor": "Color(0xFF42A5F5)",
  "shadowColor": "Color(0x66000000)",
  "shadowOffset": "Offset(2.0, 2.0)",
  "isLoading": false,
  "fontFamily": "Roboto",
  "backgroundAlpha": 0.9,
  "iconSize" : 36,
};

Map<String, dynamic> navigateButton = {
  "backgroundColor": "Color(0xFF0000FF)", // Blue
  "textColor": "Color(0xFFFFFFFF)",       // White
  "borderRadius": 12.0,
  "padding": "EdgeInsets(0.0, 0.0, 0.0, 0.0)",
  "textStyle": "TextStyle(fontSize: 18.0, color: Color(0xFFFFFFFF))",
  "elevation": 6.0,
  "buttonWidth": 300.0,
  "buttonHeight": 100.0,
  "borderColor": "Color(0x00000000)",      // Transparent
  "letterSpacing": 8.0,
  "blurAmount": 10.0,
  "useGradient": true,
  "gradientStartColor": "Color(0xFF0000FF)", // Blue
  "gradientEndColor": "Color(0xFFFF00FF)",   // Purple
  "leadingIcon": "",
  "trailingIcon": "Icons.arrow_forward",
  "textAlign": "TextAlign.center",
  "isEnabled": true,
  "shape": "BoxShape.rectangle",
  "hoverColor": "Color(0xFF1E88E5)",
  "focusColor": "Color(0xFF42A5F5)",
  "shadowColor": "Color(0x66000000)",
  "shadowOffset": "Offset(4.0, 4.0)",
  "isLoading": false,
  "fontFamily": "Roboto",
  "backgroundAlpha": 0.9,
  "iconSize" : 36, 
};

Map<String, dynamic> logoutButton = {
  "backgroundColor": "Color(0xFFFF0000)", // Red
  "textColor": "Color(0xFFFFFFFF)",       // White
  "borderRadius": 12.0,
  "padding": "EdgeInsets(0.0, 0.0, 0.0, 0.0)",
  "textStyle": "TextStyle(fontSize: 18.0, color: Color(0xFFFFFFFF))",
  "elevation": 6.0,
  "buttonWidth": 300.0,
  "buttonHeight": 60.0,
  "borderColor": "Color(0x00000000)",      // Transparent
  "letterSpacing": 8.0,
  "blurAmount": 10.0,
  "useGradient": false,                    // No gradient for Logout button
  "gradientStartColor": "Color(0xFF0000FF)", // Ignored as useGradient is false
  "gradientEndColor": "Color(0xFFFF00FF)",   // Ignored as useGradient is false
  "leadingIcon": "",
  "trailingIcon": "Icons.logout",                    // No trailing icon
  "textAlign": "TextAlign.center",
  "isEnabled": true,
  "shape": "BoxShape.rectangle",
  "hoverColor": "Color(0xFF1E88E5)",
  "focusColor": "Color(0xFF42A5F5)",
  "shadowColor": "Color(0x66000000)",
  "shadowOffset": "Offset(4.0, 4.0)",
  "isLoading": false,
  "fontFamily": "Roboto",
  "backgroundAlpha": 0.9,
  "iconSize" : 24,
};

Map<String, dynamic> spotify = {
  "backgroundColor": "Color(0xFF1ED760)", // Spotify Green
  "textColor": "Color(0xFFFFFFFF)",       // White
  "borderRadius": 12.0,
  "padding": "EdgeInsets(0.0, 0.0, 0.0, 0.0)",
  "textStyle": "TextStyle(fontSize: 22.0, color: Color(0xFFFFFFFF))",
  "elevation": 6.0,
  "buttonWidth": 300.0,
  "buttonHeight": 60.0,
  "borderColor": "Color(0x00000000)",      // Transparent
  "letterSpacing": 8.0,
  "blurAmount": 10.0,
  "useGradient": false,                    // No gradient for Logout button
  "gradientStartColor": "Color(0xFF0000FF)", // Ignored as useGradient is false
  "gradientEndColor": "Color(0xFFFF00FF)",   // Ignored as useGradient is false
  "leadingIcon": "Icons.headset",
  "trailingIcon": "Icons.link",                    // No trailing icon
  "textAlign": "TextAlign.center",
  "isEnabled": true,
  "shape": "BoxShape.rectangle",
  "hoverColor": "Color(0xFF1E88E5)",
  "focusColor": "Color(0xFF42A5F5)",
  "shadowColor": "Color(0x66121212)",
  "shadowOffset": "Offset(0.0, 4.0)",
  "isLoading": false,
  "fontFamily": "Roboto",
  "backgroundAlpha": 0.9,
  "iconSize" : 24,
};

Map<String, dynamic> spotifyPlay = {
  "backgroundColor": "Color(0xFF1ED760)", // Spotify Green
  "textColor": "Color(0xFFFFFFFF)",       // White
  "borderRadius": 100.0,
  "padding": "EdgeInsets(0.0, 0.0, 0.0, 0.0)",
  "textStyle": "TextStyle(fontSize: 24.0, color: Color(0xFFFFFFFF))",
  "elevation": 6.0,
  "buttonWidth": 100.0,
  "buttonHeight": 60.0,
  "borderColor": "Color(0x00000000)",      // Transparent
  "letterSpacing": 0.0,
  "blurAmount": 10.0,
  "useGradient": false,                    // No gradient for Logout button
  "gradientStartColor": "Color(0xFF0000FF)", // Ignored as useGradient is false
  "gradientEndColor": "Color(0xFFFF00FF)",   // Ignored as useGradient is false
  "leadingIcon": "Icons.play_circle_outline",
  "trailingIcon": "",                    // No trailing icon
  "textAlign": "TextAlign.center",
  "isEnabled": true,
  "shape": "BoxShape.circle",
  "hoverColor": "Color(0xFF1E88E5)",
  "focusColor": "Color(0xFF42A5F5)",
  "shadowColor": "Color(0x66121212)",
  "shadowOffset": "Offset(0.0, 4.0)",
  "isLoading": false,
  "fontFamily": "Roboto",
  "backgroundAlpha": 0.9,
  "iconSize" : 36,
};

Map<String, dynamic> appleMusic = {
  "backgroundColor": "Color(0xFFD71E1E)", // Spotify Green
  "textColor": "Color(0xFFFFFFFF)",       // White
  "borderRadius": 12.0,
  "padding": "EdgeInsets(0.0, 0.0, 0.0, 0.0)",
  "textStyle": "TextStyle(fontSize: 22.0, color: Color(0xFFFFFFFF))",
  "elevation": 6.0,
  "buttonWidth": 300.0,
  "buttonHeight": 60.0,
  "borderColor": "Color(0x00000000)",      // Transparent
  "letterSpacing": 8.0,
  "blurAmount": 10.0,
  "useGradient": true,                    // No gradient for Logout button
  "gradientStartColor": "Color(0xFFFF4E6B)", // Ignored as useGradient is false
  "gradientEndColor": "Color(0xFFFF0436)",   // Ignored as useGradient is false
  "leadingIcon": "Icons.apple",
  "trailingIcon": "Icons.link",                    // No trailing icon
  "textAlign": "TextAlign.center",
  "isEnabled": true,
  "shape": "BoxShape.rectangle",
  "hoverColor": "Color(0xFF1E88E5)",
  "focusColor": "Color(0xFF42A5F5)",
  "shadowColor": "Color(0x66121212)",
  "shadowOffset": "Offset(0.0, 4.0)",
  "isLoading": false,
  "fontFamily": "Roboto",
  "backgroundAlpha": 0.9,
  "iconSize" : 36,
};

Map<String, dynamic> youtubeMusic = {
  "backgroundColor": "Color(0xFFFF0000)", // Spotify Green
  "textColor": "Color(0xFFFFFFFF)",       // White
  "borderRadius": 12.0,
  "padding": "EdgeInsets(0.0, 0.0, 0.0, 0.0)",
  "textStyle": "TextStyle(fontSize: 22.0, color: Color(0xFFFFFFFF))",
  "elevation": 6.0,
  "buttonWidth": 300.0,
  "buttonHeight": 60.0,
  "borderColor": "Color(0x00000000)",      // Transparent
  "letterSpacing": 8.0,
  "blurAmount": 10.0,
  "useGradient": true,                    // No gradient for Logout button
  "gradientStartColor": "Color(0xFFe52d27)", // Ignored as useGradient is false
  "gradientEndColor": "Color(0xFFb31217)",   // Ignored as useGradient is false
  "leadingIcon": "Icons.smart_display_rounded",
  "trailingIcon": "Icons.link",                    // No trailing icon
  "textAlign": "TextAlign.center",
  "isEnabled": true,
  "shape": "BoxShape.rectangle",
  "hoverColor": "Color(0xFF1E88E5)",
  "focusColor": "Color(0xFF42A5F5)",
  "shadowColor": "Color(0x66121212)",
  "shadowOffset": "Offset(0.0, 4.0)",
  "isLoading": false,
  "fontFamily": "Roboto",
  "backgroundAlpha": 0.9,
  "iconSize" : 36,
};

Map<String, dynamic> player = {
  "backgroundColor": "Color(0xFFFF0000)", // Spotify Green
  "textColor": "Color(0xFFFFFFFF)",       // White
  "borderRadius": 12.0,
  "padding": "EdgeInsets(0.0, 0.0, 0.0, 0.0)",
  "textStyle": "TextStyle(fontSize: 22.0, color: Color(0xFFFFFFFF))",
  "elevation": 6.0,
  "buttonWidth": 300.0,
  "buttonHeight": 60.0,
  "borderColor": "Color(0x00000000)",      // Transparent
  "letterSpacing": 8.0,
  "blurAmount": 10.0,
  "useGradient": true,                    // No gradient for Logout button
  "gradientStartColor": "Color(0xFFC33764)", // Ignored as useGradient is false
  "gradientEndColor": "Color(0xFF1D2671)",   // Ignored as useGradient is false
  "leadingIcon": "",
  "trailingIcon": "Icons.play_circle_outline",                    // No trailing icon
  "textAlign": "TextAlign.center",
  "isEnabled": true,
  "shape": "BoxShape.rectangle",
  "hoverColor": "Color(0xFF1E88E5)",
  "focusColor": "Color(0xFF42A5F5)",
  "shadowColor": "Color(0x66121212)",
  "shadowOffset": "Offset(0.0, 4.0)",
  "isLoading": false,
  "fontFamily": "Roboto",
  "backgroundAlpha": 0.9,
  "iconSize" : 36,
};

Map<String, dynamic> playerPlay = {
  "backgroundColor": "Color(0xFFFF0000)", // Spotify Green
  "textColor": "Color(0xFFFFFFFF)",       // White
  "borderRadius": 12.0,
  "padding": "EdgeInsets(0.0, 0.0, 0.0, 0.0)",
  "textStyle": "TextStyle(fontSize: 22.0, color: Color(0xFFFFFFFF))",
  "elevation": 6.0,
  "buttonWidth": 300.0,
  "buttonHeight": 60.0,
  "borderColor": "Color(0x00000000)",      // Transparent
  "letterSpacing": 8.0,
  "blurAmount": 10.0,
  "useGradient": true,                    // No gradient for Logout button
  "gradientStartColor": "Color(0xAA551155)", // Ignored as useGradient is false
  "gradientEndColor": "Color(0xAAFF1111)",   // Ignored as useGradient is false
  "leadingIcon": "",
  "trailingIcon": "Icons.play_arrow",                    // No trailing icon
  "textAlign": "TextAlign.center",
  "isEnabled": true,
  "shape": "BoxShape.rectangle",
  "hoverColor": "Color(0xFF1E88E5)",
  "focusColor": "Color(0xFF42A5F5)",
  "shadowColor": "Color(0x66121212)",
  "shadowOffset": "Offset(0.0, 4.0)",
  "isLoading": false,
  "fontFamily": "Roboto",
  "backgroundAlpha": 0.9,
  "iconSize" : 36,
};

Map<String, dynamic> playerPause = {
  "backgroundColor": "Color(0xFFFF0000)", // Spotify Green
  "textColor": "Color(0xFFFFFFFF)",       // White
  "borderRadius": 12.0,
  "padding": "EdgeInsets(0.0, 0.0, 0.0, 0.0)",
  "textStyle": "TextStyle(fontSize: 22.0, color: Color(0xFFFFFFFF))",
  "elevation": 6.0,
  "buttonWidth": 300.0,
  "buttonHeight": 60.0,
  "borderColor": "Color(0x00000000)",      // Transparent
  "letterSpacing": 8.0,
  "blurAmount": 10.0,
  "useGradient": true,                    // No gradient for Logout button
  "gradientStartColor": "Color(0xAAFF55FF)", // Ignored as useGradient is false
  "gradientEndColor": "Color(0xAAFFFF55)",   // Ignored as useGradient is false
  "leadingIcon": "",
  "trailingIcon": "Icons.pause",                    // No trailing icon
  "textAlign": "TextAlign.center",
  "isEnabled": true,
  "shape": "BoxShape.rectangle",
  "hoverColor": "Color(0xFF1E88E5)",
  "focusColor": "Color(0xFF42A5F5)",
  "shadowColor": "Color(0x66121212)",
  "shadowOffset": "Offset(0.0, 4.0)",
  "isLoading": false,
  "fontFamily": "Roboto",
  "backgroundAlpha": 0.9,
  "iconSize" : 36,
};

Map<String, dynamic> timerButton = {
  "backgroundColor": "Color(0xFFFF0000)", // Spotify Green
  "textColor": "Color(0xFFFFFFFF)",       // White
  "borderRadius": 12.0,
  "padding": "EdgeInsets(0.0, 0.0, 0.0, 0.0)",
  "textStyle": "TextStyle(fontSize: 22.0, color: Color(0xFFFFFFFF))",
  "elevation": 6.0,
  "buttonWidth": 300.0,
  "buttonHeight": 60.0,
  "borderColor": "Color(0x00000000)",      // Transparent
  "letterSpacing": 8.0,
  "blurAmount": 10.0,
  "useGradient": true,                    // No gradient for Logout button
  "gradientStartColor": "Color(0xAA551155)", // Ignored as useGradient is false
  "gradientEndColor": "Color(0xAAFF1111)",   // Ignored as useGradient is false
  "leadingIcon": "",
  "trailingIcon": "Icons.timer_outlined",                    // No trailing icon
  "textAlign": "TextAlign.center",
  "isEnabled": true,
  "shape": "BoxShape.rectangle",
  "hoverColor": "Color(0xFF1E88E5)",
  "focusColor": "Color(0xFF42A5F5)",
  "shadowColor": "Color(0x66121212)",
  "shadowOffset": "Offset(0.0, 4.0)",
  "isLoading": false,
  "fontFamily": "Roboto",
  "backgroundAlpha": 0.9,
  "iconSize" : 36,
};

Map<String, dynamic> changeLayout = {
  "backgroundColor": "Color(0xFFFF0000)", // Spotify Green
  "textColor": "Color(0xFFFFFFFF)",       // White
  "borderRadius": 12.0,
  "padding": "EdgeInsets(0.0, 0.0, 0.0, 0.0)",
  "textStyle": "TextStyle(fontSize: 22.0, color: Color(0xFFFFFFFF))",
  "elevation": 6.0,
  "buttonWidth": 300.0,
  "buttonHeight": 60.0,
  "borderColor": "Color(0x00000000)",      // Transparent
  "letterSpacing": 8.0,
  "blurAmount": 10.0,
  "useGradient": true,                    // No gradient for Logout button
  "gradientStartColor": "Color(0xFF654ea3)", // Ignored as useGradient is false
  "gradientEndColor": "Color(0xFFeaafc8)",   // Ignored as useGradient is false
  "leadingIcon": "",
  "trailingIcon": "Icons.change_circle_outlined",                    // No trailing icon
  "textAlign": "TextAlign.center",
  "isEnabled": true,
  "shape": "BoxShape.rectangle",
  "hoverColor": "Color(0xFF1E88E5)",
  "focusColor": "Color(0xFF42A5F5)",
  "shadowColor": "Color(0x66121212)",
  "shadowOffset": "Offset(0.0, 4.0)",
  "isLoading": false,
  "fontFamily": "Roboto",
  "backgroundAlpha": 0.9,
  "iconSize" : 36,
};

Map<String, dynamic> startSession = {
  "backgroundColor": "Color(0xFFFF0000)", // Spotify Green
  "textColor": "Color(0xFFFFFFFF)",       // White
  "borderRadius": 12.0,
  "padding": "EdgeInsets(0.0, 0.0, 0.0, 0.0)",
  "textStyle": "TextStyle(fontSize: 22.0, color: Color(0xFFFFFFFF))",
  "elevation": 6.0,
  "buttonWidth": 300.0,
  "buttonHeight": 60.0,
  "borderColor": "Color(0x00000000)",      // Transparent
  "letterSpacing": 8.0,
  "blurAmount": 10.0,
  "useGradient": true,                    // No gradient for Logout button
  "gradientStartColor": "Color(0xFF11998e)", // Ignored as useGradient is false
  "gradientEndColor": "Color(0xFF38ef7d)",   // Ignored as useGradient is false
  "leadingIcon": "",
  "trailingIcon": "Icons.start_outlined",                    // No trailing icon
  "textAlign": "TextAlign.center",
  "isEnabled": true,
  "shape": "BoxShape.rectangle",
  "hoverColor": "Color(0xFF1E88E5)",
  "focusColor": "Color(0xFF42A5F5)",
  "shadowColor": "Color(0x66121212)",
  "shadowOffset": "Offset(0.0, 4.0)",
  "isLoading": false,
  "fontFamily": "Roboto",
  "backgroundAlpha": 0.9,
  "iconSize" : 36,
};

Map<String, dynamic> stopSession = {
  "backgroundColor": "Color(0xFFFF0000)", // Spotify Green
  "textColor": "Color(0xFFFFFFFF)",       // White
  "borderRadius": 12.0,
  "padding": "EdgeInsets(0.0, 0.0, 0.0, 0.0)",
  "textStyle": "TextStyle(fontSize: 22.0, color: Color(0xFFFFFFFF))",
  "elevation": 6.0,
  "buttonWidth": 300.0,
  "buttonHeight": 60.0,
  "borderColor": "Color(0x00000000)",      // Transparent
  "letterSpacing": 8.0,
  "blurAmount": 10.0,
  "useGradient": true,                    // No gradient for Logout button
  "gradientStartColor": "Color(0xFF333333)", // Ignored as useGradient is false
  "gradientEndColor": "Color(0xFFdd1818)",   // Ignored as useGradient is false
  "leadingIcon": "",
  "trailingIcon": "Icons.start_outlined",                    // No trailing icon
  "textAlign": "TextAlign.center",
  "isEnabled": true,
  "shape": "BoxShape.rectangle",
  "hoverColor": "Color(0xFF1E88E5)",
  "focusColor": "Color(0xFF42A5F5)",
  "shadowColor": "Color(0x66121212)",
  "shadowOffset": "Offset(0.0, 4.0)",
  "isLoading": false,
  "fontFamily": "Roboto",
  "backgroundAlpha": 0.9,
  "iconSize" : 36,
};


ButtonParams mainButtonParams = ButtonParams.fromMap(mainButton);
ButtonParams navigateButtonParams = ButtonParams.fromMap(navigateButton);
ButtonParams logoutButtonParams = ButtonParams.fromMap(logoutButton);
ButtonParams spotifyButtonParams = ButtonParams.fromMap(spotify);
ButtonParams linkedAppsButtonParams = ButtonParams.fromMap(linkedApps);
ButtonParams playlistButtonParams = ButtonParams.fromMap(playlistButton);
ButtonParams spotifyPlayButtonParams = ButtonParams.fromMap(spotifyPlay);
ButtonParams appleMusicButtonParams = ButtonParams.fromMap(appleMusic);
ButtonParams youtubeMusicButtonParams = ButtonParams.fromMap(youtubeMusic);
ButtonParams playerButtonParams = ButtonParams.fromMap(player);
ButtonParams playerPlayButtonParams = ButtonParams.fromMap(playerPlay);
ButtonParams playerPauseButtonParams = ButtonParams.fromMap(playerPause);
ButtonParams timerButtonParams = ButtonParams.fromMap(timerButton);
ButtonParams changeLayoutButtonParams = ButtonParams.fromMap(changeLayout);
ButtonParams startSessionButtonParams = ButtonParams.fromMap(startSession);
ButtonParams stopSessionButtonParams = ButtonParams.fromMap(stopSession);