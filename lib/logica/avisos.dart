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

// Trocas de nível (e o aviso 1 minuto antes de cada uma) que ainda vão acontecer.
List<Aviso> avisosFuturos(Torneio torneio, DateTime agora) {
  if (!torneio.isRodando) return [];

  final niveis = torneio.estrutura.niveis;
  final decorrido = tempoDecorrido(torneio, agora);
  final avisos = <Aviso>[];
  var inicio = Duration.zero;
  var numero = 0;

  for (var i = 0; i < niveis.length; i++) {
    final nivel = niveis[i];
    if (!nivel.isIntervalo) numero++;
    if (i > 0) {
      final troca = agora.add(inicio - decorrido);
      final umMinutoAntes = troca.subtract(const Duration(minutes: 1));
      final nome = nivel.isIntervalo ? 'o intervalo' : 'o nível $numero';
      if (umMinutoAntes.isAfter(agora)) {
        avisos.add((
          tipo: TipoAviso.umMinuto,
          quando: umMinutoAntes,
          titulo: '1 minuto para $nome',
          texto: _descrever(nivel),
        ));
      }
      if (troca.isAfter(agora)) {
        avisos.add((
          tipo: TipoAviso.troca,
          quando: troca,
          titulo: nivel.isIntervalo ? 'INTERVALO' : 'NÍVEL $numero',
          texto: _descrever(nivel),
        ));
      }
    }
    inicio += nivel.duracao;
  }
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
