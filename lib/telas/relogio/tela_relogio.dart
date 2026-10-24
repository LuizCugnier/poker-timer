import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logica/avisos.dart';
import '../../logica/formatacao.dart';
import '../../logica/relogio_torneio.dart';
import '../../modelos/nivel.dart';
import '../../modelos/torneio.dart';
import '../../servicos/alarmes.dart';
import '../../servicos/sons.dart';
import '../../theme/tema_relogio.dart';
import '../componentes.dart';
import '../configuracoes/configuracao_notifier.dart';
import '../configuracoes/tela_configuracoes.dart';
import '../fichas/fichas_notifier.dart';
import 'estado_relogio_provider.dart';
import 'torneio_notifier.dart';

// Tela da mesa (ESPECIFICACAO, seções 2 e 3). Cada parte observa só o pedaço do
// estado que mostra, para a tela não reconstruir inteira a cada 250 ms.
class TelaRelogio extends ConsumerStatefulWidget {
  const TelaRelogio({super.key});

  @override
  ConsumerState<TelaRelogio> createState() => _TelaRelogioState();
}

class _TelaRelogioState extends ConsumerState<TelaRelogio> {
  // Vigia de som separado do redesenho: o Riverpod pausa os listeners de telas
  // encobertas (Configurações aberta), e o som precisa tocar mesmo assim.
  late final Timer _vigiaSom;
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
      onHide: () {
        final configuracao = ref.read(configuracaoProvider);
        alarmes.agendar(
          ref.read(torneioProvider),
          DateTime.now(),
          configuracao.antecedencias,
          isAvisoMetade: configuracao.isAvisoMetade,
        );
      },
      onShow: () {
        alarmes.cancelar();
        // O que mudou enquanto o app estava fora já foi avisado pela notificação.
        _estadoAnterior = null;
      },
    );
    _vigiaSom = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _verificarSom(),
    );
  }

  @override
  void dispose() {
    _vigiaSom.cancel();
    _ciclo.dispose();
    super.dispose();
  }

  void _verificarSom() {
    final torneio = ref.read(torneioProvider);
    final estado = calcularEstado(torneio, DateTime.now());
    final antes = _estadoAnterior;
    // Fora da tela quem avisa é a notificação; o Timer pode seguir rodando até o
    // Android congelar o processo, e tocaria o som em dobro.
    final isNaTela = !const {
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.detached,
    }.contains(WidgetsBinding.instance.lifecycleState);
    if (isNaTela && antes != null && identical(torneio, _torneioAnterior)) {
      final configuracao = ref.read(configuracaoProvider);
      final som = somDaTransicao(
        antes,
        estado,
        configuracao.antecedencias,
        isAvisoMetade: configuracao.isAvisoMetade,
      );
      if (som != null) ref.read(sonsProvider).tocar(som);
    }
    _torneioAnterior = torneio;
    _estadoAnterior = estado;
  }

  Future<void> _iniciarOuPausar() async {
    final torneio = ref.read(torneioProvider);
    final isComeco =
        !torneio.isRodando && torneio.decorridoAcumulado == Duration.zero;
    // No começo, o diálogo de permissões vem antes do relógio correr e do som.
    if (isComeco) await _pedirPermissoesSeFaltarem();
    if (!mounted) return;
    ref.read(torneioProvider.notifier).iniciarOuPausar();
    if (isComeco) ref.read(sonsProvider).tocar(TipoAviso.troca);
  }

  Future<void> _pedirPermissoesSeFaltarem() async {
    final alarmes = ref.read(alarmesProvider);
    if (await alarmes.temPermissoes() || !mounted) return;
    final permitir = await confirmar(
      context,
      icone: Icons.notifications_active_outlined,
      titulo: 'Permitir alarmes?',
      texto:
          'Para tocar o alarme da troca de nível com a tela apagada ou com o '
          'app em segundo plano, o Poker Timer precisa enviar notificações '
          'e agendar alarmes exatos.\n\n'
          'Na próxima tela, permita as notificações. Se abrir "Alarmes e '
          'lembretes", ative a opção e volte para o app.',
      botaoConfirmar: 'Permitir',
      botaoCancelar: 'Agora não',
    );
    if (permitir) await alarmes.pedirPermissoes();
  }

  Future<void> _avancar() async {
    final estado = ref.read(estadoRelogioProvider);
    final proximo = estado.proximoNivel;
    if (proximo == null) return;
    final atual = estado.nivelAtual.isIntervalo
        ? 'O intervalo'
        : 'O nível ${estado.numeroNivel}';
    final numero = estado.numeroNivel + (proximo.isIntervalo ? 0 : 1);
    if (await confirmar(
      context,
      icone: Icons.skip_next_outlined,
      titulo: 'Pular para o próximo nível?',
      texto:
          '$atual termina agora e o relógio começa '
          '${_destino(proximo, numero)}.',
    )) {
      ref.read(torneioProvider.notifier).avancarNivel();
    }
  }

  Future<void> _voltar() async {
    final torneio = ref.read(torneioProvider);
    final indice = ref.read(estadoRelogioProvider).indiceNivel;
    final niveis = torneio.estrutura.niveis;
    final alvo = indice > 0 ? indice - 1 : 0;
    final numero = niveis.take(alvo + 1).where((n) => !n.isIntervalo).length;
    final texto = alvo == indice
        ? 'O relógio volta ao começo do nível 1, com o tempo cheio.'
        : 'O relógio volta para ${_destino(niveis[alvo], numero)}, '
              'com o tempo cheio.';
    if (await confirmar(
      context,
      icone: Icons.skip_previous_outlined,
      titulo: 'Voltar para o nível anterior?',
      texto: texto,
    )) {
      ref.read(torneioProvider.notifier).voltarNivel();
    }
  }

  Future<void> _reiniciar() async {
    if (await confirmar(
      context,
      icone: Icons.restart_alt_outlined,
      titulo: 'Reiniciar o torneio?',
      texto: 'O relógio volta para o nível 1 e o tempo é zerado.',
      isPerigo: true,
    )) {
      ref.read(torneioProvider.notifier).reiniciar();
    }
  }

  void _abrirConfiguracoes() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const TelaConfiguracoes()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cores = ref.watch(coresProvider);
    final notifier = ref.read(torneioProvider.notifier);

    return Scaffold(
      backgroundColor: cores.fundo,
      // Desenhada em 1280×800 e escalada: em qualquer tablet 16:10 fica igual ao design,
      // seja qual for a densidade ("Tamanho da tela") configurada no Android.
      body: SizedBox.expand(
        child: FittedBox(
          child: SizedBox(
            width: EspacosRelogio.larguraTela,
            height: EspacosRelogio.alturaTela,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ColunaLateral(aoIniciarOuPausar: _iniciarOuPausar),
                Expanded(
                  child: _FundoPrincipal(
                    child: Column(
                      children: [
                        const _Topo(),
                        const Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [_Tempo(), _Blinds(), _Ante()],
                            ),
                          ),
                        ),
                        const _Proximo(),
                        const SizedBox(height: EspacosRelogio.gapControlesTopo),
                        _Controles(
                          aoConfigurar: _abrirConfiguracoes,
                          aoReiniciar: _reiniciar,
                          aoVoltar: _voltar,
                          aoAjustar: notifier.ajustarTempoRestante,
                          aoAvancar: _avancar,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _destino(Nivel nivel, int numero) => nivel.isIntervalo
    ? 'o intervalo de **${nivel.duracao.inMinutes} minutos**'
    : 'o nível $numero: **${descreverBlinds(nivel)}**';

// Fundo da área principal: nos últimos 10 s pisca entre `fundo` e `fundoUltimoMinuto`
// uma vez por segundo (só a cor de um AnimatedContainer).
class _FundoPrincipal extends ConsumerWidget {
  const _FundoPrincipal({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = ref.watch(coresProvider);
    final isRodando = ref.watch(torneioProvider.select((t) => t.isRodando));
    final isVermelho =
        isRodando &&
        ref.watch(estadoRelogioProvider.select((e) => e.isPiscadaVermelha));

    return AnimatedContainer(
      key: const Key('fundoPrincipal'),
      duration: DuracoesRelogio.piscada,
      color: isVermelho ? cores.fundoUltimoMinuto : cores.fundo,
      padding: const EdgeInsets.fromLTRB(
        EspacosRelogio.margemLados,
        EspacosRelogio.margemTopo,
        EspacosRelogio.margemLados,
        EspacosRelogio.margemBase,
      ),
      child: child,
    );
  }
}

class _ColunaLateral extends ConsumerWidget {
  const _ColunaLateral({required this.aoIniciarOuPausar});

  final VoidCallback aoIniciarOuPausar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = ref.watch(coresProvider);
    final fichas = ref.watch(fichasProvider);

    return Container(
      width: EspacosRelogio.larguraLateral,
      decoration: BoxDecoration(
        color: cores.fundoLateral,
        border: Border(
          right: BorderSide(
            color: cores.bordaLateral,
            width: EspacosRelogio.bordaLateral,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        EspacosRelogio.paddingLateral,
        EspacosRelogio.paddingLateralTopo,
        EspacosRelogio.paddingLateral,
        EspacosRelogio.paddingLateral,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: fichas.isEmpty
                ? const SizedBox.shrink()
                // Muitas fichas encolhem juntas em vez de empurrar o play.
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: EspacosRelogio.gapFichas,
                      children: [
                        Text(
                          'FICHAS',
                          style: TextStyle(
                            fontSize: TiposRelogio.rotuloFichas,
                            fontWeight: FontWeight.w600,
                            letterSpacing: TiposRelogio.em(
                              TiposRelogio.rotuloFichas,
                              0.16,
                            ),
                            color: cores.rotuloFichas,
                          ),
                        ),
                        for (final ficha in fichas)
                          Row(
                            spacing: EspacosRelogio.gapBolinhaValor,
                            children: [
                              BolinhaFicha(cor: ficha.cor),
                              Text(
                                formatarValor(ficha.valor),
                                style: TiposRelogio.numero(
                                  TiposRelogio.ficha,
                                  FontWeight.w700,
                                  cores.texto,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
          ),
          _BotaoPlay(aoTocar: aoIniciarOuPausar),
        ],
      ),
    );
  }
}

class _BotaoPlay extends ConsumerWidget {
  const _BotaoPlay({required this.aoTocar});

  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = ref.watch(coresProvider);
    final isRodando = ref.watch(torneioProvider.select((t) => t.isRodando));
    final isTerminado = ref.watch(
      estadoRelogioProvider.select((e) => e.isTerminado),
    );
    final isChamando = !isRodando && !isTerminado;
    final fundo = isChamando ? cores.primaria : cores.superficie;
    final borda = isChamando ? cores.primaria : cores.playBorda;
    final frente = isChamando ? cores.naPrimaria : cores.playIcone;
    final rotulo = isRodando && !isTerminado ? 'PAUSAR' : 'INICIAR';

    return Semantics(
      button: true,
      enabled: !isTerminado,
      label: isRodando ? 'Pausar' : 'Iniciar',
      child: Opacity(
        opacity: isTerminado ? CoresRelogio.opacidadeDesabilitado : 1,
        child: AnimatedContainer(
          duration: DuracoesRelogio.troca,
          width: EspacosRelogio.larguraPlay,
          height: EspacosRelogio.alturaPlay,
          decoration: BoxDecoration(
            color: fundo,
            borderRadius: BorderRadius.circular(RaiosRelogio.play),
            border: Border.all(color: borda, width: EspacosRelogio.bordaPlay),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(RaiosRelogio.play),
              onTap: isTerminado ? null : aoTocar,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: EspacosRelogio.gapPlay,
                children: [
                  Icon(
                    isRodando && !isTerminado
                        ? Icons.pause_outlined
                        : Icons.play_arrow_outlined,
                    size: TiposRelogio.iconePlay,
                    color: frente,
                  ),
                  Text(
                    rotulo,
                    style: TextStyle(
                      fontSize: TiposRelogio.playTexto,
                      fontWeight: FontWeight.w800,
                      letterSpacing: TiposRelogio.em(
                        TiposRelogio.playTexto,
                        0.14,
                      ),
                      color: frente,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Topo extends StatelessWidget {
  const _Topo();

  @override
  Widget build(BuildContext context) {
    // O selo fica por cima, centralizado, sem empurrar o nível nem o "Intervalo em".
    return const SizedBox(
      height: EspacosRelogio.alturaTopo,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(children: [_Nivel(), Spacer(), _IntervaloEm()]),
          _Selo(),
        ],
      ),
    );
  }
}

class _Nivel extends ConsumerWidget {
  const _Nivel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = ref.watch(coresProvider);
    final texto = ref.watch(
      estadoRelogioProvider.select(
        (e) => e.nivelAtual.isIntervalo ? '' : 'NÍVEL ${e.numeroNivel}',
      ),
    );
    return Text(
      texto,
      style: TiposRelogio.numero(
        TiposRelogio.nivel,
        FontWeight.w800,
        cores.destaque,
        espacoEm: 0.08,
      ),
    );
  }
}

class _IntervaloEm extends ConsumerWidget {
  const _IntervaloEm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = ref.watch(coresProvider);
    final tempo = ref.watch(
      estadoRelogioProvider.select((e) {
        final ate = e.tempoAteProximoIntervalo;
        return e.nivelAtual.isIntervalo || ate == null
            ? null
            : formatarTempo(ate);
      }),
    );
    if (tempo == null) return const SizedBox.shrink();
    return Text.rich(
      TextSpan(
        text: 'Intervalo em ',
        children: [
          TextSpan(
            text: tempo,
            style: TextStyle(color: cores.texto, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      style: TiposRelogio.numero(
        TiposRelogio.intervaloEm,
        FontWeight.w500,
        cores.textoSecundario,
      ),
    );
  }
}

class _Selo extends ConsumerWidget {
  const _Selo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = ref.watch(coresProvider);
    final isRodando = ref.watch(torneioProvider.select((t) => t.isRodando));
    final isTerminado = ref.watch(
      estadoRelogioProvider.select((e) => e.isTerminado),
    );
    final (IconData, String)? selo = isTerminado
        ? (Icons.flag_outlined, 'FIM DA ESTRUTURA')
        : isRodando
        ? null
        : (Icons.pause_outlined, 'PAUSADO');
    if (selo == null) return const SizedBox.shrink();

    return Container(
      height: EspacosRelogio.alturaSelo,
      padding: const EdgeInsets.only(
        left: EspacosRelogio.paddingSeloEsquerda,
        right: EspacosRelogio.paddingSeloDireita,
      ),
      decoration: BoxDecoration(
        color: cores.primaria,
        borderRadius: BorderRadius.circular(RaiosRelogio.pilula),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: EspacosRelogio.gapSelo,
        children: [
          Icon(selo.$1, size: TiposRelogio.iconeSelo, color: cores.naPrimaria),
          Text(
            selo.$2,
            style: TextStyle(
              fontSize: TiposRelogio.selo,
              fontWeight: FontWeight.w800,
              letterSpacing: TiposRelogio.em(TiposRelogio.selo, 0.10),
              color: cores.naPrimaria,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tempo extends ConsumerWidget {
  const _Tempo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = ref.watch(coresProvider);
    final isRodando = ref.watch(torneioProvider.select((t) => t.isRodando));
    final (texto, isUltimoMinuto, isTerminado) = ref.watch(
      estadoRelogioProvider.select(
        (e) =>
            (formatarTempo(e.tempoRestante), e.isUltimoMinuto, e.isTerminado),
      ),
    );
    final cor = isTerminado || !isRodando
        ? cores.pausado
        : isUltimoMinuto
        ? cores.ultimoMinuto
        : cores.texto;

    return SizedBox(
      height: EspacosRelogio.alturaTempo,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: AnimatedDefaultTextStyle(
            duration: DuracoesRelogio.troca,
            style: TiposRelogio.numero(
              texto.length > 5 ? TiposRelogio.tempoLongo : TiposRelogio.tempo,
              FontWeight.w800,
              cor,
              espacoEm: -0.02,
            ),
            child: Text(texto, key: const Key('tempo')),
          ),
        ),
      ),
    );
  }
}

class _Blinds extends ConsumerWidget {
  const _Blinds();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = ref.watch(coresProvider);
    final nivel = ref.watch(estadoRelogioProvider.select((e) => e.nivelAtual));
    final texto = nivel.isIntervalo
        ? 'INTERVALO'
        : formatarBlinds(nivel.smallBlind, nivel.bigBlind);
    final estilo = nivel.isIntervalo
        ? TiposRelogio.numero(
            TiposRelogio.intervaloTitulo,
            FontWeight.w800,
            cores.intervalo,
            espacoEm: 0.12,
          )
        : TiposRelogio.numero(
            texto.length > 13 ? TiposRelogio.blindsLongo : TiposRelogio.blinds,
            FontWeight.w700,
            cores.destaque,
            espacoEm: -0.01,
          );

    return SizedBox(
      height: EspacosRelogio.alturaBlinds,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: AnimatedDefaultTextStyle(
            duration: DuracoesRelogio.troca,
            style: estilo,
            child: Text(texto),
          ),
        ),
      ),
    );
  }
}

class _Ante extends ConsumerWidget {
  const _Ante();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = ref.watch(coresProvider);
    final nivel = ref.watch(estadoRelogioProvider.select((e) => e.nivelAtual));
    // Sem ante, a caixa continua com a mesma altura: nada se move.
    return SizedBox(
      height: EspacosRelogio.alturaAnte,
      child: Center(
        child: nivel.isIntervalo || nivel.ante == 0
            ? null
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'ANTE ${formatarValor(nivel.ante)}',
                  style: TiposRelogio.numero(
                    TiposRelogio.ante,
                    FontWeight.w600,
                    cores.textoSecundario,
                    espacoEm: 0.06,
                  ),
                ),
              ),
      ),
    );
  }
}

class _Proximo extends ConsumerWidget {
  const _Proximo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = ref.watch(coresProvider);
    final (proximo, isTerminado) = ref.watch(
      estadoRelogioProvider.select((e) => (e.proximoNivel, e.isTerminado)),
    );
    final (rotulo, valor) = isTerminado
        ? ('Fim da estrutura', null)
        : proximo == null
        ? ('Último nível', null)
        : (
            'Próximo: ',
            proximo.isIntervalo ? 'intervalo' : descreverBlinds(proximo),
          );

    return Container(
      height: EspacosRelogio.alturaProximo + EspacosRelogio.gapProximo,
      padding: const EdgeInsets.only(top: EspacosRelogio.gapProximo),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cores.linha, width: EspacosRelogio.filete),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text.rich(
          TextSpan(
            text: rotulo,
            children: [
              if (valor != null)
                TextSpan(
                  text: valor,
                  style: TextStyle(
                    color: cores.textoProximo,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          style: TiposRelogio.numero(
            TiposRelogio.proximo,
            FontWeight.w500,
            cores.textoSecundario,
          ),
        ),
      ),
    );
  }
}

class _Controles extends ConsumerWidget {
  const _Controles({
    required this.aoConfigurar,
    required this.aoReiniciar,
    required this.aoVoltar,
    required this.aoAjustar,
    required this.aoAvancar,
  });

  final VoidCallback aoConfigurar;
  final VoidCallback aoReiniciar;
  final VoidCallback aoVoltar;
  final void Function(Duration delta) aoAjustar;
  final VoidCallback aoAvancar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = ref.watch(coresProvider);

    Widget botao(
      String dica,
      VoidCallback aoTocar, {
      IconData? icone,
      String? texto,
    }) {
      final forma = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RaiosRelogio.controle),
        side: BorderSide(
          color: cores.bordaControle,
          width: EspacosRelogio.bordaControle,
        ),
      );
      return Tooltip(
        message: dica,
        child: Material(
          type: MaterialType.transparency,
          shape: forma,
          child: InkWell(
            customBorder: forma,
            onTap: aoTocar,
            child: SizedBox.square(
              dimension: EspacosRelogio.botaoControle,
              child: Center(
                child: icone != null
                    ? Icon(
                        icone,
                        size: TiposRelogio.icone,
                        color: cores.controles,
                      )
                    : Text(
                        texto!,
                        style: TiposRelogio.numero(
                          TiposRelogio.botao,
                          FontWeight.w700,
                          cores.controles,
                        ),
                      ),
              ),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: EspacosRelogio.gapControles,
        children: [
          botao('Configurações', aoConfigurar, icone: Icons.settings_outlined),
          botao(
            'Reiniciar torneio',
            aoReiniciar,
            icone: Icons.restart_alt_outlined,
          ),
          Container(
            width: EspacosRelogio.filete,
            height: EspacosRelogio.alturaDivisoria,
            margin: const EdgeInsets.symmetric(
              horizontal: EspacosRelogio.margemDivisoria,
            ),
            color: cores.bordaControle,
          ),
          botao(
            'Nível anterior',
            aoVoltar,
            icone: Icons.skip_previous_outlined,
          ),
          botao(
            'Menos 1 minuto',
            () => aoAjustar(const Duration(minutes: -1)),
            texto: '−1',
          ),
          botao(
            'Mais 1 minuto',
            () => aoAjustar(const Duration(minutes: 1)),
            texto: '+1',
          ),
          botao('Próximo nível', aoAvancar, icone: Icons.skip_next_outlined),
        ],
      ),
    );
  }
}
