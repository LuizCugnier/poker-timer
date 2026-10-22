import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logica/formatacao.dart';
import '../../modelos/configuracao.dart';
import '../../tema.dart';
import '../estrutura/estrutura_notifier.dart';
import '../estrutura/tela_estrutura.dart';
import '../fichas/fichas_notifier.dart';
import '../fichas/tela_fichas.dart';
import 'configuracao_notifier.dart';

// Menu de configurações: cada item novo do app entra aqui como mais um ListTile.
class TelaConfiguracoes extends ConsumerWidget {
  const TelaConfiguracoes({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estrutura = ref.watch(estruturaProvider);
    final fichas = ref.watch(fichasProvider);
    final configuracao = ref.watch(configuracaoProvider);
    final duracaoTotal = estrutura.niveis.fold(
      Duration.zero,
      (soma, nivel) => soma + nivel.duracao,
    );

    void abrir(Widget tela) {
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => tela));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        children: [
          ListTile(
            leading: const Icon(Icons.format_list_numbered),
            title: const Text('Estrutura de blinds'),
            subtitle: Text(
              '${estrutura.niveis.length} níveis · ${formatarTempo(duracaoTotal)}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => abrir(const TelaEstrutura()),
          ),
          ListTile(
            leading: const Icon(Icons.toll),
            title: const Text('Fichas'),
            subtitle: Text(
              fichas.isEmpty
                  ? 'Nenhuma ficha'
                  : fichas.map((f) => formatarValor(f.valor)).join(' · '),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => abrir(const TelaFichas()),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('Avisar antes da troca de nível'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      for (final minutos in Configuracao.opcoesAvisoMinutos)
                        FilterChip(
                          label: Text('$minutos min'),
                          selected: configuracao.avisosMinutos.contains(
                            minutos,
                          ),
                          onSelected: (_) => ref
                              .read(configuracaoProvider.notifier)
                              .alternarAviso(minutos),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    configuracao.avisosMinutos.isEmpty
                        ? 'Nenhum aviso: toca só na troca de nível.'
                        : 'O som de aviso toca nesses momentos antes de cada '
                              'troca, além do som da troca.',
                    style: const TextStyle(color: Tema.textoSecundario),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
