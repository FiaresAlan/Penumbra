# PLANO-MVP — um MVP bonito, jogável e bem estruturado (03/11/2026)

Pedido do Alan: o MVP só vai para outras pessoas quando estiver visual e mecanicamente decente. Itens que parecem bolinhas, monstro que é uma sombra e interface sem cara de jogo não passam. Este plano define a **régua de qualidade**, as fases, as horas estimadas e as regras de trabalho noturno. Ele vale a partir de agora e substitui a fila 4A como prioridade.

## 0. Régua do MVP (só vai para testes quando tudo isto for verdade)

| # | Critério | Como se confere |
|---|---|---|
| 1 | Todo item que se pega é um modelo 3D reconhecível (relíquia, gema, moeda antiga, cálice, chave...), nunca uma esfera | Foto do item no chão, na mochila, no baú e no recibo |
| 2 | O monstro tem modelo com pele, animações (parado, andar, farejar, correr, atacar), som próprio e uma IA que não é previsível | Vídeo curto ou fotos em sequência; Output da IA |
| 3 | A interface tem um estilo único (cores, fonte, ícones, painéis) em todas as telas, no PC e no celular | Foto de cada tela, comparada com o guia de estilo |
| 4 | O lobby e a vila são legíveis em 10 segundos: o jogador sabe onde descer, vender e melhorar | Teste de "quem nunca viu" com 2 amigos |
| 5 | A caverna tem colisão nas pedras, salões grandes, teto alto, iluminação boa e perigos variados | Auditar caminhos 28/0/3 e fotos por zona |
| 6 | Áudio: música por zona, ambiente, passos por material, sons de item, de porta, do monstro e da interface | Lista de sons conferida no Output e ouvida |
| 7 | Mecânica: dá vontade de "mais uma descida" (risco, recompensa, progressão e ferramentas) | Partida cronometrada com o Alan |
| 8 | Sem erro no Output em 10 descidas seguidas; 60 FPS no PC e 30 no celular médio | Output, MicroProfiler e teste no celular |
| 9 | Tudo testado por mim no Studio, com prints e números, e anotado em `docs/NOITE-STATUS.md` | Tabela de status |

Só depois do 9 vêm os testes com pessoas (seção 9).

## 1. Pesquisa de assets (feita em 03/11; licenças conferidas só nas páginas indicadas, confirmar de novo antes de baixar)

Regra de pipeline: baixar para uma pasta nova e vazia em `tools/downloads/`, converter para FBX ou OBJ (`tools/dae2obj.py` já converte DAE), auditar (sem scripts), importar pelo Import 3D do Studio, copiar o MeshPart para `ServerStorage.EcosAssets.*`, registrar autor e licença em `docs/CREDITOS.md`. Pedir o OK do Alan antes de cada download (nome, origem e tamanho).

| Uso | Candidato | Licença | Observação |
|---|---|---|---|
| Monstro principal | Quaternius "Ultimate Monsters Pack" (50 monstros, animações de andar, correr, atacar, morrer; FBX, OBJ, glTF) | CC0 | É o melhor primeiro candidato; escolher 1 monstro de cara séria e talvez 2 variantes para os Guardiões Corista e Enganador |
| Monstro alternativo | OpenGameArt "Hydrach" (criatura de caverna, rigged, andar/pular/agachar), "Forest Monster" e "3D Horror Game Monster" (humanoide, corre e ataca, FBX) | CC0 | Boas para variantes; conferir a página de cada um |
| Monstros extras | Quaternius "LowPoly Animated Monsters" e "Easy Animated Enemies" | CC0 (conferir) | Para criaturas menores (morcegos, aranhas) que dão vida à caverna |
| Evitar | "PSX Horror Entity" e "Phenebub" | CC BY (exigem crédito) | Só se o Alan aceitar dar crédito no jogo |
| Itens e tesouros | OpenGameArt "Treasure Pack" (6 baús, 7 chaves, 11 moedas, 18 gemas, 13 gemas lapidadas, 4 medalhas, 2 pergaminhos, 1 coroa, 1 barra de ouro, 5 pedras de ruína) | CC0 | Cobre quase todo o catálogo de itens |
| Itens extras | Mehrasaur "3D Treasure Pack" (itch.io) e "Low Poly 3D Crates Chests Coins and Barrels Collection" (OpenGameArt) | CC0 | Baús, caixas, barris |
| Itens extras (conferir) | Binbun3D "Treasure" (gemas, anéis, moedas, chaves, pergaminhos) | licença a conferir | Só entra se a página disser CC0 ou permitir uso comercial |
| Cavernas e rochas | 3TD Cave Pack Pro v1.0 (já importado: 15 peças), OpenGameArt "Free mine assets pack", "PS1 Living Cave" (CC0, props de caverna) | CC0 | Falta colisão nas peças (ver F5) |
| Interface | Kenney UI Pack (430 recursos, versões sci-fi e aventura) e Kenney Input Prompts (teclas e botões) | CC0 | Base para painéis, botões e dicas de tecla |
| Ícones | Game-icons.net (milhares de ícones de inventário e habilidades) | CC BY 3.0 | Exige crédito do autor de cada ícone em `docs/CREDITOS.md` |
| Sons e música | Kenney Audio, OpenGameArt e Freesound (filtrar por CC0) | CC0 por arquivo | Conferir a licença de cada arquivo; guardar a lista em `docs/CREDITOS.md` |
| Animações extras | Mixamo | termos próprios (uso em jogos permitido, sem redistribuir cru) | Só se o Alan aceitar; os pacotes do Quaternius já trazem animações |

## 2. Fases (em ordem) e horas estimadas de trabalho meu

As horas supõem acesso ao computador, trabalho contínuo e commit a cada módulo. Há incerteza de cerca de 40% para mais ou para menos; o que mais atrasa é importar e ajustar modelos no Studio.

### F0. Preparação (2 h)
Guia de estilo (cores, fontes, ícones), pastas de assets, lista de tarefas, backup do lugar em `tools/backups/`, tag `antes-do-mvp`, checklist de aceite em `docs/NOITE-STATUS.md`.

### F1. Monstro (12 h)
1. Baixar, converter, auditar e importar o monstro principal e as variantes (conferir se o rig e as animações sobrevivem ao importador).
2. Trocar o `GuardianModel` atual (hoje uma forma simples) pelo monstro, com Humanoid ou AnimationController, hitbox simples e escala certa.
3. Animações ligadas ao estado da IA: Sleeping, Alert, Hunting, LostScent, Returning, Dragging, mais ataque e susto.
4. Sons do monstro: respiração, passos pesados, rosnado de alerta, grito de caça, e áudio espacial (AudioEmitter) que sobe com a distância.
5. IA mais esperta (sem trapaça): visão em cone curta além do som; investigar portas e cantos; rondar antes de dormir (P5 já existe); responder a iscas de barulho do jogador; mudar de comportamento por tempo (já há tiers e diretor de tensão); duas variantes com comportamento próprio (Corista e Enganador).
6. Presença: sombra e sons que o jogador percebe antes de ver; efeito de tela (batida de coração) já existe e precisa de ajuste.
Critério: foto do monstro de perto e de longe, vídeo da caça, auditoria de caminhos 28/0/3.

### F2. Itens e loot (10 h)
1. Catálogo de 18 a 24 itens em 5 categorias (relíquias, gemas, moedas antigas, utensílios, curiosidades), cada um com nome, modelo, raridade, valor, peso e uma frase de lore.
2. Modelos do "Treasure Pack" e afins, ajustados (escala, pivô, material, brilho).
3. Substituir as esferas dos núcleos por modelos; o núcleo passa a ser um item entre vários (a regra de núcleo continua na Fase 1).
4. Aparência no chão (brilho discreto por raridade), na mochila e no baú (ViewportFrame com o modelo certo), no recibo e na loja.
5. Peso e ruído continuam server-authoritative; valor e peso balanceados em `Config.ItemWeights`/`LootRules` sem mudar os preços já fixados da Fase 1.
Critério: foto de 10 itens diferentes no chão e na interface, Output sem erro, extração com mistura de itens.

### F3. Interface e UX (14 h)
1. Guia de estilo aplicado: um tema escuro de aventura (cores, fonte única, cantos e bordas), tokens em `Theme.lua`.
2. HUD de caverna refeito: barra de ruído, peso, mochila, bússola de objetivo, prompts com tecla (Input Prompts) e aviso de perigo.
3. Mochila e baú com grade, ícones e detalhe do item; mercado e oficina com cartas consistentes; perfil, contratos, placar e ajustes.
4. Telas de fim, recibo, tutorial e votação revisadas.
5. Versão para celular: botões maiores, zonas de toque, escalas por `UIScale`, teste em tamanhos 375x812 e 768x1024.
6. Sons de interface (clique, abrir, fechar, comprar, erro).
Critério: foto de cada tela no PC e no celular emulado, lado a lado com o guia de estilo.

### F4. Lobby e vila (8 h)
Entrada legível (placas, setas, marcadores), vila organizada em três zonas (descer, vender, melhorar), iluminação e hora do dia, música de vila, NPCs com falas melhores, carrinho, taverna e praça já escritos e agora conferidos e ajustados em posição.
Critério: foto de cada área, teste "quem nunca viu" em 10 segundos.

### F5. Caverna (16 h)
1. **Colisão das pedras:** hoje parte das peças do 3TD foi colocada sem colisão e o jogador atravessa. Corrigir de vez: rochas, estalagmites e pedras ganham `CanCollide` com `CollisionFidelity = Hull`, sempre nas bordas dos corredores; estalactites e samambaias continuam sem colisão. Rodar "Auditar caminhos" depois de cada ajuste.
2. Salões grandes (mais de 40 studs), uma caverna "catedral" com lago e ponte, rios rasos, iluminação por zona com raios de luz e cogumelos que brilham.
3. Perigos variados e legíveis: goteira que denuncia posição, chão que racha, fogo-fátuo que atrai, teia que prende por um instante, queda de pedra com aviso (reaproveitando RouteShift).
4. Pontos de interesse com recompensa maior e risco maior (câmara do tesouro, altar, cofre trancado), salas secretas.
5. Mais variedade por local (Mina, Masmorra, Gruta), arcos e escadas na Masmorra, cristais e água na Gruta.
6. Atualizar a assinatura do mapa no `CLAUDE.md` e rodar a auditoria nos três locais.
Critério: fotos por zona e local, auditoria 28/0/3 em cada um, nenhum item enterrado.

### F6. Áudio (8 h)
Mapa de sons: música de lobby, de vila e de cada zona da caverna; ambiente (vento, goteira, respiração da caverna); passos por material; pegar item, largar, vender; porta, elevador, desabamento; monstro (F1); UI (F3). Todos CC0, listados em `docs/CREDITOS.md`; mixagem por grupo (`SoundGroup`) e opção de volume.
Critério: lista de sons carregada sem erro no Output, volume equilibrado, opção de música desligada funcionando.

### F7. Mecânica e progressão (12 h)
1. Ferramentas que mudam o risco: lanterna, isca de barulho, vela, corda (o gancho já existe), poção de silêncio.
2. Progressão: melhorias por categoria (peso, silêncio, luz, bolsos), contratos diários, metas semanais, marcos (já há), pódio do fim.
3. Cooperação: pings simples, marcar item, ajudar quem foi capturado, divisão de papéis sem classes fixas.
4. Dificuldade por tempo (tiers) e por escolha (condição da descida, já feita), com limites claros.
5. Economia revisada com planilha simples (preço, valor médio por descida, tempo de descida) e anotação no plano.
Critério: partida cronometrada de 12 a 15 minutos com o Alan, com "mais uma descida" como pergunta final.

### F8. Técnica (8 h)
Desempenho (instâncias, luzes, partículas, StreamingEnabled), celular, segurança dos remotes (revisão com o roblox-reviewer), persistência (DataStore com retry), limpeza de módulos antigos e documentação.
Critério: 10 descidas sem erro, FPS medido, revisão de segurança sem pendência.

### F9. Teste com pessoas (depois da régua)
Alfa com 2 a 3 amigos, depois 5 a 10 pessoas. Medir: terminaram a primeira extração, voltaram no dia seguinte, pediram "mais uma", riram ou gritaram. Critério de decisão escrito antes: menos de 3 em 10 chegando à segunda descida exige mudar o núcleo do jogo; a maioria querendo repetir libera o lançamento.

## 3. Total estimado
F0 2 + F1 12 + F2 10 + F3 14 + F4 8 + F5 16 + F6 8 + F7 12 + F8 8 = **90 horas de trabalho**, mais cerca de **10 horas** de correções e conferência final da régua: **cerca de 100 horas**, com incerteza de 40%. Em sessões noturnas de 8 horas são cerca de **12 a 13 noites**; com sessões de 5 horas por dia, cerca de **3 semanas**.

## 4. Regras do trabalho noturno
- Um módulo por vez, com commit e push a cada um, nunca `git push -f`.
- Antes de cada download: pedir o OK do Alan (nome, origem, tamanho), pasta nova e vazia, auditar sem scripts, registrar a licença.
- Se um erro persistir por 3 tentativas: parar, anotar em `docs/NOITE-STATUS.md` e passar ao próximo item.
- Nunca publicar para jogadores, mudar privacidade ou monetização, comprar, aceitar termos, criar contas ou digitar senhas.
- Antes de mexer no Terrain ou no mapa: backup do lugar; depois: "Auditar caminhos" e salvar o lugar.
- Só marcar OK com prints e números; o resto fica PARCIAL ou BLOQUEADO com o motivo.
- Poupar tokens: leitura parcial, busca antes de ler, imagens só quando necessário.

## 5. Decisões que dependem do Alan
1. Estilo visual: low-poly estilizado e sombrio (recomendado, combina com os pacotes CC0) ou algo mais realista (exige assets pagos).
2. Nível de susto: tenso e sugerido (recomendado) ou com sustos visuais fortes.
3. Aceitar assets que exigem crédito (CC BY), como ícones do Game-icons.net: sim ou não.
4. Suporte ao celular desde o MVP (recomendado) ou só PC.
5. Janela fixa para o computador à noite, sem uso do Alan na máquina.

---

# PARTE B — Tarefas detalhadas (cada linha é uma unidade de trabalho com commit)

Formato: **ID** · tarefa · arquivos principais · critério de aceite · horas. Marcas no `docs/NOITE-STATUS.md`: PENDENTE, EM ANDAMENTO, OK (com prints e números), PARCIAL, BLOQUEADO (com motivo). Toda tarefa que mexe no Terrain ou nos sistemas da Fase 1 começa com backup do lugar e termina com "Auditar caminhos" (esperado 28 ok, 0 falhas, 3 só pelo gancho) e o lugar salvo.

## F0. Preparação (2 h)
| ID | Tarefa | Arquivos | Aceite | h |
|---|---|---|---|---|
| F0.1 | Tag git `antes-do-mvp` e backup `.rbxl` | tools/backups | tag no GitHub, arquivo salvo | 0,2 |
| F0.2 | Guia de estilo (paleta, fontes, cantos, bordas, ícones, sons de UI) | docs/GUIA-DE-ESTILO.md, Theme.lua | arquivo escrito, tokens no Theme | 0,8 |
| F0.3 | Pastas de assets e passo a passo do pipeline (baixar, converter, auditar) | tools/downloads, tools/pipeline.md | passo a passo escrito e testado com 1 modelo | 0,5 |
| F0.4 | Registro de créditos e licenças | docs/CREDITOS.md | seção por pacote com autor, link e licença | 0,2 |
| F0.5 | Tabela da régua nos status | docs/NOITE-STATUS.md | as 9 linhas da régua | 0,3 |

## F1. Monstro (12 h)
| ID | Tarefa | Arquivos | Aceite | h |
|---|---|---|---|---|
| F1.1 | Baixar o pacote de monstros CC0, escolher 3 candidatos e vê-los no Studio | tools/downloads/monstros | 3 prints lado a lado | 1 |
| F1.2 | Converter se preciso e importar o escolhido com rig e animações | Import 3D, ServerStorage.EcosAssets.Monstros | modelo no lugar, 0 scripts, animações listadas | 2 |
| F1.3 | Trocar o `GuardianModel` pelo monstro (escala, hitbox, pivô, Humanoid ou AnimationController) | GuardianModel.lua | foto no ninho; a caça continua funcionando | 1,5 |
| F1.4 | Ligar animações aos estados (Sleeping, Alert, Hunting, LostScent, Returning, Dragging, ataque) | GuardianAI.lua, novo GuardianAnimator.lua | foto ou vídeo de cada estado | 1,5 |
| F1.5 | Sons do monstro (respiração, passos, rosnado, grito, ataque) e áudio espacial | AudioBroadcast, WorldAudio, Config.Audio | os 5 sons tocam no estado certo | 1,5 |
| F1.6 | Percepção nova: visão em cone curta, investigação de cantos, reação a iscas de barulho | GuardianAI.lua | testes pelo QA com prints do Output | 2 |
| F1.7 | Variantes do Corista e do Enganador com aparência própria | MimicGuardian, DeceiverGuardian | foto de cada variante | 1 |
| F1.8 | Efeitos de presença revisados (sombra, vibração, batida de coração, cor da tela) | GuardianPresence.lua | fotos em 3 distâncias | 0,5 |
| F1.9 | Auditoria de caminhos e medida de desempenho do monstro | PathAudit | 28/0/3 e FPS anotado | 0,5 |

## F2. Itens e loot (10 h)
| ID | Tarefa | Arquivos | Aceite | h |
|---|---|---|---|---|
| F2.1 | Catálogo de 18 a 24 itens (nome, categoria, raridade, valor, peso, lore, modelo) | shared/ItemCatalog.lua (novo), Config.ItemWeights | arquivo único, revisado pelo Alan | 1,5 |
| F2.2 | Baixar, converter e importar os pacotes de tesouro (baús, gemas, moedas, chaves, coroa, medalhas) | tools/downloads/tesouros | 20 modelos prontos, 0 scripts | 2 |
| F2.3 | Ajustar escala, pivô, material e brilho por raridade e guardar em `EcosAssets.Itens` | Studio, ItemLibrary.lua (novo) | foto de uma grade com todos os modelos | 1,5 |
| F2.4 | Substituir as esferas dos núcleos e relíquias no mundo, mantendo as regras da Fase 1 | Cores.lua, LootSystem.lua | foto de 10 itens no chão da caverna | 1,5 |
| F2.5 | `ItemViewport` com o modelo real (mochila, baú, loja, recibo, fim) | ItemViewport.lua | foto de cada tela com os modelos | 1,5 |
| F2.6 | Brilho, partícula e som ao pegar por raridade | LootSystem, WorldAudio | 3 raridades diferentes | 0,5 |
| F2.7 | Balanceamento de valor e peso por categoria sem mexer nos preços da Fase 1 | Config, planilha no plano | tabela de valor médio por descida | 1 |

## F3. Interface e UX (14 h)
| ID | Tarefa | Arquivos | Aceite | h |
|---|---|---|---|---|
| F3.1 | Tema aplicado: tokens, fontes, painéis, botões, cantos, sombras | Theme.lua, Widgets.lua | UISample refeito no novo estilo | 1,5 |
| F3.2 | HUD da caverna: ruído, peso, mochila, objetivo, aviso de perigo, tecla nos prompts | NoiseBar, ExtractionUI, InventoryUI | foto do HUD em 3 situações | 2 |
| F3.3 | Mochila e baú com grade, ícones, ordenação e detalhe | InventoryUI.lua | foto de mochila cheia e baú cheio | 2 |
| F3.4 | Mercado, oficina, perfil, contratos e placar no mesmo estilo | ShopPanels.lua, ProfileHUD, BoardUI | foto de cada painel | 2,5 |
| F3.5 | Telas de fim, recibo, abertura, tutorial e votação revisadas | EndScreen, ReceiptUI, Intro, TutorialUI | foto de cada tela | 1,5 |
| F3.6 | Versão para celular (escala, zonas de toque, botões grandes) | UIScale, init.client | prints em 375x812 e 768x1024 | 2 |
| F3.7 | Sons de interface e animações curtas (abrir, fechar, comprar, erro) | WorldAudio, Widgets | lista de sons e vídeo curto | 1 |
| F3.8 | Acessibilidade mínima (contraste, tamanho do texto, daltonismo, reduzir efeitos) | SettingsUI | opções funcionando | 1,5 |

## F4. Lobby e vila (8 h)
| ID | Tarefa | Arquivos | Aceite | h |
|---|---|---|---|---|
| F4.1 | Conferir e ajustar a posição de tudo o que foi escrito às cegas (praça, vila, taverna, carrinho, cachorro, portas, altar, estátua, placares) | PlazaDecor, VillageExtras | foto de cada peça no lugar certo | 2 |
| F4.2 | Legibilidade: placas, setas e marcadores para descer, vender e melhorar | WorldMarkers, GuideArrow | teste "quem nunca viu" em 10 s | 1,5 |
| F4.3 | Iluminação, hora do dia, névoa e sons de ambiente da vila e da mina | ZoneLighting, AmbientAudio | foto ao entardecer e à noite | 1,5 |
| F4.4 | NPCs com falas melhores, rotinas simples e conversa variada | NpcSystem, Config.NpcLines | 8 falas novas por NPC | 1 |
| F4.5 | Câmera do elevador e tela de espera mais bonitas | LobbyHUD, GroupCallUI | foto e vídeo da espera | 1 |
| F4.6 | Tutorial T1 revisto no lugar (galeria, sombra, bipe, prêmio) | TutorialSystem | percurso completo com prints | 1 |

## F5. Caverna (16 h)
| ID | Tarefa | Arquivos | Aceite | h |
|---|---|---|---|---|
| F5.1 | Colisão nas pedras do 3TD e nas peças Synty grandes (código já escrito; falta conferir) | CaveScatter, CaveLibrary | o jogador não atravessa; auditoria 28/0/3 | 1,5 |
| F5.2 | Salões de mais de 40 studs e uma câmara "catedral" com lago e ponte | CaveShape, CaveTerrain | foto, rebake dos 3 locais, auditoria | 3 |
| F5.3 | Iluminação por zona com raios de luz, cogumelos e cristais que brilham | ZoneLighting, CaveGeometry | fotos por zona | 2 |
| F5.4 | Perigos: goteira que denuncia posição, chão que racha, fogo-fátuo, teia, queda de pedra com aviso | novo HazardSystem.lua, RouteShift | 5 perigos testados no QA | 3 |
| F5.5 | Pontos de interesse com risco e recompensa (câmara do tesouro, altar, cofre trancado, sala secreta) | CaveMarkers, LootSystem | fotos e Output de cada um | 2 |
| F5.6 | Variedade por local: arcos e escadas na Masmorra, cristais e água na Gruta, ferrugem e trilhos na Mina | CaveExtras, CaveScatter | fotos por local | 2 |
| F5.7 | Criaturas pequenas e vida da caverna (morcegos, ratos, aranhas) com assets CC0 | CaveLife | foto e Output | 1 |
| F5.8 | Nova assinatura do mapa no CLAUDE.md e auditoria dos três locais | CLAUDE.md | 3 auditorias 28/0/3 | 1,5 |

## F6. Áudio (8 h)
| ID | Tarefa | Arquivos | Aceite | h |
|---|---|---|---|---|
| F6.1 | Lista final de sons e escolha dos arquivos CC0 (música, ambiente, passos, itens, porta, elevador, monstro, UI) | docs/CREDITOS.md | planilha com id, fonte e licença | 1,5 |
| F6.2 | Importar os sons (Asset Manager) e registrar em `Config.Audio` | Config.lua | todos carregam sem erro no Output | 1,5 |
| F6.3 | Música por zona e por estado (lobby, vila, A, B, C, perseguição) com transição suave | AmbientAudio.lua | troca audível ao andar entre zonas | 1,5 |
| F6.4 | Passos por material, eco por tamanho de salão, respiração do jogador | WorldAudio, SneakInput | passos diferentes em 3 materiais | 1,5 |
| F6.5 | Mixagem por `SoundGroup` e opções de volume (música, efeitos, voz) | SettingsUI | sliders funcionando | 1 |
| F6.6 | Voz de proximidade conferida (AudioDeviceInput, AudioEmitter, AudioListener, Wire) | VoiceNoise.lua | revisão por leitura; teste real fica para a fase com pessoas | 1 |

## F7. Mecânica e progressão (12 h)
| ID | Tarefa | Arquivos | Aceite | h |
|---|---|---|---|---|
| F7.1 | Ferramentas: lanterna melhor, isca de barulho, vela, poção de silêncio | novo ToolSystem.lua, Workshop | 4 ferramentas usáveis, server-authoritative | 3 |
| F7.2 | Melhorias por categoria (peso, silêncio, luz, bolsos) com árvore curta | WorkshopSystem, Config | 8 melhorias, preços na tabela | 2 |
| F7.3 | Contratos e metas semanais com recompensas revisadas | ContractSystem, ContractRules | 3 diários e 2 semanais funcionando | 1,5 |
| F7.4 | Cooperação: ping, marcar item, ajudar capturado, dividir peso | novo PingSystem.lua, NestSystem | ping visível a todos, validado no servidor | 2 |
| F7.5 | Morte, resgate e retorno revistos (o que se perde, o que se mantém) | KidnapSystem, ExpeditionSystem | tabela de regras no plano | 1,5 |
| F7.6 | Economia revisada com planilha (preço, valor por descida, tempo) | docs/ECONOMIA.md | planilha e metas de tempo | 1 |
| F7.7 | Partida cronometrada de 12 a 15 minutos | — | roteiro e anotações | 1 |

## F8. Técnica (8 h)
| ID | Tarefa | Arquivos | Aceite | h |
|---|---|---|---|---|
| F8.1 | Desempenho: contagem de instâncias, luzes, partículas e StreamingEnabled | Config, MapBuilder | FPS medido no PC; relatório | 2 |
| F8.2 | Celular: teste no emulador e ajustes de toque | UI | prints e FPS emulado | 1,5 |
| F8.3 | Revisão de segurança dos remotes e do DataStore | server/ | relatório sem pendência (agente roblox-reviewer) | 1,5 |
| F8.4 | Limpeza de módulos antigos e revisão do CLAUDE.md | todos | CLAUDE.md revisado | 1 |
| F8.5 | 10 descidas seguidas sem erro | — | log do Output | 1 |
| F8.6 | Backup final e tag `mvp-pronto` | tools/backups | tag no GitHub | 1 |

## F9. Teste com pessoas (depois da régua)
| ID | Tarefa | Aceite |
|---|---|---|
| F9.1 | Roteiro de observação (o que olhar, o que perguntar, sem explicar nada) | arquivo `docs/ROTEIRO-DE-TESTE.md` |
| F9.2 | Alfa com 2 ou 3 amigos | 3 respostas por escrito |
| F9.3 | Teste com 5 a 10 pessoas | planilha das 4 métricas e decisão pelo critério escrito |

## Ordem de execução
F0, F1 (monstro), F2 (itens), F3 (interface), F4 (lobby), F5 (caverna), F6 (áudio), F7 (mecânica), F8 (técnica), conferência da régua. A cada fase fechada, uma nota curta no `docs/NOITE-STATUS.md` com prints e um commit com a tag da fase (por exemplo `mvp-f1`).

## Riscos conhecidos e o que fazer
| Risco | Efeito | Resposta |
|---|---|---|
| O importador do Studio não preserva as animações do monstro | F1 atrasa | converter para glTF, reimportar pelo Animation Editor, ou recriar 4 animações simples por código com `Motor6D` |
| Modelos CC0 com estilos diferentes entre si | visual incoerente | tingir e ajustar materiais para uma paleta única (guia de estilo) |
| Peças novas fecham corredores | auditoria falha | colocar só nas bordas, rodar a auditoria a cada ajuste, desligar a peça se persistir |
| Interface quebra no celular | UX ruim | testar em 375x812 e 768x1024 a cada tela |
| Limite de cota da sessão | trabalho para no meio | commit a cada tarefa e tabela de status sempre atualizada |
| Licenças que exigem crédito | passivo legal | só aceitar CC BY com a decisão do Alan e crédito no jogo e no repositório |
