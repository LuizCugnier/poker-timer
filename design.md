# Relógio de Poker: design visual da tela da mesa

## Contexto
Estou fazendo um app Android (Flutter) que serve de relógio para torneios de poker de **home game entre amigos**. Ele roda em um **tablet de 10–11" em pé na mesa, na horizontal** (cerca de 1280×800 dp), em tela cheia, sempre ligado, num ambiente de luz baixa, e é lido **a uns 2 metros de distância** por 6 a 10 jogadores, alguns olhando de lado. Ninguém fica segurando o tablet: o anfitrião encosta nos controles de vez em quando.

A lógica já está pronta. Preciso de uma **direção visual** para substituir o layout provisório. Toda a interface é em **português do Brasil**.

## Tela principal (a que mais importa)
Hierarquia, da mais forte para a mais fraca:
1. **Tempo restante do nível**: enorme, `mm:ss` (ou `h:mm:ss` quando passa de 1 hora). Algarismos de largura fixa, para os dígitos não "tremerem".
2. **Blinds atuais**: `500 / 1.000`, e embaixo `ANTE 100` quando houver.
3. **Nível atual** (`NÍVEL 11`) e **próximo nível** (`Próximo: 600 / 1.200 · ante 200`, ou `Próximo: intervalo`).
4. **Fichas**: coluna lateral com bolinha da cor + valor (ex.: branca 25, vermelha 100, verde 500, preta 1.000). Pode estar vazia.
5. **Tempo até o próximo intervalo**: `Intervalo em 47:12`.
6. **Controles**: configurações, reiniciar, nível anterior, −1 min, **iniciar/pausar** (o principal), +1 min, próximo nível. Precisam ser grandes para o toque e **discretos**, sem disputar atenção com o tempo. Pular nível e reiniciar abrem uma confirmação.

Valores sempre no padrão brasileiro, com ponto de milhar e sem decimais: `1.000`, `10.000`.

## Estados que o design precisa cobrir
- **Rodando**: estado normal.
- **Pausado**: o tempo fica apagado ou acinzentado e precisa ser óbvio de longe que o relógio está parado. Hoje é só uma cor cinza; pode ganhar um selo "PAUSADO".
- **Último minuto** (≤ 60 s): destaque forte, hoje o tempo fica vermelho. Avalie pulsar ou mudar o fundo, sem cansar a vista.
- **Intervalo**: no lugar dos blinds aparece **"INTERVALO"** com uma cor própria, sem número de nível, e o tempo mostra quanto falta para voltar.
- **Com ante e sem ante**: a altura do bloco muda; o layout não pode pular.
- **Valores longos**: `4.000 / 8.000` + `ANTE 1.000` precisam caber sem encolher demais.
- **Último nível** ("Último nível") e **fim da estrutura** (tempo parado em 00:00, "Fim da estrutura").
- **Sem fichas cadastradas**: a lateral some e o conteúdo ocupa a largura toda.

## Telas secundárias (prioridade menor, mesmo sistema visual)
- **Configurações**: lista com "Estrutura de blinds" (18 níveis · 6:20:00), "Fichas" (25 · 100 · 500 · 1.000) e "Avisar antes da troca de nível" (chips de 1, 2, 3, 5 e 10 min).
- **Editor de estrutura**: lista reordenável de níveis (blinds, ante e duração) e de intervalos, com os botões "Adicionar nível", "Adicionar intervalo", "Restaurar padrão" e "Salvar".
- **Editor de fichas**: lista de fichas e um diálogo com valor, nome opcional e uma paleta de 12 cores.
- **Diálogo de confirmação**: texto grande, "Cancelar" / "Confirmar".

Essas telas são usadas de perto, antes do jogo começar. Material 3 escuro, bem ajustado, já resolve.

## Restrições técnicas
- O app é escuro (fundo quase preto). Luz baixa, então nada de branco puro em áreas grandes.
- Contraste alto para leitura a 2 m: o tempo e os blinds precisam ser legíveis por quem enxerga mal.
- Todas as cores e tamanhos ficam num único arquivo de tema em Flutter. Entregue os **tokens** (cores em hex, tamanhos de fonte, espaçamentos, raios) com nomes claros para eu traduzir direto. O tema atual tem: `fundo`, `fundoLateral`, `texto`, `textoSecundario`, `pausado`, `ultimoMinuto`, `intervalo`, `controles`, `bordaFicha`, além de tamanhos para nível, blinds, ante, próximo, intervalo, ficha e ícones.
- Fonte: sugira uma fonte do Google Fonts com **algarismos tabulares** que eu possa empacotar como asset (sem depender de internet). Uma fonte só, ou no máximo duas.
- Ícones: Material Icons.
- Animações só se forem baratas (fade, mudança de cor). A tela redesenha a cada 250 ms, o dia todo.
- As cores das fichas são escolhidas pelo usuário (inclusive branca e preta), então a bolinha precisa aparecer bem sobre o fundo com qualquer uma delas.

## O que eu quero receber
1. **2 ou 3 direções visuais** diferentes para a tela principal (por exemplo: minimalista de alto contraste; "mesa de cassino" com feltro verde e dourado; painel tipo broadcast de TV), cada uma no estado **rodando com ante**.
2. Para a direção que eu escolher: todos os estados listados acima.
3. **Tokens de design** (tabela de cores, tipografia e espaçamento) prontos para virar o arquivo de tema em Flutter.
4. Uma proposta curta para as telas secundárias no mesmo estilo.

## Referências
- Relógios de torneio ao vivo (WSOP, EPT, Triton): números gigantes, poucas informações e nada de decoração.
- Apps de relógio de poker para tablet (Blinds Up, BlindClock, Poker Club HQ, The Tournament Director): a mesma hierarquia de tempo, blinds e próximo nível, além de presets de estrutura.
- Vou anexar screenshots de referência. Use como direção de hierarquia, não como modelo para copiar.

Comece pelas direções visuais da tela principal.
