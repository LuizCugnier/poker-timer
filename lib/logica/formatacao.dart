import '../modelos/nivel.dart';

// 1000 -> "1.000"
String formatarValor(int valor) => valor.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => '.',
);

// Arredonda os segundos para cima, como todo cronômetro regressivo:
// mostra 20:00 no início do nível e só chega a 00:00 quando o tempo acaba.
String formatarTempo(Duration tempo) {
  final segundos = (tempo.inMilliseconds + 999) ~/ 1000;
  final h = segundos ~/ 3600;
  final mm = (segundos ~/ 60 % 60).toString().padLeft(2, '0');
  final ss = (segundos % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
}

String formatarBlinds(int smallBlind, int bigBlind) =>
    '${formatarValor(smallBlind)} / ${formatarValor(bigBlind)}';

// "500 / 1.000 · ante 100", ou só os blinds quando não há ante.
String descreverBlinds(Nivel nivel) {
  final blinds = formatarBlinds(nivel.smallBlind, nivel.bigBlind);
  return nivel.ante > 0
      ? '$blinds · ante ${formatarValor(nivel.ante)}'
      : blinds;
}
