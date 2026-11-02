# Plano de desenvolvimento: Fase 1 de Ecos da Penumbra (versão 2)

Versão de 02/11/2026, escrita por Opus para execução por Sonnet. Inclui o meta-loop e substitui a versão anterior, que não chegou a ser implementada. Nenhum código foi escrito.

## 1. Como usar este plano

1. Faça a preparação da seção 3 uma única vez.
2. Abra uma sessão nova com o Sonnet para cada módulo. Isso economiza tokens.
3. Faça a etapa "Prepare no Studio" do módulo, se houver.
4. Cole o prompt e, com o Rojo ligado, rode o teste manual.
5. Se passar, responda `Aprovado, pode fazer o commit`. Se falhar, descreva o que viu e copie o texto vermelho da janela Output.
6. Ao chegar em um **Portão**, pare e teste com pessoas. Os portões decidem se a próxima camada vale o custo.

Siga a ordem: cada módulo usa funções criadas pelos anteriores.

## 2. Decisões de design

### Decididas por você

| Tema | Decisão |
|---|---|
| Servidores | Um grupo por servidor. Lobby, floresta e caverna ficam no mesmo lugar. |
| Ordem | Quatro camadas, com teste entre elas. |
| PvP | Adiado. O Mercado Negro entra sem Iscas de Eco e sem NPCs hostis. |
| Elevador | Várias viagens. Cada jogador sai quando quiser, e o restante pode continuar. |
| Ninho | O Guardião entrega o preso e volta a caçar. Soltar leva 5s e faz muito ruído. O preso pode bater nas grades. Sem ninguém livre na caverna, volta direto ao lobby. |
| Valor | Começa em 100% e sobe até 150% no minuto 10. Itens do fundo da caverna valem mais. Sem penalidade por sair cedo. |
| Relíquias | Sem sistema de espaço: muito pesadas, logo barulhentas. Valem bastante ou viram troféus na Oficina. |
| Falha do pity | Ninguém do grupo extraiu nenhum item. |
| Variantes | Sorteio de 1 Guardião por expedição, sem repetir o anterior. |
| Clipes | Vídeo real com `CaptureService`, sem 9:16 por enquanto. |

### Decididas por mim, ajustáveis em `Config.lua`

| Tema | Decisão | Motivo |
|---|---|---|
| Descer ao meio de uma expedição | Não pode. Quem subiu espera no lobby até o fim. | Evita um novo cálculo de tempo por jogador |
| Duração máxima | 15 min. Quem continuar na caverna perde a mochila e volta ao lobby. | Com várias viagens, a expedição precisa terminar |
| Fúria | A partir do minuto 8, quem estiver em uma Zona de Fúria é ouvido mesmo parado. Cubra os arredores do elevador com uma dessas zonas. | Pune quem espera escondido |
| Aviso da fúria | Tremor e som global antes da mudança; zonas marcadas no mapa. | A morte precisa parecer justa |
| Morte comum | Se o personagem morrer (ou usar Reset), perde a mochila e renasce no lobby. | Fecha o exploit de fugir do Ninho |
| Mochila no sequestro | Fica com o preso. Resgatado, ele a mantém. | Mais simples, sem risco de duplicação |
| Arrastar | Efeito real por até 8s, depois teleporta ao Ninho. | Evita travar em paredes |
| Perfil | ProfileStore, biblioteca recomendada pela skill de DataStores. **Na prática:** o perfil usa código próprio (`PlayerProfile.lua`) com trava de sessão por JobId, UpdateAsync e retentativas, revisado em 02/11/2026. | Evita perda e duplicação de itens |
| Valor após extrair | Fica travado no item guardado. | O Mercado não precisa conhecer o tempo |
| Botas | Reduzem só o ruído de passos, nunca o da voz. | Preserva a tensão central |
| Gancho | Só engancha em pontos marcados no mapa e faz barulho. | Resolve o exploit e a regra de mapa |
| Pity contínuo | Ativo até uma extração bem-sucedida. | O PDF não trata de uma terceira falha |
| Núcleos falsos | Sem Attribute `IsFake`: ficam em tabela no servidor. | Senão um exploiter identifica o falso |
| Áudio de mundo | O servidor envia só o tipo de som e a posição, e o cliente toca. | A documentação não confirma `AudioPlayer:Play()` no servidor |

### Fora da Fase 1

Guildas, base compartilhada, monetização, PvP com Iscas de Eco e cavernas em servidores reservados. Correr e agachar também ficam de fora: se o teste do Portão 1 pedir, voltamos a isso.

### Problemas do código atual que este plano corrige

| Achado | Onde | Módulo |
|---|---|---|
| Só existe uma expedição: núcleos não voltam e o Guardião não é reiniciado. | `LootSystem.lua:62-65`, `ExtractionSystem.lua:61-63` | M1 |
| O Guardião não captura ninguém. | `GuardianAI.lua` | M3, M7 |
| O ruído usa a velocidade configurada, não a real. | `NoiseSystem.lua:20` | M3 |
| O limite de caça é 1.5, mas sem voz o ruído chega a 1.3. | `GuardianAI.lua:69` | M3 |
| O timer de silêncio nunca zera. | `GuardianAI.lua:76` | M3 |
| Depois de dormir, o Guardião não acorda de novo. | `GuardianAI.lua:102-106` | M3 |
| Sem `PathfindingService`. | `GuardianAI.lua:71` | M3b, se travar |
| A voz real não existe; a tecla V simula o grito. | `init.client.lua:15-21` | M4 |
| Enviar `NaN` no `VoiceSpike` esconde o jogador do Guardião. | `NoiseSystem.lua:54-61` | M4 |
| O PDF pede `VideoCaptureService`, e a sua regra proíbe. | PDF 2.4 | M20 |

## 3. Preparação (uma única vez)

**Git e CLAUDE.md.** O projeto ainda não tem Git. O `CLAUDE.md` já foi renomeado, mas ainda descreve a Fase 1 antiga: troque a linha final por `Fase 1 em andamento: seguir docs/PLANO-FASE-1.md`. Depois, na raiz do projeto, rode um comando de cada vez:

```bash
git init
```

```bash
git add -A
```

```bash
git commit -m "Estado validado da Fase 0 e plano da Fase 1"
```

**Áudios.** Escolha em `create.roblox.com/store/audio` e anote os IDs. Você precisa do primeiro para o M5 e dos demais a partir do M7.

| Som | Busca sugerida | Módulo |
|---|---|---|
| Tremor da caverna | `rumble` | M5 |
| Batida em grades | `metal bang` | M8 |
| Voz grave e distorcida | `distorted voice` | M14 |
| Risada curta | `creepy laugh` | M15 |
| Pedra caindo | `rock drop` | M15 |

**Propriedades no Studio.** Em Explorer → Properties, anote:

- `VoiceChatService` → `UseAudioApi`. O M4 precisa de `Enabled`.
- `SoundService` → `DefaultListenerLocation`. Se for `None`, avise no M5.
- `Workspace` → `StreamingEnabled`. Informe no M1, porque afeta os teleportes.

**Publicação.** O M4 (voz), o M10 (salvar dados) e o M20 (vídeo) precisam de um lugar publicado e privado.

## 4. Visão geral

| Camada | Módulo | Depende de |
|---|---|---|
| **1. Caverna** | M1 Fundação da expedição | Fase 0 |
| | M2 Elevador de várias viagens | M1 |
| | M3 Caça real | M1 |
| | M3b Pathfinding (condicional) | M3 |
| | M4 Voz real | M3 |
| | M5 Relógio e fúria | M3 |
| | M6 Valor e Relíquias | M2, M5 |
| | M7 Sequestro | M3 |
| | M8 Ninho e Resgate | M7 |
| | M9 PitySystem | M2, M6 |
| | **Portão 1: 4 pessoas** | |
| **2. Superfície** | M10 Perfil salvo | M6 |
| | M11 Lobby | M10 |
| | M12 Mercado do Lobby | M11 |
| | M13 Oficina e Botas | M12 |
| | **Portão 2: 4 pessoas** | |
| **3. Variedade** | M14 Guardião Corista | M5 |
| | M15 Guardião Enganador | M14, M9 |
| | M16 Gancho | M13 |
| | M17 Contratos | M13 |
| | **Portão 3: 4 pessoas** | |
| **4. Mundo e viral** | M18 Mercado Negro | M12 |
| | M19 Mural de Destaques | M10 |
| | M20 Clipes | M8 |
| | **Portão final** | |

---

# Camada 1: Caverna

## M1. Fundação da expedição

**O que faz:** registra onde cada jogador está (lobby, caverna, arrastado ou preso) e cria o ciclo completo: descer, jogar, voltar, reiniciar a caverna. Inclui um painel de teste que só existe no Studio.

**Skills:** `roblox-architecture`, `roblox-testing`, `roblox-security`, `luau-strict-typing`.

**Prepare no Studio:**
1. Construa uma plataforma simples, longe da caverna, com um `SpawnLocation`. Esse é o lobby provisório.
2. Crie nela uma Part `LobbyElevator` (Anchored), com um `ProximityPrompt`.
3. Crie uma Part `LobbyArrival` no lobby e uma Part `CaveArrival` na entrada da caverna, ambas Anchored, sem colisão e invisíveis.
4. Remova qualquer outro `SpawnLocation` da caverna.

**Teste manual:**
1. Dê Play. Você nasce no lobby. O Output mostra `[Expedition] Aguardando`.
2. Acione `LobbyElevator` e fique perto. Depois de 10s, você aparece na caverna e o Output mostra `Iniciada`.
3. Pegue um núcleo. Clique em **Encerrar: falha**. Você volta ao lobby, a mochila zera, e o núcleo reaparece.
4. Desça de novo, abra o menu Esc e use Reset. Você renasce no lobby e o Output mostra o fim da expedição.
5. Em **Clients and Servers** com 2 jogadores, deixe um longe do elevador ao descer. Ele fica no lobby e não consegue chamar o elevador durante a expedição.
6. Repita 3 vezes. Tudo continua funcionando.

**Prompt:**

```text
Use a skill ecos-da-penumbra. Consulte roblox-dev:roblox-architecture, roblox-dev:roblox-testing, roblox-dev:roblox-security e roblox-dev:luau-strict-typing. Implemente o módulo M1 de docs/PLANO-FASE-1.md. Mantenha o padrão da Fase 0 (.lua, systems/, Init()). StreamingEnabled neste lugar é [COLE O VALOR].

1. Enums: adicione PlayerLocation (Lobby, Cave, Dragged, Captive), ExpeditionPhase (Waiting, Active, Resetting) e ExpeditionOutcome (Success, Failure, Abandoned).
2. Crie src/server/systems/PlayerState.lua (--!strict), sem depender de outros sistemas: Get(player), Set(player, location), GetPlayersIn(location), BindableEvent Changed(player, location). Todo jogador começa em Lobby. Limpe ao sair do servidor.
3. Crie src/server/systems/ExpeditionSystem.lua (--!strict), com BindableEvents Started e Ended(outcome, extractedPlayers), e as funções GetPhase(), GetElapsedTime(), RecordExtraction(player), ReturnToLobby(player, keepLoot) e End(outcome).
4. Prompt de workspace.LobbyElevator: só funciona na fase Waiting e para quem estiver em Lobby. Conte Config.DescentCountdown (10s) e leve para workspace.CaveArrival, com PivotTo, quem estiver a até Config.LobbyElevatorRadius (15 studs). Se StreamingEnabled for true, garanta que a área carregue antes do teleporte usando a API adequada; se não tiver certeza da API, pergunte.
5. ReturnToLobby leva para workspace.LobbyArrival e define Lobby. Com keepLoot false, chama LootSystem.ClearInventory.
6. Se o Humanoid de um jogador morrer fora do Lobby: limpe a mochila e defina Lobby. O renascimento padrão o traz ao SpawnLocation do lobby. No renascimento, CarryWeight começa em 0.
7. Quando ninguém mais estiver em Cave, Dragged ou Captive, encerre: Success se RecordExtraction foi chamado ao menos uma vez, Failure se não, Abandoned se o último saiu do servidor. Aos Config.ExpeditionMaxTime (900s), devolva todos ao lobby sem mochila.
8. Ao terminar, aguarde Config.ExpeditionResetDelay (5s), restaure tudo e volte para Waiting.
9. LootSystem.lua: adicione ResetCores(), restaurando Collected, Transparency, CanCollide e prompt aos valores originais, guardados em connectCore.
10. GuardianAI.lua: adicione Reset() (Sleeping, PivotTo para a posição inicial, sem alvo). NoiseSystem.GetLoudestPlayer considera só quem está em Cave; o ruído dos demais é 0.
11. ExtractionSystem.lua: remova apenas o reset de FirstCoreExtracted, que passa para ExpeditionSystem. O elevador será refeito no M2; mantenha-o funcionando, sem encerrar nada.
12. Crie src/server/systems/QACommands.lua e src/client/ui/QAPanel.lua. O RemoteEvent QACommand só existe se RunService:IsStudio() for true; o handler verifica de novo e valida contra uma lista fixa. Botões: "Encerrar: falha" e "Encerrar: sucesso", usando as APIs de ExpeditionSystem. Deixe simples adicionar botões.
13. Logue com prefixo [Expedition]. Registre tudo em init.server.lua e init.client.lua.

Arquivos autorizados: os citados, Config.lua e Enums.lua. Avise antes se algo quebrar a Fase 0. Siga o fluxo de trabalho do CLAUDE.md. Não rode Rojo, não abra o Studio e não faça commit até eu aprovar o teste. Entregue o teste manual em passos para quem não é desenvolvedor.
```

## M2. Elevador de várias viagens

**O que faz:** cada grupo decide quando sair. O elevador sobe com quem estiver dentro, volta depois de um tempo, e os demais continuam na caverna.

**Skills:** `roblox-security`, `luau-strict-typing`.

**Teste manual** (em **Clients and Servers**, com 2 jogadores):
1. Desçam. Cada um pega um núcleo.
2. O jogador A chama o elevador e entra. O jogador B fica fora.
3. Ao fechar, A vai ao lobby com a mensagem de extração. B continua na caverna, com a mochila intacta, e a expedição segue.
4. Depois de 15s, B consegue chamar o elevador e sai. O Output mostra o fim com `success`.
5. Refaça com os dois fora ao fechar: ninguém sai e o elevador pode ser chamado de novo.
6. Em uma expedição nova, só B extrai, sem itens. O Output mostra `failure`.

**Prompt:**

```text
Use a skill ecos-da-penumbra. Consulte roblox-dev:roblox-security e roblox-dev:luau-strict-typing. Implemente o módulo M2 de docs/PLANO-FASE-1.md. M1 já existe.

Em src/server/systems/ExtractionSystem.lua, refaça o elevador da caverna como uma pequena máquina de estados: Idle, Arriving (Config.ElevatorArrivalTime), Open (Config.ElevatorCloseTime), Cooldown (Config.ElevatorCooldown = 15s), de volta a Idle.
1. O prompt só aceita quem estiver em Cave na fase Active, e no estado Idle.
2. Ao fechar, para cada jogador em Cave dentro do elevador: se tiver ao menos 1 item, chame ExpeditionSystem.RecordExtraction(player). Depois, dispare o BindableEvent Extracted(player, itemCount) e chame ExpeditionSystem.ReturnToLobby(player, true). Limpe a mochila com ClearInventory somente ao final, depois de disparar o evento e registrar no Output quantos itens e qual o valor.
3. Quem estiver fora não perde nada.
4. Envie ElevatorUpdate apenas aos jogadores em Cave, e inclua o estado cooldown. Atualize ExtractionUI.lua para lidar com ele.
5. Quando a expedição terminar, volte o elevador para Idle e cancele qualquer contagem com um contador de geração.
6. Esta mudança substitui a regra do PDF 1.4 ("quem não entrar perde a mochila"). Explique isso em linguagem simples na entrega.

Arquivos autorizados: ExtractionSystem.lua, ExtractionUI.lua, Config.lua. Siga o fluxo de trabalho do CLAUDE.md. Não rode Rojo, não abra o Studio e não faça commit até eu aprovar o teste. Entregue o teste manual em passos para quem não é desenvolvedor.
```

## M3. Caça real

**O que faz:** faz o Guardião ouvir o movimento de verdade, manter a perseguição e voltar a acordar. Por enquanto, a captura devolve o jogador ao lobby sem mochila. O M7 troca isso pelo sequestro.

**Skills:** `roblox-performance`, `roblox-security`, `luau-strict-typing`.

**Teste manual:**
1. Pegue um núcleo. O Output mostra Alerta e depois Caçando.
2. Ande sem parar. Ele continua atrás de você por mais de 10s.
3. Pare totalmente. Em cerca de 3s ele perde o rastro e volta para casa.
4. Quando ele dormir, espere 10s e ande. Ele acorda de novo.
5. Deixe ele encostar. Você volta ao lobby, sem mochila.
6. Se ele ficar preso em paredes, faça o M3b.
7. Se você sempre escapar andando, tudo bem por enquanto: você anda a 16 e ele caça a 14. O M5 muda isso.

**Prompt:**

```text
Use a skill ecos-da-penumbra. Consulte roblox-dev:roblox-performance, roblox-dev:roblox-security e roblox-dev:luau-strict-typing. Implemente o módulo M3 de docs/PLANO-FASE-1.md. M1 e M2 já existem.

1. NoiseSystem.lua: em calculateNoise, troque humanoid.WalkSpeed pela velocidade horizontal real de HumanoidRootPart.AssemblyLinearVelocity, limitada a Config.SprintSpeed. Parado, o componente de movimento é 0.
2. GuardianAI.lua: troque o 1.5 fixo por Config.GuardianHearThreshold (0.5).
3. Em Hunting, use um silenceTimer separado, zerado sempre que o alvo estiver acima do limite. Só vá para LostScent após Config.GuardianLostScentTime de silêncio contínuo.
4. Em Sleeping, com FirstCoreExtracted true, passado Config.GuardianRestTime (10s) desde que dormiu e com alguém acima do limite, vá para Alert.
5. Chame MoveTo no máximo a cada 0.25s, e só se o destino mudar.
6. Exponha o BindableEvent PlayerCaught. A cada 0.1s, em Hunting e LostScent, verifique no servidor a distância até cada jogador em Cave. Se for <= Config.GuardianCatchRadius (5), dispare PlayerCaught(player). Não use dados do cliente.
7. ExpeditionSystem.lua: ao receber PlayerCaught, chame ReturnToLobby(player, false). Comente que isso é temporário até o M7.

Arquivos autorizados: NoiseSystem.lua, GuardianAI.lua, ExpeditionSystem.lua, Config.lua. A mudança altera o equilíbrio da Fase 0: explique em linguagem simples. Siga o fluxo de trabalho do CLAUDE.md. Não rode Rojo, não abra o Studio e não faça commit até eu aprovar o teste. Entregue o teste manual em passos para quem não é desenvolvedor.
```

### M3b. Pathfinding (somente se o Guardião travar)

**Skills:** `roblox-performance`, `luau-strict-typing`.

**Teste manual:** fique atrás de uma parede em um corredor com curva e faça barulho. O Guardião contorna a parede. Em um beco sem saída, o Output não mostra erros repetidos.

**Prompt:**

```text
Use a skill ecos-da-penumbra. Consulte roblox-dev:roblox-performance e roblox-dev:luau-strict-typing. Em src/server/systems/GuardianAI.lua, substitua o movimento direto por PathfindingService (CreatePath e ComputeAsync). Recalcule no máximo a cada Config.GuardianRepathInterval (0.5s) e só se o destino tiver mudado mais de 4 studs. Envolva ComputeAsync em pcall e, se falhar, use MoveTo direto e registre um único warn. Não rode cálculos simultâneos. Não altere estados nem captura.

Arquivos autorizados: GuardianAI.lua, Config.lua. Siga o fluxo de trabalho do CLAUDE.md. Não rode Rojo, não abra o Studio e não faça commit até eu aprovar o teste. Entregue o teste manual em passos para quem não é desenvolvedor.
```

## M4. Voz real

**O que faz:** liga o microfone ao ruído, a mecânica central do jogo. Também fecha a falha de segurança do `VoiceSpike`. A tecla V continua como alternativa para quem não tem microfone.

**Skills:** `roblox-security`, `roblox-performance`, `luau-strict-typing`.

**Prepare no Studio:** defina `VoiceChatService.UseAudioApi` como `Enabled`. O teste precisa de uma conta com voice chat e, possivelmente, de um lugar publicado.

**Teste manual:**
1. Fique 30s em silêncio. O Output não mostra `[Voice] spike`.
2. Fale baixo por 2s. Anote os valores de RMS.
3. Grite por 2s. O Output mostra `[Voice] spike` e o Guardião reage.
4. Fale com outra pessoa. O voice chat continua normal.
5. Em uma conta sem voz, aparece um único aviso e a tecla V funciona.
6. Se o limite parecer errado, ajuste `VoiceRmsThreshold` em `Config.lua`.

**Prompt:**

```text
Use a skill ecos-da-penumbra. Consulte roblox-dev:roblox-security, roblox-dev:roblox-performance e roblox-dev:luau-strict-typing. Implemente o módulo M4 de docs/PLANO-FASE-1.md. M1 a M3 já existem.

1. NoiseSystem.lua: no handler de VoiceSpike, rejeite NaN e infinito, aceite só quem estiver em Cave ou Captive, e limite a 2 por segundo por jogador, limpando ao sair. Adicione o BindableEvent VoiceSpiked(player, intensity), com intensidade de 0 a 10.
2. Crie src/client/VoiceNoise.lua (--!strict), iniciado por init.client.lua. Localize o microfone com LocalPlayer:WaitForChild("AudioDeviceInput", 15). A documentação não garante a criação automática: se não existir, registre um único warn e encerre sem erro.
3. Crie um AudioAnalyzer e um Wire de AudioDeviceInput para ele, sem alterar ligações existentes nem o voice chat.
4. Em task.spawn com task.wait(0.1), leia RmsLevel. Acima de Config.VoiceRmsThreshold (0.3) por Config.VoiceSustainTime (0.5s), chame VoiceSpike:FireServer(intensity), com 0 a 10 calculado do RMS. Espere ao menos 1s entre envios. O remote recebe só intensity.
5. Com Config.VoiceDebug = true, logue RMS e picos com prefixo [Voice]. Deixe true durante o teste.
6. Não grave nem armazene áudio.

Arquivos autorizados: NoiseSystem.lua, VoiceNoise.lua, init.client.lua, Config.lua. Siga o fluxo de trabalho do CLAUDE.md. Não rode Rojo, não abra o Studio e não faça commit até eu aprovar o teste. Entregue o teste manual em passos para quem não é desenvolvedor.
```

## M5. Relógio e fúria

**O que faz:** o Guardião piora com o tempo: lento até o minuto 3, normal até o 8, e em fúria depois. Na fúria, ficar parado em uma zona marcada não protege mais.

**Skills:** `roblox-testing` (lógica pura), `roblox-security`, `luau-strict-typing`.

**Prepare no Studio:** crie no Workspace a pasta `FuryZones`, com Parts invisíveis, sem colisão e Anchored, cobrindo as áreas perigosas. **Uma delas deve cobrir os arredores do elevador.** Marque essas áreas visualmente, por exemplo com rachaduras vermelhas. Tenha em mãos o ID do tremor.

**Teste manual:**
1. Clique em **Pular para minuto 3**. O tremor toca e o Output mostra `[CaveRules] tier Normal`. O `WalkSpeed` do Guardião caçando é 14; antes era 11,2.
2. Clique em **Pular para minuto 8**. O tremor toca de novo, e o `WalkSpeed` é 16,8.
3. Fique parado **dentro** de uma Zona de Fúria: o Guardião vem até você.
4. Fique parado **fora** de uma zona: ele perde o rastro.
5. Vire a câmera ao ouvir o tremor. Ele toca igual para todos na caverna, e não no lobby.

**Prompt:**

```text
Use a skill ecos-da-penumbra. Consulte roblox-dev:roblox-testing, roblox-dev:roblox-security e roblox-dev:luau-strict-typing. Implemente o módulo M5 de docs/PLANO-FASE-1.md. M1 a M4 já existem. O ID do tremor é [COLE O ID]. DefaultListenerLocation é [COLE O VALOR]; se for None, pergunte antes de seguir.

1. Crie src/server/systems/CaveRules.lua (--!strict), lógica pura, sem serviços: GetTier(elapsedSeconds) e GetValueMultiplier(elapsedSeconds). Tiers em Config.GuardianTiers: Slow (minuto 0, velocidade 0.8, limite 0.7), Normal (minuto 3, 1.0, 0.5), Fury (minuto 8, 1.2, 0.2). Valor: 1.0 no início, subindo linearmente até 1.5 em Config.ValueMaxMinute (10), e fica nisso.
2. GuardianAI.lua: adicione SetSpeedMultiplier(key, value), combinando multiplicadores por chave (tier agora, pity no M9), e SetHearThreshold(value).
3. ExpeditionSystem.lua: durante a fase Active, verifique a cada 1s o tier. Ao mudar, aplique no Guardião, logue [CaveRules] e envie o tremor. Adicione SetElapsedForQA(seconds).
4. Fúria: em NoiseSystem.GetLoudestPlayer, quando Tier for Fury, um jogador em Cave dentro de uma Part de workspace.FuryZones é tratado como audível mesmo parado. Verifique com GetPartBoundsInBox no servidor, a cada 0.5s no máximo. Se a pasta não existir, registre um único warn.
5. Crie o RemoteEvent WorldAudio (servidor para cliente), com soundKey e position opcional. Crie src/client/audio/WorldAudio.lua (--!strict): aceita apenas chaves de Config.Audio. Com position, crie uma Part ancorada invisível com AudioPlayer (use Asset, não AssetId, que é deprecado) -> Wire -> AudioEmitter. Sem position, toque de forma não espacial, com AudioPlayer -> Wire -> AudioDeviceOutput. Destrua tudo ao fim do som. Não use Sound. Envie só aos jogadores na caverna.
6. QAPanel e QACommands: botões "Pular para minuto 3" e "Pular para minuto 8".

Se não tiver certeza de uma API de áudio, consulte a documentação oficial ou diga "não tenho certeza". Arquivos autorizados: os citados, init.client.lua, init.server.lua, Config.lua. Siga o fluxo de trabalho do CLAUDE.md. Não rode Rojo, não abra o Studio e não faça commit até eu aprovar o teste. Entregue o teste manual em passos para quem não é desenvolvedor.
```

## M6. Valor e Relíquias

**O que faz:** cria as Relíquias, o bônus de profundidade, o valor crescente e o recibo de extração. Ainda não salva nada: o dinheiro entra no M10.

**Skills:** `roblox-security`, `roblox-testing`, `luau-strict-typing`.

**Prepare no Studio:**
1. Em cada núcleo, adicione o Attribute `DepthZone` (texto: `A`, `B` ou `C`).
2. Crie 2 ou 3 Relíquias: copie um núcleo, mude a aparência e adicione o Attribute `ItemType` = `Relic`.

**Teste manual:**
1. Pegue um núcleo da zona A e extraia logo. O recibo mostra cerca de 100% do valor.
2. Pegue um núcleo da zona C, clique em **Pular para minuto 8** e extraia. O recibo mostra o bônus de profundidade e cerca de +40% pelo tempo.
3. Pegue uma Relíquia. A barra de peso sobe muito, e o Guardião te ouve de mais longe.
4. Tente pegar mais itens acima de `MaxCarryWeight`. O servidor recusa e a tela avisa "Mochila pesada demais".
5. Olhe a mochila no HUD: o valor sobe com o tempo.

**Prompt:**

```text
Use a skill ecos-da-penumbra. Consulte roblox-dev:roblox-security, roblox-dev:roblox-testing e roblox-dev:luau-strict-typing. Implemente o módulo M6 de docs/PLANO-FASE-1.md. M1 a M5 já existem.

1. Config: adicione ItemWeights (Core 2, Relic 6), RelicValue (500), DepthBonus (A 1.0, B 1.15, C 1.3).
2. LootSystem.lua: cada item na mochila guarda type, rarity e baseValue (valor da raridade ou da relíquia, multiplicado pelo DepthBonus do Attribute DepthZone, no momento da coleta). ItemType ausente é Core; DepthZone ausente é A.
3. Peso: some por tipo. Recuse a coleta acima de Config.MaxCarryWeight no servidor, sem consumir o item, e avise só aquele jogador.
4. LootSystem.GetBackpackValue(player, multiplier) retorna o total. Crie também FinalizeExtraction(player, multiplier), que retorna um recibo com itens e valor final travado e limpa a mochila, para que nunca seja possível extrair duas vezes.
5. ExtractionSystem.lua: ao extrair, use FinalizeExtraction com CaveRules.GetValueMultiplier(ExpeditionSystem.GetElapsedTime()). Envie o recibo só ao jogador. Registre o recibo no Output. Dispare Extracted(player, receipt) no lugar do itemCount.
6. HUDUpdate: a cada 5s, envie a quem está em Cave o valor atual da mochila. Mostre em ExtractionUI.lua, junto com uma tela simples de recibo por alguns segundos.
7. NoiseBar.lua: troque o 10 fixo por Config.MaxCarryWeight.

Arquivos autorizados: LootSystem.lua, ExtractionSystem.lua, ExtractionUI.lua, NoiseBar.lua, Config.lua. Siga o fluxo de trabalho do CLAUDE.md. Não rode Rojo, não abra o Studio e não faça commit até eu aprovar o teste. Entregue o teste manual em passos para quem não é desenvolvedor.
```

## M7. Sequestro

**O que faz:** o toque do Guardião agora arrasta o jogador até o Ninho. Se ninguém mais estiver livre na caverna, o preso volta direto ao lobby, sem mochila.

**Skills:** `roblox-security`, `roblox-performance`, `luau-strict-typing`.

**Prepare no Studio:** construa o Ninho na caverna, em um ponto distante do elevador, com ao menos duas entradas. Crie a pasta `NestSlots`, no Workspace, com 4 Parts Anchored, invisíveis e sem colisão, onde os presos ficarão.

**Teste manual** (em **Clients and Servers**, com 2 jogadores):
1. Deixe o Guardião pegar o jogador A. A é arrastado sem conseguir se mover. O Guardião não pega ninguém enquanto arrasta.
2. Em até 8s, A aparece em um `NestSlot`, sem conseguir andar, com a mochila intacta.
3. O Guardião volta a caçar B.
4. Sozinho em uma expedição, ao ser pego, você volta direto ao lobby sem mochila.
5. Com A preso, use Reset nele: A vai ao lobby, sem mochila, e o Output mostra isso.
6. Se o Guardião pegar B enquanto A estiver preso: como ninguém sobra livre, os dois voltam ao lobby e a expedição termina.

**Prompt:**

```text
Use a skill ecos-da-penumbra. Consulte roblox-dev:roblox-security, roblox-dev:roblox-performance e roblox-dev:luau-strict-typing. Implemente o módulo M7 de docs/PLANO-FASE-1.md. M1 a M6 já existem.

1. Enums.GuardianState: adicione Dragging.
2. Crie src/server/systems/KidnapSystem.lua (--!strict), ouvindo GuardianAI.PlayerCaught. Remova a chamada temporária em ExpeditionSystem.
3. Se, descontado o capturado, ninguém estiver em Cave: chame ReturnToLobby(false) para o capturado e para todo Captive. Fim.
4. Caso contrário: Set Dragged. Com o HumanoidRootPart sob controle do servidor (SetNetworkOwner(nil), PlatformStand e Weld ao Guardião), o Guardião entra em Dragging e caminha até workspace.NestSlots. Sem captura durante o arraste.
5. Ao chegar ou após Config.DragMaxTime (8s), remova o Weld, coloque o jogador no primeiro slot livre com PivotTo, ancore o HumanoidRootPart e Set Captive. Devolva a posse física quando sair desse estado. Sem slot livre ou sem pasta: registre warn e devolva ao lobby sem mochila.
6. GuardianAI: após entregar, volte para Alert. Se o capturado sair do servidor ou morrer durante o arraste, limpe o Weld e retome a caça.
7. KidnapSystem expõe o BindableEvent PlayerCaptive(player) e a função Release(player), que desancora e define Cave.
8. Mantenha a mochila com o preso. Se não tiver certeza de um comportamento de rede ou física, diga antes de codar.

Arquivos autorizados: KidnapSystem.lua, GuardianAI.lua, ExpeditionSystem.lua, Enums.lua, Config.lua, init.server.lua. Siga o fluxo de trabalho do CLAUDE.md. Não rode Rojo, não abra o Studio e não faça commit até eu aprovar o teste. Entregue o teste manual em passos para quem não é desenvolvedor.
```

## M8. Ninho e Resgate

**O que faz:** o grupo tem 2 minutos para resgatar o preso. Soltar leva 5s e faz muito ruído. O preso pode bater nas grades, o que guia o grupo mas também atrai o Guardião.

**Skills:** `roblox-security`, `roblox-ui`, `luau-strict-typing`.

**Teste manual** (em **Clients and Servers**, com 2 jogadores; tenha o ID da batida):
1. Com A preso, A vê o tempo restante e B vê o aviso "A está no Ninho", sem direção.
2. B segura a interação em A por 5s, e a barra de ruído dispara. Ao soltar antes de 5s, nada acontece.
3. Depois de 5s, A volta a andar, com a mochila.
4. A aperta F: B ouve as grades vindo do Ninho e o Guardião reage. Apertar sem parar só funciona a cada 3s.
5. Deixe o tempo acabar: A volta ao lobby, sem mochila.
6. A não consegue acionar o próprio resgate.

**Prompt:**

```text
Use a skill ecos-da-penumbra. Consulte roblox-dev:roblox-security, roblox-dev:roblox-ui e roblox-dev:luau-strict-typing. Implemente o módulo M8 de docs/PLANO-FASE-1.md. M1 a M7 já existem. O ID da batida é [COLE O ID].

1. Crie src/server/systems/NestSystem.lua (--!strict), ouvindo KidnapSystem.PlayerCaptive.
2. Timer de Config.CaptiveTimeLimit (120s). Ao acabar: ExpeditionSystem.ReturnToLobby(player, false). Se o último jogador livre for capturado, siga a regra do M7.
3. Crie um ProximityPrompt no slot, com HoldDuration = Config.RescueHoldTime (5s). Use PromptButtonHoldBegan e PromptButtonHoldEnded. Durante o segurar, adicione ruído alto com a nova função NoiseSystem.SetNoiseBoost(player, key, amount); ao soltar, remova. Em Triggered, valide no servidor: quem aciona está em Cave, não é o preso, está a até 12 studs, e o preso continua Captive. Então chame KidnapSystem.Release e remova o prompt.
4. RemoteEvent CaptiveBang (cliente para servidor): sem argumentos, aceito só de Captive, no máximo 1 a cada Config.CaptiveBangCooldown (3s). O efeito é um pulso de ruído por 2s e WorldAudio com a posição do slot, para todos na caverna.
5. O ruído do preso, por voz ou batida, pode atrair o Guardião. Fora isso, ele não é alvo de captura.
6. RemoteEvent NestUpdate (servidor para cliente): só o nome do preso e o tempo restante, sem posição.
7. Crie src/client/ui/NestUI.lua (--!strict): tempo e dica da tecla F para o preso; aviso para os demais. Use tamanhos em escala. Em celular, ofereça botão no lugar da tecla F.

Arquivos autorizados: os citados, NoiseSystem.lua, Config.lua, init.server.lua, init.client.lua. Siga o fluxo de trabalho do CLAUDE.md. Não rode Rojo, não abra o Studio e não faça commit até eu aprovar o teste. Entregue o teste manual em passos para quem não é desenvolvedor.
```

## M9. PitySystem

**O que faz:** depois de 2 falhas seguidas do grupo, o Guardião fica 10% mais lento e um núcleo Common aparece na primeira sala. O jogador nunca vê um contador.

**Skills:** `roblox-testing`, `roblox-security`, `luau-strict-typing`.

**Prepare no Studio:**
1. Copie um núcleo Common para `ServerStorage` e renomeie para `CoreTemplate`.
2. Crie na primeira sala uma Part `PitySpawnPoint`, Anchored, invisível e sem colisão, um pouco acima do chão.

**Teste manual:**
1. Clique em **Encerrar: falha**. O Output mostra `[Pity] falhas=1, inativo`, sem núcleo extra.
2. Clique de novo. O Output mostra `falhas=2, ativo`. Na próxima descida, há um núcleo em `PitySpawnPoint`.
3. Pegue-o: conta como um núcleo normal.
4. Com o Guardião em caça, o `WalkSpeed` é 90% do valor daquele tier.
5. Clique em **Encerrar: falha** de novo. O pity continua ativo.
6. Clique em **Encerrar: sucesso**. O Output mostra `falhas=0, inativo`, e o núcleo extra some na próxima expedição.
7. Na visão Client do Explorer, nada mostra o contador.

**Prompt:**

```text
Use a skill ecos-da-penumbra. Consulte roblox-dev:roblox-testing, roblox-dev:roblox-security e roblox-dev:luau-strict-typing. Implemente o módulo M9 de docs/PLANO-FASE-1.md. M1 a M8 já existem.

1. Crie src/server/systems/PitySystem.lua (--!strict), lógica pura: RecordResult(outcome), IsActive(), GetGuardianSpeedMultiplier(). consecutiveFailures fica em memória, por servidor. Failure soma 1, Success zera, Abandoned não muda. Ativa com Config.PityFailureThreshold (2), até um Success. Multiplicador: Config.PityGuardianSpeedMultiplier (0.9).
2. LootSystem.lua: adicione SpawnGuaranteedCore(), que clona ServerStorage.CoreTemplate, define Rarity = Common e Collected = false, posiciona em workspace.PitySpawnPoint e faz parent no Workspace por último, e RemoveGuaranteedCore(). Sem template ou ponto, registre warn e siga.
3. ExpeditionSystem.lua: em Ended, chame RecordResult. Antes de Started, aplique GuardianAI.SetSpeedMultiplier("pity", ...) e crie ou remova o núcleo.
4. Logue [Pity] falhas=N, ativo/inativo só no servidor. Sem Attribute, remote ou Instance replicada para o contador. Sem DataStore.
5. Crie src/server/systems/PitySystem.spec.lua com testes TestEZ da sequência de resultados. Não adicione TestEZ nem execute: diga se ele precisaria ser instalado.

Arquivos autorizados: os citados e Config.lua. Siga o fluxo de trabalho do CLAUDE.md. Não rode Rojo, não abra o Studio e não faça commit até eu aprovar o teste. Entregue o teste manual em passos para quem não é desenvolvedor.
```

## Portão 1: o medo funciona?

Publique em modo privado e jogue com 4 pessoas reais, com voz, por pelo menos 5 expedições.

| Pergunta | Aprovado se |
|---|---|
| Pedem "só mais uma" sem você sugerir? | Pelo menos 3 de 4 |
| Aconteceu um resgate memorável ou um grito? | Pelo menos 1 por sessão |
| Taxa de extração | Entre 40% e 60% |
| Alguém escolhe ficar por mais valor? | Pelo menos 1 vez por sessão |
| O preso ficou entediado? | Não reclamaram dos 2 minutos |

Se não passar, ajuste `Config.lua` e repita antes de seguir. Economia não resolve um problema de medo.

---

# Camada 2: Superfície

## M10. Perfil salvo

**O que faz:** salva dinheiro, itens guardados e upgrades entre sessões.

**Skills:** `roblox-datastores`, `roblox-security`, `luau-strict-typing`. Ao final, rode o agente `roblox-dev:roblox-reviewer`.

**Prepare no Studio:** publique o lugar. Em **Game Settings → Security**, ligue **Enable Studio Access to API Services**.

**Teste manual:**
1. Extraia itens. Uma mensagem mostra os itens guardados.
2. Clique em **Dar 100 moedas**. O HUD mostra 100.
3. Pare o teste e dê Play de novo. Os itens e as moedas continuam.
4. Clique em **Resetar perfil** e reinicie. Está tudo zerado.
5. Use Reset no personagem enquanto carrega itens: eles se perdem, e o guardado continua.
6. Em uma sessão de 2 minutos, confira no Output que há um autosave.

**Prompt:**

```text
Use a skill ecos-da-penumbra. Consulte roblox-dev:roblox-datastores, roblox-dev:roblox-security e roblox-dev:luau-strict-typing. Implemente o módulo M10 de docs/PLANO-FASE-1.md. M1 a M9 já existem.

Antes de codar, leia a documentação oficial do ProfileStore e me diga como pretende adicioná-lo. Este projeto não usa Wally. Pare e pergunte antes de baixar qualquer arquivo. Se não for viável, diga em vez de escrever session locking à mão.

1. Crie src/server/systems/PlayerProfile.lua (--!strict), único módulo que acessa dados persistidos. Formato com version: money (0), stash (lista de { id, type, rarity, value }), upgrades ({}), relicDisplay (lista de ids), contracts ({}).
2. API: Get(player), AddMoney(player, amount), SpendMoney(player, amount) -> boolean, AddStashItems(player, items), RemoveStashItem(player, id) -> item?, BindableEvent Updated(player). Valide inteiros e não negativos. Os ids dos itens são gerados no servidor com HttpService:GenerateGUID.
3. Limite Config.StashMaxItems (40). Se o baú estiver cheio, nenhuma extração pode perder itens: permita ultrapassar e avise o jogador para vender antes de pegar mais; não apague nada.
4. Se o carregamento falhar, não deixe o jogador jogar com perfil vazio: mostre mensagem e use a saída indicada pela biblioteca.
5. ExtractionSystem: guarde o recibo do M6 com AddStashItems antes de limpar a mochila, com o valor travado. A ordem nunca pode permitir duplicar nem perder.
6. RemoteEvent ProfileUpdate (servidor para cliente): dinheiro e itens guardados, sem dados de outros jogadores. Crie src/client/ui/ProfileHUD.lua com o dinheiro em tamanho responsivo.
7. QA: "Dar 100 moedas" e "Resetar perfil", usando a mesma API.
8. Salvamento: autosave, saída do jogador e BindToClose, conforme a biblioteca.

Arquivos autorizados: os citados, QACommands.lua, QAPanel.lua, init.server.lua, init.client.lua, Config.lua, e o arquivo da biblioteca depois da minha aprovação. Siga o fluxo de trabalho do CLAUDE.md. Não rode Rojo, não abra o Studio e não faça commit até eu aprovar o teste. Entregue o teste manual em passos para quem não é desenvolvedor. Ao final, rode o agente roblox-dev:roblox-reviewer e me mostre o resumo.
```

## M11. Lobby

**O que faz:** dá identidade à superfície: claro e seguro em contraste com a caverna. A transição acontece no elevador.

**Skills:** `roblox-ui`, `roblox-performance`, `luau-strict-typing`.

**Prepare no Studio:** construa o lobby com a Plataforma do Elevador, o Mercado, a Oficina e o Quadro de Contratos. Crie as Parts `LobbyMarket`, `LobbyWorkshop` e `LobbyBoard` (Anchored) em cada zona, sem scripts. Deixe `LobbyElevator` a poucos passos de onde o jogador chega.

**Teste manual:**
1. No lobby, a tela é clara e não aparece a barra de ruído.
2. Ao descer, a tela escurece em uma transição, e a caverna fica escura.
3. Ao extrair, ocorre a transição inversa.
4. O painel do elevador mostra "Expedição em andamento" com o número de pessoas na caverna.
5. Se o Guardião rugir com alguém no Ninho, quem está no lobby ouve um som abafado.
6. Em tela de celular (Device Emulator), nada sobrepõe.

**Prompt:**

```text
Use a skill ecos-da-penumbra. Consulte roblox-dev:roblox-ui, roblox-dev:roblox-performance e roblox-dev:luau-strict-typing. Implemente o módulo M11 de docs/PLANO-FASE-1.md. M1 a M10 já existem.

1. RemoteEvent LocationChanged (servidor para cliente), disparado por PlayerState.Changed, somente ao próprio jogador.
2. Crie src/client/ZoneLighting.lua (--!strict): aplica no cliente as predefinições Config.LobbyLighting e Config.CaveLighting em Lighting, com transição usando TweenService e uma tela escura curta nos teleportes.
3. NoiseBar: visível só na caverna. Sem novas lógicas de ruído.
4. Painel do elevador: SurfaceGui em workspace.LobbyElevator com fase e número de pessoas na caverna, atualizado pelo servidor, nada além disso.
5. Quando um jogador virar Captive, envie aos jogadores em Lobby um som abafado via WorldAudio, sem posição. Use a chave Config.Audio.Rumble.

Arquivos autorizados: os citados, PlayerState.lua, NestSystem.lua, ExpeditionSystem.lua, init.client.lua, init.server.lua, Config.lua. Siga o fluxo de trabalho do CLAUDE.md. Não rode Rojo, não abra o Studio e não faça commit até eu aprovar o teste. Entregue o teste manual em passos para quem não é desenvolvedor.
```

## M12. Mercado do Lobby

**O que faz:** vende itens guardados por 80% do valor, sem risco.

**Skills:** `roblox-security`, `roblox-ui`, `luau-strict-typing`. Ao final, rode o agente `roblox-dev:roblox-reviewer`.

**Teste manual:**
1. Vá até o `LobbyMarket` e abra a tela. Os itens aparecem com o preço de venda.
2. Venda um item de valor 100. Você recebe 80 e o item some.
3. Reinicie: a venda continua registrada.
4. Com a tela aberta, afaste-se do mercado e tente vender. Não funciona.
5. Clique rápido duas vezes em Vender. Só uma venda acontece.

**Prompt:**

```text
Use a skill ecos-da-penumbra. Consulte roblox-dev:roblox-security, roblox-dev:roblox-ui e roblox-dev:luau-strict-typing. Implemente o módulo M12 de docs/PLANO-FASE-1.md. M1 a M11 já existem.

1. Crie src/server/systems/MarketSystem.lua (--!strict). Prompt em workspace.LobbyMarket abre a tela.
2. RemoteEvent SellItem(itemId): valide tipo string, limite 5 por segundo, jogador em Lobby e a até Config.MarketRadius (20 studs). Remova o item com PlayerProfile.RemoveStashItem primeiro e só então chame AddMoney, com math.floor(value * Config.LobbyMarketRate), sendo a taxa 0.8. Se o item não existir, ignore. O preço nunca vem do cliente.
3. Crie src/client/ui/MarketUI.lua (--!strict), que só mostra o estado recebido por ProfileUpdate e faz pedidos. Mostre o preço de venda de forma positiva ("Venda segura"), sem falar em desconto. Tamanhos em escala, com rolagem.

Arquivos autorizados: os citados, init.server.lua, init.client.lua, Config.lua. Siga o fluxo de trabalho do CLAUDE.md. Não rode Rojo, não abra o Studio e não faça commit até eu aprovar o teste. Entregue o teste manual em passos para quem não é desenvolvedor. Ao final, rode o agente roblox-dev:roblox-reviewer e me mostre o resumo.
```

## M13. Oficina e Botas

**O que faz:** cria os upgrades permanentes, começando pelas Botas Silenciosas, e a exposição de Relíquias.

**Skills:** `roblox-security`, `roblox-ui`, `luau-strict-typing`. Ao final, rode o agente `roblox-dev:roblox-reviewer`.

**Prepare no Studio:** na Oficina, crie a pasta `RelicDisplays` com 3 Parts Anchored.

**Teste manual:**
1. Tente comprar as Botas sem dinheiro: recusado.
2. Com dinheiro, compre: o valor é descontado e o botão muda para "Comprado". Não dá para comprar duas vezes.
3. Na caverna, caminhe e compare a barra de ruído: menor do que antes.
4. Aperte V: o pico de voz é igual ao de antes das Botas.
5. Exponha uma Relíquia: ela aparece em um suporte para todos, e não pode mais ser vendida.
6. Retire a Relíquia: ela volta ao baú. Reinicie: a exposição continua.

**Prompt:**

```text
Use a skill ecos-da-penumbra. Consulte roblox-dev:roblox-security, roblox-dev:roblox-ui e roblox-dev:luau-strict-typing. Implemente o módulo M13 de docs/PLANO-FASE-1.md. M1 a M12 já existem.

1. Crie src/server/systems/WorkshopSystem.lua (--!strict). Config.Upgrades é o catálogo: Boots (preço Config.BootsPrice = 500), com espaço para Hook no M16.
2. RemoteEvent BuyUpgrade(upgradeId): valide tipo, limite de frequência, catálogo, Lobby e distância até workspace.LobbyWorkshop. Só compre se SpendMoney retornar true e o upgrade não estiver no perfil.
3. NoiseSystem: SetMoveMultiplier(player, value), aplicado somente ao componente de movimento. Com Boots use Config.BootsMoveMultiplier (0.6). Voz, peso e boosts não mudam.
4. RemoteEvents DisplayRelic(itemId) e RetrieveRelic(itemId), com as mesmas validações. Só aceitam type Relic. Relíquia exposta fica fora do baú e em relicDisplay, de modo que não possa ser vendida. Limite ao número de Parts em workspace.RelicDisplays. Mostre um modelo simples por servidor para os presentes.
5. Crie src/client/ui/WorkshopUI.lua (--!strict), que só mostra estado e faz pedidos. Tamanhos em escala.

Arquivos autorizados: os citados, MarketSystem.lua somente se necessário, PlayerProfile.lua, init.server.lua, init.client.lua, Config.lua. Siga o fluxo de trabalho do CLAUDE.md. Não rode Rojo, não abra o Studio e não faça commit até eu aprovar o teste. Entregue o teste manual em passos para quem não é desenvolvedor. Ao final, rode o agente roblox-dev:roblox-reviewer e me mostre o resumo.
```

## Portão 2: a superfície dá vontade de voltar?

Com os mesmos 4 testers:

| Pergunta | Aprovado se |
|---|---|
| Quanto tempo ficam no lobby entre expedições? | Menos de 1 minuto em média |
| Voltam no dia seguinte sem convite? | Pelo menos 2 de 4 |
| Sabem dizer o que querem comprar? | A maioria sabe |
| Houve perda de dados ou item duplicado? | Nenhuma ocorrência |

---

# Camada 3: Variedade

## M14. Guardião Corista

**O que faz:** cria o sorteio de variantes. Com o Corista, uma voz distorcida toca em um ponto falso quando alguém faz barulho de voz.

**Skills:** `roblox-security`, `roblox-architecture`, `roblox-performance`, `luau-strict-typing`. Ao final, rode o agente `roblox-dev:roblox-reviewer`.

**Teste manual:**
1. Clique em **Próximo: Corista** e desça. O Output mostra `[Director] Mimic`.
2. Aperte V. Uma voz distorcida toca em outro lugar. Vire a câmera: o som vem de um ponto fixo.
3. Aperte V várias vezes. A voz toca no máximo uma vez a cada 12s.
4. Clique em **Próximo: Cego**, desça e aperte V. A voz não toca.
5. Faça 10 expedições sem forçar. O Output nunca repete a variante duas vezes seguidas.
6. Em **Clients and Servers** com 2 jogadores, os dois ouvem do mesmo lugar.

**Prompt:**

```text
Use a skill ecos-da-penumbra. Consulte roblox-dev:roblox-security, roblox-dev:roblox-architecture, roblox-dev:roblox-performance e roblox-dev:luau-strict-typing. Implemente o módulo M14 de docs/PLANO-FASE-1.md. M1 a M13 já existem. O ID da voz é [COLE O ID].

1. Enums: adicione GuardianVariant (Blind, Mimic, Deceiver).
2. Crie src/server/systems/GuardianDirector.lua (--!strict): em Started, sorteie a variante sem repetir a anterior e chame Start() do módulo; em Ended, chame Stop(). Blind não faz nada extra. O sorteio é lógica pura com rng injetado. Variante só no servidor. Registre Blind e Mimic, de modo que Deceiver entre em uma linha. Logue [Director] <variante>.
3. Crie src/server/systems/MimicGuardian.lua (--!strict), com Start() e Stop(). Ao receber NoiseSystem.VoiceSpiked com intensidade >= Config.MimicTriggerIntensity (5), respeitando Config.MimicCooldown (12s) por servidor, escolha um ponto de 15 a 30 studs do centro dos jogadores em Cave, ajustado ao chão por raycast. Sem chão, não toque. Envie via WorldAudio com position.
4. WorldAudio.lua: adicione a chave MimicVoice com PlaybackSpeed aleatório entre 0.85 e 0.95 no AudioPlayer. AudioEmitter não tem essa propriedade. Não adicione efeitos de áudio.
5. Não implemente gravação da voz real.
6. QA: "Próximo: Cego" e "Próximo: Corista".

Arquivos autorizados: os citados, QACommands.lua, QAPanel.lua, init.server.lua, Config.lua, Enums.lua. Siga o fluxo de trabalho do CLAUDE.md. Não rode Rojo, não abra o Studio e não faça commit até eu aprovar o teste. Entregue o teste manual em passos para quem não é desenvolvedor. Ao final, rode o agente roblox-dev:roblox-reviewer e me mostre o resumo.
```

## M15. Guardião Enganador

**O que faz:** cria núcleos falsos perto do jogador mais barulhento, com som de queda, e paredes falsas atravessáveis.

**Skills:** `roblox-security`, `roblox-performance`, `luau-strict-typing`. Ao final, rode o agente `roblox-dev:roblox-reviewer`.

**Prepare no Studio:** crie a pasta `FakeWallSlots` com 2 a 4 Parts cobrindo corredores, Anchored, sem colisão e invisíveis. Tenha os IDs da risada e da queda.

**Teste manual:**
1. Clique em **Próximo: Enganador** e desça.
2. Ande. A cada 8s pode surgir um núcleo perto de você, com som de queda. Há no máximo 3, e eles somem em 20s.
3. Acione um falso: ele some, toca a risada, e a mochila **não** muda.
4. Compare um falso com um verdadeiro na visão Client: propriedades e Attributes são iguais.
5. Pegue um falso antes de qualquer núcleo verdadeiro. O Guardião não acorda.
6. Espere uma parede falsa: parece sólida, é atravessável e some em 5s.
7. Encerre a expedição: tudo que era falso desaparece.

**Prompt:**

```text
Use a skill ecos-da-penumbra. Consulte roblox-dev:roblox-security, roblox-dev:roblox-performance e roblox-dev:luau-strict-typing. Implemente o módulo M15 de docs/PLANO-FASE-1.md. M1 a M14 já existem. IDs: risada [COLE O ID], queda [COLE O ID].

1. LootSystem.lua: troque a verificação do Attribute IsFake por uma tabela só no servidor. Adicione MarkFake(part, onTriggered). Acionado, um falso chama onTriggered, é destruído e não altera mochila, peso nem FirstCoreExtracted. Deve ser chamado antes de entrar no Workspace.
2. Crie src/server/systems/DeceiverGuardian.lua (--!strict), com Start() e Stop(), usando contador de geração para encerrar loops antigos.
3. A cada Config.DeceiverCoreInterval (8s), se o jogador mais barulhento em Cave estiver acima do limite e houver menos de Config.DeceiverMaxFakeCores (3): clone ServerStorage.CoreTemplate, marque com MarkFake e coloque de 8 a 20 studs do jogador, no chão por raycast. Sem chão, pule. Limpe com Debris após Config.DeceiverCoreLifetime (20s). Envie WorldAudio de queda nessa posição. Ao acionar, envie a risada. O falso não leva nenhuma marca que o diferencie.
4. A cada Config.DeceiverWallInterval (20s), escolha um slot de workspace.FakeWallSlots e crie uma parede no mesmo CFrame e Size, com CanCollide = false, Transparency = 0, material de rocha, por Config.DeceiverWallLifetime (5s). Sem pasta, registre um único warn.
5. Stop() destrói tudo que foi criado.
6. Registre Deceiver em GuardianDirector, adicione as chaves em Config.Audio e o botão "Próximo: Enganador".

Arquivos autorizados: os citados, WorldAudio.lua, QACommands.lua, QAPanel.lua, Config.lua. Siga o fluxo de trabalho do CLAUDE.md. Não rode Rojo, não abra o Studio e não faça commit até eu aprovar o teste. Entregue o teste manual em passos para quem não é desenvolvedor. Ao final, rode o agente roblox-dev:roblox-reviewer e me mostre o resumo.
```

## M16. Gancho

**O que faz:** dá fuga vertical em pontos marcados no mapa, ao custo de barulho.

**Skills:** `roblox-security`, `roblox-performance`, `luau-strict-typing`. Ao final, rode o agente `roblox-dev:roblox-reviewer`.

**Prepare no Studio:** na caverna, construa saliências e buracos no teto. Cada um recebe uma Part na pasta `HookPoints`, Anchored e sem colisão. Devem existir rotas que só o gancho alcança, sem que sejam obrigatórias para extrair.

**Teste manual:**
1. Sem o upgrade, nada acontece ao apertar a tecla.
2. Compre o Gancho na Oficina. Na caverna, um indicador aparece perto de um ponto.
3. Use o gancho: você sobe até o ponto, e a barra de ruído dispara.
4. Tente usar de novo logo em seguida: há uma espera de 10s.
5. Tente alcançar um ponto atrás de uma parede: não funciona.
6. Aperte a tecla preso no Ninho: nada acontece.

**Prompt:**

```text
Use a skill ecos-da-penumbra. Consulte roblox-dev:roblox-security, roblox-dev:roblox-performance e roblox-dev:luau-strict-typing. Implemente o módulo M16 de docs/PLANO-FASE-1.md. M1 a M15 já existem.

Antes de codar, diga como pretende mover o personagem de forma confiável, considerando que o cliente controla a física do próprio personagem. Se não tiver certeza, diga "não tenho certeza" e proponha uma opção para eu testar.

1. Adicione Hook em Config.Upgrades (Config.HookPrice = 1500).
2. Crie src/server/systems/HookSystem.lua (--!strict). RemoteEvent UseHook(pointName): valide tipo, limite de frequência, posse do upgrade, estado Cave, ponto em workspace.HookPoints, distância até Config.HookRange (40 studs), linha de visão por raycast no servidor e cooldown Config.HookCooldown (10s). O cliente nunca envia posição.
3. Ao usar, dê um pulso de ruído por NoiseSystem.SetNoiseBoost.
4. Crie src/client/HookController.lua (--!strict), que destaca o ponto válido mais próximo e faz o pedido por tecla e por botão no celular.

Arquivos autorizados: os citados, init.server.lua, init.client.lua, Config.lua. Siga o fluxo de trabalho do CLAUDE.md. Não rode Rojo, não abra o Studio e não faça commit até eu aprovar o teste. Entregue o teste manual em passos para quem não é desenvolvedor. Ao final, rode o agente roblox-dev:roblox-reviewer e me mostre o resumo.
```

## M17. Contratos

**O que faz:** cria missões diárias e semanais que dão motivos para correr riscos na caverna.

**Skills:** `roblox-datastores`, `roblox-security`, `roblox-ui`, `luau-strict-typing`.

**Teste manual:**
1. Abra o Quadro de Contratos. Há 3 diários e 1 semanal, com progresso.
2. Extraia itens: o contrato "Extraia 5 núcleos" avança.
3. Extraia depois do minuto 8 (com **Pular para minuto 8**): o contrato correspondente avança.
4. Resgate alguém: o contrato "Resgate um preso" avança.
5. Complete um e clique em **Receber**: o dinheiro entra, e não dá para receber duas vezes.
6. Clique em **Virar o dia**: os diários mudam, e o semanal continua.
7. Reinicie: o progresso continua.

**Prompt:**

```text
Use a skill ecos-da-penumbra. Consulte roblox-dev:roblox-datastores, roblox-dev:roblox-security, roblox-dev:roblox-ui e roblox-dev:luau-strict-typing. Implemente o módulo M17 de docs/PLANO-FASE-1.md. M1 a M16 já existem.

1. Crie src/server/systems/ContractSystem.lua (--!strict). Config.Contracts define tipo, meta e recompensa. Exemplos: extrair núcleos, extrair Relíquia, extrair depois do minuto 8, resgatar um preso.
2. Escolha de 3 diários e 1 semanal por data UTC, determinística, usando funções puras com a data como parâmetro. Guarde progresso em PlayerProfile.contracts, com a chave da data.
3. Avance só por eventos do servidor: Extracted e o novo KidnapSystem/NestSystem.PlayerRescued(rescuer, captive).
4. RemoteEvent ClaimContract(contractId): valide tudo no servidor e marque como recebido antes de chamar AddMoney. Nunca aceite progresso do cliente.
5. Crie src/client/ui/ContractUI.lua (--!strict), com prompt em workspace.LobbyBoard. Tamanhos em escala.
6. QA: "Virar o dia", avançando um deslocamento de data apenas no Studio.

Arquivos autorizados: os citados, NestSystem.lua, QACommands.lua, QAPanel.lua, init.server.lua, init.client.lua, Config.lua. Siga o fluxo de trabalho do CLAUDE.md. Não rode Rojo, não abra o Studio e não faça commit até eu aprovar o teste. Entregue o teste manual em passos para quem não é desenvolvedor.
```

## Portão 3: as variantes mudam a forma de jogar?

| Pergunta | Aprovado se |
|---|---|
| Comentam qual Guardião estavam enfrentando? | Em metade das expedições |
| A taxa de extração | Entre 50% e 65% |
| Os contratos mudaram alguma decisão? | Citam pelo menos um exemplo |
| Veteranos com Botas ainda sentem medo? | Dizem que sim |

---

# Camada 4: Mundo e viral

## M18. Mercado Negro

**O que faz:** cria a loja da floresta, com preços de 100% a 150% baseados em pedidos de NPCs. O PvP não entra nesta fase.

**Skills:** `roblox-security`, `roblox-ui`, `luau-strict-typing`. Ao final, rode o agente `roblox-dev:roblox-reviewer`.

**Prepare no Studio:** construa a floresta a menos de 30 segundos de caminhada do lobby. Crie a Part `BlackMarketStall` e, ao lado do elevador do lobby, a Part `OrdersBoard`.

**Teste manual:**
1. O `OrdersBoard` mostra os pedidos atuais, como "Preciso de 5 Núcleos — 130%".
2. Com 5 núcleos no baú, vá à floresta e entregue: você recebe o valor total × 1,3.
3. Com só 4, a entrega é recusada, e os itens continuam no baú.
4. Tente entregar de longe da barraca: não funciona.
5. Espere 10 minutos ou clique em **Girar pedidos**: novos pedidos aparecem.
6. Sem ir à floresta, ainda dá para vender tudo no Mercado do Lobby.

**Prompt:**

```text
Use a skill ecos-da-penumbra. Consulte roblox-dev:roblox-security, roblox-dev:roblox-ui e roblox-dev:luau-strict-typing. Implemente o módulo M18 de docs/PLANO-FASE-1.md. M1 a M17 já existem. Não implemente Iscas de Eco, NPCs hostis ou PvP.

1. Crie src/server/systems/BlackMarketSystem.lua (--!strict). Ele mantém 3 pedidos por servidor, em memória, com type, rarity opcional, quantity e priceRate entre 1.0 e 1.5, gerados por lógica pura com rng injetado, e trocados a cada Config.BlackMarketRotation (600s).
2. RemoteEvent FulfillOrder(orderId): valide tipo, limite de frequência, Lobby, distância até workspace.BlackMarketStall. Confirme que há itens suficientes no baú e que o pedido ainda vale. Remova todos os itens primeiro e só então pague a soma dos valores × priceRate, arredondada para baixo. Um pedido por servidor pode ser atendido uma vez.
3. Mostre os pedidos em SurfaceGui em workspace.OrdersBoard e na interface da barraca. Crie src/client/ui/BlackMarketUI.lua (--!strict), que só mostra estado e faz pedidos.
4. Relíquias expostas nunca entram.
5. QA: "Girar pedidos".

Arquivos autorizados: os citados, PlayerProfile.lua somente se necessário, QACommands.lua, QAPanel.lua, init.server.lua, init.client.lua, Config.lua. Siga o fluxo de trabalho do CLAUDE.md. Não rode Rojo, não abra o Studio e não faça commit até eu aprovar o teste. Entregue o teste manual em passos para quem não é desenvolvedor. Ao final, rode o agente roblox-dev:roblox-reviewer e me mostre o resumo.
```

## M19. Mural de Destaques

**O que faz:** exibe os maiores saques da semana e as histórias do servidor na plataforma do elevador.

**Skills:** `roblox-datastores`, `roblox-performance`, `roblox-ui`, `luau-strict-typing`.

**Prepare no Studio:** crie a Part `HighlightsWall` na Plataforma do Elevador.

**Teste manual:**
1. Extraia um saque grande. Em até 5 minutos, ou com **Atualizar mural**, seu nome aparece.
2. Um saque menor não substitui o seu recorde.
3. Com um resgate, uma frase como "Ana voltou do Ninho faltando 3s" aparece no mural.
4. Desligue o acesso às APIs do Studio: o jogo continua, e o mural mostra uma mensagem neutra.

**Prompt:**

```text
Use a skill ecos-da-penumbra. Consulte roblox-dev:roblox-datastores, roblox-dev:roblox-performance, roblox-dev:roblox-ui e roblox-dev:luau-strict-typing. Implemente o módulo M19 de docs/PLANO-FASE-1.md. M1 a M18 já existem.

1. Crie src/server/systems/HighlightsSystem.lua (--!strict). Use OrderedDataStore com chave por semana UTC e valor inteiro do melhor saque. Grave no máximo uma vez ao fim de cada expedição, por jogador, e só se superar o melhor conhecido, com UpdateAsync.
2. Leia o top 10 a cada Config.HighlightsRefresh (300s). Todas as chamadas em pcall, com retry e sem nunca interromper o jogo.
3. Obtenha nomes pelo UserId com pcall e cache.
4. Mantenha em memória as 5 últimas histórias do servidor, a partir de eventos: resgate perto do fim do tempo, extração depois do minuto 10, Relíquia extraída. Só frases prontas com nomes de usuário: sem texto livre.
5. Mostre em SurfaceGui em workspace.HighlightsWall. Se a leitura falhar, mostre mensagem neutra.
6. QA: "Atualizar mural".

Arquivos autorizados: os citados, QACommands.lua, QAPanel.lua, init.server.lua, Config.lua. Siga o fluxo de trabalho do CLAUDE.md. Não rode Rojo, não abra o Studio e não faça commit até eu aprovar o teste. Entregue o teste manual em passos para quem não é desenvolvedor.
```

## M20. Clipes

**O que faz:** grava em vídeo durante a expedição e, no sequestro falho, no retorno ao lobby ou na extração, oferece **Salvar** e **Compartilhar**.

**Limite conhecido:** a documentação não informa o limite de tempo, nem se o Studio grava, nem se a voz entra no vídeo. Também não cita buffer retroativo, 9:16 ou watermark. A Parte B mede isso.

**Skills:** `roblox-ui`, `roblox-security`, `luau-strict-typing`. Ao final, rode o agente `roblox-dev:roblox-reviewer`.

**Teste manual:**

Parte A, no Studio:
1. Dê Play e desça. O Output mostra `[Clips] Gravação: <resultado>`.
2. Se der erro, o jogo segue normal e nada aparece na tela. Isso é aceitável no Studio.

Parte B, em um lugar publicado e privado:
1. Perca a mochila ou extraia. A tela oferece **Salvar** e **Compartilhar**.
2. Salve e abra o vídeo. Anote a duração.
3. Clique em **Compartilhar** e veja o que a Roblox oferece.
4. Fale no voice chat durante a gravação e veja se a voz entra no vídeo.
5. Veja se o texto "Ecos da Penumbra" aparece.
6. Jogue 15 minutos e anote quando o Output mostra `TimeLimitReached`.
7. Envie os resultados ao Opus, para decidir sobre 9:16 e voz.

**Prompt:**

```text
Use a skill ecos-da-penumbra. Consulte roblox-dev:roblox-ui, roblox-dev:roblox-security e roblox-dev:luau-strict-typing. Implemente o módulo M20 de docs/PLANO-FASE-1.md. M1 a M19 já existem. Antes de codar, leia https://create.roblox.com/docs/reference/engine/classes/CaptureService e use os argumentos exatos dos exemplos de lá. Não use VideoCaptureService.

1. RemoteEvent ClipSignal (somente servidor para cliente), com "start" e "stop". Envie "start" quando o jogador descer. Envie "stop" ao voltar ao lobby por qualquer motivo. O cliente não envia nada por esse remote.
2. Crie src/client/clips/ClipExporter.lua (--!strict), iniciado por init.client.lua. Use StartVideoCaptureAsync e StopVideoCapture. Logue o resultado com prefixo [Clips].
3. Ao receber TimeLimitReached, guarde a gravação e comece outra. Mantenha as 2 últimas. Se a última tiver menos de 10s, ofereça a anterior. É uma aproximação dos últimos 30s: não tente implementar buffer.
4. Qualquer falha é silenciosa para o jogador: registre no Output e siga. O jogo nunca depende da gravação. Use pcall nas chamadas que podem falhar.
5. Crie src/client/ui/ClipPrompt.lua (--!strict), com Salvar (PromptSaveCapturesToGallery) e Compartilhar (PromptShareCapture com Content.fromObject). Tamanhos em escala. Só aparece com gravação válida e fecha na próxima descida.
6. Durante a gravação, mostre um pequeno texto "Ecos da Penumbra" no canto, para verificarmos se a interface entra no vídeo.
7. Não implemente recorte 9:16, watermark no arquivo nem mixagem de voz.

Se a documentação não deixar claro algum argumento, diga "não tenho certeza" e pergunte. Arquivos autorizados: os citados, ExpeditionSystem.lua, init.server.lua, init.client.lua. Siga o fluxo de trabalho do CLAUDE.md. Não rode Rojo, não abra o Studio e não faça commit até eu aprovar o teste. Entregue o teste manual em passos para quem não é desenvolvedor. Ao final, rode o agente roblox-dev:roblox-reviewer e me mostre o resumo.
```

## Portão final

Com os mesmos 4 testers, segundo o PDF 2.5:

- Voltam no dia seguinte sem convite.
- A taxa de extração fica entre 50% e 65%.
- Pelo menos um clipe é gerado e compartilhado espontaneamente.

Só então volte ao PvP com Iscas de Eco, com os resultados do teste na mão, e às guildas e monetização.
