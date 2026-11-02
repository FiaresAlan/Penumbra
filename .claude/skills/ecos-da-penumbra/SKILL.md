---
name: ecos-da-penumbra
description: Regras obrigatórias do jogo Roblox "Ecos da Penumbra" (extração cooperativa 16+, Luau + Rojo). Use sempre que for planejar, escrever, revisar ou testar qualquer código deste projeto, incluindo Guardiões, ruído, núcleos, elevador, PitySystem, voice chat e clipes, mesmo que o pedido não cite a skill.
---

# Ecos da Penumbra

Jogo de extração cooperativa 16+. O loop central: pegar núcleos, carregar peso
(que gera ruído), fugir do Guardião, extrair no elevador. O Guardião caça pelo
som acumulado do jogador, nunca pela visão.

## Regras técnicas (sem exceção)

1. **Server-authoritative.** O cliente pede, o servidor valida e decide. Todo
   RemoteEvent valida tipo, faixa e frequência. Estado que dá vantagem (quais
   núcleos são falsos, contador do pity, variante do Guardião) fica só no
   servidor: não vai em Attribute, nome de Part nem Instance replicada.
2. **Nunca `wait()`.** Use `task.wait()`, `task.delay()` e `task.spawn()`.
3. **Clipes: `CaptureService` no cliente.** Nunca `VideoCaptureService`, que é
   restrito. Isso vale mesmo que o PDF de design cite `VideoCaptureService`: esta
   regra prevalece.
4. **Voice chat: sistema de áudio moderno.** `AudioDeviceInput` → `Wire` →
   `AudioAnalyzer`, lido no cliente, porque no servidor a análise retorna zero. O
   valor vira um pedido ao servidor, que aplica limites. Nunca use `Sound` legado
   para voice chat.
5. **`--!strict` em todo módulo novo.** Módulos pequenos e testáveis.
6. **Não invente APIs.** Na dúvida sobre uma propriedade ou serviço, diga "não
   tenho certeza" e peça confirmação antes de codar.

## Fases

- **Fase 0: validada.** Loop de extração funcional. Se uma mudança quebrar a
  compatibilidade com ela, avise antes de fazer.
- **Fase 1: em andamento.** Inclui o meta-loop, em quatro camadas com testes entre
  elas: caverna, superfície, variedade, mundo e viral. `docs/PLANO-FASE-1.md` é a
  referência de escopo, ordem e decisões. Não comece um módulo antes dos anteriores.
- **Fase 2: só depois da Fase 1 validada.** Guildas, base compartilhada,
  monetização e PvP com Iscas de Eco pertencem a ela. Não adiante nada disso, nem
  "preparando o terreno".
- **Modelo de servidor:** um grupo por servidor, com lobby, floresta e caverna no
  mesmo lugar. Sem `TeleportService` nem servidores reservados.
- **Persistência:** somente pelo módulo `PlayerProfile`, sem acesso direto a
  DataStore no restante do jogo. O mural (M19) é a única exceção.
- **Fora do escopo do Corista na Fase 1:** gravar a voz real do jogador. Use a voz
  genérica distorcida.

## Como trabalhar

- Opus planeja e não escreve código. Sonnet implementa.
- Um módulo por vez, um teste manual por vez, um commit por vez.
- Antes de codar, reformule o pedido em 3 linhas. Se for ambíguo, faça UMA pergunta.
- Altere somente os arquivos que o pedido autoriza.
- Toda entrega traz o caminho dos arquivos e o teste manual no Studio, em passos
  para quem não é desenvolvedor: onde clicar e o que deve aparecer.
- O usuário controla o Rojo e o Studio e é o validador. Não rode comandos de Rojo.
  Peça permissão antes de testar no Studio ou de fazer algo que ele próprio faria.
- O mapa é montado no Studio e não é versionado. Se o código precisar de algo no
  mapa, liste exatamente o que deve ser criado, com nome e propriedades.

## Onde o código fica

- `src/shared/`: Config, Enums, tipos. Números ajustáveis vão em `Config.lua`.
- `src/server/systems/`: sistemas do servidor, iniciados por `init.server.lua`.
- `src/client/ui/` e `src/client/clips/`: módulos do cliente, iniciados por
  `init.client.lua`.
