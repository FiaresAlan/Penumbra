# Plano de refino: mundo vivo, inventário e novas mecânicas

Versão 2, de 02/11/2026. Opus só planeja e pesquisa: não escreve código nem edita o Studio. Sonnet executa. Complementa `docs/PLANO-FASE-1.md`, que continua valendo para os Portões de teste com pessoas.

**O que mudou na versão 2:** floresta muito maior, casas e lojas em vez de tendas, assets oficiais da Synty e terreno gerado uma vez e salvo no lugar, em vez de a cada partida.

## 1. Onde o projeto está

| Item | Estado |
|---|---|
| Módulos M1 a M20 | Código pronto e testado **sozinho** no Studio |
| Item 5 do M11 (som abafado no lobby quando alguém é preso) | **Faltando**: `Rumble` só toca em `CaveClock` |
| 2 jogadores, microfone real, salvamento e clipes em servidor publicado | **Nunca testados** |
| Portões 1, 2 e 3 (4 pessoas reais) | **Nunca feitos** |
| Pontos menores da revisão | Abertos: seção R0 |

**Conclusão:** a primeira parte está construída, mas não validada. Ainda não sabemos se o medo funciona com pessoas.

## 2. Avaliação do que o Alan trouxe

| Fonte | Veredito | Por quê |
|---|---|---|
| [roblox-procedural-worlds](https://github.com/Gzeu/roblox-procedural-worlds) (gerador do GitHub) | **Não usar** | O `CaveSystem.lua` **não escava nada**: o próprio comentário do código diz que, por enquanto, só coloca cristais e lava nas células. Sem túnel real. A caverna é um passeio aleatório, que não garante caminho entre elevador, Ninho e núcleos. O `VillageGenerator` faz casas de Parts retas, justamente o que queremos abandonar. Licença MIT, 0 estrelas, um autor, ativo por 2 semanas. |
| [Synty Nature Pack](https://create.roblox.com/store/asset/6933438443/Synty-Nature-Pack) | **Usar: base da floresta** | Publicado por @Roblox, grátis, 96% de aprovação, licenciado para qualquer jogo Roblox. 200 MeshParts: árvores, plantas, arbustos, flores, troncos e pedras. Substitui o Kenney da versão 1. |
| `Blocky Cave.rbxl` | **Não como base; só peças** | Li o arquivo sem abrir no Studio: 1.157 objetos, 310 Parts, 82 MeshParts, 38 luzes, 19 partículas, **nenhum script**. Tem `Torch`, `Rock`, `Ore`, `Crystal` e `Waterfall`. É pequena, de estilo bloco, e não segue o labirinto de que o jogo depende. Vale tirar o minério, os cristais e a cachoeira, se ficarem bons ao lado da Synty. Autoria e licença desconhecidas. |
| [Creator Store](https://create.roblox.com/store/category) | **Usar com filtro** | Tem muita coisa grátis e também risco: seção 7. |

**Outros achados da pesquisa:**

- **Mais 5 pacotes oficiais da Synty**, também de @Roblox, grátis e no mesmo estilo:
  - [Cave & Castle Interiors](https://create.roblox.com/store/asset/6934021345/Synty-Dungeon-Pack-Cave-Castle-Interiors): caverna modular, rochas, runas, ponte e túneis.
  - [Basement & Goblin Camp](https://create.roblox.com/store/asset/6933905899/Synty-Dungeon-Pack-Basement-Goblin-Camp): trilhos de mina, plantas subterrâneas e acampamento.
  - [Skeletons & Bones](https://create.roblox.com/store/asset/6934081776/Synty-Dungeon-Pack-Skeletons-Bones): perfeito para o Ninho.
  - [Weapons & Props](https://create.roblox.com/store/asset/6933790012): objetos de cena.
  - [City Pack](https://create.roblox.com/store/asset/6933556508/Synty-City-Pack): tem fachadas de loja, mas urbanas e modernas. Não combina com o tema; só o teste de elenco dirá.
- **[roblox-runtime-terrain](https://github.com/maddoxbouldin/roblox-runtime-terrain)** (CC0, usa `WriteVoxels`): é um gerador melhor, mas suas cavernas são ruído 3D sem garantia de caminho e ele carrega pedaços em volta do jogador. Fica só como referência de técnica.
- **[Quaternius Medieval Village MegaKit](https://quaternius.com/packs/medievalvillagemegakit.html)** (CC0, FBX): mais de 300 peças modulares de vila. A versão Standard é a candidata. Plano B para as casas: dá mais trabalho, mas a licença é a mais limpa.

**Decisão sobre a caverna:** manter o nosso labirinto e esculpir em Terrain. Nenhum gerador pronto garante o que o jogo exige: caminho até tudo, zonas A, B e C, Ninho e elevador nos lugares certos.

## 3. Direção visual

**O mundo vira uma viagem, de leste a oeste:**

```text
oeste                                                                     leste
Mercado Negro  <--- mata fechada --->  VILA  <--- floresta --->  MINA E SPAWN | caverna
(escondido, ~70 s a pé)              (lojas, ~40 s a pé)        (elevador, baú)
```

- **Mina (X perto de 0):** spawn, torre do elevador, mural de destaques e quadro de pedidos. É o coração do ciclo.
- **Floresta:** grande, com colinas, riacho, ponte, clareiras e ruínas. Do alto de uma trilha, a torre da mina e o sino da vila servem de referência.
- **Vila (X perto de -640):** casas e lojas de verdade, em volta de uma praça: mercado, oficina com ferreiro, quadro de contratos, taverna e casas decorativas.
- **Mercado Negro (X perto de -1120):** uma cabana sem placa, no fim de uma trilha quase apagada. Encontrá-lo é a aventura.

**Caverna: três andares de medo.**

| Zona | Identidade | Chão e parede | Luz | Assets |
|---|---|---|---|---|
| A: Mina abandonada | Vigas, barris, trilhos | Terra e rocha | Tochas quentes, com falhas | Trilhos da Synty, KayKit |
| B: Galerias alagadas | Lama, poças, gotas | Ardósia, basalto e lama | Azul fraco, quase só a lanterna | Plantas subterrâneas da Synty |
| C: Jardim de cristal | Salões altos, cristais | Calcário escuro azulado | Cristais e fungos verdes | Runas e rochas da Synty |

**Atenção de design:** o Portão 2 pede menos de 1 minuto no lobby entre expedições. Andar 40 s até a loja é bom na primeira vez e cansativo na vigésima. Por isso, o módulo R9 traz corrida na superfície, carroça e chamada do grupo. O que é **obrigatório** para descer fica na mina; a floresta é onde se vai para comprar, vender e explorar.

## 4. Ordem recomendada

| # | Módulo | Risco | Resultado visível |
|---|---|---|---|
| 1 | R0 Pendências | Baixo | Nenhum |
| 2 | R1 Gerador em partes e botões de geração | Médio | Mapa visível no Studio sem Play |
| 3 | A1 Biblioteca e teste de elenco | Baixo | Prints para o Alan escolher as casas |
| 4 | **R2 Caverna em Terrain** | **Alto** | Paredes e chão orgânicos |
| 5 | R3 Identidade das zonas | Baixo | Cada zona com cara própria |
| 6 | **R4 Mundo: mina, floresta e vila** | **Alto** | Mapa grande, com colinas e trilhas |
| 7 | R5 Floresta densa | Médio | Mata de verdade |
| 8 | R6 Vila e construções | Médio | Lojas e casas |
| 9 | R9 Viagem e chamada do grupo | Médio | O mapa grande não atrapalha |
| 10 | I1 Tela de inventário | Baixo | Mochila abre |
| 11 | J1 Itens mudam de lugar | Baixo | Cada descida é diferente |
| | **Portão visual e Portão 1 com 4 pessoas** | | Decide o que vem depois |
| 12 | R7 Vida no mundo | Baixo | NPCs, pássaros, fumaça |
| 13 | R8 Caverna em desnível | Médio | Descer de verdade |
| 14 | I2, I3, I4 Soltar, arremessar, mochila visível | Médio | Inventário vira jogabilidade |
| 15 | J2 em diante | Varia | Conforme o Portão 1 |

**Por que parar no Portão 1:** cada mecânica nova custa caro e pode resolver o problema errado. O visual e a tela de inventário melhoram o teste sem mudar a regra que ele mede.

## 5. Cabeçalho comum dos prompts

Abra uma sessão nova com o Sonnet para cada módulo e cole o texto abaixo, seguido do prompt do módulo:

```text
Use a skill ecos-da-penumbra e leia CLAUDE.md. Implemente o módulo indicado de docs/PLANO-REFINO.md, seguindo a seção 6 (Terrain e geração) se tocar no mapa e a seção 7 (assets) se usar assets.
Autorização do Alan: use o rojo serve (inicie se estiver parado e conecte o plugin), o Roblox Studio e o painel QA via Computer Use, limitado a Studio, VSCode e GitHub. O lugar agora é "Ecos da Penumbra | Servidor de Desenvolvimento", com edição ao vivo: não publique para jogadores. Teste você mesmo seguindo o "Teste" do módulo. Com o Output sem erros novos, faça o commit de um módulo por vez. Não dependa do Alan para nada que você possa fazer.
Só edite os arquivos que o módulo cita, mais Config.lua, Enums.lua, QACommands.lua e os init quando precisar. Não invente API: se tiver dúvida, consulte a documentação oficial. Toda regra de jogo fica no servidor. Se precisar quebrar algo da Fase 1, pare e explique. No fim, diga em linguagem simples o que mudou, o que foi testado, o que não foi, e mande um print.
```

## 6. Terrain e geração

**Mudança da versão 2: o cenário é gerado uma vez e salvo no lugar.** Com uma floresta deste tamanho, gerar a cada partida faria todo servidor demorar para abrir. O Refúgio já fazia assim no mapa grande.

| O quê | Quando é criado | Onde fica |
|---|---|---|
| Terrain, árvores, pedras, casas, decoração | Uma vez, por botão no Ecos Tools, no modo de edição | `workspace.Terrain` e `workspace.WorldBaked`, salvos no lugar |
| Núcleos, elevadores, bancadas com prompt, marcadores, Guardião | A cada partida, pelo `MapBuilder` | Attribute `Generated`, como hoje |

Regras:

- Os scripts que geram o cenário ficam no Git e são a fonte da verdade. O resultado fica no lugar.
- A geração recusa rodar com o jogo em andamento (`RunService:IsRunning()`), como no `RebuildAll` do Refúgio. O botão usa uma cópia do módulo (`Clone`), para sempre pegar o código atual.
- `Terrain:Clear()` só existe na geração por botão, **nunca** em uma partida. Grave `WorldVersion` como Attribute do Workspace. Na partida, se a versão não bater com `Config.WorldVersion`, avise em vermelho no Output.
- `clearPrevious` não pode tocar em `WorldBaked`, que não tem `Generated`.
- O botão **Prévia** cria as peças de jogo no modo de edição, para o Alan ver o mundo sem Play. **Limpar prévia** remove. O Play limpa sozinho, pois elas têm `Generated`.
- Depois de gerar, salve o lugar. Exporte uma cópia de `WorldBaked` para `tools/assets/` se o tamanho permitir.

**Forma da caverna.** A grade do labirinto continua sendo a fonte da verdade.

- `src/server/world/CaveShape.lua`: funções puras, sem criar nada, usadas tanto na geração quanto na partida:
  - `IsOpen(x, z)`: desloque `x` e `z` com `math.noise` (no máximo `Config.CaveWarp` = 4 studs, frequência perto de 1/24) e só então consulte a célula. As paredes de 16 studs nunca abrem passagem nova com esse limite.
  - `FloorAt(x, z)`: `FLOOR_Y` mais ruído de até ±2 studs.
  - `CeilingAt(x, z)`: chão + `WALL_H` mais ruído de até ±3. **O vão nunca pode ficar abaixo de 13 studs**, porque o Guardião tem `AgentHeight` 9.
- Áreas planas: ruído de altura zero com transição suave em volta do elevador, de `CaveArrival`, de `PitySpawnPoint`, dos `NestSlots` e das salas com saliência de gancho.
- Suavidade: amostre `IsOpen` em 4 pontos por voxel horizontal, para obter ocupação parcial. A ocupação final é o maior valor entre parede, chão e teto.
- Rocha sólida com pelo menos 12 studs em volta de tudo.
- A caverna fica onde está (X a partir de 420). A superfície cresce **para oeste**, sem encostar nela.

**Escrita.** `Terrain:WriteVoxels` com resolução 4, em blocos de 32 voxels e regiões alinhadas à grade de 4 studs, com `task.wait()` entre blocos. Registre o tempo no Output.

**Materiais.** `Terrain:SetMaterialColor` muda a cor do material no mundo inteiro. Então cada material pertence a um lugar só:

| Lugar | Materiais |
|---|---|
| Superfície | `Grass`, `LeafyGrass`, `Mud` (trilha), `Sand` (margem), `Rock` (montanha) |
| Zona A | `Ground`, `Cobblestone` |
| Zona B | `Slate`, `Basalt`, `Pavement` (como lama escura) |
| Zona C | `Limestone`, `Salt` |
| Zonas de Fúria | `CrackedLava` |

**Encaixe.** Nada usa mais `FLOOR_Y` direto para posicionar: use `FloorAt`, `CeilingAt` e, na superfície, `HeightAt`. Marcadores do jogo seguem invisíveis e com os mesmos nomes.

**Grama animada.** A documentação em inglês diz que `Terrain.Decoration` pode ser alterada por script, e as páginas traduzidas dizem que não. O Refúgio usa `pcall`. Faça o mesmo e confira o valor. Se não mudar, ligue a propriedade no Studio e salve o lugar.

**Orçamento da floresta** (o caminho oficial é medir, não adivinhar):

| Item | Limite inicial |
|---|---|
| Árvores | 2.500 |
| Detalhes (flores, arbustos, pedras) | 3.000 |
| Colisão | Só uma Part invisível no tronco. Copa e detalhes com `CanCollide`, `CanTouch` e `CanQuery` falsos |
| Sombra | Só em árvores grandes |

- Use `Clone` de um mesmo modelo, com `CollisionFidelity` Box nas peças que colidem. Evite Union: prefira MeshPart.
- Mantenha `StreamingEnabled`. Ajuste a névoa para esconder o carregamento distante.
- `RenderFidelity` Automatic não é garantia: há relatos de árvores mudando de detalhe perto demais. Compare com o MicroProfiler (Ctrl+F6).
- **Se o celular sofrer, corte árvores antes de cortar o tamanho do mapa.**

## 7. Regras de assets

Roblox avisa que assets da Creator Store podem conter scripts maliciosos e que a moderação não garante remover todos. A popularidade também não garante segurança.

1. **Prioridade:** (1) @Roblox/Synty; (2) pacotes CC0 importados por nós (KayKit, Quaternius); (3) outros criadores da loja, só com o filtro abaixo.
2. **Teste de script:** a página informa "Contém scripts" e a contagem. Prefira modelos sem scripts.
3. **Nenhum script entra no jogo.** Antes de usar um modelo, inspecione no lugar de teste e apague todo `Script`, `LocalScript`, `ModuleScript` e qualquer objeto estranho. Rode um comando de auditoria que falha se `WorldBaked` ou `ServerStorage.EcosAssets` tiverem scripts.
4. **Nunca inserir direto no lugar do jogo:** primeiro em um lugar vazio separado.
5. **Peso:** veja a contagem de partes e triângulos. Evite Unions e milhares de Parts.
6. **Crédito:** registre autor e link em `docs/CREDITOS.md`. Respeite pedidos como "credit if you use".
7. **Sem marcas e personagens de outras obras** nos modelos (Attack on Titan, por exemplo): há vários nos resultados de busca.

**Licença da Synty:** a loja diz que os pacotes foram licenciados para qualquer jogo Roblox, e o anúncio de 2021 diz que podem ser usados em qualquer criação dentro do Roblox. Isso vale dentro do Roblox: não extraia esses modelos para outros lugares.

**Candidatos para as casas** (só vi as páginas da loja, não os modelos em si; a escolha é por print, no A1):

| Modelo | Criador | Dados da loja | Observação |
|---|---|---|---|
| [Village House](https://create.roblox.com/store/asset/8915687805/Village-House) | @TannyTzx9 | 96%, 40+ votos, 12,5 mil triângulos | **Melhor sinal até agora** |
| [Medieval House With Shop](https://create.roblox.com/store/asset/5050401777/Medieval-House-With-Shop) | @Zivick0 | 4,2 mil triângulos, sem interior, sem avaliações | Leve; candidato a loja |
| [Blacksmith](https://create.roblox.com/store/asset/8162056813/Blacksmith) | @HolyBlack_Phantom | 8,2 mil triângulos, **2 scripts**, sem avaliações | Candidato à oficina, sem os scripts |
| [Casas Medievales](https://create.roblox.com/store/asset/110321397681966/Casas-Medievales-Paquete-House-Village-Town-Shop) | @Matubono67 | 13 modelos, sem scripts segundo o autor, 6.336 partes, 259 Unions | Vila pronta, mas **pesada** e sem avaliações |
| [tent market stall](https://create.roblox.com/store/asset/10970560969/tent-market-stall) | Não conferido | 100% | Barraca da praça |
| Quaternius MegaKit | Quaternius | CC0, mais de 300 peças | **Escolhido (Rota 2, 02/11/2026)**: 69 peças importadas e testadas, ver `docs/ELENCO-ASSETS.md` seção 6 |

## 8. Bloco R: mundo

### R0. Pendências

**O que faz:** fecha o que sobrou antes de mexer no mundo.

**Teste:** ciclo completo no painel QA. Force um sequestro e confira a mensagem do Ninho. Pare o jogo e confira no Output que nada novo apareceu.

```text
Módulo R0.
1. NestSystem e NestUI: cada preso recebe o próprio tempo; quem deixou de estar preso recebe limpeza da mensagem.
2. NestSystem: remova o reforço de ruído do resgate ao remover o preso; valide no servidor o tempo mínimo segurando (Config.RescueHoldTime).
3. Tecla V: só no Studio ou para quem não tem microfone. No servidor, limite o VoiceSpike vindo de quem tem AudioDeviceInput ativo se isso for viável; se não for, explique.
4. M11 item 5: quando alguém virar Captive, jogadores no Lobby ouvem Rumble via WorldAudio, sem posição.
5. Coloque --!strict nos arquivos que ainda não têm, corrigindo os erros de tipo que aparecerem, sem mudar comportamento.
6. DeceiverGuardian: troque os números 580 e 724 por valores do Config.
7. Atualize a seção de estrutura do CLAUDE.md e a nota de PLANO-FASE-1.md sobre ProfileStore (o perfil usa código próprio). No CLAUDE.md, registre que o cenário é gerado por botão e salvo no lugar.
8. Mova "Blocky Cave.rbxl" da raiz para tools/assets/referencia/ e confirme que .gitignore cobre arquivos .rbxl, sem versionar o arquivo.
```

### R1. Gerador em partes e botões de geração

**O que faz:** divide `MapBuilder.lua`, de 923 linhas, sem mudar a partida, e cria os botões do plugin. Resolve a surpresa de abrir o Studio e ver o mapa vazio.

**Teste:**
1. O mapa de jogo fica idêntico (mesma contagem de partes no Output, mesma posição de núcleos), e um ciclo completo roda sem erro.
2. Reinicie o Studio se preciso. Na aba Plugins, **Prévia** mostra o mapa sem Play. **Limpar prévia** remove.
3. Dê Play com a prévia ainda na tela: nada duplica.
4. Rode **Auditar caminhos** e guarde o resultado como referência.

```text
Módulo R1. Siga a seção 6. Nenhum efeito visual ou de jogo na partida.
1. Divida src/server/world/MapBuilder.lua em módulos --!strict em src/server/world/: CaveLayout (grade e funções puras: IsOpenCell, zoneOf, cellCenter, retângulos especiais), Lobby, Forest, CaveGeometry, CaveDecor, CaveMarkers, Props. MapBuilder.Build() só chama os módulos, na mesma ordem e com os mesmos geradores aleatórios, para o mapa sair idêntico.
2. Antes de dividir, registre no Output a contagem de partes e as posições dos núcleos; confira que são iguais depois.
3. Props: crie cada mesh uma única vez com CreateMeshPartAsync e use Clone nas demais cópias.
4. Crie src/server/world/WorldBake.lua, por enquanto com Preview() e ClearPreview(), recusando rodar com o jogo em andamento. Consulte C:\Users\Administrador\Desktop\refugio\src\mapgen\RebuildAll.luau para a técnica de cópia sem cache.
5. Plugin Ecos Tools (plugin/src/init.server.lua): botões "Prévia" e "Limpar prévia", que chamam esse módulo. Refaça o build do plugin. Deixe fácil somar os botões "Gerar caverna" e "Gerar mundo" nos próximos módulos.
6. Novo comando QA "Auditar caminhos" (QACommands e Config.QAButtons): com PathfindingService e os parâmetros de agente do Guardião, calcula o caminho de CaveArrival até cada núcleo, relíquia, NestSlot e o elevador. Imprime [Audit] OK ou FALHOU com o nome de cada destino e um total. Ignore os alvos em saliências de gancho, marcando-os como "gancho".
```

### A1. Biblioteca e teste de elenco

**O que faz:** traz os pacotes para um lugar seguro, compara os estilos e deixa o Alan escolher por imagem, antes de construir a vila.

**Teste:** a auditoria não acha scripts na biblioteca. O Alan recebe a folha de prints e responde quais casas quer. **Este é o único ponto do plano que espera o Alan.**

```text
Módulo A1. Siga a seção 7. Não insira nada no lugar do jogo ainda.
1. Em um lugar vazio separado, pela Toolbox, insira os 5 pacotes Synty da seção 2 (Nature, Cave & Castle Interiors, Basement & Goblin Camp, Skeletons & Bones, Weapons & Props) e, para comparar, as candidatas de casa da seção 7, o City Pack e a pasta de peças de tools/assets/referencia/Blocky Cave.rbxl.
2. Em cada um, liste e apague scripts e objetos suspeitos, e anote partes, triângulos e scripts encontrados.
3. Monte uma cena de comparação com personagem padrão para escala, ao entardecer e sobre grama. Tire prints de cada casa, de um bosque Synty e das peças de caverna.
4. Gere docs/ELENCO-ASSETS.md com os prints, os números e a sua recomendação: uma casa para cada função (mercado, oficina, contratos, taverna, 3 casas comuns, cabana do Mercado Negro). Marque o que não combina. Se nada servir para as casas, recomende o Quaternius MegaKit, que deve ser importado como o KayKit.
5. Com a escolha do Alan, leve só as peças aprovadas, sem scripts, para ServerStorage.EcosAssets (subpastas Nature, Cave, Village) no lugar do jogo. Crie o comando "Auditar assets", que falha se houver script ali. Atualize docs/CREDITOS.md.
```

### R2. Caverna em Terrain

**O que faz:** troca paredes, chão e teto de Parts por Terrain esculpido e ajusta tudo que dependia do chão plano. É um dos módulos mais arriscados.

**Teste:**
1. O botão **Gerar caverna** termina, e o Output mostra o tempo. Dê Play sem gerar de novo: a caverna continua lá, e o jogo abre sem demora extra.
2. **Auditar caminhos** sem novas falhas em relação ao R1.
3. Use **Ir a um prop** e **Ir ao elevador**: nada enterrado, nada flutuando, nenhuma luz de céu.
4. Guardião vai de casa até você e te arrasta até o Ninho.
5. **Perto do gancho** seguido do gancho: você chega na saliência.
6. Com Enganador: núcleos e paredes falsas aparecem em lugar válido. Com Corista: a voz vem de um corredor.
7. Ciclo completo duas vezes seguidas, para ver que o reinício da expedição não quebra nada.

```text
Módulo R2. Siga a seção 6.
1. Crie src/server/world/CaveShape.lua (puro) e src/server/world/CaveTerrain.lua com Build. WorldBake ganha BakeCave, com botão "Gerar caverna" no plugin. Pare de criar as Parts Floor, Ceiling e Wall. Use um só material por enquanto; a identidade por zona é o R3.
2. O MapBuilder não mexe no Terrain. Ele avisa se WorldVersion estiver errado ou ausente.
3. Ajuste para FloorAt e CeilingAt: núcleos e relíquias, espinhos, pedras, cristais, pilares, vigas da zona A, props, tochas, lâmpadas, poças, gotas, poeira, elevador, CaveArrival, PitySpawnPoint, FuryZones, rachaduras, NestSlots, marcas do Ninho e o Guardião.
4. Remova as WallRock: o Terrain já quebra a parede.
5. Paredes falsas do Enganador: aumente a largura em 8 studs para entrarem no Terrain e não deixarem fresta.
6. FloorPicker: aceite Normal.Y acima de 0.7 e descarte pontos onde CaveShape.IsOpen for falso, para nada nascer dentro da rocha.
7. HookSystem: confirme que a linha de visão continua funcionando com Terrain. Saliências: mantenha as Parts, com teto ao menos 10 studs acima delas. A altura de 10 studs continua fora do alcance de um pulo; confira.
8. Se o Guardião travar, ajuste CaveWarp e o vão antes de mexer na IA. Não mude os estados nem a captura do Guardião.
```

### R3. Identidade das zonas

**O que faz:** dá material, cor, luz e peças próprias a cada zona, e troca os cubos de luz.

**Teste:** tire um print em cada zona e no Ninho. As três precisam ser reconhecíveis sem o HUD. **Auditar caminhos** segue sem falhas: as peças novas não podem bloquear corredor. O Output registra o número de luzes.

```text
Módulo R3. Siga as seções 6 e 7.
1. CaveTerrain: aplique os materiais de cada zona, com SetMaterialColor. Transição com ruído entre zonas, não em linha reta. Manchas de lama por ruído na zona B e veios de Salt na zona C.
2. Zonas de Fúria: pinte CrackedLava no chão, por ruído, e remova as FuryCrack retangulares. O jogador ainda precisa reconhecer a área.
3. Ninho: pinte Ground escuro, troque NestMark por manchas irregulares e use ossos do pacote Skeletons & Bones. Os NestSlots continuam claros para o preso e para quem resgata.
4. Luz: remova CaveLamp. Zona A usa torch_lit dos props em paredes, várias com falha (cliente, uma única rotina para todas). Zona B usa poucas luzes azuis fracas. Zona C usa cristais e fungos em cachos irregulares. Limite: Config.CaveMaxLights = 60 luzes no total.
5. Peças em EcosAssets.Cave, geradas com o botão e salvas em WorldBaked: trilhos e carrinhos na zona A, plantas subterrâneas na zona B, rochas e runas na zona C. Encoste nas paredes; nada no meio do corredor, com colisão simples.
6. Depois de escolher as cores, confira cada zona com a lanterna ligada e desligada. A zona B precisa ser escura sem virar tela preta.
Arquivos: CaveTerrain.lua, CaveDecor.lua, Props.lua, WorldBake.lua, ZoneLighting.lua se precisar ajustar a atmosfera.
```

### R4. Mundo: mina, floresta e vila

**O que faz:** troca as lajes por um mapa grande de Terrain. As bancadas mudam de lugar, mas mantêm os nomes.

**Teste:**
1. Do spawn, siga a trilha até a vila e cronometre: cerca de 40 s andando. Depois até o Mercado Negro: mais 30 s, com a trilha mais apagada.
2. Use os prompts de cada ponto: distância e tela continuam funcionando.
3. Procure o fim do mundo: montanhas e névoa escondem a borda, e você não consegue sair.
4. Desça e volte: `LobbyArrival` não te deixa enterrado.
5. Reinicie o Studio e dê Play: tudo continua lá, sem gerar de novo.

```text
Módulo R4. Siga a seção 6. O teste de tempo manda mais do que os números abaixo; ajuste se preciso.
1. Crie src/server/world/SurfaceShape.lua (puro: HeightAt, MaterialAt, TrailDistance) e SurfaceTerrain.lua (Build). WorldBake ganha BakeWorld, com botão "Gerar mundo". Pode consultar C:\Users\Administrador\Desktop\refugio\src\mapgen\TerrainGen.luau como técnica, sem copiar biomas.
2. Área: X de -1400 a 380, Z de -600 a 600. Sem encostar no bloco da caverna (X 420).
3. Altura: colinas por ruído, de até 25 studs na floresta e suaves perto das trilhas; borda de montanhas de 100 a 180 studs, alta para ninguém subir e irregular para não parecer muro.
4. Áreas planas (Config.WorldPads), com transição suave: Mina em X próximo de 0, na altura atual do piso, para LobbyElevator e os demais marcadores seguirem funcionando; Vila em X próximo de -640; Mercado Negro em X próximo de -1120, deslocado para fora da linha reta.
5. Trilhas de Mud com curvas: mina até vila, larga; vila até Mercado Negro, estreita e cada vez mais apagada, com material misturado. Ramais curtos até 3 clareiras (ruína, lago e acampamento abandonado), sem nada obrigatório.
6. Riacho raso de norte a sul entre a mina e a vila, atravessado por uma ponte na trilha. Margens de Sand.
7. Lobby.lua e Forest.lua: mova LobbyMarket, LobbyWorkshop, LobbyBoard e RelicDisplays para a vila, e BlackMarketStall para o seu ponto. HighlightsWall, OrdersBoard, LobbyElevator e o baú ficam na mina. Mantenha nomes e prompts; use os mesmos sistemas de raio. As aparências entram no R6; por enquanto, use as peças atuais encaixadas no chão.
8. Remova LobbyFloor, ForestGround e as árvores de cilindro e bola. O SpawnLocation fica invisível e sem decal.
9. Confira AmbientAudio, ZoneLighting e TutorialHints: pássaros na mina e na vila, insetos e luz mais baixa na mata; fim de tarde (ClockTime perto de 16.8) e névoa nas montanhas. A superfície continua claramente mais clara e segura que a caverna.
10. Confira MovementGuard e LocationSync com as novas distâncias. QACommands: "Ir ao mercado" e similares continuam funcionando; acrescente "Ir à vila".
```

### R5. Floresta densa

**O que faz:** a mata de verdade, com o Synty Nature Pack. A sensação de aventura vem de trechos fechados que se abrem em clareiras.

**Teste:**
1. Do spawn, todas as direções têm profundidade: trilha, árvores perto, árvores longe, montanha.
2. Trilhas livres. Você não fica preso em galhos.
3. Perto do Mercado Negro a mata fica fechada e escura.
4. O Output mostra a contagem de cada tipo, dentro do orçamento.
5. Em Device Emulator e no MicroProfiler, compare com o jogo antes da floresta e registre os números.
6. **Auditar assets** sem scripts.

```text
Módulo R5. Siga as seções 6 e 7. Depende do A1.
1. Crie src/server/world/SurfaceDecor.lua, chamado pelo BakeWorld, usando Clone de EcosAssets.Nature e gravando em workspace.WorldBaked.Forest, dividido por regiões (Models por região, para ajudar o streaming). Use Random com seed fixa. Consulte a técnica de densidade e encaixe de C:\Users\Administrador\Desktop\refugio\src\mapgen\BuildNature.luau, sem copiar seus limites.
2. Densidade por ruído: bosques fechados e clareiras, com mata cada vez mais fechada a oeste. Nada a menos de 8 studs de trilha ou em área plana, exceto detalhes pequenos, nem em encosta muito inclinada.
3. Árvores variam em tamanho (fator 0.8 a 1.6) e rotação. Algumas gigantes marcam o caminho.
4. Detalhes em manchas, não espalhados de modo uniforme: flores nas clareiras, cogumelos e troncos na sombra, pedras nas encostas, arbustos na beira da trilha.
5. Aplique o orçamento da seção 6. Registre triângulos e partes. Se o celular ficar ruim, corte árvores até ficar fluido e informe o número final.
6. Clareiras do R4: acrescente ruína (peças Synty de pedra), lago com pedras e acampamento abandonado com cena de abandono. Só decoração nesta etapa.
```

### R6. Vila e construções

**O que faz:** as tendas e caixas viram casas e lojas de verdade, conforme a escolha do Alan no A1.

**Teste:** sem ler nada, dá para distinguir mercado, oficina, contratos, taverna e Mercado Negro a 30 studs. Todos os prompts funcionam. Você não fica preso em nenhuma peça. **Auditar assets** sem scripts.

```text
Módulo R6. Siga as seções 6 e 7, usando as casas aprovadas no docs/ELENCO-ASSETS.md e EcosAssets.Village. Depende do A1 e do R4.
1. Praça da vila com chão de pedra, poço, bancos, lampiões, carroças, barracas e casas ao redor, em ângulos variados, nunca em grade. Gravada em WorldBaked.Village pelo BakeWorld.
2. Mercado, oficina e contratos: LobbyMarket, LobbyWorkshop e LobbyBoard viram balcão, bancada e quadro na entrada de cada loja, mantendo nome, prompt e função. O jogador usa o prompt do lado de fora, sem precisar entrar. Uma placa de madeira com ícone identifica cada uma.
3. RelicDisplays: vitrine na oficina. Mural e quadro de pedidos seguem legíveis.
4. Taverna e casas: decoração. Se uma casa não tiver interior, feche a porta. Colisão simples (Box) em tudo que for possível.
5. Mina: torre de madeira (treliça de Parts inclinadas, roda no topo, cabos) sobre o poço do elevador, cerca, trilhos, barracão e baú. O painel de estado do elevador segue visível de longe.
6. Mercado Negro: cabana torta e escondida, tecido escuro, lanterna fraca, sem placa.
7. Lampiões em estacas de madeira ao longo das trilhas da vila. Pequenas rotações em postes e tábuas para nada parecer reto.
Arquivos: Lobby.lua, Forest.lua, Props.lua, Assets.lua, WorldBake.lua, módulo novo Village.lua.
```

### R9. Viagem e chamada do grupo

**O que faz:** evita que o mapa grande quebre o ritmo e separe o grupo. Sem isso, quem estiver na vila quando o grupo descer fica de fora por até 15 minutos.

**Teste:**
1. Shift na superfície corre mais rápido; na caverna não muda nada.
2. Vá à vila a pé: a carroça da vila libera. Use: chega à mina em poucos segundos, com tela de transição. Tente sem ter descoberto: recusado.
3. Com 2 jogadores em **Clients and Servers**, A aciona o elevador enquanto B está na vila: B recebe aviso e pode voltar de carroça a tempo. O Output confirma que o servidor validou tudo.
4. Se todos já estão no elevador, a descida usa os 10 s de hoje.

```text
Módulo R9. Consulte roblox-dev:roblox-security.
1. Corrida só na superfície: Shift aumenta WalkSpeed para Config.SurfaceRunSpeed = 26, aplicado pelo servidor apenas em quem está em Lobby. Volta ao normal ao descer. SneakInput e SneakSystem não mudam. Botão no celular. Confira que o MovementGuard aceita essa velocidade.
2. Carroças nos pontos Mina e Vila, com ProximityPrompt. Só o servidor teleporta (PivotTo), com MovementGuard.Exempt e a transição de ZoneLighting. Fica em Lobby. Cooldown de Config.CartCooldown = 10 s e sem custo. O destino Vila precisa ter sido descoberto: guarde discoveredVillage no perfil, com migração para perfis antigos, marcado ao entrar na área.
3. Mercado Negro sem carroça: a caminhada é o preço de achar os pedidos.
4. Chamada do grupo: ao acionar LobbyElevator, se houver jogador em Lobby fora do raio, a contagem passa a Config.DescentCountdownFar = 30 s, em vez de 10, e cada um deles vê "O grupo vai descer" com o tempo e botão para usar a carroça da mina, mesmo sem estar perto dela, durante a contagem. O botão apenas pede: o servidor confere fase, estado e cooldown.
5. Placas nas bifurcações da trilha. Bússola simples no HUD só na superfície, com mina e vila, nunca o Mercado Negro.
Arquivos: ExpeditionSystem.lua, MovementGuard.lua, PlayerProfile.lua, ExtractionUI.lua ou módulo novo TravelSystem.lua e TravelUI.lua.
```

### R7. Vida no mundo (depois do Portão 1)

**O que faz:** coisas que se mexem. Tudo só visual e no cliente, salvo os NPCs.

**Teste:** fique parado 60 s na vila: algo acontece à sua volta. Com a câmera na caverna, nada da superfície consome processamento. Em Device Emulator de celular, o jogo continua fluido.

```text
Módulo R7. Crie src/client/WorldLife.lua, ativo só com o jogador na superfície e perto do efeito.
1. Bando de pássaros em voo ocasional, formado por poucas Parts ou meshes simples; fumaça com ParticleEmitter nas chaminés e fogueiras; vaga-lumes na mata; folhas caindo em alguns pontos; nuvens com a instância Clouds, se disponível.
2. Servidor: NPCs (mercador, ferreiro, capataz de contratos, taverneiro, 2 ou 3 moradores andando na praça com trajeto curto, e um vulto encapuzado no Mercado Negro), criados como o Guardião e com animação. Sem novo prompt: o prompt continua na bancada. Balão de fala curto ocasional no cliente, de uma lista em Config, que pode comentar a caverna.
3. Animais pequenos na floresta: coelhos ou cervos que fogem quando o jogador se aproxima.
4. Caverna, no cliente: morcegos que fogem quando o jogador passa perto de alguns pontos, e poeira caindo quando o Guardião passa perto. Isso é decoração e não informa posição além do que a presença já informa.
5. Pare e destrua os efeitos ao entrar na caverna, e o inverso ao voltar. Sem vazamento de conexões.
```

### R8. Caverna em desnível (depois do Portão 1)

**O que faz:** cada zona fica mais funda, e a câmara final vira um salão enorme. Vai depois do Portão para não mudar o equilíbrio durante o teste.

**Teste:** **Auditar caminhos** sem falhas. Na rampa, o Guardião e você sobem e descem. Zonas de Fúria continuam detectando você. Gancho e Ninho funcionam.

```text
Módulo R8. Em CaveShape, some a FloorAt uma altura por zona (Config.CaveDepth: A 0, B -8, C -18), com rampa suave nas colunas de transição, inclinação máxima de 35 graus. Teto da zona B até 22 studs, câmara e Ninho até 34, com domo por ruído. Adicione 2 ou 3 salões extras por alargamento em cruzamentos das zonas B e C, sem criar atalho novo entre zonas. Atualize tudo que depende da altura, incluindo os limites verticais das FuryZones, e rode "Gerar caverna". Se a auditoria falhar, reduza o desnível antes de mudar a IA.
```

## 9. Bloco I: inventário

Hoje a mochila é só um texto, e o baú só aparece no mercado. A mochila passa a usar **espaços que representam o peso**: cada 2 de peso é 1 espaço, então cabem 5 Núcleos, ou 1 Relíquia (3 espaços) e 2 Núcleos. Não muda nenhuma regra e torna o peso visível.

**Decisões já tomadas:**
- A tela **não pausa o jogo**: olhar a mochila na caverna é um risco.
- A tecla é **I**, mais um botão na tela para celular. O Tab abre a lista de jogadores do Roblox.
- O baú na tela é só consulta. Vender continua sendo na loja, o que reforça a ida à vila.

### I1. Tela de inventário

**Teste:**
1. Aperte I em qualquer lugar: abre e fecha com animação rápida, e o personagem continua andando.
2. Pegue Núcleos e uma Relíquia: os espaços se enchem, com a cor da raridade.
3. Passe o mouse ou toque no item: tipo, zona de origem, valor agora e peso.
4. A aba Baú lista tudo, com total e filtro por tipo.
5. No celular (Device Emulator): nada fica fora da tela, e o botão substitui a tecla.
6. Com 150 itens no baú, a rolagem continua fluida.

```text
Módulo I1. Consulte roblox-dev:roblox-ui e roblox-dev:roblox-security.
1. LootSystem: cada item da mochila ganha id (HttpService:GenerateGUID no servidor) e depthZone. Inclua a lista de itens no HUDUpdate (id, type, rarity, depthZone, baseValue, weight), sem nada de outros jogadores. O valor atual continua calculado no servidor.
2. Crie src/client/ui/InventoryUI.lua (--!strict): só mostra estado, sem pedir nada ao servidor neste módulo. Tecla I e botão na tela. Abas Mochila e Baú. Mochila: espaços conforme Config.MaxCarryWeight e Config.SlotWeight = 2, Relíquia ocupando 3 espaços juntos, barra de peso com a frase do efeito no ruído, valor total. Baú: dados do ProfileUpdate via ProfileHUD, rolagem, total, filtro.
3. Detalhe do item ao passar o mouse ou tocar. Ícones simples por tipo, cor por raridade, em UDim2 de escala, com UISizeConstraint.
4. Barra pequena com os espaços sempre visível na caverna, acima da NoiseBar, com pulo curto ao encher.
5. Troque o texto antigo da mochila por essa barra. Não mude regras de peso. Teclado de chat e caixas de texto não podem abrir a tela (use o parâmetro processed).
6. Adicione a dica em TutorialHints.
```

### I2. Soltar e pegar (depois do Portão 1)

**O que faz:** soltar um item para ficar mais silencioso ou passar a um aliado. Abre uma decisão real: "largo a Relíquia para fugir?"

**Teste:** solte um item; ele aparece no chão com o mesmo valor. Um segundo jogador pega e extrai por aquele valor. Clique rápido em soltar: nunca duplica. Solte em pé: pulso de ruído. Solte andando devagar: silêncio. Fim da expedição: itens no chão somem.

```text
Módulo I2. Consulte roblox-dev:roblox-security.
1. Remote DropItem(id): valide tipo, RateLimiter, jogador em Cave, vivo e dono do id. Remova da mochila primeiro e só depois crie a Part. Limite Config.MaxDroppedItems = 12 por expedição; acima disso, recuse.
2. A Part usa a mesma aparência do item. O item fica em tabela no servidor (droppedItems[part]), sem o valor em Attribute. Ao pegar, a pessoa recebe exatamente aquele item, sem recalcular o bônus. Respeite o limite de peso; se recusado, o item fica no chão.
3. Os itens soltos não entram em coreOriginals. ResetCores e o fim da expedição destroem os que restarem.
4. Ruído: pulso de Config.DropNoise se a pessoa não estiver andando devagar (SneakSystem).
5. Botão Soltar na InventoryUI, e posição no chão resolvida no servidor (FloorPicker ou raycast).
```

### I3. Arremessar para distrair (depois do I2)

**O que faz:** versão cooperativa das Iscas de Eco. Sacrifica posição e tempo por uma chance de distrair o Guardião. O item continua existindo no local onde caiu, para quem tiver coragem de buscar.

**Teste:** tecla G com o item selecionado. Ele voa até 40 studs e faz barulho ao cair. O Guardião vai investigar o ponto. Relíquia não pode ser arremessada. Tecla repetida respeita 15 s de espera. Um cliente enviando direção inválida (NaN) não causa nada.

```text
Módulo I3. Consulte roblox-dev:roblox-security. Depende do I2.
1. Remote ThrowItem(id, direction): valide tipo, comprimento perto de 1, sem NaN ou infinito, Config.ThrowCooldown = 15 s, Cave, vivo, dono do id, item não Relíquia. Origem e distância máxima (Config.ThrowRange = 40) vêm do servidor. Raycast decide o ponto de queda; a parede corta o voo.
2. Trajetória visual em arco, no servidor, com tween curto de Part ancorada. Ao cair, vira item solto (I2) e toca som de pedra via AudioBroadcast com posição.
3. GuardianAI: exponha a investigação de um ponto, reutilizando a lógica existente para o Corista se houver. Não troque um alvo em Hunting a menos de Config.ThrowIgnoreRadius, para que não seja uma forma garantida de escapar.
4. Tecla G e botão na UI. Dica curta em TutorialHints.
```

### I4. Mochila visível (depois do Portão 1)

**O que faz:** um aliado enxerga quanto você carrega. Relíquia na mochila faz você brilhar, o que junta o grupo e deixa as fugas mais bonitas. Só visual, sem alterar a detecção pelo Guardião.

```text
Módulo I4. Servidor: ao mudar o peso, atualize no personagem uma mochila de Part ou mesh soldada às costas, com tamanho conforme o peso e PointLight na cor do item mais raro (forte com Relíquia). Limpe ao morrer, renascer e extrair. Não altere a detecção. Verifique que não atrapalha a câmera nem o arraste do sequestro.
```

## 10. Bloco J: novas mecânicas

### J1. Itens mudam de lugar a cada expedição (antes do Portão 1)

Hoje os núcleos sempre voltam às mesmas posições (`ResetCores`). Em poucas partidas, o grupo decora a rota. Com o mapa fixo e os itens sorteados, o labirinto continua aprendível, mas o caminho muda.

**Teste:** faça 3 expedições, anotando onde estão 3 núcleos: as posições mudam. Quantidade e raridade por zona seguem iguais. **Auditar caminhos** sem falhas em todas. Núcleos de saliência de gancho e veias da câmara ficam fixos.

```text
Módulo J1. Em LootSystem/CaveLayout, a cada Started sorteie novas células abertas para os núcleos e relíquias normais, usando as mesmas quantidades por zona, sem repetir célula, sem salas especiais, e usando FloorAt. Sorteio com Random no servidor. Mantenha fixos LedgeCore e as veias da câmara. Não crie ou destrua os núcleos: mova-os no ResetCores, para os prompts continuarem ligados.
```

### Demais ideias (decidir depois do Portão 1)

| # | Mecânica | Por que funciona neste jogo | Custo | Minha opinião |
|---|---|---|---|---|
| J2 | **Consumíveis na oficina**: sinalizador (ilumina um corredor por 20 s) e frasco do silêncio (10 s sem ruído de passos) | Dá destino ao dinheiro. Cria decisão antes de descer | Médio | **Primeiro depois do Portão** |
| J3 | **Esconderijos** em fendas da rocha | Clássico do terror: o grupo prende a respiração enquanto ele passa. Terrain deixa natural | Médio | **Alta prioridade** |
| J4 | **Cofre em dupla**: duas alavancas distantes, seguradas ao mesmo tempo, abrem um tesouro barulhento | Força cooperação e voz | Médio | **Alta prioridade** |
| J5 | **Giz**: marcar setas nas paredes, sem texto livre | Barato, emergente, útil em labirinto, sem risco de moderação | Baixo | Boa aposta |
| J6 | **Bateria da lanterna** | Mais tensão, com pouca regra. Pode irritar | Baixo | Testar com cuidado |
| J7 | **Eventos**: apagão, desabamento que muda rota, gás que obriga a sair | Quebra rotina em partidas longas | Alto | Depois |
| J8 | **Diários de mineradores** e histórias dos NPCs | Dá sentido ao mundo sem custo de sistema | Baixo | Bom com R7 |
| J9 | **Achados da floresta**: cogumelos, sucata e baús escondidos nas clareiras, vendidos na vila, com limite diário | Faz valer andar na floresta sem virar obrigação nem substituir a caverna | Médio | **Melhor ideia nova para a floresta** |
| J10 | **Noite na floresta**: ao anoitecer, luzes e sons estranhos, mas nunca perigo real | Mantém a superfície segura, com um arrepio. Prepara a Fase 2 | Baixo | Boa aposta |
| J11 | **Pedidos da vila**: moradores pedem itens específicos da caverna, com balões de fala | Dá rosto ao sistema de contratos | Médio | Junto com R7 |
| J12 | **Nível e cosméticos** | Fase 2 do PDF. Só depois do Portão final | Alto | Ainda não |

Ao escolher, peça ao Opus os prompts: as regras podem mudar com o que o teste mostrar.

## 11. Portão visual

Depois do R9, antes de chamar pessoas, o Alan olha estas 10 imagens, enviadas pelo Sonnet: spawn olhando para cada lado (4), trilha na floresta, praça da vila, Mercado Negro, e uma de cada zona da caverna (3).

| Pergunta | Aprovado se |
|---|---|
| Ainda parece "tudo quadrado"? | Não, em nenhuma imagem |
| A floresta dá sensação de aventura? | Sim, e dá vontade de ver o que tem além |
| A viagem cansa? | Com carroça e corrida, não |
| O contraste entre superfície e caverna está forte? | Sim |
| O jogo roda bem em um celular comum? | Sem travadas perceptíveis |

Depois disso, siga o **Portão 1** de `docs/PLANO-FASE-1.md`: publique em modo privado e jogue com 4 pessoas reais, com voz. Como a Mercado e a Oficina mudaram de lugar, inclua a pergunta do Portão 2: quanto tempo ficam na superfície entre expedições?

## 12. O que ainda não foi verificado

- Nenhum modelo da loja ou peça da Blocky Cave foi visto no Studio: avaliei pelas páginas e pelo conteúdo do arquivo. O A1 existe para isso.
- Desempenho da floresta com estes números: é uma estimativa, a medir no R5.
- Tempo real de geração do mapa grande.
- Autoria e licença da Blocky Cave.
- Licença atual da Synty além do texto da loja e do anúncio de 2021.
- "Sexy ou smoothie contra uma blog" na mensagem do Alan veio de transcrição de voz. Interpretei como: buscar casas e lojas em pacotes como a Synty e em sites de assets.

## Fontes

- [Synty Nature Pack](https://create.roblox.com/store/asset/6933438443/Synty-Nature-Pack) e [anúncio dos pacotes Synty](https://devforum.roblox.com/t/free-synty-asset-packs-released-in-the-marketplace/1283755)
- [roblox-procedural-worlds, CaveSystem.lua](https://github.com/Gzeu/roblox-procedural-worlds/blob/main/src/CaveSystem.lua)
- [roblox-runtime-terrain](https://github.com/maddoxbouldin/roblox-runtime-terrain) e [post no DevForum](https://devforum.roblox.com/t/open-source-runtime-parallel-terrain-generation-with-caves-springs-and-vegetation/4732451)
- [Quaternius Medieval Village MegaKit](https://quaternius.com/packs/medievalvillagemegakit.html)
- [Vulnerabilidades de assets de terceiros, Roblox](https://create.roblox.com/docs/scripting/security/third-party-vulnerabilities)
- [Referência oficial de Terrain](https://create.roblox.com/docs/reference/engine/classes/Terrain.md) e [página traduzida](https://create.roblox.com/docs/pt-br/reference/engine/classes/Terrain)
- [Relato sobre RenderFidelity em mundos grandes](https://devforum.roblox.com/t/more-renderfidelity-options/460741)
