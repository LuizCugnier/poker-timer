import 'package:flutter/material.dart';

import '../tema.dart';

Future<bool> perguntar(
  BuildContext context,
  String pergunta, {
  String confirmar = 'Confirmar',
  String cancelar = 'Cancelar',
}) async {
  final resposta = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(pergunta, style: const TextStyle(fontSize: 24)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelar),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmar),
        ),
      ],
    ),
  );
  return resposta == true && context.mounted;
}

// Campo numérico usado nos editores de nível e de ficha.
class CampoNumero extends StatelessWidget {
  const CampoNumero({
    super.key,
    required this.rotulo,
    required this.controle,
    required this.validar,
    this.sufixo,
    this.autofocus = false,
  });

  final String rotulo;
  final TextEditingController controle;
  final FormFieldValidator<String> validar;
  final String? sufixo;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controle,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: rotulo, suffixText: sufixo),
      validator: validar,
    );
  }
}

class BolinhaFicha extends StatelessWidget {
  const BolinhaFicha({
    super.key,
    required this.cor,
    this.isSelecionada = false,
  });

  final int cor;
  final bool isSelecionada;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Tema.diametroFicha,
      height: Tema.diametroFicha,
      decoration: BoxDecoration(
        color: Color(cor),
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelecionada ? Tema.texto : Tema.bordaFicha,
          width: isSelecionada ? 4 : 2,
        ),
      ),
    );
  }
}
