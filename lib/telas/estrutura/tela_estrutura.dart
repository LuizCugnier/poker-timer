import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logica/formatacao.dart';
import '../../logica/validacao.dart';
import '../../modelos/estrutura.dart';
import '../../modelos/nivel.dart';
import '../../theme/tema_relogio.dart';
import '../componentes.dart';
import '../configuracoes/configuracao_notifier.dart';
import '../relogio/torneio_notifier.dart';
import 'dialogo_nivel.dart';
import 'estrutura_notifier.dart';

class TelaEstrutura extends ConsumerStatefulWidget {
  const TelaEstrutura({super.key});

  @override
  ConsumerState<TelaEstrutura> createState() => _TelaEstruturaState();
}

// Rascunho local: nada é salvo até tocar em Salvar.
class _TelaEstruturaState extends ConsumerState<TelaEstrutura> {
  // O id dá a cada linha uma Key estável; Nivel const repetidos são o mesmo objeto.
  final _niveis = <({int id, Nivel nivel})>[];
  var _proximoId = 0;
  var _isAlterado = false;

  @override
  void initState() {
    super.initState();
    _carregar(ref.read(estruturaProvider).niveis);
  }

  void _carregar(List<Nivel> niveis) {
    _niveis
      ..clear()
      ..addAll([for (final nivel in niveis) (id: _proximoId++, nivel: nivel)]);
  }

  void _mudar(VoidCallback mudanca) {
    setState(() {
      mudanca();
      _isAlterado = true;
    });
  }

  Future<void> _editar(int indice) async {
    final editado = await editarNivel(
      context,
      _niveis[indice].nivel,
      isNovo: false,
    );
    if (editado == null) return;
    _mudar(() => _niveis[indice] = (id: _niveis[indice].id, nivel: editado));
  }

  Future<void> _adicionar({required bool isIntervalo}) async {
    final jogo = _niveis.map((item) => item.nivel).where((n) => !n.isIntervalo);
    final ultimo = jogo.isEmpty ? Estrutura.padrao.niveis.first : jogo.last;
    final sugestao = isIntervalo
        ? const Nivel.intervalo(Duration(minutes: 10))
        : ultimo.copyWith(
            smallBlind: ultimo.smallBlind * 2,
            bigBlind: ultimo.bigBlind * 2,
            ante: ultimo.ante * 2,
          );
    final novo = await editarNivel(context, sugestao, isNovo: true);
    if (novo == null) return;
    _mudar(() => _niveis.add((id: _proximoId++, nivel: novo)));
  }

  Future<void> _restaurarPadrao() async {
    if (!await confirmar(
      context,
      icone: Icons.settings_backup_restore,
      titulo: 'Restaurar a estrutura padrão?',
      texto:
          'Todos os níveis desta lista serão trocados pelos da estrutura '
          'padrão. Nada é gravado até tocar em Salvar.',
    )) {
      return;
    }
    _mudar(() => _carregar(Estrutura.padrao.niveis));
  }

  void _salvar() {
    final niveis = [for (final item in _niveis) item.nivel];
    final mensagens = ScaffoldMessenger.of(context);
    final erro = validarNiveis(niveis);
    if (erro != null) {
      mensagens.showSnackBar(SnackBar(content: Text(erro)));
      return;
    }

    final estrutura = ref.read(estruturaProvider).copyWith(niveis: niveis);
    ref.read(estruturaProvider.notifier).salvar(estrutura);
    final aplicou = ref
        .read(torneioProvider.notifier)
        .usarEstruturaSeNaoComecou(estrutura);
    mensagens.showSnackBar(
      SnackBar(
        content: Text(
          aplicou
              ? 'Estrutura salva.'
              : 'Estrutura salva. O torneio em andamento continua com a '
                    'estrutura antiga; a nova vale depois de Reiniciar.',
        ),
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _sairSemSalvar() async {
    if (await confirmar(
          context,
          icone: Icons.undo,
          titulo: 'Sair sem salvar?',
          texto: 'As alterações nesta estrutura serão perdidas.',
          botaoConfirmar: 'Sair',
          isPerigo: true,
        ) &&
        mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = ref.watch(coresProvider);
    // Intervalos não contam na numeração, como no relógio.
    final numeros = <int>[];
    for (final item in _niveis) {
      numeros.add((numeros.lastOrNull ?? 0) + (item.nivel.isIntervalo ? 0 : 1));
    }
    final duracaoTotal = _niveis.fold(
      Duration.zero,
      (soma, item) => soma + item.nivel.duracao,
    );
    final estiloSubtexto = TextStyle(
      fontSize: TiposRelogio.subtexto,
      fontWeight: FontWeight.w500,
      color: cores.textoSecundario,
      fontFeatures: TiposRelogio.numeros,
    );

    return PopScope(
      canPop: !_isAlterado,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _sairSemSalvar();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Estrutura de blinds'),
              Text(
                '${_niveis.length} níveis · ${formatarTempo(duracaoTotal)}',
                style: estiloSubtexto,
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: _restaurarPadrao,
              icon: const Icon(Icons.settings_backup_restore),
              label: const Text('Restaurar padrão'),
            ),
            const SizedBox(width: EspacosRelogio.gapMedio),
            FilledButton.icon(
              onPressed: _salvar,
              icon: const Icon(Icons.check),
              label: const Text('Salvar'),
            ),
            const SizedBox(width: EspacosRelogio.margemTabela),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                EspacosRelogio.margemTabela,
                EspacosRelogio.gapMedio,
                EspacosRelogio.margemTabela,
                0,
              ),
              child: SizedBox(
                height: EspacosRelogio.alturaCabecalhoTabela,
                child: _LinhaTabela(
                  alca: const SizedBox.shrink(),
                  nivel: _cabecalho('NÍVEL', cores),
                  blinds: _cabecalho('BLINDS', cores),
                  ante: _cabecalho('ANTE', cores),
                  duracao: _cabecalho('DURAÇÃO', cores),
                  acao: const SizedBox.shrink(),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EspacosRelogio.margemTabela,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(RaiosRelogio.card),
                  child: ColoredBox(
                    color: cores.superficie,
                    child: ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      itemCount: _niveis.length,
                      itemExtent: EspacosRelogio.alturaLinha,
                      onReorderItem: (de, para) => _mudar(
                        () => _niveis.insert(para, _niveis.removeAt(de)),
                      ),
                      proxyDecorator: (filho, _, _) =>
                          Material(color: cores.superficieAlta, child: filho),
                      itemBuilder: (context, i) => _linha(i, numeros[i], cores),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              height: EspacosRelogio.alturaRodape,
              margin: const EdgeInsets.only(top: EspacosRelogio.gapMedio),
              padding: const EdgeInsets.symmetric(
                horizontal: EspacosRelogio.margemTabela,
              ),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: cores.linha)),
              ),
              child: Row(
                spacing: EspacosRelogio.gapMedio,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _adicionar(isIntervalo: false),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar nível'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _adicionar(isIntervalo: true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cores.intervalo,
                    ),
                    icon: const Icon(Icons.coffee_outlined),
                    label: const Text('Adicionar intervalo'),
                  ),
                  Expanded(
                    child: Text(
                      'Toque numa linha para editar · arraste para reordenar',
                      style: estiloSubtexto,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linha(int i, int numero, CoresRelogio cores) {
    final nivel = _niveis[i].nivel;
    final corTexto = nivel.isIntervalo ? cores.intervalo : cores.texto;
    TextStyle estilo(Color cor, {double espacoEm = 0}) => TiposRelogio.numero(
      TiposRelogio.linhaTabela,
      FontWeight.w600,
      cor,
      espacoEm: espacoEm,
    );

    return Material(
      key: ValueKey(_niveis[i].id),
      color: nivel.isIntervalo ? cores.fundoIntervalo : Colors.transparent,
      child: InkWell(
        onTap: () => _editar(i),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: i == _niveis.length - 1
                ? null
                : Border(bottom: BorderSide(color: cores.linha)),
          ),
          child: _LinhaTabela(
            alca: ReorderableDragStartListener(
              index: i,
              child: Icon(Icons.drag_indicator, color: cores.controles),
            ),
            nivel: nivel.isIntervalo
                ? Icon(Icons.coffee_outlined, color: cores.intervalo)
                : Text('$numero', style: estilo(cores.textoSecundario)),
            blinds: Text(
              nivel.isIntervalo
                  ? 'INTERVALO'
                  : formatarBlinds(nivel.smallBlind, nivel.bigBlind),
              style: estilo(corTexto, espacoEm: nivel.isIntervalo ? 0.12 : 0),
            ),
            ante: nivel.isIntervalo
                ? const SizedBox.shrink()
                : Text(
                    nivel.ante > 0 ? formatarValor(nivel.ante) : '—',
                    style: estilo(
                      nivel.ante > 0 ? cores.texto : cores.controles,
                    ),
                  ),
            duracao: Text(
              formatarTempo(nivel.duracao),
              style: estilo(corTexto),
            ),
            acao: IconButton(
              icon: Icon(Icons.delete_outline, color: cores.controles),
              tooltip: 'Remover',
              onPressed: () => _mudar(() => _niveis.removeAt(i)),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _cabecalho(String texto, CoresRelogio cores) {
  return Text(
    texto,
    style: TextStyle(
      fontSize: TiposRelogio.cabecalhoTabela,
      fontWeight: FontWeight.w700,
      letterSpacing: TiposRelogio.em(TiposRelogio.cabecalhoTabela, 0.12),
      color: cores.textoSecundario,
    ),
  );
}

// Colunas da tabela: 56 | 120 | 1fr | 1fr | 1fr | 64.
class _LinhaTabela extends StatelessWidget {
  const _LinhaTabela({
    required this.alca,
    required this.nivel,
    required this.blinds,
    required this.ante,
    required this.duracao,
    required this.acao,
  });

  final Widget alca;
  final Widget nivel;
  final Widget blinds;
  final Widget ante;
  final Widget duracao;
  final Widget acao;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: EspacosRelogio.colunaAlca,
          child: Center(child: alca),
        ),
        SizedBox(
          width: EspacosRelogio.colunaNivel,
          child: Align(alignment: Alignment.centerLeft, child: nivel),
        ),
        for (final celula in [blinds, ante, duracao])
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: celula),
          ),
        SizedBox(
          width: EspacosRelogio.colunaRemover,
          child: Center(child: acao),
        ),
      ],
    );
  }
}
