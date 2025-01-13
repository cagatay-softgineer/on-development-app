import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:ssdk_rsrc/main.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _initializeAppLinks();
  }

  Future<void> _initializeAppLinks() async {
    _appLinks = AppLinks();

    // Handle the link when the app starts
    final Uri? initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      _processLink(initialLink);
    }

    // Listen for new links
    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _processLink(uri);
      }
    });
  }

  void _processLink(Uri uri) {
    print('Received URI: $uri');
    if (uri.path.startsWith('/open')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => StartPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Deep Link Example")),
        body: Center(
          child: Text("Waiting for a link..."),
        ),
      ),
    );
  }
}
