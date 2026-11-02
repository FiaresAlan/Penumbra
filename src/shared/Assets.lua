--!strict
-- IDs dos meshes do KayKit Dungeon Remastered (CC0, Kay Lousberg, kaylousberg.com) importados pelo Studio.
-- Gerado a partir de tools/assets/imported_ids.json. Os arquivos originais ficam em tools/assets/kaykit.
-- `size` é o tamanho original do mesh; o MapBuilder multiplica por uma escala ao criar o prop.
export type Prop = { mesh: string, texture: string, size: Vector3 }

local Assets: { [string]: Prop } = {
    banner_triple_brown = { mesh = "rbxassetid://102088116995070", texture = "rbxassetid://136213525758523", size = Vector3.new(3.700, 3.196, 0.362) },
    barrel_large = { mesh = "rbxassetid://103999015612495", texture = "rbxassetid://78041158500230", size = Vector3.new(1.800, 2.000, 1.800) },
    barrel_small_stack = { mesh = "rbxassetid://83964737100344", texture = "rbxassetid://80301725875130", size = Vector3.new(1.850, 1.770, 1.000) },
    box_large = { mesh = "rbxassetid://109648177403325", texture = "rbxassetid://136213525758523", size = Vector3.new(1.500, 1.500, 1.500) },
    box_stacked = { mesh = "rbxassetid://97272052791718", texture = "rbxassetid://83214019534754", size = Vector3.new(3.475, 3.309, 3.635) },
    candle_triple = { mesh = "rbxassetid://133709674097937", texture = "rbxassetid://136213525758523", size = Vector3.new(0.501, 0.873, 0.390) },
    chest = { mesh = "rbxassetid://123909638992604", texture = "rbxassetid://128948079757971", size = Vector3.new(1.600, 0.600, 1.246) },
    chest_gold = { mesh = "rbxassetid://101881276532279", texture = "rbxassetid://97455269751947", size = Vector3.new(1.600, 1.041, 1.246) },
    column = { mesh = "rbxassetid://132210486660778", texture = "rbxassetid://136213525758523", size = Vector3.new(0.700, 1.400, 0.700) },
    crates_stacked = { mesh = "rbxassetid://109583148766345", texture = "rbxassetid://94893142116351", size = Vector3.new(2.089, 2.142, 2.249) },
    keg_decorated = { mesh = "rbxassetid://123009077245847", texture = "rbxassetid://136213525758523", size = Vector3.new(3.519, 2.051, 2.000) },
    rubble_half = { mesh = "rbxassetid://99920461176877", texture = "rbxassetid://136213525758523", size = Vector3.new(4.000, 3.500, 3.000) },
    rubble_large = { mesh = "rbxassetid://128437016361974", texture = "rbxassetid://136213525758523", size = Vector3.new(8.129, 3.496, 3.183) },
    sword_shield_broken = { mesh = "rbxassetid://129522300163546", texture = "rbxassetid://136213525758523", size = Vector3.new(1.426, 1.962, 0.336) },
    torch_lit = { mesh = "rbxassetid://93129079752994", texture = "rbxassetid://136213525758523", size = Vector3.new(0.550, 1.126, 0.550) },
    torch_mounted = { mesh = "rbxassetid://75322650764517", texture = "rbxassetid://97556672642610", size = Vector3.new(0.550, 1.062, 0.616) },
}

return Assets
