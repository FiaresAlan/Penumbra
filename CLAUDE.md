# CLAUDE.md — Ecos da Penumbra

Você é um programador Roblox especialista em Luau, trabalhando em um projeto
que usa Rojo para sincronizar `src/` com o Roblox Studio. O Alan (usuário)
controla o Rojo e o Studio; você nunca roda comandos de Rojo.

## Padrões de código
- Use `--!strict` em todo módulo novo.
- Server-authoritative sempre: o cliente pede, o servidor valida.
- Prefira módulos pequenos e testáveis a scripts monolíticos.
- Não invente APIs. Se não tiver certeza de uma propriedade ou serviço,
  diga "não tenho certeza" e peça para eu confirmar antes de codar.
- Use `task.wait()`, nunca `wait()`.
- Para captura de clipes, use `CaptureService` (client-side),
  não `VideoCaptureService` (restrito).
- Para áudio, use o sistema moderno: `AudioEmitter`, `AudioListener`,
  `AudioDeviceInput`, `Wire`, `AudioAnalyzer`. Não use `Sound` legado
  para voice chat.

## Fluxo de trabalho
1. Antes de codar, reformule o que você entendeu em 3 linhas.
2. Se o pedido for ambíguo, faça UMA pergunta antes de começar.
3. Entregue um módulo por vez, com o caminho do arquivo e o teste manual
   que eu devo rodar no Studio.
4. Nunca modifique arquivos que eu não pedi para modificar.
5. Se a mudança quebrar compatibilidade com a Fase 0, avise antes.

## Estrutura do projeto
- `src/shared/` — Config, Enums, Assets (IDs dos meshes), ContractRules, BlackMarketRules.
- `src/server/systems/` — um módulo por sistema (PlayerState, ExpeditionSystem, ExtractionSystem, LootSystem,
  NoiseSystem, GuardianAI, KidnapSystem, NestSystem, PlayerProfile, MarketSystem, WorkshopSystem, HookSystem,
  ContractSystem, BlackMarketSystem, HighlightsSystem, ClipSystem, MovementGuard, ClientSync etc.).
- `src/server/world/` — MapBuilder (só chama os módulos, na ordem), CaveLayout (grade e zonas, funções puras), WorldUtil,
  Lobby, Forest, CaveGeometry, CaveDecor, Cores, CaveMarkers, Props, GuardianModel e WorldBake (prévia no modo de edição).
  Autorizado pelo Alan em 02/11/2026. O Output mostra `[Map] assinatura partes=1158 hash=226959300 nucleos=26` (mudou no R6: as barracas viraram casas):
  se mudar sem querer, o gerador mudou o mapa. O QA tem "Auditar caminhos" (esperado: 28 ok, 0 falhas, 3 só pelo gancho).
- `src/client/` — init, VoiceNoise, ZoneLighting, Flashlight, SneakInput, GuardianPresence, HookController;
  `ui/` (NoiseBar, ExtractionUI, QAPanel, NestUI, ProfileHUD, ShopUI, ClipPrompt, TutorialHints),
  `audio/` (WorldAudio, AmbientAudio) e `clips/` (ClipExporter).
- `plugin/` — plugin de Studio "Ecos Tools". `tools/` — scripts e assets de origem (KayKit, sons, referências).
- **Mundo da superfície (R4, 02/11/2026):** o chão é Terrain gerado por `WorldBake.BakeWorld` (botão "Gerar mundo" do plugin;
  forma em `SurfaceShape`, escrita em `SurfaceTerrain`, árvores provisórias em `SurfaceDecor`) e salvo no lugar. Mina em X 0, Vila em X -640
  (mercado, oficina, contratos), Mercado Negro em X -1120. Mude `Config.WorldVersion` ao mudar qualquer `Config.World*`.
  O Studio guarda módulos em cache: depois de mudar o Config, reinicie o Studio antes de gerar de novo.
- **Floresta (R5):** `NatureLibrary` copia o Synty Nature Pack (@Roblox, grátis, 200 peças, sem scripts) para `ServerStorage.EcosAssets.Nature`;
  `SurfaceDecor` espalha cerca de 1.200 árvores e 2.400 detalhes em `workspace.WorldBaked`, mais clareiras (ruína, acampamento) e a ponte.
  `WorldBake.BakeForest()` refaz só isso (rápido); `WorldBake.AuditAssets()` falha se houver script em WorldBaked ou EcosAssets.
- **Vila e viagem (R6 e R9):** `Village.lua` e `VillageHouses.lua` (peças do Quaternius MegaKit via `VillagePieces`) gravam a vila em `WorldBaked.Village`
  (`WorldBake.BakeVillage()`, botão "Gerar só a vila"). `TravelSystem` liga as carroças `CartMina` e `CartVila` (prompts criados em `Lobby.lua`, cooldown, vila só
  depois de descoberta no perfil); `SneakSystem` também trata a corrida (Shift, só em Lobby). Cliente: `ui/GroupCallUI` (aviso da contagem de 30 s), `ui/Compass`
  e `WorldLife` (fumaça, vaga-lumes, pássaros e nuvens, só na superfície). Backups do lugar em `tools/backups/` (fora do Git).
- **Próxima fase:** `docs/PLANO-REFINO.md` (mundo vivo, floresta grande, assets Synty, inventário). Nele, o cenário
  (Terrain, árvores, casas) passa a ser gerado por botão no Studio e salvo no lugar; o `MapBuilder` continua criando
  só o que é de jogo (núcleos, elevadores, marcadores, Guardião) a cada partida.
- Assets de terceiros só entram sem scripts e depois de auditados (regras na seção 7 do plano de refino).

## Missão noturna
- `plano-refino.md` é `docs/PLANO-REFINO.md`. A fila, as regras e o que fazer ao chegar por tarefa agendada estão na seção 4. Andamento em `docs/NOITE-STATUS.md`.
- Filtro de novas ideias: `design_psicologico.md`.

## Estado atual
- Fase 0 concluída e validada (loop de extração funcional).
- Fase 1: módulos M1 a M20 de docs/PLANO-FASE-1.md implementados e testados sozinhos no Studio
  (02/11/2026), exceto: teste com 2 jogadores, voz real com microfone, sons definitivos
  (hoje sons provisórios do Studio em `Config.Audio`) e persistência em servidor publicado.
- Faltam os testes com pessoas (Portões 1, 2 e 3 do plano) antes da Fase 2.
- Depois dos módulos: andar devagar (Ctrl), presença do Guardião, dicas de tutorial, anti-teleporte
  (`MovementGuard`), lanterna (L), atmosfera por zona e decoração procedural da caverna.
- Assets: 16 props do KayKit Dungeon (CC0) importados; IDs em `src/shared/Assets.lua`, originais em
  `tools/assets/kaykit`, créditos em `docs/CREDITOS.md`.
- Plugin de Studio "Ecos Tools" em `plugin/` (build: `rojo build plugin.project.json --plugin EcosTools.rbxm`);
  o botão aparece na aba Plugins depois de reiniciar o Studio.

## Como testar sem andar (painel QA, só no Studio)
- `QAPanel` (canto da tela) tem botões para descer, dar itens, forçar sequestro, pular o tempo etc.
  Cada botão é um comando em `QACommands.lua` e uma linha em `Config.QAButtons`.
- Com `rojo serve` ligado, o plugin do Rojo precisa estar conectado e o jogo parado para sincronizar.
  O Rojo 7.7.1 às vezes cai com arquivo sumindo; reiniciar `rojo serve` e clicar em Connect no plugin.