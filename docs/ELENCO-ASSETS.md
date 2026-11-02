# Elenco de assets (módulo A1)

Teste de 02/11/2026, feito em um lugar vazio separado (nada foi inserido no lugar do jogo). Cena ao entardecer, sobre terra, com as peças em fileira. Prints em `docs/elenco/`; a folha principal é `docs/elenco/folha-casas-e-natureza.jpg`.

## Resultado em uma frase

**Synty Nature serve para a floresta. As casas gratuitas da loja são fracas: só uma família combina com o estilo, e ela é pesada. Falta variedade, então recomendo decidir entre duas rotas (seção 4).**

## 1. Pacotes Synty (@Roblox, grátis, licenciados para qualquer jogo Roblox)

Inseridos pela API do Studio. Todos com **0 scripts**.

| Pacote | MeshParts | Extensão (studs) | Veredito |
|---|---|---|---|
| Synty Nature Pack | 200 | 678 x 82 x 435 | **Aprovado.** Pinheiros altos e escuros, carvalhos, árvores secas, arbustos, pedras, troncos. Estilo low poly limpo. Prints `nature-1/2/3.jpg` |
| Synty Dungeon: Cave & Castle Interiors | 271 | 380 x 105 x 799 | **Só acentos.** Pilares ocos e módulos de pedra cinza e lisa. Prints `cave-pilares.jpg`, `cave-pecas.jpg`. Não substituem o Terrain da caverna |
| Synty Dungeon: Basement & Goblin Camp | 179 | 312 x 48 x 534 | **Útil na zona A.** Trilhos de mina, plantas subterrâneas, módulos de porão. Print `basement-pecas.jpg` |
| Synty Dungeon: Skeletons & Bones | 50 | 97 x 13 x 111 | **Aprovado para o Ninho** (ossos). Não fotografei de perto |
| Synty Dungeon: Weapons & Props | 234 | 89 x 27 x 414 | **Aprovado para decoração.** Não fotografei de perto |
| Synty City Pack | 332 | 870 x 162 x 876 | **Não usar.** Prédios modernos de vidro e escritório |

**Observações:**
- As peças vêm soltas dentro de uma pasta `Meshes`. Ao ligar ao jogo, vale agrupá-las em modelos com um pivô na base.
- Os troncos e as copas têm cor própria por vértice: não precisam de textura, o que ajuda no celular.
- Em distância média a neblina padrão apaga os detalhes: ajustar a Atmosphere no jogo.

## 2. Casas testadas

Inseridas pela Toolbox do Studio, só gratuitas, com o aviso de scripts lido antes de cada inserção.

| # | Modelo | Autor | Partes | Scripts | Tamanho | Estilo | Veredito |
|---|---|---|---|---|---|---|---|
| A | MedievalHouse (casa enxaimel, telhado rosa, janelas acesas, chaminé) | anomon | **1.300** | 0 | 53 x 57 x 58 | Low poly estilizado, combina com Synty | **Melhor opção, mas pesada.** Usar em poucos prédios-chave, ou converter em MeshPart |
| B | Casita medieval (casa com roda d'água) | desconhecido | 37 | 0 | 40 x 48 x 75 | Low poly estilizado | **Boa e leve.** Serve de moinho ou oficina |
| C | Japanese rural house pack (PBR) | creeperatchanel | 9 | 0 | 39 x 36 x 92 | **Realista**, telhado de palha, texturas PBR | **Não combina** com o low poly. Descartada |
| D | Medieval blacksmith shop | desconhecido | 133 soltas | 0 | 64 x 14 x 69 | Forja aberta, simples | **Serve para a oficina**, agrupando as 133 peças em um modelo |
| E | Medival Village House (Medieval Test Wooden Cottage) | desconhecido | n/d | **4** | n/d | n/d | **Rejeitada:** tem scripts, não inseri |
| F | Low Poly Medieval House (outro autor) | desconhecido | n/d | **6** | n/d | n/d | **Rejeitada:** tem scripts, não inseri |
| G | Low Poly Medieval House Pack | Cyphen_Studios | n/d | n/d | n/d | Bonito na miniatura | **Pago (US$ 2,99). Não comprei.** Só com sua autorização |

**Não consegui testar** as candidatas da pesquisa anterior (Village House, Loja do Zivick, Ferreiro HolyBlack, Casas Medievales, tent market stall): o carregamento por script devolve "usuário não autorizado", porque são de terceiros e não estão no inventário. Pela Toolbox, a busca trouxe outros modelos.

## 3. Problemas encontrados

1. **A casa A tem 1.300 partes cada.** Oito casas iguais seriam mais de 10 mil partes. Com tudo ancorado e sem colisão nos detalhes funciona, mas pesa no celular. Mitigação: usar a casa A em 3 ou 4 prédios-chave (mercado, taverna, contratos) e a casita B nas demais.
2. **Pouca variedade.** Só temos duas casas boas (A e B) e a forja (D). Uma vila de 10 prédios precisa de mais.
3. **O ferreiro vem em 133 partes soltas**, sem modelo. Dá para agrupar, mas é trabalho.
4. **A câmera do Studio por script não mudou a rotação** (só a posição). Os prints foram feitos com a tecla F sobre a seleção.

## 4. Decisão necessária do Alan

**Rota 1: usar o que já temos (rápida).** Casa A nos prédios principais, casa B e forja D nos secundários, mais cabanas simples montadas por código para completar. Visual coerente com a Synty, pouca variedade, risco de peso.

**Rota 2: montar as casas com o Quaternius Medieval Village MegaKit (CC0, mais de 300 peças modulares).** Variedade quase ilimitada e leve (MeshPart), licença limpa, e o fluxo de importar FBX já existe (usamos para o KayKit). Custa mais tempo no R6 e o estilo é parecido com o da Synty, mas não idêntico.

**Minha recomendação: Rota 2 para a vila, e usar A e B só como peças de destaque** (taverna e moinho). Assim a vila tem variedade e o peso fica sob controle.

## 5. O que fica para depois da escolha

- Levar as peças aprovadas, sem scripts, para `ServerStorage.EcosAssets` no lugar do jogo.
- Comando "Auditar assets", que falha se houver script ali.
- Atualizar `docs/CREDITOS.md` com autores e links (Synty, anomon, e o autor da casita, se identificado).
