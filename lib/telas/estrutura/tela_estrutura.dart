import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logica/formatacao.dart';
import '../../logica/validacao.dart';
import '../../modelos/estrutura.dart';
import '../../modelos/nivel.dart';
import '../../tema.dart';
import '../componentes.dart';
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
    final editado = await editarNivel(context, _niveis[indice].nivel);
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
    final novo = await editarNivel(context, sugestao);
    if (novo == null) return;
    _mudar(() => _niveis.add((id: _proximoId++, nivel: novo)));
  }

  Future<void> _restaurarPadrao() async {
    if (!await perguntar(
      context,
      'Trocar todos os níveis pela estrutura padrão?',
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

  @override
  Widget build(BuildContext context) {
    // Intervalos não contam na numeração, como no relógio.
    final numeros = <int>[];
    for (final item in _niveis) {
      numeros.add((numeros.lastOrNull ?? 0) + (item.nivel.isIntervalo ? 0 : 1));
    }
    final duracaoTotal = _niveis.fold(
      Duration.zero,
      (soma, item) => soma + item.nivel.duracao,
    );

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
          title: const Text('Estrutura de blinds'),
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
        body: ReorderableListView.builder(
          buildDefaultDragHandles: false,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          itemCount: _niveis.length,
          onReorderItem: (de, para) =>
              _mudar(() => _niveis.insert(para, _niveis.removeAt(de))),
          itemBuilder: (context, i) {
            final nivel = _niveis[i].nivel;
            return ListTile(
              key: ValueKey(_niveis[i].id),
              leading: SizedBox(
                width: 48,
                child: Center(
                  child: nivel.isIntervalo
                      ? const Icon(Icons.coffee, color: Tema.intervalo)
                      : Text(
                          '${numeros[i]}',
                          style: const TextStyle(fontSize: 22),
                        ),
                ),
              ),
              title: Text(
                nivel.isIntervalo ? 'Intervalo' : descreverBlinds(nivel),
                style: TextStyle(
                  fontSize: 22,
                  color: nivel.isIntervalo ? Tema.intervalo : null,
                ),
              ),
              subtitle: Text('${nivel.duracao.inMinutes} min'),
              onTap: () => _editar(i),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remover',
                    onPressed: () => _mudar(() => _niveis.removeAt(i)),
                  ),
                  ReorderableDragStartListener(
                    index: i,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.drag_handle),
                    ),
                  ),
                ],
              ),
            );
          },
          footer: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _adicionar(isIntervalo: false),
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar nível'),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => _adicionar(isIntervalo: true),
                  icon: const Icon(Icons.coffee),
                  label: const Text('Adicionar intervalo'),
                ),
                const Spacer(),
                Text(
                  'Duração total: ${formatarTempo(duracaoTotal)}',
                  style: const TextStyle(color: Tema.textoSecundario),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
