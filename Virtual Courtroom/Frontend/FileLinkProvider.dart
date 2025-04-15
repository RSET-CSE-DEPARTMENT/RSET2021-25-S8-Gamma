import 'package:flutter/material.dart';

class FileLinkProvider extends ChangeNotifier {
  String? _fileLink;

  String? get fileLink => _fileLink;

  void setFileLink(String link) {
    _fileLink = link;
    notifyListeners(); // Notify listeners to update UI
  }
}
