import 'package:flutter/material.dart';

import '../../logica/validacao.dart';
import '../../modelos/nivel.dart';
import '../componentes.dart';

// Devolve o nível editado, ou null se cancelar.
Future<Nivel?> editarNivel(BuildContext context, Nivel inicial) {
  return showDialog<Nivel>(
    context: context,
    builder: (context) => _DialogoNivel(inicial: inicial),
  );
}

class _DialogoNivel extends StatefulWidget {
  const _DialogoNivel({required this.inicial});

  final Nivel inicial;

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

  @override
  void dispose() {
    for (final controle in [_smallBlind, _bigBlind, _ante, _minutos]) {
      controle.dispose();
    }
    super.dispose();
  }

  void _salvar() {
    if (!_form.currentState!.validate()) return;
    final duracao = Duration(minutes: int.parse(_minutos.text.trim()));
    Navigator.pop(
      context,
      widget.inicial.isIntervalo
          ? Nivel.intervalo(duracao)
          : Nivel(
              smallBlind: int.parse(_smallBlind.text.trim()),
              bigBlind: int.parse(_bigBlind.text.trim()),
              ante: int.parse(_ante.text.trim()),
              duracao: duracao,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIntervalo = widget.inicial.isIntervalo;
    final duracao = CampoNumero(
      rotulo: 'Duração',
      sufixo: 'min',
      controle: _minutos,
      autofocus: isIntervalo,
      validar: (texto) => validarInteiro(texto, minimo: 1),
    );

    return AlertDialog(
      title: Text(isIntervalo ? 'Intervalo' : 'Nível'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: isIntervalo
                ? duracao
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CampoNumero(
                              rotulo: 'Small blind',
                              controle: _smallBlind,
                              autofocus: true,
                              validar: (texto) =>
                                  validarInteiro(texto, minimo: 1),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CampoNumero(
                              rotulo: 'Big blind',
                              controle: _bigBlind,
                              validar: (texto) =>
                                  validarBigBlind(texto, _smallBlind.text),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: CampoNumero(
                              rotulo: 'Ante',
                              controle: _ante,
                              validar: validarInteiro,
                            ),
                          ),
                          const SizedBox(width: 16),
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
        FilledButton(onPressed: _salvar, child: const Text('OK')),
      ],
    );
  }
}
