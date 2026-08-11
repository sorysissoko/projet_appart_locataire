import 'package:flutter/material.dart';

class ConnexionModel {
  TextEditingController? emailAddressTextController;
  TextEditingController? passwordTextController;
  FocusNode? emailAddressFocusNode;
  FocusNode? passwordFocusNode;
  bool passwordVisibility = false;
  // Validators (si nécessaire)
  String? Function(String?)? emailAddressTextControllerValidator;
  String? Function(String?)? passwordTextControllerValidator;

  void dispose() {
    emailAddressTextController?.dispose();
    passwordTextController?.dispose();
    emailAddressFocusNode?.dispose();
    passwordFocusNode?.dispose();
  }
}

// Pour imiter la fonction de FlutterFlow createModel
ConnexionModel createModel(BuildContext context, ConnexionModel Function() modelBuilder) {
  return modelBuilder();
}
