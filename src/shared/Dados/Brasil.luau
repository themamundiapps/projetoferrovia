-- Brasil.luau · GERADO por tools/dados/gerar.mjs a partir de tools/dados/brasil.json. Não editar à mão.
-- Posições em pixels do mapa completo (2048x2048), na mesma projeção dos tiles.
-- Custos provisórios (economia ainda não balanceada).

return {
	id = "brasil",
	moeda = "BRL",
	simbolo = "R$",
	terrenos = {
		planalto = { nome = "Planalto", custo = 1 },
		baixada = { nome = "Baixada litorânea", custo = 1.1 },
		vale = { nome = "Vale", custo = 1.2 },
		serra_leve = { nome = "Serra", custo = 1.6 },
		serra = { nome = "Serra do Mar", custo = 2.4 },
	},
	estacoes = {
		porto_maua = { nome = "Porto Mauá", pos = Vector2.new(1549.9, 1398.8), lon = -43.18, lat = -22.69, porte = 1, produz = nil, porto = false },
		fragoso = { nome = "Fragoso", pos = Vector2.new(1552.3, 1394.3), lon = -43.13, lat = -22.6, porte = 1, produz = nil, porto = false },
		rio = { nome = "Rio de Janeiro", pos = Vector2.new(1549.5, 1409.5), lon = -43.19, lat = -22.9, porte = 5, produz = nil, porto = true },
		japeri = { nome = "Japeri", pos = Vector2.new(1527.9, 1396.3), lon = -43.65, lat = -22.64, porte = 1, produz = nil, porto = false },
		barra_pirai = { nome = "Barra do Piraí", pos = Vector2.new(1519.5, 1387.7), lon = -43.83, lat = -22.47, porte = 2, produz = "cafe", porto = false },
		juiz_de_fora = { nome = "Juiz de Fora", pos = Vector2.new(1542.0, 1351.8), lon = -43.35, lat = -21.76, porte = 3, produz = nil, porto = false },
		barbacena = { nome = "Barbacena", pos = Vector2.new(1522.3, 1324.6), lon = -43.77, lat = -21.22, porte = 2, produz = nil, porto = false },
		bh = { nome = "Belo Horizonte", pos = Vector2.new(1514.3, 1259.5), lon = -43.94, lat = -19.92, porte = 4, produz = nil, porto = false },
		santos = { nome = "Santos", pos = Vector2.new(1402.3, 1463.6), lon = -46.33, lat = -23.96, porte = 3, produz = nil, porto = true },
		paranapiacaba = { nome = "Paranapiacaba", pos = Vector2.new(1403.7, 1454.4), lon = -46.3, lat = -23.78, porte = 1, produz = nil, porto = false },
		sao_paulo = { nome = "São Paulo", pos = Vector2.new(1388.0, 1441.9), lon = -46.635, lat = -23.535, porte = 5, produz = nil, porto = false },
		jundiai = { nome = "Jundiaí", pos = Vector2.new(1376.5, 1424.3), lon = -46.88, lat = -23.19, porte = 2, produz = "cafe", porto = false },
		campinas = { nome = "Campinas", pos = Vector2.new(1368.1, 1410.0), lon = -47.06, lat = -22.91, porte = 3, produz = "cafe", porto = false },
		rio_claro = { nome = "Rio Claro", pos = Vector2.new(1344.7, 1384.6), lon = -47.56, lat = -22.41, porte = 2, produz = "cafe", porto = false },
		sao_carlos = { nome = "São Carlos", pos = Vector2.new(1329.2, 1364.9), lon = -47.89, lat = -22.02, porte = 2, produz = "cafe", porto = false },
		araraquara = { nome = "Araraquara", pos = Vector2.new(1315.6, 1353.3), lon = -48.18, lat = -21.79, porte = 2, produz = "cafe", porto = false },
		bauru = { nome = "Bauru", pos = Vector2.new(1274.4, 1380.1), lon = -49.06, lat = -22.32, porte = 2, produz = nil, porto = false },
		vitoria = { nome = "Vitória", pos = Vector2.new(1683.0, 1279.5), lon = -40.34, lat = -20.32, porte = 3, produz = nil, porto = true },
		colatina = { nome = "Colatina", pos = Vector2.new(1669.4, 1240.6), lon = -40.63, lat = -19.54, porte = 1, produz = nil, porto = false },
		valadares = { nome = "Governador Valadares", pos = Vector2.new(1607.6, 1206.3), lon = -41.95, lat = -18.85, porte = 2, produz = nil, porto = false },
		itabira = { nome = "Itabira", pos = Vector2.new(1547.6, 1244.6), lon = -43.23, lat = -19.62, porte = 1, produz = "minerio", porto = false },
	},
	linhas = {
		{
			id = "maua", nome = "E.F. Mauá", ano = 1854, cor = 6, ordem = 1,
			trechos = {
				{ id = "maua_1", de = "porto_maua", para = "fragoso", ano = 1854, km = 14, terreno = "baixada", custo = 92 },
			},
		},
		{
			id = "dpedro2", nome = "E.F. Dom Pedro II", ano = 1858, cor = 2, ordem = 2,
			trechos = {
				{ id = "dpedro2_1", de = "rio", para = "japeri", ano = 1858, km = 69, terreno = "baixada", custo = 774 },
				{ id = "dpedro2_2", de = "japeri", para = "barra_pirai", ano = 1864, km = 33, terreno = "serra_leve", custo = 539 },
				{ id = "dpedro2_3", de = "barra_pirai", para = "juiz_de_fora", ano = 1875, km = 116, terreno = "vale", custo = 1420 },
				{ id = "dpedro2_4", de = "juiz_de_fora", para = "barbacena", ano = 1880, km = 93, terreno = "serra_leve", custo = 1518 },
				{ id = "dpedro2_5", de = "barbacena", para = "bh", ano = 1895, km = 182, terreno = "planalto", custo = 1856 },
			},
		},
		{
			id = "spr", nome = "Santos–Jundiaí", ano = 1867, cor = 1, ordem = 3,
			trechos = {
				{ id = "spr_1", de = "santos", para = "paranapiacaba", ano = 1867, km = 25, terreno = "serra", custo = 1040,
					alternativas = {
						{ id = "serra", nome = "Subir a Serra do Mar", descricao = "Cremalheira: caro, mas curto e rápido.", terreno = "serra", km = 25, custo = 1040, fatorDemanda = 1, historico = true },
						{ id = "vale", nome = "Contornar pelo vale", descricao = "Mais barato, porém longo; perde passageiros.", terreno = "vale", km = 38, custo = 791, fatorDemanda = 0.8, historico = false },
					} },
				{ id = "spr_2", de = "paranapiacaba", para = "sao_paulo", ano = 1867, km = 55, terreno = "planalto", custo = 954 },
				{ id = "spr_3", de = "sao_paulo", para = "jundiai", ano = 1867, km = 57, terreno = "planalto", custo = 988 },
			},
		},
		{
			id = "paulista", nome = "Cia. Paulista", ano = 1872, cor = 3, ordem = 4,
			trechos = {
				{ id = "paulista_1", de = "jundiai", para = "campinas", ano = 1872, km = 45, terreno = "planalto", custo = 1327 },
				{ id = "paulista_2", de = "campinas", para = "rio_claro", ano = 1876, km = 95, terreno = "planalto", custo = 2800 },
				{ id = "paulista_3", de = "rio_claro", para = "sao_carlos", ano = 1884, km = 69, terreno = "planalto", custo = 2034 },
				{ id = "paulista_4", de = "sao_carlos", para = "araraquara", ano = 1885, km = 49, terreno = "planalto", custo = 1444 },
				{ id = "paulista_5", de = "araraquara", para = "bauru", ano = 1910, km = 135, terreno = "planalto", custo = 3980 },
			},
		},
		{
			id = "vitoria_minas", nome = "Vitória–Minas", ano = 1904, cor = 5, ordem = 5,
			trechos = {
				{ id = "vitoria_minas_1", de = "vitoria", para = "colatina", ano = 1906, km = 115, terreno = "baixada", custo = 6339 },
				{ id = "vitoria_minas_2", de = "colatina", para = "valadares", ano = 1910, km = 198, terreno = "vale", custo = 11907 },
				{ id = "vitoria_minas_3", de = "valadares", para = "itabira", ano = 1942, km = 199, terreno = "serra_leve", custo = 15956 },
			},
		},
	},
}
