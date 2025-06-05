import '../interactor/widgets_showroom_interactor.dart';
import 'package:flutter/material.dart';

class WidgetsShowroomPresenter {
  final WidgetsShowroomInteractor _interactor = WidgetsShowroomInteractor();

  void onLinkTap(BuildContext context, String url) {
    _interactor.openUrl(context, url);
  }
}
