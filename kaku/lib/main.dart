import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/network/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // Fallback to default if .env not found
  }
  await ApiClient.instance.initialize();

  // Set system UI overlay style for seamless obsidian dark immersion
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF090B10),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const KakuApp());
}
