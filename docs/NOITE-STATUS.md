# Status da fila da noite

Atualizado pelo Sonnet a cada módulo. A fila e as regras estão na seção 4 de `docs/PLANO-REFINO.md`.

**Situação:** em andamento (iniciada 02/11 às 21:20). O Studio estava fechado ao começar: reaberto, conectado ao Rojo e maximizado.

| # | Módulo | Estado | Commit | Testado | Não testado ou observação |
|---|---|---|---|---|---|
| 1 | N0 Preparar e fechar pontas | OK | ver Git | Auditar caminhos (28 ok, 0 falhas, 3 gancho), Auditar assets (sem scripts), WorldVersion=1, chegada de carroça com prompt à vista, backup .rbxl | **Teste com 2 clientes NÃO feito**: "Server and Clients" abriu só o servidor, sem clientes (tentei uma vez e encerrei) |
| 2 | L1 Tema e componentes | OK | ver Git | Play: amostra de UI com abas Botões, Cartas e Barras, selos, dica ao passar o mouse, fechar no X, Output sem erros | Não testado: tela de celular (375x812), tecla Esc (fecha via evento MenuOpened do Roblox), som de clique (usa rbxasset://sounds/button.wav; não ouvi) |
| 3 | L2 HUD do lobby | OK | ver Git | Play: HUD no lobby (DESCER, frase, moedas, 7 botões laterais, selo de contrato, objetivo), DESCER longe leva ao elevador, perto inicia a contagem (DESCENDO EM n s), some na caverna e volta ao subir, Output sem erros | Botões laterais ainda sem painel ("em breve"): Mochila no I1, lojas no L3. Não testado: 2 jogadores, celular. Chat do Roblox pode cobrir o topo-esquerdo, por isso a coluna começa em 27% da altura |
| 4 | I1 Mochila e Baú | Pendente | | | |
| 5 | L3 Painéis de loja | Pendente | | | |
| 6 | L4 Guia | Pendente | | | |
| 7 | L5 Praça da Mina | Pendente | | | |
| 8 | T1 Primeira descida | Pendente | | | |
| 9 | J1 Itens mudam de lugar | Pendente | | | |
| 10 | R2 Caverna em Terrain | Pendente | | | |
| 11 | R3 Identidade das zonas | Pendente | | | |
| 12 | L6 Nível, XP e diária | Pendente | | | |
| 13 | L7 Fim de expedição | Pendente | | | |
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
