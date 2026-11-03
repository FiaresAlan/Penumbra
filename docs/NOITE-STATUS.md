# Status da fila da noite

Atualizado pelo Sonnet a cada módulo. A fila e as regras estão na seção 4 de `docs/PLANO-REFINO.md`.

**Situação:** em andamento (iniciada 02/11 às 21:20). O Studio estava fechado ao começar: reaberto, conectado ao Rojo e maximizado.

| # | Módulo | Estado | Commit | Testado | Não testado ou observação |
|---|---|---|---|---|---|
| 1 | N0 Preparar e fechar pontas | OK | ver Git | Auditar caminhos (28 ok, 0 falhas, 3 gancho), Auditar assets (sem scripts), WorldVersion=1, chegada de carroça com prompt à vista, backup .rbxl | **Teste com 2 clientes NÃO feito**: "Server and Clients" abriu só o servidor, sem clientes (tentei uma vez e encerrei) |
| 2 | L1 Tema e componentes | OK | ver Git | Play: amostra de UI com abas Botões, Cartas e Barras, selos, dica ao passar o mouse, fechar no X, Output sem erros | Não testado: tela de celular (375x812), tecla Esc (fecha via evento MenuOpened do Roblox), som de clique (usa rbxasset://sounds/button.wav; não ouvi) |
| 3 | L2 HUD do lobby | OK | ver Git | Play: HUD no lobby (DESCER, frase, moedas, 7 botões laterais, selo de contrato, objetivo), DESCER longe leva ao elevador, perto inicia a contagem (DESCENDO EM n s), some na caverna e volta ao subir, Output sem erros | Botões laterais ainda sem painel ("em breve"): Mochila no I1, lojas no L3. Não testado: 2 jogadores, celular. Chat do Roblox pode cobrir o topo-esquerdo, por isso a coluna começa em 27% da altura |
| 4 | I1 Mochila e Baú | OK | ver Git | Play: botão Mochila abre o painel com espaços (2 núcleos + relíquia de 3 espaços), barra de peso, valor, ruído extra, detalhe ao tocar/passar o mouse; aba Baú com filtros e total; barrinha de espaços na caverna acima da barra de ruído e abre o painel ao tocar; texto antigo da mochila removido | **Tecla I não testada**: o teclado injetado não disparou (usa ContextActionService). Não testado: celular, baú com 150 itens, ícones (usa emoji) |
| 5 | L3 Painéis de loja | OK | ver Git | Play: Mercado (grade, detalhe, vender, 8 💎 recebidos de 1 núcleo, "vender todos" com confirmação não exercitado), Oficina (melhorias e relíquias), Contratos, Mercado Negro (aberto pela barraca, entrega habilitada perto), Perfil; botões desabilitados e faixa vermelha quando longe da bancada; ShopUI antigo removido. Dois bugs achados e corrigidos no PanelManager (clique em área vazia fechava o painel; reabrir painel sem abas duplicava o conteúdo) | Não testado: comprar melhoria (já compradas neste perfil), expor/retirar relíquia, receber contrato, entregar pedido, "Vender todos", efeito "+N 💎", celular |
| 6 | L4 Guia | OK | ver Git | Play: seta dourada no chão apontando para o Mercado (passo "vender"), marcador "Mercado 19 m", frase do DESCER mostra o passo, Ajustes liga e desliga o guia (seta e marcadores somem) | Não testado: passos de contratos e oficina, marcadores de todos os lugares de perto/longe, guia desligado ao voltar da caverna, celular. O guia só vale na sessão (não grava no perfil). A seta só indica a direção em linha reta |
| 7 | L5 Praça da Mina | OK | ver Git | Play: praça de tijolo em manchas irregulares (Terrain Brick) na mina e na vila, lampiões de madeira com luz quente, estandartes, fogueira com fogo, bancos, barris, casas giradas até 7 graus, elevador de madeira com placa "A MINA", quadros de madeira; Auditar caminhos 28 ok / 0 falhas; assinatura do mapa 1186 / 225025228; lugar salvo no Roblox | Não testado: fogueira de perto (fogo legado), fumaça da fogueira, desempenho em celular, marcadores de estandarte versus compasso. O material Brick do Terrain agora é das praças |
| 8 | T1 Primeira descida | ADIADO | | | Adiado de propósito: é grande e mexe em vários sistemas (nova localização Tutorial). Fica depois de L6 a L8 se sobrar limite |
| 9 | J1 Itens mudam de lugar | OK | ver Git | Play: botão QA Embaralhar itens muda as posições (Core1 508,64 para 540,96); Auditar caminhos depois de 3 sorteios: 28 ok / 0 falhas (a primeira tentativa deu 1 falha porque um item caiu sobre decoração: o sorteio agora pula células com sólidos) ; liga e desliga em Config.Variation.ShuffleItems | Não testado: 3 expedições completas seguidas, itens fora do alcance de prompt em cantos, interação com Enganador/Pity, núcleos de saliência ficam fixos (sem atributo Shuffle) |
| 10 | R2 Caverna em Terrain | Pendente | | | |
| 11 | R3 Identidade das zonas | Pendente | | | |
| 12 | L6 Nível, XP e diária | Pendente | | | |
| 13 | L7 Fim de expedição | OK | ver Git | Play: extração real pelo elevador; tela com título, 1588 💎 contando, "Você trouxe 7 itens", carta "Maior saque" com foto, botão Fechar, some em 9 s; Output sem erros | Corrigido depois do teste: o resultado era comparado com "Success" em vez de "success" (mostrou "fracassou" numa extração). Depois da correção testei "Encerrar: sucesso" (título dourado, "Você não extraiu desta vez"). Não testado: 2+ jogadores, "Voltou para salvar". O recibo antigo em texto continua para quem extrai antes do fim |
| 14 | L8 Placares e convite | Pendente | | | |
| 15 | A2 Música e sons | Pendente | | | |
| 16 | R7b NPCs e balões | Pendente | | | |
| 17 | R7c Animais, morcegos e poeira | Pendente | | | |
| 18 | P1 Desempenho e celular | Pendente | | | |
| 19 | A3 Portão visual e capa | Pendente | | | |
| 20 | S1 `--!strict` restante | Pendente | | | |
| 21 | I2, I3, I4 (desligados) | Pendente | | | |
| 22 | J2 a J5, J13, J14 (desligados) | Pendente | | | |
| 23 | R8 (só em branch) | Pendente | | | |

## Decisões tomadas sem o Alan

- N0: o hash do mapa continua o mesmo (as peças de carroça são de jogo e entram fora da assinatura).
- Rojo foi iniciado por mim em segundo plano com reinício automático.

## Bloqueios e problemas

- Teste de 2 clientes (R9): não consegui abrir clientes pelo "Server and Clients". Fica para o Alan testar com a opção Clients and Servers.

## Para o Alan decidir de manhã

Nenhum ainda.
