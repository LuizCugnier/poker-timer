# Relógio de Poker · contexto do projeto

App Android (Flutter) para controlar torneios de **home game entre amigos**. Roda em um
**tablet em pé na mesa, na horizontal**, lido a uns 2 metros de distância por todos os jogadores.
Mostra o tempo restante do nível, os blinds atuais e os próximos, o número do nível e os valores das fichas.

É um projeto separado do Assistente de Poker em Python: não compartilham código.

O usuário fala português e conhece Flutter, mas não Kotlin. Responda em português. Toda a
interface e as mensagens ficam em português do Brasil. Se algo exigir código nativo
(Kotlin/Gradle), explique o que foi alterado e por quê.

## Comandos

```bash
flutter run                      # roda no tablet conectado (USB ou depuração sem fio)
flutter test                     # testes
flutter analyze                  # lint; manter sem avisos
flutter build apk --release      # versão para usar na mesa
flutter install                  # instala a release no tablet conectado
```

## Stack

- Flutter estável, Dart 3, **apenas Android**, minSdk 26
- Estado: `flutter_riverpod` (Notifier/StateNotifier simples; sem geração de código)
- `wakelock_plus`: tela sempre ligada enquanto o relógio estiver aberto
- `flutter_local_notifications` + `timezone`: alarmes agendados das trocas de nível
  (funcionam com o app em segundo plano ou com a tela apagada)
- `audioplayers`: som de troca de nível e aviso de 1 minuto com o app aberto
- `shared_preferences` com JSON: estruturas, fichas e o torneio em andamento.
  Trocar por `drift` só se o volume de dados justificar.

Antes de adicionar qualquer dependência nova, pergunte.

## Estrutura

```
lib/
  main.dart                 inicialização (orientação, wakelock, notificações, ProviderScope)
  modelos/
    nivel.dart              Nivel(smallBlind, bigBlind, ante, duracao, isIntervalo)
    estrutura.dart          Estrutura(nome, niveis) + estrutura padrão de home game
    ficha.dart              Ficha(valor, cor, rotulo)
    torneio.dart            estado persistido do torneio (ver "Regra do relógio")
  logica/
    relogio_torneio.dart    funções puras: dado o torneio e "agora", calcula o estado exibido
  dados/
    repositorio.dart        salvar/carregar JSON no shared_preferences
  servicos/
    alarmes.dart            agenda/cancela notificações das trocas de nível
    sons.dart
  telas/
    relogio/                tela principal (a da mesa)
    estrutura/              editor de níveis
    fichas/                 editor de fichas
test/
  modelos_test.dart
  relogio_torneio_test.dart
```

Os modelos são imutáveis, com `copyWith`, `toJson` e `fromJson` escritos à mão (sem freezed).

## Regra do relógio (a mais importante)

O tempo **nunca** é um contador decrementado por `Timer`. O torneio persiste apenas:

- `decorridoAcumulado` (Duration): tempo de jogo corrido até a última pausa
- `rodandoDesde` (DateTime?): quando o relógio foi retomado pela última vez; `null` = pausado

Tempo total de jogo = `decorridoAcumulado + (agora - rodandoDesde)` quando rodando.
O nível atual, o tempo restante e o próximo nível são **derivados** desse total, somando as
durações dos níveis. Consequências:

- Fechar o app, travar ou reiniciar o tablet não faz o tempo escorregar: ao reabrir, recalcula.
- Pausar = somar o trecho corrido em `decorridoAcumulado` e zerar `rodandoDesde`.
- Avançar/voltar nível manualmente = ajustar `decorridoAcumulado` para o início do nível alvo.
- Ajustar ±1 minuto = somar/subtrair do `decorridoAcumulado`, com limite em zero.
- O `Timer.periodic` da tela só serve para redesenhar (a cada ~250 ms); não guarda estado.
- Depois do último nível, o relógio para no último nível com tempo 00:00 (não quebra).

`logica/relogio_torneio.dart` recebe `agora` como parâmetro (nunca chama `DateTime.now()`
lá dentro), para os testes serem determinísticos. Todo comportamento dessa lógica tem teste.

## Alarmes

- Ao iniciar ou retomar: cancelar tudo e agendar uma notificação para cada troca de nível
  futura e para o aviso de 1 minuto antes de cada troca (`zonedSchedule`, exato).
- Ao pausar, pular nível ou ajustar tempo: cancelar e reagendar.
- Permissões: `POST_NOTIFICATIONS` (Android 13+) e alarmes exatos (`SCHEDULE_EXACT_ALARM`);
  pedir na primeira vez que o torneio for iniciado, com explicação em português.
- O `flutter_local_notifications` exige core library desugaring no
  `android/app/build.gradle.kts`.

## Tela do relógio (layout provisório; o design vem depois)

- Horizontal, fundo escuro, tela cheia (modo imersivo), tela sempre ligada.
- Hierarquia: **tempo restante** enorme > blinds atuais (e ante, se houver) > nível atual e
  próximo nível > fichas na lateral > tempo até o próximo intervalo.
- Últimos 60 segundos com destaque visual. Intervalo exibido como "INTERVALO", não como blinds.
- Controles grandes e discretos: iniciar/pausar, nível anterior/próximo, ±1 min. Ações que
  alteram o torneio (pular nível, reiniciar) pedem confirmação, porque alguém pode encostar sem querer.
- Valores formatados no padrão brasileiro com separador de milhar (1.000, 10.000), sem casas decimais.
- Cores e tamanhos em um único arquivo de tema, para a troca de design ser fácil.

## Convenções

- Nomes de classes, variáveis, funções e comentários em português, sem acentos nos
  identificadores (`nivelAtual`, `tempoRestante`). Exceção: booleanos usam o prefixo `is`
  (`isIntervalo`, `isRodando`), não `eh`.
- Lógica fora dos widgets; widgets só leem o estado e chamam métodos do notifier.
- Testes de lógica com `flutter_test`. Testes de widget só para a tela do relógio.
- Comentários só para o que o código sozinho não deixa claro.
- Depois de mudanças grandes, rodar `flutter analyze` e `flutter test` antes de concluir.

## Roteiro

1. Modelos, lógica do relógio e testes
2. Persistência (torneio sobrevive ao fechamento do app)
3. Tela do relógio funcional com a estrutura padrão
4. Alarmes, sons e permissões
5. Editor de estrutura de blinds e editor de fichas
6. Design final (feito depois com o usuário)

Fora do escopo por enquanto: controle de jogadores, rebuys, premiação, sincronização entre aparelhos.
