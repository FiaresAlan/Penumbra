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
- Ainda não entraram no jogo (módulo R5).
