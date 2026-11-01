import 'package:flutter/material.dart';

import '../../logica/validacao.dart';
import '../../modelos/nivel.dart';
import '../../theme/tema_relogio.dart';
import '../componentes.dart';

// Devolve o nível editado, ou null se cancelar.
Future<Nivel?> editarNivel(
  BuildContext context,
  Nivel inicial, {
  required bool isNovo,
}) {
  return showDialog<Nivel>(
    context: context,
    builder: (context) => _DialogoNivel(inicial: inicial, isNovo: isNovo),
  );
}

class _DialogoNivel extends StatefulWidget {
  const _DialogoNivel({required this.inicial, required this.isNovo});

  final Nivel inicial;
  final bool isNovo;

  @override
  State<_DialogoNivel> createState() => _DialogoNivelState();
}

class _DialogoNivelState extends State<_DialogoNivel> {
  final _form = GlobalKey<FormState>();
  late final _smallBlind = TextEditingController(
    text: '${widget.inicial.smallBlind}',
  );
  late final _bigBlind = TextEditingController(
    text: '${widget.inicial.bigBlind}',
  );
  late final _ante = TextEditingController(text: '${widget.inicial.ante}');
  late final _minutos = TextEditingController(
    text: '${widget.inicial.duracao.inMinutes}',
  );
  // Não fica salvo no nível: ao abrir, vem marcada se o ante já é igual ao small blind.
  late var _isAnteIgualSmallBlind =
      widget.inicial.ante > 0 &&
      widget.inicial.ante == widget.inicial.smallBlind;

  @override
  void initState() {
    super.initState();
    _smallBlind.addListener(_copiarSmallBlind);
  }

  @override
  void dispose() {
    for (final controle in [_smallBlind, _bigBlind, _ante, _minutos]) {
      controle.dispose();
    }
    super.dispose();
  }

  // O listener também dispara quando só o cursor muda: copia só se o texto mudou.
  void _copiarSmallBlind() {
    if (_isAnteIgualSmallBlind && _ante.text != _smallBlind.text) {
      _ante.text = _smallBlind.text;
    }
  }

  void _trocarAnteIgualSmallBlind(bool? isMarcado) {
    setState(() => _isAnteIgualSmallBlind = isMarcado ?? false);
    _copiarSmallBlind();
  }

  void _salvar() {
    if (!_form.currentState!.validate()) return;
    final duracao = Duration(minutes: int.parse(_minutos.text.trim()));
    final smallBlind = int.parse(_smallBlind.text.trim());
    Navigator.pop(
      context,
      widget.inicial.isIntervalo
          ? Nivel.intervalo(duracao)
          : Nivel(
              smallBlind: smallBlind,
              bigBlind: int.parse(_bigBlind.text.trim()),
              ante: _isAnteIgualSmallBlind
                  ? smallBlind
                  : int.parse(_ante.text.trim()),
              duracao: duracao,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIntervalo = widget.inicial.isIntervalo;
    final tipo = isIntervalo ? 'intervalo' : 'nível';
    final duracao = CampoRotulado(
      rotulo: 'Duração (min)',
      controle: _minutos,
      autofocus: isIntervalo,
      validar: (texto) => validarInteiro(texto, minimo: 1),
    );

    return AlertDialog(
      title: Text(widget.isNovo ? 'Novo $tipo' : 'Editar $tipo'),
      content: SizedBox(
        width: EspacosRelogio.larguraDialogoFicha,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: isIntervalo
                ? duracao
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: EspacosRelogio.gapGrande,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: EspacosRelogio.gapGrande,
                        children: [
                          Expanded(
                            child: CampoRotulado(
                              rotulo: 'Small blind',
                              controle: _smallBlind,
                              autofocus: true,
                              validar: (texto) =>
                                  validarInteiro(texto, minimo: 1),
                            ),
                          ),
                          Expanded(
                            child: CampoRotulado(
                              rotulo: 'Big blind',
                              controle: _bigBlind,
                              validar: (texto) =>
                                  validarBigBlind(texto, _smallBlind.text),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: EspacosRelogio.gapGrande,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CampoRotulado(
                                  rotulo: 'Ante',
                                  controle: _ante,
                                  validar: validarInteiro,
                                  isHabilitado: !_isAnteIgualSmallBlind,
                                ),
                                CheckboxListTile(
                                  title: const Text('Igual ao small blind'),
                                  value: _isAnteIgualSmallBlind,
                                  onChanged: _trocarAnteIgualSmallBlind,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ),
                          Expanded(child: duracao),
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
