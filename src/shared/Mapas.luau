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
		{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://93021538247645", arquivo = "mapas/brasil/brasil_linhas_0_0.png" },
		{ camada = "linhas", x = 1024, y = 0, w = 1024, h = 1024, id = "rbxassetid://128572779648652", arquivo = "mapas/brasil/brasil_linhas_0_1.png" },
		{ camada = "linhas", x = 0, y = 1024, w = 1024, h = 1024, id = "rbxassetid://135970764229108", arquivo = "mapas/brasil/brasil_linhas_1_0.png" },
		{ camada = "linhas", x = 1024, y = 1024, w = 1024, h = 1024, id = "rbxassetid://84132376955281", arquivo = "mapas/brasil/brasil_linhas_1_1.png" },
		{ camada = "rios", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://0", arquivo = "mapas/brasil/brasil_rios_0_0.png" },
		{ camada = "rios", x = 1024, y = 0, w = 1024, h = 1024, id = "rbxassetid://0", arquivo = "mapas/brasil/brasil_rios_0_1.png" },
		{ camada = "rios", x = 0, y = 1024, w = 1024, h = 1024, id = "rbxassetid://0", arquivo = "mapas/brasil/brasil_rios_1_0.png" },
		{ camada = "rios", x = 1024, y = 1024, w = 1024, h = 1024, id = "rbxassetid://0", arquivo = "mapas/brasil/brasil_rios_1_1.png" },
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

-- Regiões de detalhe: blocos de alta resolução que aparecem por cima do mapa base quando o zoom passa de ZOOM_DETALHE.
-- x0/y0/largura/altura em pixels do mapa base; escala = pixels do detalhe por pixel do mapa base.
Mapas.brasil.detalhes = {
	{
		id = "sudeste", x0 = 1232, y0 = 1168, largura = 512, altura = 336, escala = 4,
		tiles = {
			{ camada = "terra", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://114039282288394", arquivo = "mapas/brasil_sudeste/brasil_sudeste_terra_0_0.png" },
			{ camada = "terra", x = 1024, y = 0, w = 1024, h = 1024, id = "rbxassetid://135942309318603", arquivo = "mapas/brasil_sudeste/brasil_sudeste_terra_0_1.png" },
			{ camada = "terra", x = 0, y = 1024, w = 1024, h = 320, id = "rbxassetid://140430238835236", arquivo = "mapas/brasil_sudeste/brasil_sudeste_terra_1_0.png" },
			{ camada = "terra", x = 1024, y = 1024, w = 1024, h = 320, id = "rbxassetid://115951286204902", arquivo = "mapas/brasil_sudeste/brasil_sudeste_terra_1_1.png" },
			{ camada = "linhas", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://121705042467932", arquivo = "mapas/brasil_sudeste/brasil_sudeste_linhas_0_0.png" },
			{ camada = "linhas", x = 1024, y = 0, w = 1024, h = 1024, id = "rbxassetid://108289231527909", arquivo = "mapas/brasil_sudeste/brasil_sudeste_linhas_0_1.png" },
			{ camada = "linhas", x = 0, y = 1024, w = 1024, h = 320, id = "rbxassetid://127831580734346", arquivo = "mapas/brasil_sudeste/brasil_sudeste_linhas_1_0.png" },
			{ camada = "linhas", x = 1024, y = 1024, w = 1024, h = 320, id = "rbxassetid://120458233669700", arquivo = "mapas/brasil_sudeste/brasil_sudeste_linhas_1_1.png" },
			{ camada = "rios", x = 0, y = 0, w = 1024, h = 1024, id = "rbxassetid://0", arquivo = "mapas/brasil_sudeste/brasil_sudeste_rios_0_0.png" },
			{ camada = "rios", x = 1024, y = 0, w = 1024, h = 1024, id = "rbxassetid://0", arquivo = "mapas/brasil_sudeste/brasil_sudeste_rios_0_1.png" },
			{ camada = "rios", x = 0, y = 1024, w = 1024, h = 320, id = "rbxassetid://0", arquivo = "mapas/brasil_sudeste/brasil_sudeste_rios_1_0.png" },
			{ camada = "rios", x = 1024, y = 1024, w = 1024, h = 320, id = "rbxassetid://0", arquivo = "mapas/brasil_sudeste/brasil_sudeste_rios_1_1.png" },
		},
	},
}

return Mapas
