import '/models/button_params.dart'; // Ensure the correct path

Map<String, dynamic> main_button = {
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
  "iconSize" : 12,
};

Map<String, dynamic> navigate_button = {
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

Map<String, dynamic> logout_button = {
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
  "leadingIcon": "Icons.logout",
  "trailingIcon": "",                    // No trailing icon
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

Map<String, dynamic> Spotify = {
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

Map<String, dynamic> SpotifyPlay = {
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


Map<String, dynamic> AppleMusic = {
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
  "iconSize" : 24,
};

Map<String, dynamic> YoutubeMusic = {
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
  "useGradient": false,                    // No gradient for Logout button
  "gradientStartColor": "Color(0xFF0000FF)", // Ignored as useGradient is false
  "gradientEndColor": "Color(0xFFFF00FF)",   // Ignored as useGradient is false
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
  "iconSize" : 24,
};

Map<String, dynamic> Player = {
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
  "gradientEndColor": "Color(0xAA55FF55)",   // Ignored as useGradient is false
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
  "iconSize" : 24,
};

Map<String, dynamic> PlayerPlay = {
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

Map<String, dynamic> PlayerPause = {
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


ButtonParams mainButtonParams = ButtonParams.fromMap(main_button);
ButtonParams navigateButtonParams = ButtonParams.fromMap(navigate_button);
ButtonParams logoutButtonParams = ButtonParams.fromMap(logout_button);
ButtonParams spotifyButtonParams = ButtonParams.fromMap(Spotify);
ButtonParams spotifyPlayButtonParams = ButtonParams.fromMap(SpotifyPlay);
ButtonParams appleMusicButtonParams = ButtonParams.fromMap(AppleMusic);
ButtonParams youtubeMusicButtonParams = ButtonParams.fromMap(YoutubeMusic);
ButtonParams playerButtonParams = ButtonParams.fromMap(Player);
ButtonParams playerPlayButtonParams = ButtonParams.fromMap(PlayerPlay);
ButtonParams playerPauseButtonParams = ButtonParams.fromMap(PlayerPause);