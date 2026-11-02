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
- `src/shared/` — Config, Enums, tipos.
- `src/server/systems/` — NoiseSystem, LootSystem, GuardianAI, ExtractionSystem.
- `src/client/ui/` — NoiseBar, ExtractionUI.
- O mapa (lobby, caverna, marcadores) é gerado por `src/server/world/MapBuilder.lua`,
  autorizado pelo Alan em 02/11/2026. Peças novas que o código precise vão lá.
- Decoração e assets pesados continuam sendo montados no Studio.

## Estado atual
- Fase 0 concluída e validada (loop de extração funcional).
- Fase 1 em andamento: seguir docs/PLANO-FASE-1.md.