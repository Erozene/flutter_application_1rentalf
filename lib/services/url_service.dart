// ignore_for_file: unused_import

import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter  
import 'url_service_web.dart' if (dart.library.io) 'url_service_mobile.dart';

Future<void> openUrl(String url) => launchUrlPlatform(url);
