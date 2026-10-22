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
