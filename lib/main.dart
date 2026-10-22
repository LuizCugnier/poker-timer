import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'dados/repositorio.dart';
import 'tema.dart';
import 'telas/relogio/tela_relogio.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await WakelockPlus.enable();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [repositorioProvider.overrideWithValue(Repositorio(prefs))],
      child: const AppRelogio(),
    ),
  );
}

class AppRelogio extends StatelessWidget {
  const AppRelogio({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Relógio de Poker',
      debugShowCheckedModeBanner: false,
      theme: Tema.tema,
      home: const TelaRelogio(),
    );
  }
}
