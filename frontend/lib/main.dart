import 'package:flutter/material.dart';

import 'app.dart';
import 'services/bootstrap_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appController = await BootstrapService().createController();
  runApp(AiPlacematApp(controller: appController));
}
