--!strict
-- IDs do Quaternius Medieval Village MegaKit (CC0, quaternius.com), importados como GLB separados por material.
-- Gerado por tools/make_village_assets.py a partir de tools/assets/village_ids.json. Não edite à mão.
-- Medidas em metros do kit: o jogo multiplica por Scale. O pivô de cada peça é o centro da base.
export type Part = { material: string, mesh: string, size: Vector3, offset: CFrame }
export type Texture = { color: string, normal: string, roughness: string, metalness: string }

local VillageAssets = {}

VillageAssets.Scale = 3

VillageAssets.Textures = {
    MI_Brick = { color = "rbxassetid://71041984848270", normal = "rbxassetid://73527938649688", roughness = "rbxassetid://89853862477708", metalness = "rbxassetid://138876298127777" },
    MI_MetalOrnaments = { color = "rbxassetid://73840585513129", normal = "", roughness = "rbxassetid://127155662189315", metalness = "rbxassetid://118937370264503" },
    MI_Plaster = { color = "rbxassetid://88532664593787", normal = "rbxassetid://117756090990377", roughness = "rbxassetid://79100348720348", metalness = "rbxassetid://116714776856791" },
    MI_RockTrim = { color = "rbxassetid://74987951647646", normal = "rbxassetid://76415200990596", roughness = "rbxassetid://78035453195567", metalness = "rbxassetid://81687874669862" },
    MI_RoundTiles = { color = "rbxassetid://121822035351867", normal = "rbxassetid://90021388505064", roughness = "rbxassetid://127577366372174", metalness = "rbxassetid://118279272723288" },
    MI_UnevenBrick = { color = "rbxassetid://94733881027531", normal = "rbxassetid://75764001902240", roughness = "rbxassetid://92177194061111", metalness = "rbxassetid://109624058842605" },
    MI_WoodTrim = { color = "rbxassetid://108357239901861", normal = "rbxassetid://95497095630289", roughness = "rbxassetid://77521864790225", metalness = "rbxassetid://139065267826259" },
} :: { [string]: Texture }

VillageAssets.Pieces = {
    Balcony_Cross_Straight = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://120935822975049", size = Vector3.new(2, 1.22989, 0.20628), offset = CFrame.new(0, 0.50986, -1.00111, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Balcony_Simple_Corner = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://138666222771703", size = Vector3.new(2.10425, 1.22989, 2.10425), offset = CFrame.new(-0.05212, 0.50985, 0.05213, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Balcony_Simple_Straight = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://71177724806052", size = Vector3.new(2, 1.22989, 0.20628), offset = CFrame.new(0, 0.50986, -1.00111, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Corner_ExteriorWide_Wood = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://107870818680341", size = Vector3.new(0.29046, 3, 0.33118), offset = CFrame.new(0, 1.50002, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Corner_Exterior_Brick = {
        { material = "MI_RockTrim", mesh = "rbxassetid://78287265759408", size = Vector3.new(0.53067, 3.01563, 0.57583), offset = CFrame.new(0.08761, 1.50072, -0.08878, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Corner_Exterior_Wood = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://136314470967231", size = Vector3.new(0.21017, 3, 0.23964), offset = CFrame.new(0, 1.49998, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Corner_Interior_Big = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://124231070951067", size = Vector3.new(0.33314, 3, 0.36813), offset = CFrame.new(-0.15731, 1.5, 0.13983, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    DoorFrame_Flat_WoodDark = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://99773230578263", size = Vector3.new(1.57399, 2.31226, 0.38845), offset = CFrame.new(-0.00079, 1.14759, 0.04906, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    DoorFrame_Round_WoodDark = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://122217434526705", size = Vector3.new(1.40698, 2.56339, 0.53896), offset = CFrame.new(0, 1.27316, -0.02945, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Door_1_Flat = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://81382724872779", size = Vector3.new(1.11787, 2.09972, 0.1207), offset = CFrame.new(-0.51267, 1.08508, -0.00279, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_WindowGlass", mesh = "rbxassetid://102092331211469", size = Vector3.new(0.70505, 0.45068, 0.001), offset = CFrame.new(-0.51424, 1.5392, -0.03125, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Door_1_Round = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://72024443918756", size = Vector3.new(1.12001, 2.31824, 0.1207), offset = CFrame.new(-0.51374, 1.19221, -0.00279, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_WindowGlass", mesh = "rbxassetid://116437586912506", size = Vector3.new(0.70505, 0.45068, 0.001), offset = CFrame.new(-0.51424, 1.53706, -0.03125, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Door_2_Round = {
        { material = "MI_WoodTrim_Wear", mesh = "rbxassetid://121708929015217", size = Vector3.new(1.11545, 2.32749, 0.09948), offset = CFrame.new(-0.51506, 1.19207, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_MetalOrnaments", mesh = "rbxassetid://99493140221070", size = Vector3.new(1.01496, 1.71149, 0.2609), offset = CFrame.new(-0.53016, 1.18263, 0.00323, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Floor_Brick = {
        { material = "MI_Brick", mesh = "rbxassetid://100589320841266", size = Vector3.new(2, 0.02, 2), offset = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Floor_UnevenBrick = {
        { material = "MI_UnevenBrick", mesh = "rbxassetid://89668699040186", size = Vector3.new(2, 0.02, 2), offset = CFrame.new(0, 0.00001, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Floor_WoodDark = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://93866192235347", size = Vector3.new(2, 0.02, 2), offset = CFrame.new(0, -0.00001, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Floor_WoodLight = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://103289356179253", size = Vector3.new(2, 0.02, 2), offset = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Overhang_Plaster_Corner = {
        { material = "MI_Plaster", mesh = "rbxassetid://95441778125242", size = Vector3.new(3.09482, 2.91355, 3.09482), offset = CFrame.new(0.45259, 1.45677, -0.45259, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_WoodTrim", mesh = "rbxassetid://75303753117219", size = Vector3.new(3.1008, 2.70344, 3.1008), offset = CFrame.new(0.4496, 1.76504, -0.4496, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Overhang_Plaster_Long = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://112051548108709", size = Vector3.new(2, 2.61469, 2.01252), offset = CFrame.new(0, 1.72067, -0.99374, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_Plaster", mesh = "rbxassetid://122650578619443", size = Vector3.new(2, 2.92453, 2.2), offset = CFrame.new(0, 1.46227, -0.9, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Overhang_Plaster_Short = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://110868939748331", size = Vector3.new(2, 2.70937, 1.13535), offset = CFrame.new(0, 1.768, -0.55516, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_Plaster", mesh = "rbxassetid://111169616226833", size = Vector3.new(2, 2.91355, 1.29482), offset = CFrame.new(0, 1.45677, -0.44741, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Prop_Chimney = {
        { material = "MI_RockTrim", mesh = "rbxassetid://83951785173948", size = Vector3.new(0.8899, 0.33802, 0.90474), offset = CFrame.new(0.00665, 3.00886, -0.02102, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_Brick", mesh = "rbxassetid://79699265320930", size = Vector3.new(0.94578, 3, 1), offset = CFrame.new(0.02711, 1.5, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Prop_Chimney2 = {
        { material = "MI_UnevenBrick", mesh = "rbxassetid://116290649130197", size = Vector3.new(0.94578, 3, 0.98802), offset = CFrame.new(0.02711, 1.5, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Prop_Crate = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://94227953323826", size = Vector3.new(1.08358, 1.05958, 1.08358), offset = CFrame.new(0, 0.53315, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Prop_ExteriorBorder_Straight1 = {
        { material = "MI_RockTrim", mesh = "rbxassetid://136426809353264", size = Vector3.new(2, 0.13402, 0.7), offset = CFrame.new(0, 0.06701, -0.35, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Prop_MetalFence_Simple = {
        { material = "MI_MetalOrnaments", mesh = "rbxassetid://131375183725229", size = Vector3.new(1.9491, 2.86835, 0.15606), offset = CFrame.new(-0.00445, 1.43418, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Prop_Support = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://116220751568061", size = Vector3.new(0.1986, 1.70864, 2.03627), offset = CFrame.new(0, 2.0657, -0.90001, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Prop_Wagon = {
        { material = "MI_WoodTrim_Wear", mesh = "rbxassetid://96453812382690", size = Vector3.new(1.95141, 1.5292, 4.02402), offset = CFrame.new(0.00365, 0.76773, 1.13842, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Prop_WoodenFence_Extension1 = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://138421326130668", size = Vector3.new(2.04504, 0.83811, 0.11036), offset = CFrame.new(-0.01012, 0.3908, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Prop_WoodenFence_Single = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://72455078815382", size = Vector3.new(2.0641, 0.83811, 0.11982), offset = CFrame.new(-0.0006, 0.3908, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Roof_Dormer_RoundTile = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://100135338800467", size = Vector3.new(1.86235, 2.37749, 2.10619), offset = CFrame.new(-0.86492, 1.2184, -0.00007, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_Plaster", mesh = "rbxassetid://78119860633059", size = Vector3.new(1.43382, 2.10744, 1.44356), offset = CFrame.new(-0.92432, 1.12732, 0.00097, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_WindowGlass", mesh = "rbxassetid://133492331599878", size = Vector3.new(0.001, 0.78764, 0.86983), offset = CFrame.new(-1.64502, 0.6428, -0.002, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_RoundTiles", mesh = "rbxassetid://87295062250945", size = Vector3.new(1.91881, 1.75589, 2.43916), offset = CFrame.new(-0.94071, 1.82482, -0.00007, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Roof_FrontSupports = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://78930015930521", size = Vector3.new(5.48626, 0.23119, 0.65453), offset = CFrame.new(0, -0.00266, -0.3, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Roof_Front_Brick4 = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://75997649703429", size = Vector3.new(4.3998, 2.7718, 1.1291), offset = CFrame.new(-0.0161, 1.25412, -0.22959, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_Plaster", mesh = "rbxassetid://125226314231000", size = Vector3.new(4.30198, 2.91754, 0.2497), offset = CFrame.new(-0.03719, 1.47795, 0.12485, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Roof_Front_Brick6 = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://77116068311874", size = Vector3.new(6.6944, 4.51578, 1.1291), offset = CFrame.new(-0.00068, 2.12609, -0.22959, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_Plaster", mesh = "rbxassetid://113341047388052", size = Vector3.new(6.2451, 4.35806, 0.2497), offset = CFrame.new(0, 2.1982, 0.12485, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Roof_Front_Brick8 = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://81480773913606", size = Vector3.new(8.51079, 5.40144, 1.1291), offset = CFrame.new(-0.00068, 2.56892, -0.22959, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_Plaster", mesh = "rbxassetid://75917607104734", size = Vector3.new(8.32554, 5.2949, 0.2497), offset = CFrame.new(0, 2.66662, 0.12485, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Roof_Log = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://97805681212934", size = Vector3.new(1.14893, 1.38695, 10.6958), offset = CFrame.new(0.01186, 4.54218, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Roof_RoundTiles_4x4 = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://73623749880830", size = Vector3.new(5.13524, 3.71642, 5.48539), offset = CFrame.new(0, 1.34251, -0.00278, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_RoundTiles", mesh = "rbxassetid://80409861339898", size = Vector3.new(5.51308, 4.12151, 5.52341), offset = CFrame.new(0, 1.67294, -0.05986, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Roof_RoundTiles_6x10 = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://108348443254798", size = Vector3.new(7.9179, 5.12473, 11.65751), offset = CFrame.new(0, 1.78024, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_RoundTiles", mesh = "rbxassetid://96465516557566", size = Vector3.new(8.24978, 5.52849, 11.85219), offset = CFrame.new(0, 2.1258, -0.02851, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Roof_RoundTiles_6x6 = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://98768134355658", size = Vector3.new(7.9179, 5.12473, 7.58675), offset = CFrame.new(0, 1.78024, -0.00594, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_RoundTiles", mesh = "rbxassetid://115975641362848", size = Vector3.new(8.24978, 5.52849, 8.03219), offset = CFrame.new(0, 2.1258, -0.07789, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Roof_RoundTiles_6x8 = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://128278157165773", size = Vector3.new(7.9179, 5.12473, 9.65751), offset = CFrame.new(0, 1.78023, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_RoundTiles", mesh = "rbxassetid://101755530252154", size = Vector3.new(8.24978, 5.52849, 9.6101), offset = CFrame.new(0, 2.12579, -0.04894, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Roof_RoundTiles_8x8 = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://116887302493644", size = Vector3.new(9.91344, 6.38052, 9.71233), offset = CFrame.new(0, 2.41031, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_RoundTiles", mesh = "rbxassetid://75544873971634", size = Vector3.new(9.95199, 6.57316, 10.33219), offset = CFrame.new(0, 2.7148, -0.08135, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Roof_Support2 = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://105932292942096", size = Vector3.new(0.1997, 0.74293, 0.76513), offset = CFrame.new(0, -0.3058, -0.38256, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Roof_Tower_RoundTiles = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://120447914207344", size = Vector3.new(5.2385, 3.45537, 5.19924), offset = CFrame.new(0, 1.15571, 0.00362, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_RockTrim", mesh = "rbxassetid://99322399232591", size = Vector3.new(1.69992, 1.97599, 1.69992), offset = CFrame.new(0, 3.87138, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_RoundTiles", mesh = "rbxassetid://130679795827516", size = Vector3.new(5.65052, 5.02584, 5.4271), offset = CFrame.new(0, 2.20522, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_MetalOrnaments", mesh = "rbxassetid://137382059124873", size = Vector3.new(0.24854, 2.27704, 0.24826), offset = CFrame.new(0, 5.65028, -0.00094, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Roof_Wooden_2x1 = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://106500051720243", size = Vector3.new(2.25786, 1.22938, 1.20244), offset = CFrame.new(0, 0.47248, -0.56005, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_WoodTrim_Wear", mesh = "rbxassetid://81114330773578", size = Vector3.new(2.00789, 1.24835, 1.56032), offset = CFrame.new(0.00153, 0.46299, -0.73899, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Roof_Wooden_2x1_Corner = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://121759987452635", size = Vector3.new(1.16127, 0.26504, 1.16127), offset = CFrame.new(-0.58064, -0.00971, 0.58063, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_WoodTrim_Wear", mesh = "rbxassetid://119725937516104", size = Vector3.new(1.54426, 1.18305, 1.55686), offset = CFrame.new(-0.67123, 0.42268, 0.66454, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Stair_Interior_Simple = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://109477254352035", size = Vector3.new(1.67618, 3.03499, 4.61954), offset = CFrame.new(-0.00322, 1.50711, 2.27504, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Stairs_Exterior_Platform = {
        { material = "MI_RockTrim", mesh = "rbxassetid://132215675806691", size = Vector3.new(1.62523, 0.20691, 2.00134), offset = CFrame.new(0, 0.8852, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_Brick", mesh = "rbxassetid://117972512010223", size = Vector3.new(2, 1, 2), offset = CFrame.new(0, 0.49999, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Stairs_Exterior_Straight = {
        { material = "MI_RockTrim", mesh = "rbxassetid://129045048441001", size = Vector3.new(1.8, 1.0221, 2.07792), offset = CFrame.new(0, 0.30735, 0.03829, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_Brick", mesh = "rbxassetid://115537093687232", size = Vector3.new(2, 1, 2), offset = CFrame.new(0, 0.49999, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Wall_Arch = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://118934413329394", size = Vector3.new(2, 3, 0.06405), offset = CFrame.new(0, 1.5, -0.03202, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Wall_BottomCover = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://135043547447491", size = Vector3.new(2, 0.23753, 0.43161), offset = CFrame.new(0, 0.002, 0.09823, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Wall_Plaster_Door_Flat = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://83540430480075", size = Vector3.new(2, 2.47311, 0.40648), offset = CFrame.new(0, 1.88613, 0.11079, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_Plaster", mesh = "rbxassetid://87581276298226", size = Vector3.new(2, 3, 0.2), offset = CFrame.new(0, 1.49999, 0.1, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_RockTrim", mesh = "rbxassetid://103250007566985", size = Vector3.new(2, 0.88, 0.001), offset = CFrame.new(0, 0.44, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Wall_Plaster_Door_Round = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://78755237043821", size = Vector3.new(2, 2.47311, 0.40648), offset = CFrame.new(0, 1.88614, 0.11079, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_Plaster", mesh = "rbxassetid://125370108890345", size = Vector3.new(2, 3, 0.2), offset = CFrame.new(0, 1.5, 0.1, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_RockTrim", mesh = "rbxassetid://110924765666446", size = Vector3.new(2, 0.91006, 0.001), offset = CFrame.new(0, 0.45503, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Wall_Plaster_Door_RoundInset = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://111251714293944", size = Vector3.new(2, 0.24538, 0.40648), offset = CFrame.new(0, 2.99998, 0.11079, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_Plaster", mesh = "rbxassetid://91919488336298", size = Vector3.new(2, 3, 1), offset = CFrame.new(0, 1.49998, 0.5, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_RockTrim", mesh = "rbxassetid://128949646174851", size = Vector3.new(2, 0.91006, 1), offset = CFrame.new(0, 0.45502, 0.5, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Wall_Plaster_Straight = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://121061699984550", size = Vector3.new(2, 3.12478, 0.40648), offset = CFrame.new(0, 1.5603, 0.11079, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_Plaster", mesh = "rbxassetid://134585945338433", size = Vector3.new(2, 3, 0.2), offset = CFrame.new(0, 1.49999, 0.1, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Wall_Plaster_Straight_Base = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://116831240243610", size = Vector3.new(2, 2.47311, 0.40648), offset = CFrame.new(0, 1.88613, 0.11079, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_Plaster", mesh = "rbxassetid://126776559503528", size = Vector3.new(2, 3, 0.2), offset = CFrame.new(0, 1.49999, 0.1, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_Brick", mesh = "rbxassetid://118183658041029", size = Vector3.new(2, 0.88, 0.001), offset = CFrame.new(0, 0.43999, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Wall_Plaster_Straight_L = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://121111408319875", size = Vector3.new(2.00178, 2.47311, 0.40648), offset = CFrame.new(-0.00089, 1.88613, 0.11079, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_Plaster", mesh = "rbxassetid://90273215006277", size = Vector3.new(2, 3, 0.2), offset = CFrame.new(0, 1.5, 0.1, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_Brick", mesh = "rbxassetid://105422255160925", size = Vector3.new(2, 0.88, 0.001), offset = CFrame.new(0, 0.44, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Wall_Plaster_Straight_R = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://84094354668918", size = Vector3.new(2.00178, 2.47311, 0.40648), offset = CFrame.new(0.00089, 1.88614, 0.11079, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_Plaster", mesh = "rbxassetid://76523638312617", size = Vector3.new(2, 3, 0.2), offset = CFrame.new(0, 1.5, 0.1, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_Brick", mesh = "rbxassetid://118235544587972", size = Vector3.new(2, 0.88, 0.001), offset = CFrame.new(0, 0.44, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Wall_Plaster_Window_Thin_Round = {
        { material = "MI_Plaster", mesh = "rbxassetid://138552508229205", size = Vector3.new(2, 3, 0.2), offset = CFrame.new(0, 1.5, 0.1, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_Brick", mesh = "rbxassetid://87020207875048", size = Vector3.new(2, 0.88, 0.001), offset = CFrame.new(0, 0.44, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_WoodTrim", mesh = "rbxassetid://134163591375880", size = Vector3.new(2, 2.47311, 0.40648), offset = CFrame.new(0, 1.88614, 0.11079, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Wall_Plaster_Window_Wide_Flat = {
        { material = "MI_Plaster", mesh = "rbxassetid://80744510681305", size = Vector3.new(2, 3, 0.2), offset = CFrame.new(0, 1.5, 0.1, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_Brick", mesh = "rbxassetid://81387017832745", size = Vector3.new(2, 0.88, 0.001), offset = CFrame.new(0, 0.44, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_WoodTrim", mesh = "rbxassetid://96684569029209", size = Vector3.new(2, 2.47311, 0.40648), offset = CFrame.new(0, 1.88613, 0.11079, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Wall_Plaster_Window_Wide_Round = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://86624314313693", size = Vector3.new(2, 2.47311, 0.40648), offset = CFrame.new(0, 1.88614, 0.11079, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_Plaster", mesh = "rbxassetid://131302323264099", size = Vector3.new(2, 3, 0.2), offset = CFrame.new(0, 1.5, 0.1, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_Brick", mesh = "rbxassetid://74388894825161", size = Vector3.new(2, 0.88, 0.001), offset = CFrame.new(0, 0.44, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Wall_Plaster_WoodGrid = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://94026800273611", size = Vector3.new(2, 2.47311, 0.40648), offset = CFrame.new(0, 1.88613, 0.11079, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_Plaster", mesh = "rbxassetid://101550936715835", size = Vector3.new(2, 0.83609, 0.2), offset = CFrame.new(0, 0.41804, 0.1, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Wall_UnevenBrick_Door_Round = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://107672612633740", size = Vector3.new(2, 0.24538, 0.40648), offset = CFrame.new(0, 3, 0.11079, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_Plaster", mesh = "rbxassetid://134703235291736", size = Vector3.new(2, 3, 0.001), offset = CFrame.new(0, 1.5, 0.2, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_UnevenBrick", mesh = "rbxassetid://77825534928266", size = Vector3.new(2, 3, 0.001), offset = CFrame.new(0, 1.5, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Wall_UnevenBrick_Straight = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://125859125152658", size = Vector3.new(2, 0.24538, 0.40648), offset = CFrame.new(0, 3, 0.11079, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_Plaster", mesh = "rbxassetid://119122183550149", size = Vector3.new(2, 3, 0.001), offset = CFrame.new(0, 1.5, 0.2, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_UnevenBrick", mesh = "rbxassetid://124001165574369", size = Vector3.new(2, 3, 0.001), offset = CFrame.new(0, 1.5, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Wall_UnevenBrick_Window_Thin_Round = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://78602865443254", size = Vector3.new(2, 0.24538, 0.40648), offset = CFrame.new(0, 3, 0.11079, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_Plaster", mesh = "rbxassetid://132702854707097", size = Vector3.new(2, 3, 0.001), offset = CFrame.new(0, 1.5, 0.2, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_UnevenBrick", mesh = "rbxassetid://71556085324697", size = Vector3.new(2, 3, 0.001), offset = CFrame.new(0, 1.5, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Wall_UnevenBrick_Window_Wide_Round = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://98415989354516", size = Vector3.new(2, 0.24538, 0.40648), offset = CFrame.new(0, 3, 0.11079, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_Plaster", mesh = "rbxassetid://98041109397352", size = Vector3.new(2, 3, 0.001), offset = CFrame.new(0, 1.5, 0.2, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_UnevenBrick", mesh = "rbxassetid://104471949441005", size = Vector3.new(2, 3, 0.001), offset = CFrame.new(0, 1.5, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    WindowShutters_Thin_Round_Open = {
        { material = "MI_WoodTrim_Wear", mesh = "rbxassetid://95636661212989", size = Vector3.new(1.60628, 1.51842, 0.37649), offset = CFrame.new(0.01643, 1.85245, -0.24726, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    WindowShutters_Wide_Round_Closed = {
        { material = "MI_WoodTrim_Wear", mesh = "rbxassetid://99608805475012", size = Vector3.new(1.34694, 1.64719, 0.13577), offset = CFrame.new(0, 1.91684, -0.22035, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    WindowShutters_Wide_Round_Open = {
        { material = "MI_WoodTrim_Wear", mesh = "rbxassetid://119626913651141", size = Vector3.new(2.30348, 1.64719, 0.47236), offset = CFrame.new(0.04822, 1.91683, -0.32697, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Window_Thin_Round1 = {
        { material = "MI_WoodTrim_Wear", mesh = "rbxassetid://138391678340854", size = Vector3.new(0.88762, 1.60468, 0.34439), offset = CFrame.new(0, 1.81839, 0.07983, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_WindowGlass", mesh = "rbxassetid://119239238148765", size = Vector3.new(0.556, 1.39136, 0.001), offset = CFrame.new(0.00094, 1.78325, -0.00389, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Window_Wide_Flat1 = {
        { material = "MI_WoodTrim", mesh = "rbxassetid://103515388091767", size = Vector3.new(1.60824, 1.58011, 0.68344), offset = CFrame.new(0, 1.73423, -0.07514, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_WindowGlass", mesh = "rbxassetid://113145583265141", size = Vector3.new(1.01094, 1.25822, 0.001), offset = CFrame.new(0, 1.72625, -0.00389, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
    Window_Wide_Round1 = {
        { material = "MI_WoodTrim_Wear", mesh = "rbxassetid://134226815667826", size = Vector3.new(1.36492, 1.72574, 0.52958), offset = CFrame.new(0, 1.87892, -0.0125, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { material = "MI_WindowGlass", mesh = "rbxassetid://87913265430338", size = Vector3.new(1.08586, 1.55449, 0.001), offset = CFrame.new(0.00162, 1.84202, -0.00389, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    },
} :: { [string]: { Part } }

return VillageAssets
