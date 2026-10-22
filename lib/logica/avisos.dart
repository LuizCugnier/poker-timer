import '../modelos/nivel.dart';
import '../modelos/torneio.dart';
import 'formatacao.dart';
import 'relogio_torneio.dart';

enum TipoAviso { troca, aviso }

typedef Aviso = ({
  TipoAviso tipo,
  DateTime quando,
  String titulo,
  String texto,
});

// Trocas de nível e o fim da estrutura que ainda vão acontecer, cada um precedido
// dos avisos com as antecedências configuradas (ver _antecedenciasDo).
List<Aviso> avisosFuturos(
  Torneio torneio,
  DateTime agora,
  List<Duration> antecedencias, {
  bool isAvisoMetade = false,
}) {
  if (!torneio.isRodando) return [];

  final niveis = torneio.estrutura.niveis;
  final decorrido = tempoDecorrido(torneio, agora);
  final avisos = <Aviso>[];

  void avisar(
    Duration momento,
    Nivel queTermina,
    String nome,
    String titulo,
    String texto,
  ) {
    final troca = agora.add(momento - decorrido);
    for (final antecedencia in _antecedenciasDo(
      queTermina,
      antecedencias,
      isAvisoMetade,
    )) {
      final quando = troca.subtract(antecedencia);
      if (quando.isAfter(agora)) {
        avisos.add((
          tipo: TipoAviso.aviso,
          quando: quando,
          titulo: '${_antecedencia(antecedencia)} para $nome',
          texto: texto,
        ));
      }
    }
    if (troca.isAfter(agora)) {
      avisos.add((
        tipo: TipoAviso.troca,
        quando: troca,
        titulo: titulo,
        texto: texto,
      ));
    }
  }

  var inicio = Duration.zero;
  var numero = 0;
  for (final (i, nivel) in niveis.indexed) {
    if (!nivel.isIntervalo) numero++;
    if (i > 0) {
      avisar(
        inicio,
        niveis[i - 1],
        nivel.isIntervalo ? 'o intervalo' : 'o nível $numero',
        nivel.isIntervalo ? 'INTERVALO' : 'NÍVEL $numero',
        _descrever(nivel),
      );
    }
    inicio += nivel.duracao;
  }
  avisar(
    inicio,
    niveis.last,
    'o fim da estrutura',
    'FIM DA ESTRUTURA',
    'O relógio para em 00:00 no último nível',
  );
  return avisos..sort((a, b) => a.quando.compareTo(b.quando));
}

// Quando avisar antes do fim de `nivel`: as antecedências configuradas e, se ligada,
// a metade do nível (só nos de jogo). Cada uma só vale dentro do próprio nível (o
// aviso de 10 minutos não toca antes de um intervalo de 5), e repetidas (metade de
// 20 = 10 minutos) tocam uma vez só.
Set<Duration> _antecedenciasDo(
  Nivel nivel,
  List<Duration> antecedencias,
  bool isAvisoMetade,
) {
  return {
    ...antecedencias,
    if (isAvisoMetade && !nivel.isIntervalo) nivel.duracao ~/ 2,
  }.where((a) => a > Duration.zero && a < nivel.duracao).toSet();
}

// "5 minutos", "1 minuto" ou, na metade de um nível de 15, "07:30".
String _antecedencia(Duration tempo) {
  if (tempo.inSeconds % 60 != 0) return formatarTempo(tempo);
  return tempo.inMinutes == 1 ? '1 minuto' : '${tempo.inMinutes} minutos';
}

String _descrever(Nivel nivel) => nivel.isIntervalo
    ? '${nivel.duracao.inMinutes} minutos de pausa'
    : descreverBlinds(nivel);

// Som a tocar entre dois redesenhos seguidos do relógio rodando; null se nada mudou.
TipoAviso? somDaTransicao(
  EstadoRelogio antes,
  EstadoRelogio depois,
  List<Duration> antecedencias, {
  bool isAvisoMetade = false,
}) {
  if (depois.indiceNivel != antes.indiceNivel ||
      depois.isTerminado && !antes.isTerminado) {
    return TipoAviso.troca;
  }
  final cruzouUmAviso =
      _antecedenciasDo(depois.nivelAtual, antecedencias, isAvisoMetade).any(
        (antecedencia) =>
            antes.tempoRestante > antecedencia &&
            depois.tempoRestante <= antecedencia,
      );
  return cruzouUmAviso ? TipoAviso.aviso : null;
}
