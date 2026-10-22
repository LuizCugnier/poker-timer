import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logica/formatacao.dart';
import '../../logica/validacao.dart';
import '../../modelos/ficha.dart';
import '../../theme/tema_relogio.dart';
import '../componentes.dart';
import '../configuracoes/configuracao_notifier.dart';
import 'fichas_notifier.dart';

// Editor de fichas (ESPECIFICACAO 5.3). Rascunho local: nada é salvo até tocar em Salvar.
class TelaFichas extends ConsumerStatefulWidget {
  const TelaFichas({super.key});

  @override
  ConsumerState<TelaFichas> createState() => _TelaFichasState();
}

class _TelaFichasState extends ConsumerState<TelaFichas> {
  late final _fichas = [...ref.read(fichasProvider)];
  var _isAlterado = false;

  void _mudar(VoidCallback mudanca) {
    setState(() {
      mudanca();
      _isAlterado = true;
    });
  }

  Future<void> _editar(int indice) async {
    final editada = await _editarFicha(context, _fichas[indice], isNova: false);
    if (editada == null) return;
    _mudar(() => _fichas[indice] = editada);
  }

  Future<void> _adicionar() async {
    final sugestao = Ficha(
      valor: _fichas.isEmpty ? 25 : _fichas.last.valor * 2,
      cor: coresFicha[_fichas.length % coresFicha.length],
      rotulo: '',
    );
    final nova = await _editarFicha(context, sugestao, isNova: true);
    if (nova == null) return;
    _mudar(() => _fichas.add(nova));
  }

  void _salvar() {
    ref.read(fichasProvider.notifier).salvar(_fichas);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Fichas salvas.')));
    Navigator.pop(context);
  }

  Future<void> _sairSemSalvar() async {
    if (await confirmar(
          context,
          icone: Icons.undo,
          titulo: 'Sair sem salvar?',
          texto: 'As alterações nas fichas serão perdidas.',
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

    return PopScope(
      canPop: !_isAlterado,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _sairSemSalvar();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fichas'),
          actions: [
            FilledButton.icon(
              onPressed: _salvar,
              icon: const Icon(Icons.check),
              label: const Text('Salvar'),
            ),
            const SizedBox(width: EspacosRelogio.margemTabela),
          ],
        ),
        body: ConteudoCentralizado(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              vertical: EspacosRelogio.margemTabela,
            ),
            children: [
              for (final (i, ficha) in _fichas.indexed) ...[
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _editar(i),
                    child: SizedBox(
                      height: EspacosRelogio.alturaCardFicha,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: EspacosRelogio.paddingCardHorizontal,
                        ),
                        child: Row(
                          spacing: EspacosRelogio.gapGrande,
                          children: [
                            BolinhaFicha(cor: ficha.cor),
                            Text(
                              formatarValor(ficha.valor),
                              style: TiposRelogio.numero(
                                TiposRelogio.valorFicha,
                                FontWeight.w700,
                                cores.texto,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                ficha.rotulo,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: TiposRelogio.nomeFicha,
                                  fontWeight: FontWeight.w500,
                                  color: cores.textoSecundario,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.edit_outlined,
                                color: cores.controles,
                              ),
                              tooltip: 'Editar',
                              onPressed: () => _editar(i),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: cores.controles,
                              ),
                              tooltip: 'Remover',
                              onPressed: () =>
                                  _mudar(() => _fichas.removeAt(i)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: EspacosRelogio.gapCards),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _adicionar,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar ficha'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<Ficha?> _editarFicha(
  BuildContext context,
  Ficha inicial, {
  required bool isNova,
}) {
  return showDialog<Ficha>(
    context: context,
    builder: (context) => _DialogoFicha(inicial: inicial, isNova: isNova),
  );
}

class _DialogoFicha extends ConsumerStatefulWidget {
  const _DialogoFicha({required this.inicial, required this.isNova});

  final Ficha inicial;
  final bool isNova;

  @override
  ConsumerState<_DialogoFicha> createState() => _DialogoFichaState();
}

class _DialogoFichaState extends ConsumerState<_DialogoFicha> {
  final _form = GlobalKey<FormState>();
  late final _valor = TextEditingController(text: '${widget.inicial.valor}');
  late final _rotulo = TextEditingController(text: widget.inicial.rotulo);
  late var _cor = widget.inicial.cor;

  @override
  void dispose() {
    _valor.dispose();
    _rotulo.dispose();
    super.dispose();
  }

  void _salvar() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(
      context,
      Ficha(
        valor: int.parse(_valor.text.trim()),
        cor: _cor,
        rotulo: _rotulo.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cores = ref.watch(coresProvider);
    final estiloRotulo = TextStyle(
      fontSize: TiposRelogio.rotuloCampo,
      fontWeight: FontWeight.w600,
      letterSpacing: TiposRelogio.em(TiposRelogio.rotuloCampo, 0.10),
      color: cores.textoSecundario,
    );

    return AlertDialog(
      title: Text(widget.isNova ? 'Nova ficha' : 'Editar ficha'),
      content: SizedBox(
        width: EspacosRelogio.larguraDialogoFicha,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: EspacosRelogio.gapGrande,
                  children: [
                    Expanded(
                      child: CampoRotulado(
                        rotulo: 'Valor',
                        controle: _valor,
                        autofocus: true,
                        validar: (texto) => validarInteiro(texto, minimo: 1),
                      ),
                    ),
                    Expanded(
                      child: CampoRotulado(
                        rotulo: 'Nome (opcional)',
                        controle: _rotulo,
                        isNumero: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: EspacosRelogio.gapGrande),
                Text('COR', style: estiloRotulo),
                const SizedBox(height: EspacosRelogio.gapPequeno),
                GridView.count(
                  crossAxisCount: EspacosRelogio.colunasCores.toInt(),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final cor in coresFicha)
                      _AlvoCor(
                        cor: cor,
                        isSelecionada: cor == _cor,
                        corSelecao: cores.primaria,
                        aoTocar: () => setState(() => _cor = cor),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _salvar, child: const Text('Salvar')),
      ],
    );
  }
}

// Bolinha de 50 dentro de um alvo de 64; a selecionada ganha anel e ✓.
class _AlvoCor extends StatelessWidget {
  const _AlvoCor({
    required this.cor,
    required this.isSelecionada,
    required this.corSelecao,
    required this.aoTocar,
  });

  final int cor;
  final bool isSelecionada;
  final Color corSelecao;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: aoTocar,
        child: Container(
          width: EspacosRelogio.alvoCor,
          height: EspacosRelogio.alvoCor,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: isSelecionada
                ? Border.all(
                    color: corSelecao,
                    width: EspacosRelogio.anelSelecao,
                  )
                : null,
          ),
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              BolinhaFicha(cor: cor, isTracejada: false),
              if (isSelecionada)
                Icon(Icons.check, color: CoresRelogio.sobre(Color(cor))),
            ],
          ),
        ),
      ),
    );
  }
}
