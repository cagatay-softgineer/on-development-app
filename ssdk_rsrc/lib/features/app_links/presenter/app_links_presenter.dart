import 'package:ssdk_rsrc/models/linked_app.dart';
import 'package:ssdk_rsrc/providers/appsSession.dart';
import 'package:ssdk_rsrc/providers/userSession.dart';
import 'package:ssdk_rsrc/utils/authlib.dart';
import '../../constants/default/apps.dart';
import '../../constants/default/user.dart';
import '../interactor/app_links_interactor.dart';

class AppLinksPresenter {
  final AppLinksInteractor _interactor = AppLinksInteractor();

  List<LinkedApp> get linkedApps => AppsSession.linkedApps;

  bool isLoading = false;

  Future<void> initializeLinkedApps() async {
    final String? userEmail = await AuthService.getUserId();
    if (userEmail == null) {
      return;
    }
    AppsSession.userEmail = userEmail;
    isLoading = true;

    final response = await _interactor.fetchBindings(userEmail);
    if (response.containsKey('apps')) {
      final Map<String, dynamic> appsBindingMap = {};
      for (var app in response['apps']) {
        if (app is Map<String, dynamic> && app.containsKey('app_name')) {
          appsBindingMap[app['app_name']] = app;
        }
      }

      for (var app in AppsSession.linkedApps) {
        if (appsBindingMap.containsKey(app.name)) {
          final appData = appsBindingMap[app.name];
          app.isLinked = appData['user_linked'] ?? false;

          if (app.isLinked &&
              appData['user_profile'] != null &&
              appData['user_profile'] is Map) {
            final profile = appData['user_profile'];
            if (app.name == "Spotify") {
              app.userDisplayName = profile['display_name'] ?? 'No Display Name';
              if (profile['images'] != null &&
                  profile['images'] is List &&
                  profile['images'].isNotEmpty) {
                app.userPic = profile['images'][0]['url'] ??
                    UserSession.userPIC ??
                    UserConstants.defaultAvatarUrl;
              } else {
                app.userPic =
                    UserSession.userPIC ?? UserConstants.defaultAvatarUrl;
              }
            } else if (app.name == "YoutubeMusic") {
              app.userDisplayName = profile['name'] ?? 'No Display Name';
              app.userPic = profile['picture'] ??
                  UserSession.userPIC ??
                  UserConstants.defaultAvatarUrl;
            } else {
              app.userDisplayName = profile['name'] ?? 'No Display Name';
              app.userPic = profile['picture'] ??
                  UserSession.userPIC ??
                  UserConstants.defaultAvatarUrl;
            }
          } else {
            app.userDisplayName = 'User Not Linked';
            app.userPic = UserSession.userPIC ?? UserConstants.defaultAvatarUrl;
          }
        }
      }
    }
    isLoading = false;
  }
}
