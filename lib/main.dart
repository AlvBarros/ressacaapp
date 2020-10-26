import 'dart:io';

import 'package:RessacaApp/app.dart';
import 'package:flutter/material.dart';

class HttpOverrideAcceptInvalidHttps extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext context) {
    HttpClient client = super.createHttpClient(context);
    client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return client;
  }
}

void main() {
  HttpOverrides.global = new HttpOverrideAcceptInvalidHttps();
  runApp(App());
}