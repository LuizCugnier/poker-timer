import '../modelos/nivel.dart';
import '../modelos/torneio.dart';
import 'formatacao.dart';
import 'relogio_torneio.dart';

enum TipoAviso { troca, umMinuto }

typedef Aviso = ({
  TipoAviso tipo,
  DateTime quando,
  String titulo,
  String texto,
});

// Trocas de nível e o fim da estrutura que ainda vão acontecer, cada um com o aviso
// de 1 minuto antes.
List<Aviso> avisosFuturos(Torneio torneio, DateTime agora) {
  if (!torneio.isRodando) return [];

  final niveis = torneio.estrutura.niveis;
  final decorrido = tempoDecorrido(torneio, agora);
  final avisos = <Aviso>[];

  void avisar(Duration momento, String nome, String titulo, String texto) {
    final troca = agora.add(momento - decorrido);
    final umMinutoAntes = troca.subtract(const Duration(minutes: 1));
    if (umMinutoAntes.isAfter(agora)) {
      avisos.add((
        tipo: TipoAviso.umMinuto,
        quando: umMinutoAntes,
        titulo: '1 minuto para $nome',
        texto: texto,
      ));
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
        nivel.isIntervalo ? 'o intervalo' : 'o nível $numero',
        nivel.isIntervalo ? 'INTERVALO' : 'NÍVEL $numero',
        _descrever(nivel),
      );
    }
    inicio += nivel.duracao;
  }
  avisar(
    inicio,
    'o fim da estrutura',
    'FIM DA ESTRUTURA',
    'O relógio para em 00:00 no último nível',
  );
  return avisos;
}

String _descrever(Nivel nivel) => nivel.isIntervalo
    ? '${nivel.duracao.inMinutes} minutos de pausa'
    : descreverBlinds(nivel);

// Som a tocar entre dois redesenhos seguidos do relógio rodando; null se nada mudou.
TipoAviso? somDaTransicao(EstadoRelogio antes, EstadoRelogio depois) {
  if (depois.indiceNivel != antes.indiceNivel ||
      depois.isTerminado && !antes.isTerminado) {
    return TipoAviso.troca;
  }
  if (depois.isUltimoMinuto && !antes.isUltimoMinuto) {
    return TipoAviso.umMinuto;
  }
  return null;
}
