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
- `audioplayers`: som de troca de nível e dos avisos com o app aberto
- Fonte Inter empacotada em `assets/fonts/` (400 a 800); nunca `google_fonts` nem fonte da internet
- `shared_preferences` com JSON: estruturas, fichas e o torneio em andamento.
  Trocar por `drift` só se o volume de dados justificar.

Antes de adicionar qualquer dependência nova, pergunte.

O build de release passa pelo R8 (encolhe e renomeia o código Java/Kotlin). Plugins que falam com
o Dart por JNI (hoje, `shared_preferences_android` 2.5+) precisam das classes com o nome original:
as regras ficam em `android/app/proguard-rules.pro`. Ao atualizar plugins, testar sempre também
com `flutter run --release`; o modo debug não passa pelo R8 e não mostra esse tipo de erro.

## Estrutura

```
lib/
  main.dart                 inicialização (orientação, wakelock, notificações, ProviderScope)
  theme/
    tema_relogio.dart       TODOS os tokens: CoresRelogio (2 modos), TiposRelogio, EspacosRelogio,
                            RaiosRelogio, DuracoesRelogio e o ThemeData das telas secundárias
  modelos/
    nivel.dart              Nivel(smallBlind, bigBlind, ante, duracao, isIntervalo)
    estrutura.dart          Estrutura(nome, niveis) + estrutura padrão de home game
    ficha.dart              Ficha(valor, cor, rotulo)
    torneio.dart            estado persistido do torneio (ver "Regra do relógio")
    configuracao.dart       preferências do app (ex.: antecedências dos avisos)
  logica/
    relogio_torneio.dart    funções puras: dado o torneio e "agora", calcula o estado exibido
    avisos.dart             avisos a agendar e som de cada transição (funções puras)
    formatacao.dart         valores (1.000) e tempo (mm:ss)
    validacao.dart          validadores dos formulários dos editores
  dados/
    repositorio.dart        salvar/carregar JSON no shared_preferences (torneio, estrutura, fichas)
  servicos/
    alarmes.dart            agenda/cancela notificações das trocas de nível
    sons.dart               som de troca e de 1 minuto com o app aberto
  telas/
    componentes.dart        diálogo de confirmação, campo com rótulo, bolinha de ficha
    relogio/                tela principal (a da mesa) e os providers de "agora" e do estado
    configuracoes/          menu de configurações (botão ⚙ no relógio); item novo = mais um card;
                            coresProvider (cores do modo escolhido)
    estrutura/              editor de níveis (uma estrutura salva, usada pelo próximo torneio)
    fichas/                 editor de fichas
test/
  apoio.dart                dublês (alarmes, sons, "agora" fixo), abrirApp e carregarFontes
  *_test.dart               lógica, persistência e a tela do relógio
  golden/                   golden tests 1280×800: 9 estados × 2 modos + 4 telas secundárias × 2
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

- Avisos antes da troca: antecedências escolhidas em Configurações (1, 2, 3, 5, 10 min; várias
  ou nenhuma; padrão 1 min). Um aviso só vale se for menor que a duração do nível que termina.
- Com o app na tela, quem avisa é `servicos/sons.dart` (troca de nível e os avisos antes),
  detectado entre dois redesenhos por `somDaTransicao`. Nenhuma notificação fica agendada,
  para não aparecer banner sobre o relógio nem som duplicado.
- Fora da tela o app não toca som (o `Timer` pode seguir rodando até o Android congelar o
  processo) e, ao voltar, ignora o que mudou enquanto estava fora.
- Ao sair da tela (`AppLifecycleListener.onHide`): agendar uma notificação para cada troca de
  nível futura, para o fim da estrutura e para os avisos antes de cada um
  (`zonedSchedule`, exato, em UTC). Ao voltar (`onShow`) e ao abrir o app: cancelar tudo.
- Permissões: `POST_NOTIFICATIONS` (Android 13+) e alarmes exatos (`SCHEDULE_EXACT_ALARM`);
  pedidas ao iniciar um torneio do zero, com explicação em português, se ainda faltarem.
  Sem alarme exato, agenda em modo inexato.
- Os sons existem em dois lugares: `assets/sons/` (audioplayers) e
  `android/app/src/main/res/raw/` (som dos canais de notificação, protegido do R8 por `keep.xml`).
  O som de um canal fica fixo depois de criado; para trocar, mude o id do canal.

## Design

Tablet de 10–11" na horizontal (1280×800 dp), tela cheia, lido a ~2 m em luz baixa.
Referências, que valem mais que qualquer layout anterior:
- `docs/ESPECIFICACAO.md`: medidas, estados e textos de cada tela;
- `docs/design/telas/` e `docs/design/telas_secundarias/`: imagens dos dois modos;
- `docs/design/Relogio.dc.html`: valores de cada estado (constantes `TEMAS`, `BASE`, `ESTADOS`).

Antes de mudar uma tela, leia a seção dela na especificação e a imagem correspondente.

### Regras obrigatórias
- **Tema em um só lugar.** Cor, tamanho de fonte, espaçamento, raio e duração vêm de
  `lib/theme/tema_relogio.dart`. Nada de `Color(0x…)`, `fontSize:` ou `EdgeInsets` com número
  fixo nos widgets; faltou um token, crie-o no arquivo de tema.
- **Dois modos**, `ModoRelogio.altoContraste` e `ModoRelogio.mesaCassino`, escolhidos em
  Configurações e salvos em `Configuracao.modo`. A cor sai de `ref.watch(coresProvider)` (ou do
  `Theme` nas telas secundárias); o widget nunca pergunta "qual é o modo" para escolher uma cor.
- **Algarismos tabulares em todo número:** `TiposRelogio.numero(...)` ou `TiposRelogio.numeros`.
- **Ícones:** só Material Icons, na variante `_outlined` quando existir (como no design).
- **O layout não pula.** Tempo, blinds e ante ficam em caixas de altura fixa (280, 124 e 60);
  sem ante, a caixa continua lá, vazia. `h:mm:ss` usa `tempoLongo`; blinds com mais de 13
  caracteres usam `blindsLongo`; os dois dentro de `FittedBox(fit: BoxFit.scaleDown)`.
- **Desempenho:** nada de `setState` na tela inteira. Cada parte da tela principal lê só o seu
  pedaço de `estadoRelogioProvider` com `select` (o texto do tempo reconstrói uma vez por
  segundo). Animações só de cor (`AnimatedContainer`, `AnimatedDefaultTextStyle`); nada de
  sombra, blur, gradiente animado ou `Opacity` animada. O pulso do último minuto anima só o
  fundo da área principal.
- **Luz baixa:** nada de branco puro em áreas grandes.
- **Toque:** alvos de no mínimo 48 dp; controles da tela principal com 60 dp; play 176×148.
- **Pular nível, voltar nível e reiniciar** abrem o diálogo de confirmação (`confirmar(...)` em
  `telas/componentes.dart`), com os valores reais do nível no texto.
- Valores no padrão brasileiro (1.000, 10.000), sem decimais.

### Golden tests
- `test/golden/` precisa continuar passando. Mudança visual intencional: `flutter test
  --update-goldens test/golden`, conferir as imagens novas contra as referências e dizer quais
  mudaram.
- Os dados dos goldens repetem os do `Relogio.dc.html` (estruturas de teste montadas para dar
  exatamente o Nível 11, 14:37 etc.); a estrutura padrão do app não precisa bater com o design.

## Convenções

- Nomes de classes, variáveis, funções e comentários em português, sem acentos nos
  identificadores (`nivelAtual`, `tempoRestante`). Exceção: booleanos usam o prefixo `is`
  (`isIntervalo`, `isRodando`), não `eh`.
- Lógica fora dos widgets; widgets só leem o estado e chamam métodos do notifier.
- Testes de lógica com `flutter_test`. Testes de widget para a tela do relógio; as telas
  secundárias são cobertas pelos golden tests.
- Comentários só para o que o código sozinho não deixa claro.
- Depois de mudanças grandes, rodar `flutter analyze` e `flutter test` antes de concluir.

## Roteiro

1. Modelos, lógica do relógio e testes
2. Persistência (torneio sobrevive ao fechamento do app)
3. Tela do relógio funcional com a estrutura padrão
4. Alarmes, sons e permissões
5. Editor de estrutura de blinds e editor de fichas
6. Design final (dois modos, seguindo `docs/ESPECIFICACAO.md`)

Fora do escopo por enquanto: controle de jogadores, rebuys, premiação, sincronização entre aparelhos.
