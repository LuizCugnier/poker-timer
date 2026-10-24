import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../logica/avisos.dart';
import '../modelos/torneio.dart';

// Sobrescrito no main (já inicializado) e nos testes.
final alarmesProvider = Provider<Alarmes>(
  (ref) => throw UnimplementedError('alarmesProvider precisa de override'),
);

const _detalhesTroca = NotificationDetails(
  android: AndroidNotificationDetails(
    'troca_nivel',
    'Troca de nível',
    channelDescription: 'Toca quando começa um novo nível ou intervalo',
    importance: Importance.max,
    priority: Priority.high,
    category: AndroidNotificationCategory.alarm,
    audioAttributesUsage: AudioAttributesUsage.alarm,
    sound: RawResourceAndroidNotificationSound('troca'),
  ),
);

const _detalhesAviso = NotificationDetails(
  android: AndroidNotificationDetails(
    'aviso_antes',
    'Aviso antes da troca',
    channelDescription:
        'Toca antes de cada troca de nível, na antecedência configurada',
    importance: Importance.max,
    priority: Priority.high,
    category: AndroidNotificationCategory.alarm,
    audioAttributesUsage: AudioAttributesUsage.alarm,
    sound: RawResourceAndroidNotificationSound('aviso'),
  ),
);

// As notificações só ficam agendadas com o app fora da tela; com ele aberto,
// quem toca é Sons (sem banner cobrindo o relógio nem som duplicado).
class Alarmes {
  Alarmes(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<void> inicializar() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notificacao'),
      ),
    );
  }

  Future<bool> temPermissoes() async {
    final notificacoes = await _android?.areNotificationsEnabled() ?? false;
    final exatos = await _android?.canScheduleExactNotifications() ?? false;
    return notificacoes && exatos;
  }

  Future<void> pedirPermissoes() async {
    await _android?.requestNotificationsPermission();
    if (!(await _android?.canScheduleExactNotifications() ?? true)) {
      // Abre a tela do sistema "Alarmes e lembretes".
      await _android?.requestExactAlarmsPermission();
    }
  }

  Future<void> agendar(
    Torneio torneio,
    DateTime agora,
    List<Duration> antecedencias, {
    bool isAvisoMetade = false,
  }) async {
    await cancelar();
    final exato = await _android?.canScheduleExactNotifications() ?? false;
    final modo = exato
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    for (final (id, aviso) in avisosFuturos(
      torneio,
      agora,
      antecedencias,
      isAvisoMetade: isAvisoMetade,
    ).indexed) {
      // zonedSchedule recusa horários no passado; o agendamento leva alguns ms.
      if (!aviso.quando.isAfter(DateTime.now())) continue;
      await _plugin.zonedSchedule(
        id: id,
        // Instante absoluto: em UTC não é preciso carregar a base de fusos.
        scheduledDate: tz.TZDateTime.from(aviso.quando, tz.UTC),
        notificationDetails: aviso.tipo == TipoAviso.troca
            ? _detalhesTroca
            : _detalhesAviso,
        androidScheduleMode: modo,
        title: aviso.titulo,
        body: aviso.texto,
      );
    }
  }

  Future<void> cancelar() => _plugin.cancelAll();
}
