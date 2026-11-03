# Créditos e licenças

## KayKit : Dungeon Remastered (1.0)
- Autor: Kay Lousberg (www.kaylousberg.com)
- Licença: Creative Commons Zero (CC0), uso livre pessoal, educacional e comercial; crédito não é obrigatório.
- Fonte: https://github.com/KayKit-Game-Assets/KayKit-Dungeon-Remastered-1.0
- Usado: 16 modelos (barris, caixas, baús, tochas, entulho, coluna, bandeira, vela, restos de espada). Os originais FBX e a licença
  ficam em `tools/assets/kaykit/`; os meshes importados no Roblox estão listados em `src/shared/Assets.lua`.
- Os meshes foram enviados ao Roblox pela conta do dono do projeto (importação 3D do Studio). Para reimportar, abra o Studio,
  use Importar (aba Home), escolha os FBX da pasta acima e rode o script de coleta de IDs descrito em `tools/asset_receiver.py`.

## Quaternius : Medieval Village MegaKit (Standard)
- Autor: Quaternius (quaternius.com)
- Licença: Creative Commons Zero (CC0), uso livre pessoal, educacional e comercial; crédito não é obrigatório.
- Fonte: https://quaternius.com/packs/medievalvillagemegakit.html (download gratuito pelo itch.io, versão Standard, 176 peças; usamos 69).
- Como entrou no Roblox: `tools/convert_megakit.py` separa cada peça em uma malha por material (o importador do Roblox só
  aproveita uma textura por malha), e um GLB "portador" envia cada textura uma única vez. Os IDs ficam em
  `src/shared/VillageAssets.lua` (gerado por `tools/make_village_assets.py`). O zip original e as texturas grandes não vão para o Git.

## Synty Studios : pacotes gratuitos oficiais da Roblox (Nature, Dungeon, Skeletons & Bones etc.)
- Publicados pela conta @Roblox na Creator Store, "licenciados para qualquer jogo Roblox" (anúncio de 2021 no DevForum).
- Uso apenas dentro do Roblox: não extrair os modelos para outros lugares.
- Em uso desde o R5: Synty Nature Pack (id 6933438443) para a floresta, as pedras e a ponte. As peças são copiadas para `ServerStorage.EcosAssets.Nature`.

## Músicas e sons da superfície (A2, 02/11/2026)
- Fonte: busca pública da Creator Store (áudio, categoria Música/SFX). Os arquivos carregam no lugar (testado: IsReady e duração no Output). Nenhum áudio foi enviado por nós.
- `MineMusic` 109148793011225 "Fading Sunlight" (DistrokidOfficial, 167 s): música da mina.
- `VillageMusic` 74917475529683 "A Medieval Village" (DistrokidOfficial, 215 s): música da vila.
- `Tavern` 80388954716054 "Medieval Tavern Ambience" (DistrokidOfficial, 397 s): burburinho baixo na vila.
- `Campfire` 134379431802298 "campfire wood crackling" (FormalCircuit_dev, 3 s em laço): fogueiras das praças.
- Licença exata de cada faixa não foi conferida (só aparecem como "verificado" na Creator Store). Se o Alan preferir só áudio da própria Roblox, troque os IDs em `Config.Audio`.

## 3TD Cave Pack Pro v1.0 (CC0)

Autor: RonMain (3TD), OpenGameArt: https://opengameart.org/content/3td-cave-pack-pro-v10 . Licença CC0 (domínio público). Usamos 15 peças (estalagmite, 3 estalactites, 2 entulhos, penhasco, 6 rochas e uma samambaia), convertidas de DAE para OBJ por `tools/dae2obj.py` e importadas no Studio. O download (200 MB) fica em `tools/downloads/` (fora do Git).
