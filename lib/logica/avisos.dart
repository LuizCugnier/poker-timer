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
// dos avisos com as antecedências configuradas. Um aviso só vale dentro do nível que
// está terminando (o de 10 minutos não toca antes de um intervalo de 5).
List<Aviso> avisosFuturos(
  Torneio torneio,
  DateTime agora,
  List<Duration> antecedencias,
) {
  if (!torneio.isRodando) return [];

  final niveis = torneio.estrutura.niveis;
  final decorrido = tempoDecorrido(torneio, agora);
  final avisos = <Aviso>[];

  void avisar(
    Duration momento,
    Duration duracaoQueTermina,
    String nome,
    String titulo,
    String texto,
  ) {
    final troca = agora.add(momento - decorrido);
    for (final antecedencia in antecedencias) {
      final quando = troca.subtract(antecedencia);
      if (antecedencia < duracaoQueTermina && quando.isAfter(agora)) {
        avisos.add((
          tipo: TipoAviso.aviso,
          quando: quando,
          titulo: '${_minutos(antecedencia)} para $nome',
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
        niveis[i - 1].duracao,
        nivel.isIntervalo ? 'o intervalo' : 'o nível $numero',
        nivel.isIntervalo ? 'INTERVALO' : 'NÍVEL $numero',
        _descrever(nivel),
      );
    }
    inicio += nivel.duracao;
  }
  avisar(
    inicio,
    niveis.last.duracao,
    'o fim da estrutura',
    'FIM DA ESTRUTURA',
    'O relógio para em 00:00 no último nível',
  );
  return avisos..sort((a, b) => a.quando.compareTo(b.quando));
}

String _minutos(Duration tempo) =>
    tempo.inMinutes == 1 ? '1 minuto' : '${tempo.inMinutes} minutos';

String _descrever(Nivel nivel) => nivel.isIntervalo
    ? '${nivel.duracao.inMinutes} minutos de pausa'
    : descreverBlinds(nivel);

// Som a tocar entre dois redesenhos seguidos do relógio rodando; null se nada mudou.
TipoAviso? somDaTransicao(
  EstadoRelogio antes,
  EstadoRelogio depois,
  List<Duration> antecedencias,
) {
  if (depois.indiceNivel != antes.indiceNivel ||
      depois.isTerminado && !antes.isTerminado) {
    return TipoAviso.troca;
  }
  final cruzouUmAviso = antecedencias.any(
    (antecedencia) =>
        antecedencia < depois.nivelAtual.duracao &&
        antes.tempoRestante > antecedencia &&
        depois.tempoRestante <= antecedencia,
  );
  return cruzouUmAviso ? TipoAviso.aviso : null;
}
