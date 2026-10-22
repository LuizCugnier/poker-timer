import '../modelos/estrutura.dart';
import '../modelos/nivel.dart';
import '../modelos/torneio.dart';

class EstadoRelogio {
  const EstadoRelogio({
    required this.indiceNivel,
    required this.numeroNivel,
    required this.nivelAtual,
    required this.tempoRestante,
    required this.proximoNivel,
    required this.tempoAteProximoIntervalo,
    required this.isTerminado,
  });

  final int indiceNivel;

  // Número exibido na mesa: intervalos não contam ("NÍVEL 5" é o quinto nível de jogo).
  final int numeroNivel;
  final Nivel nivelAtual;
  final Duration tempoRestante;

  // null no último nível.
  final Nivel? proximoNivel;

  // Até o começo do próximo intervalo depois do nível atual; null se não houver.
  final Duration? tempoAteProximoIntervalo;

  // Passou do fim do último nível.
  final bool isTerminado;

  bool get isUltimoMinuto => tempoRestante <= const Duration(minutes: 1);
}

Duration tempoDecorrido(Torneio torneio, DateTime agora) {
  final desde = torneio.rodandoDesde;
  if (desde == null) return torneio.decorridoAcumulado;
  return torneio.decorridoAcumulado + agora.difference(desde);
}

// Vale de 0 até niveis.length (que dá a duração total da estrutura).
Duration inicioDoNivel(Estrutura estrutura, int indice) {
  return estrutura.niveis
      .take(indice)
      .fold(Duration.zero, (soma, nivel) => soma + nivel.duracao);
}

// ponytail: varredura linear dos níveis a cada redesenho; com ~20 níveis é irrelevante.
EstadoRelogio calcularEstado(Torneio torneio, DateTime agora) {
  final niveis = torneio.estrutura.niveis;
  final decorrido = tempoDecorrido(torneio, agora);

  var indice = 0;
  var inicio = Duration.zero;
  while (indice < niveis.length - 1 &&
      decorrido >= inicio + niveis[indice].duracao) {
    inicio += niveis[indice].duracao;
    indice++;
  }

  final fim = inicio + niveis[indice].duracao;
  final isTerminado = decorrido >= fim;

  Duration? tempoAteProximoIntervalo;
  if (!isTerminado) {
    var inicioSeguinte = fim;
    for (var i = indice + 1; i < niveis.length; i++) {
      if (niveis[i].isIntervalo) {
        tempoAteProximoIntervalo = inicioSeguinte - decorrido;
        break;
      }
      inicioSeguinte += niveis[i].duracao;
    }
  }

  return EstadoRelogio(
    indiceNivel: indice,
    numeroNivel: niveis.take(indice + 1).where((n) => !n.isIntervalo).length,
    nivelAtual: niveis[indice],
    tempoRestante: isTerminado ? Duration.zero : fim - decorrido,
    proximoNivel: indice + 1 < niveis.length ? niveis[indice + 1] : null,
    tempoAteProximoIntervalo: tempoAteProximoIntervalo,
    isTerminado: isTerminado,
  );
}

Torneio iniciar(Torneio torneio, DateTime agora) {
  if (torneio.isRodando) return torneio;
  return torneio.copyWith(rodandoDesde: agora);
}

Torneio pausar(Torneio torneio, DateTime agora) {
  if (!torneio.isRodando) return torneio;
  return Torneio(
    estrutura: torneio.estrutura,
    decorridoAcumulado: tempoDecorrido(torneio, agora),
  );
}

Torneio irParaNivel(Torneio torneio, int indice, DateTime agora) {
  return _comDecorrido(
    torneio,
    inicioDoNivel(torneio.estrutura, indice),
    agora,
  );
}

Torneio avancarNivel(Torneio torneio, DateTime agora) {
  final indice = calcularEstado(torneio, agora).indiceNivel;
  if (indice == torneio.estrutura.niveis.length - 1) return torneio;
  return irParaNivel(torneio, indice + 1, agora);
}

Torneio voltarNivel(Torneio torneio, DateTime agora) {
  final indice = calcularEstado(torneio, agora).indiceNivel;
  return irParaNivel(torneio, indice > 0 ? indice - 1 : 0, agora);
}

// delta positivo dá mais tempo ao nível (o decorrido diminui).
Torneio ajustarTempoRestante(Torneio torneio, Duration delta, DateTime agora) {
  return _comDecorrido(torneio, tempoDecorrido(torneio, agora) - delta, agora);
}

// Fixa o tempo de jogo em `decorrido` (mínimo zero) a partir de `agora`, mantendo rodando/pausado.
Torneio _comDecorrido(Torneio torneio, Duration decorrido, DateTime agora) {
  return Torneio(
    estrutura: torneio.estrutura,
    decorridoAcumulado: decorrido.isNegative ? Duration.zero : decorrido,
    rodandoDesde: torneio.isRodando ? agora : null,
  );
}
