import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logica/formatacao.dart';
import '../../logica/validacao.dart';
import '../../modelos/configuracao.dart';
import '../../theme/tema_relogio.dart';
import '../componentes.dart';
import '../estrutura/estrutura_notifier.dart';
import '../estrutura/tela_estrutura.dart';
import '../fichas/fichas_notifier.dart';
import '../fichas/tela_fichas.dart';
import 'configuracao_notifier.dart';

// Menu de configurações (ESPECIFICACAO 5.1): cada item novo entra como mais um card.
class TelaConfiguracoes extends ConsumerWidget {
  const TelaConfiguracoes({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estrutura = ref.watch(estruturaProvider);
    final fichas = ref.watch(fichasProvider);
    final configuracao = ref.watch(configuracaoProvider);
    final notifier = ref.read(configuracaoProvider.notifier);
    final duracaoTotal = estrutura.niveis.fold(
      Duration.zero,
      (soma, nivel) => soma + nivel.duracao,
    );

    void abrir(Widget tela) {
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => tela));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ConteudoCentralizado(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            vertical: EspacosRelogio.margemTabela,
          ),
          children: [
            _CardComTitulo(
              icone: Icons.palette_outlined,
              titulo: 'Modo de exibição',
              child: Row(
                spacing: EspacosRelogio.gapMedio,
                children: [
                  for (final (modo, icone, rotulo) in const [
                    (
                      ModoRelogio.altoContraste,
                      Icons.contrast,
                      'Alto contraste',
                    ),
                    (
                      ModoRelogio.mesaCassino,
                      Icons.casino_outlined,
                      'Mesa de cassino',
                    ),
                  ])
                    Expanded(
                      child: _BotaoModo(
                        icone: icone,
                        rotulo: rotulo,
                        isSelecionado: configuracao.modo == modo,
                        aoTocar: () => notifier.mudarModo(modo),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: EspacosRelogio.gapCards),
            _CardNavegacao(
              icone: Icons.format_list_numbered,
              titulo: 'Estrutura de blinds',
              subtitulo: Text(
                '${estrutura.niveis.length} níveis · '
                '${formatarTempo(duracaoTotal)}',
              ),
              aoTocar: () => abrir(const TelaEstrutura()),
            ),
            const SizedBox(height: EspacosRelogio.gapCards),
            _CardNavegacao(
              icone: Icons.toll_outlined,
              titulo: 'Fichas',
              subtitulo: fichas.isEmpty
                  ? const Text('Nenhuma ficha')
                  : Row(
                      spacing: EspacosRelogio.gapBolinhaMini,
                      children: [
                        for (final ficha in fichas)
                          BolinhaFicha(
                            cor: ficha.cor,
                            tamanho: EspacosRelogio.bolinhaMini,
                            isTracejada: false,
                          ),
                        const SizedBox(width: EspacosRelogio.gapPequeno),
                        Flexible(
                          child: Text(
                            fichas
                                .map((f) => formatarValor(f.valor))
                                .join(' · '),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
              aoTocar: () => abrir(const TelaFichas()),
            ),
            const SizedBox(height: EspacosRelogio.gapCards),
            _CardComTitulo(
              icone: Icons.notifications_active_outlined,
              titulo: 'Avisar antes da troca de nível',
              child: Wrap(
                spacing: EspacosRelogio.gapMedio,
                runSpacing: EspacosRelogio.gapPequeno,
                children: [
                  for (final minutos in Configuracao.opcoesAvisoMinutos)
                    SizedBox(
                      height: EspacosRelogio.alturaChip,
                      child: FilterChip(
                        label: Text('$minutos min'),
                        selected: configuracao.avisosMinutos.contains(minutos),
                        onSelected: (_) => notifier.alternarAviso(minutos),
                      ),
                    ),
                  SizedBox(
                    height: EspacosRelogio.alturaChip,
                    child: FilterChip(
                      label: const Text('1/2'),
                      tooltip: 'Na metade de cada nível',
                      selected: configuracao.isAvisoMetade,
                      onSelected: (_) => notifier.alternarAvisoMetade(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: EspacosRelogio.gapCards),
            _CardComTitulo(
              icone: Icons.timer_outlined,
              titulo: 'Time bank',
              child: _CampoTimeBank(inicial: configuracao.timeBank),
            ),
          ],
        ),
      ),
    );
  }
}

// Salva a cada alteração válida: sair da tela (ou o "voltar" com o teclado aberto)
// nem sempre tira o foco do campo, então não dá para esperar o fim da edição.
class _CampoTimeBank extends ConsumerStatefulWidget {
  const _CampoTimeBank({required this.inicial});

  final Duration inicial;

  @override
  ConsumerState<_CampoTimeBank> createState() => _CampoTimeBankState();
}

class _CampoTimeBankState extends ConsumerState<_CampoTimeBank> {
  late final _segundos = TextEditingController(
    text: '${widget.inicial.inSeconds}',
  );

  @override
  void initState() {
    super.initState();
    _segundos.addListener(_aoMudar);
  }

  @override
  void dispose() {
    _segundos.dispose();
    super.dispose();
  }

  String? _validar(String? texto) =>
      validarInteiro(texto, minimo: Configuracao.segundosMinimoTimeBank);

  void _aoMudar() {
    if (_validar(_segundos.text) != null) return;
    final segundos = int.parse(_segundos.text.trim());
    // O listener também dispara quando só o cursor muda.
    if (segundos == ref.read(configuracaoProvider).timeBank.inSeconds) return;
    ref.read(configuracaoProvider.notifier).mudarTimeBank(segundos);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: SizedBox(
        width: EspacosRelogio.larguraCampoCurto,
        child: CampoRotulado(
          rotulo: 'Segundos',
          controle: _segundos,
          validar: _validar,
        ),
      ),
    );
  }
}

class _CardComTitulo extends StatelessWidget {
  const _CardComTitulo({
    required this.icone,
    required this.titulo,
    required this.child,
  });

  final IconData icone;
  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: EspacosRelogio.paddingCardHorizontal,
          vertical: EspacosRelogio.paddingCardVertical,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: EspacosRelogio.gapGrande,
          children: [
            Row(
              spacing: EspacosRelogio.gapGrande,
              children: [
                Icon(icone, color: tema.listTileTheme.iconColor),
                Text(titulo, style: tema.listTileTheme.titleTextStyle),
              ],
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _CardNavegacao extends StatelessWidget {
  const _CardNavegacao({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.aoTocar,
  });

  final IconData icone;
  final String titulo;
  final Widget subtitulo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(icone),
        title: Text(titulo),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: EspacosRelogio.gapPequeno),
          child: subtitulo,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: aoTocar,
      ),
    );
  }
}

// Opção do modo de exibição: preenchida quando escolhida, contornada quando não.
class _BotaoModo extends StatelessWidget {
  const _BotaoModo({
    required this.icone,
    required this.rotulo,
    required this.isSelecionado,
    required this.aoTocar,
  });

  final IconData icone;
  final String rotulo;
  final bool isSelecionado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    const tamanho = Size.fromHeight(EspacosRelogio.alturaSegmento);
    return isSelecionado
        ? FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: tamanho),
            onPressed: aoTocar,
            icon: Icon(icone),
            label: Text(rotulo),
          )
        : OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: tamanho),
            onPressed: aoTocar,
            icon: Icon(icone),
            label: Text(rotulo),
          );
  }
}
