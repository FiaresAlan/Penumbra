# Sons do jogo

## O que está em uso (Creator Store, biblioteca gratuita)
Os IDs ficam em `Config.Audio` (`src/shared/Config.lua`); a lista com nomes e durações está em `tools/assets/toolbox_sounds.json`.

| Uso | Som | Duração |
|---|---|---|
| Ambiente da caverna (loop) | Cave Ambience | 117 s |
| Drone de tensão (loop, mais alto nos tiers Normal e Fúria) | Evil Drone Deep Unsettling Rumbly Keening | 36 s |
| Vento da caverna (loop) | Barstow Wind Light Blustery Low Howl | 37 s |
| Lobby (loop) | Jungle Birds Ambience | 36 s |
| Floresta e Mercado Negro (loop) | Jungle Insects | 46 s |
| Batimento quando o Guardião se aproxima | heartbeat loop | 0,7 s |
| Passos do Guardião | Heavy Military Footstep | 0,55 s |
| Rosnado ao começar a caçada | Goliath Vocal Deep Growling Voice | 2,2 s |
| Gotas d'água aleatórias | Water Drips Into Filled Bowl | 5 s |
| Grade batendo (Ninho) | Metal Clangs | 1,5 s |
| Risada do núcleo falso | Evil Death Creepy Laugh | 4,5 s |
| Voz do Corista (velocidade 0,85 a 0,95) | creepy whispering | 8 s |
| Entulho caindo (Enganador) | terrain_destruction_smallrubble | 2,8 s |
| Sino do elevador | Mitsubishi Elevator Chime | 3 s |
| Tremor (também treme a câmera) | som embutido do Studio | |

**Importante:** os sons foram escolhidos pelo nome e confirmados como carregáveis (duração e `IsLoaded`), mas ninguém os ouviu.
Se algum não combinar, troque o ID em `Config.Audio`, ou ajuste o volume em `Config.AudioVolume` e `Config.AmbientLayers`.

## Sons sintetizados (opcionais)
`python tools/make_sounds.py` gera 18 WAV em `tools/assets/sounds/` (drone, vento, gotas, ronco, batimento, passos, rosnado, ecos, ambientes).
São 100% gerados por código, sem direitos de terceiros. Para usá-los: no site Creator Hub, em Audio, envie os arquivos
(exige conta com verificação de ID e aceitar os Termos de Uso de Áudio), depois cole os IDs em `Config.Audio`.
