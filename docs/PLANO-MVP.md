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
