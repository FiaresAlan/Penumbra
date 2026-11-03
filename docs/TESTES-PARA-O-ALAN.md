# Testes para fazer no Studio (03/11/2026)

Tudo abaixo foi escrito e conferido só por leitura e por checagem de sintaxe (`tools/check_syntax.sh`: 0 erros em 124 arquivos). Onde o Output de uma sessão anterior mostrou o resultado, está escrito. Rode com o `rojo serve` ligado, o plugin conectado e o jogo parado ao sincronizar.

## Pontos para olhar com os olhos
| O quê | Como | Esperado |
|---|---|---|
| Caverna maior e irregular | QA: "Descer agora", depois "Foto + luz" e N | Salões redondos nos cruzamentos, teto alto com cúpulas, paredes que mudam de largura, colunas com base larga |
| Peças do 3TD (estalactites, rochas, samambaias) | Mesma foto | Estalactites penduradas, rochas no chão; podem estar pálidas (textura clara) |
| Névoa por zona | Andar da zona A à C | A âmbar, B violeta, C ciano |
| Pódio no fim | QA "Tela de fim" | Três tablados, coroa MVP, baú com raios |
| Abertura de 5 s | QA "Resetar perfil", parar e entrar | Título e 3 frases; "Pular" funciona |
| Momento de silêncio | Descer e esperar 90 a 240 s (ou baixe `Config.Silence.MinDelay`) | Aviso "Algo prende a respiração", depois escuro e "Não se mova"; só quem anda faz barulho |
| Desabamento (P4) | Descer e esperar 120 a 300 s (ou baixe `Config.RouteShift`) | Ronco, depois uma rocha fecha um corredor por 60 s; rode "Auditar caminhos" com ela no lugar (esperado 28 ok, 0 falhas, 3 só pelo gancho) |
| Condição da descida (P6/P9) | Olhar o texto ao lado do DESCER | Neblina, Ar limpo ou Brasas, com o lado bom e o ruim |
| Janela do elevador (P8) | "Chamar elevador" | Portas abertas de 30 a 40 s |
| Vulto da noite (P10) | Descer várias vezes | Em 1 de 6, um vulto azul na zona B, inofensivo |
| Cadeia e marcos (P12/P13) | QA "Simular extração" 3 vezes | "Sequência de 3 voltas: +20 XP" e frases de marco |

## Ideias desligadas (precisam de teste antes de ligar)
- **P5 Guardião que aprende** (`Features.LearningGuardian`): ligue, chame o Guardião (QA "Guardião perto"), faça barulho (tecla V) e fique parado. O Output deve mostrar "[Learning] lembrou um ponto" e, na volta, "visitou um ponto lembrado".
- **P11 Ecos de outro jogador** (`Features.EchoOthers`): precisa de 2 jogadores na caverna; o outro deve ouvir um passo distante quando um grita (tecla V).

## Caso algo atrapalhe
Todas as ideias se desligam em `Config.Features` (`src/shared/Config.lua`). A caverna padrão é a Mina; as outras mudam em `Config.ActiveCaveSite`.
