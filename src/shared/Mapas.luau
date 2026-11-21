-- Mapas.lua · tiles dos mapas base e a projeção usada para gerá-los.
-- Camadas (de baixo para cima): fundo do mar (cor + textura) -> terra (tingir com land) -> linhas (tingir com coast).
-- Na terra, o país/região jogável é opaco; os vizinhos têm alfa 0.45 e ficam entre a cor do mar e a da terra.
-- As coordenadas em 'cidades' são pixels do mapa completo; o pipeline de dados usa a mesma projeção (d3-geo).

local Mapas = {}

Mapas.brasil = {
	largura = 2048, altura = 2048,
	projecao = { tipo = "geoMercator", rotacao = { 0, 0, 0 }, escala = 2684.7822, translacao = { 3573.2663, 306.6919 } },
	tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://125447283985319", arquivo = "mapas/brasil/brasil_terra_0_0.png" },
		{ camada = "terra", x = 1024, y = 0, w = 1024, h = 1024, id = "rbxassetid://87202933604088", arquivo = "mapas/brasil/brasil_terra_0_1.png" },
		{ camada = "terra", x = 0, y = 1024, w = 1024, h = 1024, id = "rbxassetid://90634831525523", arquivo = "mapas/brasil/brasil_terra_1_0.png" },
		{ camada = "terra", x = 1024, y = 1024, w = 1024, h = 1024, id = "rbxassetid://96258142798399", arquivo = "mapas/brasil/brasil_terra_1_1.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://118885708909480", arquivo = "mapas/brasil/brasil_linhas_0_0.png" },
		{ camada = "linhas", x = 1024, y = 0, w = 1024, h = 1024, id = "rbxassetid://114254701867704", arquivo = "mapas/brasil/brasil_linhas_0_1.png" },
		{ camada = "linhas", x = 0, y = 1024, w = 1024, h = 1024, id = "rbxassetid://138296618421519", arquivo = "mapas/brasil/brasil_linhas_1_0.png" },
		{ camada = "linhas", x = 1024, y = 1024, w = 1024, h = 1024, id = "rbxassetid://125528362239749", arquivo = "mapas/brasil/brasil_linhas_1_1.png" },
		{ camada = "rios", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://128212532754836", arquivo = "mapas/brasil/brasil_rios_0_0.png" },
		{ camada = "rios", x = 1024, y = 0, w = 1024, h = 1024, id = "rbxassetid://71181019889077", arquivo = "mapas/brasil/brasil_rios_0_1.png" },
		{ camada = "rios", x = 0, y = 1024, w = 1024, h = 1024, id = "rbxassetid://95200340455469", arquivo = "mapas/brasil/brasil_rios_1_0.png" },
		{ camada = "rios", x = 1024, y = 1024, w = 1024, h = 1024, id = "rbxassetid://127230307427266", arquivo = "mapas/brasil/brasil_rios_1_1.png" },
	},
	cidades = {
		["São Paulo"] = Vector2.new(1388, 1443),
		["Rio de Janeiro"] = Vector2.new(1549, 1410),
		["Santos"] = Vector2.new(1402, 1464),
		["Belo Horizonte"] = Vector2.new(1514, 1260),
		["Brasília"] = Vector2.new(1330, 1056),
		["Salvador"] = Vector2.new(1769, 920),
		["Recife"] = Vector2.new(1939, 685),
		["Fortaleza"] = Vector2.new(1768, 482),
		["Belém"] = Vector2.new(1301, 375),
		["Manaus"] = Vector2.new(761, 453),
		["Porto Alegre"] = Vector2.new(1173, 1783),
		["Curitiba"] = Vector2.new(1265, 1539),
		["Corumbá"] = Vector2.new(872, 1214),
		["Porto Velho"] = Vector2.new(579, 719),
	},
}

Mapas.eua = {
	largura = 2048, altura = 1280,
	projecao = { tipo = "geoConicEqualArea", rotacao = { 96.0, 0, 0 }, escala = 2540.4108, translacao = { 1044.0341, 856.9347 }, paralelos = { 29.5, 45.5 } },
	tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://0", arquivo = "mapas/eua/eua_terra_0_0.png" },
		{ camada = "terra", x = 1024, y = 0, w = 1024, h = 1024, id = "rbxassetid://0", arquivo = "mapas/eua/eua_terra_0_1.png" },
		{ camada = "terra", x = 0, y = 1024, w = 1024, h = 256, id = "rbxassetid://0", arquivo = "mapas/eua/eua_terra_1_0.png" },
		{ camada = "terra", x = 1024, y = 1024, w = 1024, h = 256, id = "rbxassetid://0", arquivo = "mapas/eua/eua_terra_1_1.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://0", arquivo = "mapas/eua/eua_linhas_0_0.png" },
		{ camada = "linhas", x = 1024, y = 0, w = 1024, h = 1024, id = "rbxassetid://0", arquivo = "mapas/eua/eua_linhas_0_1.png" },
		{ camada = "linhas", x = 0, y = 1024, w = 1024, h = 256, id = "rbxassetid://0", arquivo = "mapas/eua/eua_linhas_1_0.png" },
		{ camada = "linhas", x = 1024, y = 1024, w = 1024, h = 256, id = "rbxassetid://0", arquivo = "mapas/eua/eua_linhas_1_1.png" },
		{ camada = "rios", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://0", arquivo = "mapas/eua/eua_rios_0_0.png" },
		{ camada = "rios", x = 1024, y = 0, w = 1024, h = 1024, id = "rbxassetid://0", arquivo = "mapas/eua/eua_rios_0_1.png" },
		{ camada = "rios", x = 0, y = 1024, w = 1024, h = 256, id = "rbxassetid://0", arquivo = "mapas/eua/eua_rios_1_0.png" },
		{ camada = "rios", x = 1024, y = 1024, w = 1024, h = 256, id = "rbxassetid://0", arquivo = "mapas/eua/eua_rios_1_1.png" },
	},
	cidades = {
		["New York"] = Vector2.new(1771, 456),
		["Chicago"] = Vector2.new(1318, 476),
		["Omaha"] = Vector2.new(1046, 516),
		["Sacramento"] = Vector2.new(180, 519),
		["Denver"] = Vector2.new(741, 570),
		["New Orleans"] = Vector2.new(1271, 1014),
		["Seattle"] = Vector2.new(262, 125),
		["Los Angeles"] = Vector2.new(241, 744),
		["Baltimore"] = Vector2.new(1699, 537),
		["Promontory"] = Vector2.new(502, 453),
	},
}

Mapas.europa = {
	largura = 2048, altura = 1536,
	projecao = { tipo = "geoAzimuthalEqualArea", rotacao = { -10, -52, 0 }, escala = 3026.7083, translacao = { 1024, 607.3794 } },
	tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://0", arquivo = "mapas/europa/europa_terra_0_0.png" },
		{ camada = "terra", x = 1024, y = 0, w = 1024, h = 1024, id = "rbxassetid://0", arquivo = "mapas/europa/europa_terra_0_1.png" },
		{ camada = "terra", x = 0, y = 1024, w = 1024, h = 512, id = "rbxassetid://0", arquivo = "mapas/europa/europa_terra_1_0.png" },
		{ camada = "terra", x = 1024, y = 1024, w = 1024, h = 512, id = "rbxassetid://0", arquivo = "mapas/europa/europa_terra_1_1.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://0", arquivo = "mapas/europa/europa_linhas_0_0.png" },
		{ camada = "linhas", x = 1024, y = 0, w = 1024, h = 1024, id = "rbxassetid://0", arquivo = "mapas/europa/europa_linhas_0_1.png" },
		{ camada = "linhas", x = 0, y = 1024, w = 1024, h = 512, id = "rbxassetid://0", arquivo = "mapas/europa/europa_linhas_1_0.png" },
		{ camada = "linhas", x = 1024, y = 1024, w = 1024, h = 512, id = "rbxassetid://0", arquivo = "mapas/europa/europa_linhas_1_1.png" },
	},
	cidades = {
		["London"] = Vector2.new(692, 610),
		["Paris"] = Vector2.new(759, 759),
		["Berlin"] = Vector2.new(1133, 577),
		["Madrid"] = Vector2.new(474, 1168),
		["Roma"] = Vector2.new(1123, 1139),
		["Wien"] = Vector2.new(1248, 798),
		["Amsterdam"] = Vector2.new(860, 582),
		["Bruxelles"] = Vector2.new(836, 661),
		["Milano"] = Vector2.new(994, 953),
		["Lisboa"] = Vector2.new(239, 1208),
		["Warszawa"] = Vector2.new(1379, 568),
		["Zürich"] = Vector2.new(972, 851),
		["Stockton"] = Vector2.new(679, 444),
		["Liverpool"] = Vector2.new(618, 496),
		["Manchester"] = Vector2.new(641, 497),
		["Istanbul"] = Vector2.new(1775, 1092),
	},
}

-- Regiões de detalhe: blocos de 256 px do mapa base desenhados a 4x, só onde passam trilhos (gerados por
-- tools/assetgen/render_detalhes.py e mapas_detalhe.py). Aparecem por cima do mapa base a partir de ZOOM_DETALHE.
-- x0/y0/largura/altura em pixels do mapa base; escala = pixels do detalhe por pixel do mapa base.
Mapas.brasil.detalhes = {
	{ id = "2_0", x0 = 720, y0 = 144, largura = 256, altura = 256, escala = 4, tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://77613795142881", arquivo = "mapas/brasil_detalhe/brasil_detalhe_2_0_terra.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://115167344527885", arquivo = "mapas/brasil_detalhe/brasil_detalhe_2_0_linhas.png" },
		{ camada = "rios", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://136613706971082", arquivo = "mapas/brasil_detalhe/brasil_detalhe_2_0_rios.png" },
	} },
	{ id = "3_0", x0 = 976, y0 = 144, largura = 256, altura = 256, escala = 4, tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://106742003023104", arquivo = "mapas/brasil_detalhe/brasil_detalhe_3_0_terra.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://93816658095785", arquivo = "mapas/brasil_detalhe/brasil_detalhe_3_0_linhas.png" },
		{ camada = "rios", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://114965485216621", arquivo = "mapas/brasil_detalhe/brasil_detalhe_3_0_rios.png" },
	} },
	{ id = "4_0", x0 = 1232, y0 = 144, largura = 256, altura = 256, escala = 4, tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://107782405271166", arquivo = "mapas/brasil_detalhe/brasil_detalhe_4_0_terra.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://103107787958017", arquivo = "mapas/brasil_detalhe/brasil_detalhe_4_0_linhas.png" },
	} },
	{ id = "2_1", x0 = 720, y0 = 400, largura = 256, altura = 256, escala = 4, tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://129750130035648", arquivo = "mapas/brasil_detalhe/brasil_detalhe_2_1_terra.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://119630534728379", arquivo = "mapas/brasil_detalhe/brasil_detalhe_2_1_linhas.png" },
		{ camada = "rios", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://119394889942551", arquivo = "mapas/brasil_detalhe/brasil_detalhe_2_1_rios.png" },
	} },
	{ id = "3_1", x0 = 976, y0 = 400, largura = 256, altura = 256, escala = 4, tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://121238125182466", arquivo = "mapas/brasil_detalhe/brasil_detalhe_3_1_terra.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://70930591644594", arquivo = "mapas/brasil_detalhe/brasil_detalhe_3_1_linhas.png" },
		{ camada = "rios", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://139156533821312", arquivo = "mapas/brasil_detalhe/brasil_detalhe_3_1_rios.png" },
	} },
	{ id = "4_1", x0 = 1232, y0 = 400, largura = 256, altura = 256, escala = 4, tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://103380422158104", arquivo = "mapas/brasil_detalhe/brasil_detalhe_4_1_terra.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://85962958790354", arquivo = "mapas/brasil_detalhe/brasil_detalhe_4_1_linhas.png" },
		{ camada = "rios", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://129605458493687", arquivo = "mapas/brasil_detalhe/brasil_detalhe_4_1_rios.png" },
	} },
	{ id = "5_1", x0 = 1488, y0 = 400, largura = 256, altura = 256, escala = 4, tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://81815557984001", arquivo = "mapas/brasil_detalhe/brasil_detalhe_5_1_terra.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://124173029411580", arquivo = "mapas/brasil_detalhe/brasil_detalhe_5_1_linhas.png" },
		{ camada = "rios", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://137984055994924", arquivo = "mapas/brasil_detalhe/brasil_detalhe_5_1_rios.png" },
	} },
	{ id = "6_1", x0 = 1744, y0 = 400, largura = 256, altura = 256, escala = 4, tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://70933977470272", arquivo = "mapas/brasil_detalhe/brasil_detalhe_6_1_terra.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://131460597804036", arquivo = "mapas/brasil_detalhe/brasil_detalhe_6_1_linhas.png" },
	} },
	{ id = "1_2", x0 = 464, y0 = 656, largura = 256, altura = 256, escala = 4, tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://111004179900314", arquivo = "mapas/brasil_detalhe/brasil_detalhe_1_2_terra.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://118161187546769", arquivo = "mapas/brasil_detalhe/brasil_detalhe_1_2_linhas.png" },
		{ camada = "rios", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://134803388769776", arquivo = "mapas/brasil_detalhe/brasil_detalhe_1_2_rios.png" },
	} },
	{ id = "2_2", x0 = 720, y0 = 656, largura = 256, altura = 256, escala = 4, tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://110615879856893", arquivo = "mapas/brasil_detalhe/brasil_detalhe_2_2_terra.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://100071611067720", arquivo = "mapas/brasil_detalhe/brasil_detalhe_2_2_linhas.png" },
		{ camada = "rios", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://71382480159077", arquivo = "mapas/brasil_detalhe/brasil_detalhe_2_2_rios.png" },
	} },
	{ id = "3_2", x0 = 976, y0 = 656, largura = 256, altura = 256, escala = 4, tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://98345192185010", arquivo = "mapas/brasil_detalhe/brasil_detalhe_3_2_terra.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://90752959047453", arquivo = "mapas/brasil_detalhe/brasil_detalhe_3_2_linhas.png" },
		{ camada = "rios", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://99358153744409", arquivo = "mapas/brasil_detalhe/brasil_detalhe_3_2_rios.png" },
	} },
	{ id = "4_2", x0 = 1232, y0 = 656, largura = 256, altura = 256, escala = 4, tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://112883067422532", arquivo = "mapas/brasil_detalhe/brasil_detalhe_4_2_terra.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://122389072542125", arquivo = "mapas/brasil_detalhe/brasil_detalhe_4_2_linhas.png" },
		{ camada = "rios", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://95601004323220", arquivo = "mapas/brasil_detalhe/brasil_detalhe_4_2_rios.png" },
	} },
	{ id = "5_2", x0 = 1488, y0 = 656, largura = 256, altura = 256, escala = 4, tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://129750130035648", arquivo = "mapas/brasil_detalhe/brasil_detalhe_5_2_terra.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://126656121529886", arquivo = "mapas/brasil_detalhe/brasil_detalhe_5_2_linhas.png" },
		{ camada = "rios", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://105010504538739", arquivo = "mapas/brasil_detalhe/brasil_detalhe_5_2_rios.png" },
	} },
	{ id = "6_2", x0 = 1744, y0 = 656, largura = 256, altura = 256, escala = 4, tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://127578238214659", arquivo = "mapas/brasil_detalhe/brasil_detalhe_6_2_terra.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://135476157860109", arquivo = "mapas/brasil_detalhe/brasil_detalhe_6_2_linhas.png" },
		{ camada = "rios", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://139108473579682", arquivo = "mapas/brasil_detalhe/brasil_detalhe_6_2_rios.png" },
	} },
	{ id = "1_3", x0 = 464, y0 = 912, largura = 256, altura = 256, escala = 4, tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://126954365776207", arquivo = "mapas/brasil_detalhe/brasil_detalhe_1_3_terra.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://87012396350839", arquivo = "mapas/brasil_detalhe/brasil_detalhe_1_3_linhas.png" },
		{ camada = "rios", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://110946249685211", arquivo = "mapas/brasil_detalhe/brasil_detalhe_1_3_rios.png" },
	} },
	{ id = "2_3", x0 = 720, y0 = 912, largura = 256, altura = 256, escala = 4, tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://123307238130212", arquivo = "mapas/brasil_detalhe/brasil_detalhe_2_3_terra.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://131269203899640", arquivo = "mapas/brasil_detalhe/brasil_detalhe_2_3_linhas.png" },
		{ camada = "rios", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://73589763707899", arquivo = "mapas/brasil_detalhe/brasil_detalhe_2_3_rios.png" },
	} },
	{ id = "3_3", x0 = 976, y0 = 912, largura = 256, altura = 256, escala = 4, tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://129750130035648", arquivo = "mapas/brasil_detalhe/brasil_detalhe_3_3_terra.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://120779685655275", arquivo = "mapas/brasil_detalhe/brasil_detalhe_3_3_linhas.png" },
		{ camada = "rios", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://94143711743090", arquivo = "mapas/brasil_detalhe/brasil_detalhe_3_3_rios.png" },
	} },
	{ id = "4_3", x0 = 1232, y0 = 912, largura = 256, altura = 256, escala = 4, tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://129750130035648", arquivo = "mapas/brasil_detalhe/brasil_detalhe_4_3_terra.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://111413910257451", arquivo = "mapas/brasil_detalhe/brasil_detalhe_4_3_linhas.png" },
		{ camada = "rios", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://125609045311831", arquivo = "mapas/brasil_detalhe/brasil_detalhe_4_3_rios.png" },
	} },
	{ id = "5_3", x0 = 1488, y0 = 912, largura = 256, altura = 256, escala = 4, tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://97541890432803", arquivo = "mapas/brasil_detalhe/brasil_detalhe_5_3_terra.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://70858836119065", arquivo = "mapas/brasil_detalhe/brasil_detalhe_5_3_linhas.png" },
		{ camada = "rios", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://75367882598018", arquivo = "mapas/brasil_detalhe/brasil_detalhe_5_3_rios.png" },
	} },
	{ id = "6_3", x0 = 1744, y0 = 912, largura = 256, altura = 256, escala = 4, tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://85129643615434", arquivo = "mapas/brasil_detalhe/brasil_detalhe_6_3_terra.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://106976675393986", arquivo = "mapas/brasil_detalhe/brasil_detalhe_6_3_linhas.png" },
		{ camada = "rios", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://128576983080162", arquivo = "mapas/brasil_detalhe/brasil_detalhe_6_3_rios.png" },
	} },
	{ id = "2_4", x0 = 720, y0 = 1168, largura = 256, altura = 256, escala = 4, tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://81793181360779", arquivo = "mapas/brasil_detalhe/brasil_detalhe_2_4_terra.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://70556288293102", arquivo = "mapas/brasil_detalhe/brasil_detalhe_2_4_linhas.png" },
		{ camada = "rios", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://108355262188543", arquivo = "mapas/brasil_detalhe/brasil_detalhe_2_4_rios.png" },
	} },
	{ id = "3_4", x0 = 976, y0 = 1168, largura = 256, altura = 256, escala = 4, tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://129750130035648", arquivo = "mapas/brasil_detalhe/brasil_detalhe_3_4_terra.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://117972425770511", arquivo = "mapas/brasil_detalhe/brasil_detalhe_3_4_linhas.png" },
		{ camada = "rios", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://110998166309477", arquivo = "mapas/brasil_detalhe/brasil_detalhe_3_4_rios.png" },
	} },
	{ id = "4_4", x0 = 1232, y0 = 1168, largura = 256, altura = 256, escala = 4, tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://114039282288394", arquivo = "mapas/brasil_detalhe/brasil_detalhe_4_4_terra.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://138736905063154", arquivo = "mapas/brasil_detalhe/brasil_detalhe_4_4_linhas.png" },
		{ camada = "rios", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://107821848589072", arquivo = "mapas/brasil_detalhe/brasil_detalhe_4_4_rios.png" },
	} },
	{ id = "5_4", x0 = 1488, y0 = 1168, largura = 256, altura = 256, escala = 4, tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://135942309318603", arquivo = "mapas/brasil_detalhe/brasil_detalhe_5_4_terra.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://121945019881209", arquivo = "mapas/brasil_detalhe/brasil_detalhe_5_4_linhas.png" },
		{ camada = "rios", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://129704183138557", arquivo = "mapas/brasil_detalhe/brasil_detalhe_5_4_rios.png" },
	} },
	{ id = "3_5", x0 = 976, y0 = 1424, largura = 256, altura = 256, escala = 4, tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://121282936851535", arquivo = "mapas/brasil_detalhe/brasil_detalhe_3_5_terra.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://80406204135504", arquivo = "mapas/brasil_detalhe/brasil_detalhe_3_5_linhas.png" },
		{ camada = "rios", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://76388754652170", arquivo = "mapas/brasil_detalhe/brasil_detalhe_3_5_rios.png" },
	} },
	{ id = "4_5", x0 = 1232, y0 = 1424, largura = 256, altura = 256, escala = 4, tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://76638912034556", arquivo = "mapas/brasil_detalhe/brasil_detalhe_4_5_terra.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://132739007643350", arquivo = "mapas/brasil_detalhe/brasil_detalhe_4_5_linhas.png" },
		{ camada = "rios", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://106121252096755", arquivo = "mapas/brasil_detalhe/brasil_detalhe_4_5_rios.png" },
	} },
	{ id = "5_5", x0 = 1488, y0 = 1424, largura = 256, altura = 256, escala = 4, tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://76552340980639", arquivo = "mapas/brasil_detalhe/brasil_detalhe_5_5_terra.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://98934941098983", arquivo = "mapas/brasil_detalhe/brasil_detalhe_5_5_linhas.png" },
	} },
	{ id = "2_6", x0 = 720, y0 = 1680, largura = 256, altura = 256, escala = 4, tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://89625136872784", arquivo = "mapas/brasil_detalhe/brasil_detalhe_2_6_terra.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://126201789586743", arquivo = "mapas/brasil_detalhe/brasil_detalhe_2_6_linhas.png" },
		{ camada = "rios", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://120139332116020", arquivo = "mapas/brasil_detalhe/brasil_detalhe_2_6_rios.png" },
	} },
	{ id = "3_6", x0 = 976, y0 = 1680, largura = 256, altura = 256, escala = 4, tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://123875084127890", arquivo = "mapas/brasil_detalhe/brasil_detalhe_3_6_terra.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://82306962912841", arquivo = "mapas/brasil_detalhe/brasil_detalhe_3_6_linhas.png" },
		{ camada = "rios", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://83978108963823", arquivo = "mapas/brasil_detalhe/brasil_detalhe_3_6_rios.png" },
	} },
	{ id = "4_6", x0 = 1232, y0 = 1680, largura = 256, altura = 256, escala = 4, tiles = {
		{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://70996276199473", arquivo = "mapas/brasil_detalhe/brasil_detalhe_4_6_terra.png" },
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://129511916903749", arquivo = "mapas/brasil_detalhe/brasil_detalhe_4_6_linhas.png" },
		{ camada = "rios", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://93377091334302", arquivo = "mapas/brasil_detalhe/brasil_detalhe_4_6_rios.png" },
	} },
}

return Mapas
