import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logica/avisos.dart';
import '../../logica/formatacao.dart';
import '../../logica/relogio_torneio.dart';
import '../../modelos/ficha.dart';
import '../estrutura/tela_estrutura.dart';
import '../fichas/fichas_notifier.dart';
import '../fichas/tela_fichas.dart';
import '../../modelos/torneio.dart';
import '../../servicos/alarmes.dart';
import '../../servicos/sons.dart';
import '../../tema.dart';
import '../componentes.dart';
import 'torneio_notifier.dart';

class TelaRelogio extends ConsumerStatefulWidget {
  const TelaRelogio({super.key});

  @override
  ConsumerState<TelaRelogio> createState() => _TelaRelogioState();
}

class _TelaRelogioState extends ConsumerState<TelaRelogio> {
  // Só redesenha; o tempo vem sempre de calcularEstado(torneio, agora).
  late final Timer _redesenho;
  late final AppLifecycleListener _ciclo;

  // Para tocar o som só quando o nível muda sozinho, não por um toque nos controles.
  Torneio? _torneioAnterior;
  EstadoRelogio? _estadoAnterior;

  @override
  void initState() {
    super.initState();
    final alarmes = ref.read(alarmesProvider);
    alarmes.cancelar();
    _ciclo = AppLifecycleListener(
      onHide: () => alarmes.agendar(ref.read(torneioProvider), DateTime.now()),
      onShow: alarmes.cancelar,
    );
    _redesenho = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _aoRedesenhar(),
    );
  }

  @override
  void dispose() {
    _redesenho.cancel();
    _ciclo.dispose();
    super.dispose();
  }

  void _aoRedesenhar() {
    final torneio = ref.read(torneioProvider);
    final estado = calcularEstado(torneio, DateTime.now());
    final antes = _estadoAnterior;
    if (antes != null && identical(torneio, _torneioAnterior)) {
      final som = somDaTransicao(antes, estado);
      if (som != null) ref.read(sonsProvider).tocar(som);
    }
    _torneioAnterior = torneio;
    _estadoAnterior = estado;
    setState(() {});
  }

  void _abrir(Widget tela) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => tela));
  }

  Future<void> _confirmar(String pergunta, VoidCallback acao) async {
    if (await perguntar(context, pergunta)) acao();
  }

  Future<void> _iniciarOuPausar() async {
    final torneio = ref.read(torneioProvider);
    final isComeco =
        !torneio.isRodando && torneio.decorridoAcumulado == Duration.zero;
    ref.read(torneioProvider.notifier).iniciarOuPausar();

    final alarmes = ref.read(alarmesProvider);
    if (!isComeco || await alarmes.temPermissoes() || !mounted) return;
    final permitir = await perguntar(
      context,
      'Para tocar o alarme da troca de nível com a tela apagada ou com o app '
      'em segundo plano, o Relógio de Poker precisa enviar notificações e '
      'agendar alarmes exatos.\n\n'
      'Na próxima tela, permita as notificações. Se abrir "Alarmes e '
      'lembretes", ative a opção e volte para o app.',
      confirmar: 'Permitir',
      cancelar: 'Agora não',
    );
    if (permitir) await alarmes.pedirPermissoes();
  }

  @override
  Widget build(BuildContext context) {
    final torneio = ref.watch(torneioProvider);
    final notifier = ref.read(torneioProvider.notifier);
    final fichas = ref.watch(fichasProvider);
    final estado = calcularEstado(torneio, DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 16, 32, 8),
                child: Column(
                  children: [
                    _Cabecalho(estado: estado),
                    Expanded(
                      child: _Tempo(
                        estado: estado,
                        isRodando: torneio.isRodando,
                      ),
                    ),
                    _Blinds(estado: estado),
                    const SizedBox(height: 8),
                    _Proximo(estado: estado),
                    const SizedBox(height: 8),
                    _Controles(
                      isRodando: torneio.isRodando,
                      aoIniciarOuPausar: _iniciarOuPausar,
                      aoVoltar: () => _confirmar(
                        'Voltar para o nível anterior?',
                        notifier.voltarNivel,
                      ),
                      aoAvancar: () => _confirmar(
                        'Avançar para o próximo nível?',
                        notifier.avancarNivel,
                      ),
                      aoAjustar: notifier.ajustarTempoRestante,
                      aoReiniciar: () => _confirmar(
                        'Reiniciar o torneio? O relógio volta ao início do '
                        'nível 1, com a estrutura salva.',
                        notifier.reiniciar,
                      ),
                      aoEditarEstrutura: () => _abrir(const TelaEstrutura()),
                      aoEditarFichas: () => _abrir(const TelaFichas()),
                    ),
                  ],
                ),
              ),
            ),
            if (fichas.isNotEmpty) _Fichas(fichas: fichas),
          ],
        ),
      ),
    );
  }
}

Widget _texto(
  String texto,
  double tamanho,
  Color cor, {
  FontWeight peso = FontWeight.w500,
}) {
  return FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(
      texto,
      style: TextStyle(
        fontSize: tamanho,
        color: cor,
        fontWeight: peso,
        fontFeatures: Tema.algarismosFixos,
      ),
    ),
  );
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.estado});

  final EstadoRelogio estado;

  @override
  Widget build(BuildContext context) {
    final ateIntervalo = estado.tempoAteProximoIntervalo;
    return Row(
      children: [
        if (!estado.nivelAtual.isIntervalo)
          _texto(
            'NÍVEL ${estado.numeroNivel}',
            Tema.tamanhoNivel,
            Tema.textoSecundario,
            peso: FontWeight.w700,
          ),
        const Spacer(),
        if (ateIntervalo != null)
          _texto(
            'Intervalo em ${formatarTempo(ateIntervalo)}',
            Tema.tamanhoIntervalo,
            Tema.textoSecundario,
          ),
      ],
    );
  }
}

class _Tempo extends StatelessWidget {
  const _Tempo({required this.estado, required this.isRodando});

  final EstadoRelogio estado;
  final bool isRodando;

  @override
  Widget build(BuildContext context) {
    final cor = !isRodando
        ? Tema.pausado
        : estado.isUltimoMinuto
        ? Tema.ultimoMinuto
        : Tema.texto;
    return FittedBox(
      child: Text(
        formatarTempo(estado.tempoRestante),
        style: TextStyle(
          fontSize: 400,
          height: 1,
          color: cor,
          fontWeight: FontWeight.w700,
          fontFeatures: Tema.algarismosFixos,
        ),
      ),
    );
  }
}

class _Blinds extends StatelessWidget {
  const _Blinds({required this.estado});

  final EstadoRelogio estado;

  @override
  Widget build(BuildContext context) {
    final nivel = estado.nivelAtual;
    if (nivel.isIntervalo) {
      return _texto(
        'INTERVALO',
        Tema.tamanhoBlinds,
        Tema.intervalo,
        peso: FontWeight.w700,
      );
    }
    return Column(
      children: [
        _texto(
          formatarBlinds(nivel.smallBlind, nivel.bigBlind),
          Tema.tamanhoBlinds,
          Tema.texto,
          peso: FontWeight.w700,
        ),
        if (nivel.ante > 0)
          _texto(
            'ANTE ${formatarValor(nivel.ante)}',
            Tema.tamanhoAnte,
            Tema.texto,
          ),
      ],
    );
  }
}

class _Proximo extends StatelessWidget {
  const _Proximo({required this.estado});

  final EstadoRelogio estado;

  @override
  Widget build(BuildContext context) {
    final proximo = estado.proximoNivel;
    final String texto;
    if (estado.isTerminado) {
      texto = 'Fim da estrutura';
    } else if (proximo == null) {
      texto = 'Último nível';
    } else if (proximo.isIntervalo) {
      texto = 'Próximo: intervalo';
    } else {
      texto = 'Próximo: ${descreverBlinds(proximo)}';
    }
    return _texto(texto, Tema.tamanhoProximo, Tema.textoSecundario);
  }
}

class _Controles extends StatelessWidget {
  const _Controles({
    required this.isRodando,
    required this.aoIniciarOuPausar,
    required this.aoVoltar,
    required this.aoAvancar,
    required this.aoAjustar,
    required this.aoReiniciar,
    required this.aoEditarEstrutura,
    required this.aoEditarFichas,
  });

  final bool isRodando;
  final VoidCallback aoIniciarOuPausar;
  final VoidCallback aoVoltar;
  final VoidCallback aoAvancar;
  final void Function(Duration delta) aoAjustar;
  final VoidCallback aoReiniciar;
  final VoidCallback aoEditarEstrutura;
  final VoidCallback aoEditarFichas;

  @override
  Widget build(BuildContext context) {
    Widget botao(IconData icone, String dica, VoidCallback aoTocar) {
      return IconButton(
        icon: Icon(icone),
        tooltip: dica,
        iconSize: Tema.tamanhoIcone,
        color: Tema.controles,
        onPressed: aoTocar,
      );
    }

    Widget ajuste(String rotulo, Duration delta) {
      return TextButton(
        onPressed: () => aoAjustar(delta),
        style: TextButton.styleFrom(foregroundColor: Tema.controles),
        child: Text(rotulo, style: const TextStyle(fontSize: 26)),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        botao(
          Icons.format_list_numbered,
          'Estrutura de blinds',
          aoEditarEstrutura,
        ),
        botao(Icons.toll, 'Fichas', aoEditarFichas),
        botao(Icons.restart_alt, 'Reiniciar torneio', aoReiniciar),
        const SizedBox(width: 32),
        botao(Icons.skip_previous, 'Nível anterior', aoVoltar),
        ajuste('−1 min', const Duration(minutes: -1)),
        IconButton(
          icon: Icon(isRodando ? Icons.pause_circle : Icons.play_circle),
          tooltip: isRodando ? 'Pausar' : 'Iniciar',
          iconSize: Tema.tamanhoIconePrincipal,
          color: Tema.texto,
          onPressed: aoIniciarOuPausar,
        ),
        ajuste('+1 min', const Duration(minutes: 1)),
        botao(Icons.skip_next, 'Próximo nível', aoAvancar),
      ],
    );
  }
}

class _Fichas extends StatelessWidget {
  const _Fichas({required this.fichas});

  final List<Ficha> fichas;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Tema.larguraLateral,
      color: Tema.fundoLateral,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final ficha in fichas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  BolinhaFicha(cor: ficha.cor),
                  const SizedBox(width: 16),
                  Flexible(
                    child: _texto(
                      formatarValor(ficha.valor),
                      Tema.tamanhoFicha,
                      Tema.texto,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
