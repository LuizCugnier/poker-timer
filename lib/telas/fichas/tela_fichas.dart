import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logica/formatacao.dart';
import '../../logica/validacao.dart';
import '../../modelos/ficha.dart';
import '../../tema.dart';
import '../componentes.dart';
import 'fichas_notifier.dart';

class TelaFichas extends ConsumerStatefulWidget {
  const TelaFichas({super.key});

  @override
  ConsumerState<TelaFichas> createState() => _TelaFichasState();
}

// Rascunho local: nada é salvo até tocar em Salvar.
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
    final editada = await _editarFicha(context, _fichas[indice]);
    if (editada == null) return;
    _mudar(() => _fichas[indice] = editada);
  }

  Future<void> _adicionar() async {
    final sugestao = Ficha(
      valor: _fichas.isEmpty ? 25 : _fichas.last.valor * 2,
      cor: coresFicha[_fichas.length % coresFicha.length],
      rotulo: '',
    );
    final nova = await _editarFicha(context, sugestao);
    if (nova == null) return;
    _mudar(() => _fichas.add(nova));
  }

  Future<void> _restaurarPadrao() async {
    if (!await perguntar(context, 'Trocar todas as fichas pelas padrão?')) {
      return;
    }
    _mudar(() {
      _fichas
        ..clear()
        ..addAll(fichasPadrao);
    });
  }

  void _salvar() {
    ref.read(fichasProvider.notifier).salvar(_fichas);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Fichas salvas.')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isAlterado,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await perguntar(
              context,
              'Sair sem salvar as alterações?',
              confirmar: 'Sair',
            ) &&
            context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fichas'),
          actions: [
            TextButton(
              onPressed: _restaurarPadrao,
              child: const Text('Restaurar padrão'),
            ),
            const SizedBox(width: 8),
            FilledButton(onPressed: _salvar, child: const Text('Salvar')),
            const SizedBox(width: 16),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          children: [
            for (final (i, ficha) in _fichas.indexed)
              ListTile(
                leading: BolinhaFicha(cor: ficha.cor),
                title: Text(
                  formatarValor(ficha.valor),
                  style: const TextStyle(fontSize: 22),
                ),
                subtitle: ficha.rotulo.isEmpty ? null : Text(ficha.rotulo),
                onTap: () => _editar(i),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remover',
                  onPressed: () => _mudar(() => _fichas.removeAt(i)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _adicionar,
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar ficha'),
                  ),
                  const Spacer(),
                  const Text(
                    'Na mesa, as fichas aparecem em ordem de valor.',
                    style: TextStyle(color: Tema.textoSecundario),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<Ficha?> _editarFicha(BuildContext context, Ficha inicial) {
  return showDialog<Ficha>(
    context: context,
    builder: (context) => _DialogoFicha(inicial: inicial),
  );
}

class _DialogoFicha extends StatefulWidget {
  const _DialogoFicha({required this.inicial});

  final Ficha inicial;

  @override
  State<_DialogoFicha> createState() => _DialogoFichaState();
}

class _DialogoFichaState extends State<_DialogoFicha> {
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
    return AlertDialog(
      title: const Text('Ficha'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CampoNumero(
                        rotulo: 'Valor',
                        controle: _valor,
                        autofocus: true,
                        validar: (texto) => validarInteiro(texto, minimo: 1),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _rotulo,
                        decoration: const InputDecoration(
                          labelText: 'Nome (opcional)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final cor in coresFicha)
                      GestureDetector(
                        onTap: () => setState(() => _cor = cor),
                        child: BolinhaFicha(
                          cor: cor,
                          isSelecionada: cor == _cor,
                        ),
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
        FilledButton(onPressed: _salvar, child: const Text('OK')),
      ],
    );
  }
}
