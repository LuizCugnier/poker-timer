import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'dados/repositorio.dart';
import 'servicos/alarmes.dart';
import 'telas/configuracoes/configuracao_notifier.dart';
import 'telas/relogio/tela_relogio.dart';
import 'theme/tema_relogio.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await WakelockPlus.enable();
  final prefs = await SharedPreferences.getInstance();
  final alarmes = Alarmes(FlutterLocalNotificationsPlugin());
  await alarmes.inicializar();

  runApp(
    ProviderScope(
      overrides: [
        repositorioProvider.overrideWithValue(Repositorio(prefs)),
        alarmesProvider.overrideWithValue(alarmes),
      ],
      child: const AppRelogio(),
    ),
  );
}

class AppRelogio extends ConsumerWidget {
  const AppRelogio({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modo = ref.watch(configuracaoProvider.select((c) => c.modo));
    return MaterialApp(
      title: 'Relógio de Poker',
      debugShowCheckedModeBanner: false,
      theme: temaRelogio(modo),
      home: const TelaRelogio(),
    );
  }
}
