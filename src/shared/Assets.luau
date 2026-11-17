-- Assets.lua · ids das imagens. Depois do Bulk Import, cole cada rbxassetid no lugar do 0.
-- Todas as imagens (exceto identidade/) são brancas: tingir com ImageColor3 usando a cor da era.
-- Ícones: na v2 são emojis, veja Emojis.lua.

local Assets = {}

Assets.Ids = {
	-- identidade
	logo_branco = "rbxassetid://0",
	logo_vapor = "rbxassetid://0",
	-- marcadores
	anel_selecao = "rbxassetid://0",
	carimbo = "rbxassetid://0",
	disco = "rbxassetid://0",
	estacao_anel = "rbxassetid://0",
	estacao_disco = "rbxassetid://0",
	estacao_fechada = "rbxassetid://0",
	trem_ficha = "rbxassetid://0",
	-- molduras
	bilhete_contorno = "rbxassetid://0",
	bilhete_fundo = "rbxassetid://0",
	brilho = "rbxassetid://0",
	moldura_dupla = "rbxassetid://0",
	perfuracao = "rbxassetid://0",
	pilula_contorno = "rbxassetid://0",
	pilula_fundo = "rbxassetid://0",
	sombra_painel = "rbxassetid://0",
	tracejado = "rbxassetid://0",
	-- texturas
	mar_hachura = "rbxassetid://122559079201789",
	mar_ondas = "rbxassetid://0",
	mar_pontos = "rbxassetid://0",
	papel_grao = "rbxassetid://0",
	vinheta = "rbxassetid://0",
	-- trens
	trem_alta_velocidade = "rbxassetid://0",
	trem_diesel = "rbxassetid://0",
	trem_eletrico = "rbxassetid://0",
	trem_vapor = "rbxassetid://0",
}

-- Imagens das fichas das cidades (arte/cidades/). Cidades grandes têm a sua; as outras usam a paisagem
-- genérica indicada em "paisagem" nos dados. Sem id, a ficha mostra um espaço reservado.
Assets.Cidades = {
	bh = "rbxassetid://123305865514688",
	campinas = "rbxassetid://134173839324956",
	juiz_de_fora = "rbxassetid://114880616786848",
	ponta_grossa = "rbxassetid://79031387184703",
	porto_alegre = "rbxassetid://95754414027158",
	recife = "rbxassetid://75128127492856",
	rio = "rbxassetid://76051103728708",
	salvador = "rbxassetid://83326118671292",
	santa_maria = "rbxassetid://137804371375076",
	santos = "rbxassetid://120632001864198",
	sao_jose_campos = "rbxassetid://98597069519831",
	sao_paulo = "rbxassetid://132099806211623",
	sorocaba = "rbxassetid://124503637752148",
	vitoria = "rbxassetid://101719837411189",
	-- faltam: curitiba, campo_grande
} :: { [string]: string } -- id da cidade -> imagem
-- Kit de UI (imagens fatiadas em 9, arte/ui/<kit>/). slice = SliceCenter na imagem de 512 px;
-- escala = SliceScale (tamanho dos cantos na tela); borda = quanto a moldura sai para fora da caixa (px).
Assets.KitUI = {
	classico = {
		-- painel_3.png (mogno e dourado, 728 x 359); as outras opções ficam em arte/ui/classico/
		-- botao.png (686 x 159): pílula; os cantos verticais ocupam a altura toda, as pontas ficam fixas
		botao = { id = "rbxassetid://129345331580728", slice = Rect.new(130, 78, 556, 81), escala = 1, borda = 0 },
		aba = { id = "rbxassetid://136913156478333", slice = Rect.new(90, 98, 594, 101), escala = 1, borda = 0 },
		aba_ativa = { id = "rbxassetid://126520576895217", slice = Rect.new(90, 85, 594, 87), escala = 1, borda = 0 },
		-- barra_fundo.png (714 x 82): o preenchimento enche o miolo de papel entre os aros (canal = frações da peça)
		barra_fundo = { id = "rbxassetid://139803880663244", slice = Rect.new(100, 40, 614, 42), escala = 1, borda = 0, largura = 714,
			canal = { x = 44 / 714, topo = 13 / 82, base = 69 / 82 } }, -- miolo de papel entre os aros
		-- barra_cheia.png (620 x 22): cápsula em tons de cinza, tingida no jogo com a cor da barra
		barra_cheia = { id = "rbxassetid://72380358480744", slice = Rect.new(11, 10, 609, 12), escala = 1, borda = 0 },
		-- divisor.png (710 x 47): não estica; entra inteiro na largura e a altura acompanha
		divisor = { id = "rbxassetid://113765996318309", largura = 710, altura = 47 },
		-- botao_redondo.png (256 x 256): inteiro, sem fatiar (zoom)
		botao_redondo = { id = "rbxassetid://103059791524567", slice = Rect.new(1, 1, 255, 255), escala = 1, borda = 0, redondo = true },
		-- barra de medalhões (base_medalhoes 724 x 146, medalhao 684 x 684, placa_nome 693 x 146, icones/*.png 256 x 256)
		base_medalhoes = { id = "rbxassetid://120111634736868", slice = Rect.new(150, 32, 574, 116), altura = 146 },
		medalhao = { id = "rbxassetid://128950311487213" },
		placa_nome = { id = "rbxassetid://75187457767464", slice = Rect.new(45, 22, 648, 124), altura = 146 },
		icones = {
			linhas = "rbxassetid://124616010697030", projetos = "rbxassetid://139710033315937", metas = "rbxassetid://94651761536153", jornal = "rbxassetid://89354465281414",
			banco = "rbxassetid://86039982344484", companhia = "rbxassetid://124510769365600", ajustes = "rbxassetid://109103751111585",
			tarifas = "rbxassetid://88664995413135",
			-- faixa de recursos da barra de cima
			trens = "rbxassetid://98916675648299", passageiros = "rbxassetid://133528029339571", satisfacao = "rbxassetid://123709817927502", carga = "rbxassetid://81200504601477",
			decisao = "rbxassetid://135146390610624", dinheiro = "rbxassetid://88438622516582",
		},
		-- barra de cima: pontas (76 x 117) e miolo que se repete (324 x 117, rebites a cada ~65 px)
		barra_topo = { esq = "rbxassetid://105283269005279", meio = "rbxassetid://120142804099562", dir = "rbxassetid://99733052499187", altura = 117, ponta = 76, largMeio = 324 },
		-- aba das gavetas laterais (179 x 685): reta à esquerda, arredondada à direita; a da direita gira 180°
		aba_lateral = { id = "rbxassetid://124877746206647", slice = Rect.new(40, 96, 140, 590), largura = 179 },
		-- placa das capitais no mapa (691 x 218)
		placa_cidade = { id = "rbxassetid://119947908776647", slice = Rect.new(110, 50, 581, 168), altura = 218 },
		-- vinheta sobre o mapa (512 x 512, bordas escuras)
		vinheta = { id = "rbxassetid://124911406118957" },
		-- selo.png (256 x 256): emblema com coroa de café, no canto do caixa, com as iniciais da companhia
		selo = { id = "rbxassetid://124081081269666" },
		cabecalho = { id = "rbxassetid://100328537844181", slice = Rect.new(100, 114, 596, 117), escala = 1, borda = 0 },
		botao_discreto = { id = "rbxassetid://79100120490162", slice = Rect.new(70, 84, 614, 86), escala = 1, borda = 0 },
		cartao = { id = "rbxassetid://130952075358434", slice = Rect.new(80, 80, 378, 614), escala = 0.3, borda = 0 },
		painel = { id = "rbxassetid://116203976251217", slice = Rect.new(160, 155, 568, 204), escala = 0.42, borda = 9 },
	},
	moderno = {
		-- Era Elétrica (arte/ui/moderno/, referencia.png): painéis verde-petróleo com aro de alumínio,
		-- cartões creme, laranja de sinalização. Painel escuro: o texto fica creme (ver Estilo.new).
		escuro = {
			panel = Color3.fromHex("#0F3F44"), bg = Color3.fromHex("#1C5257"),
			ink = Color3.fromHex("#F3EAD3"), inkMuted = Color3.fromHex("#A8C6C2"), rule = Color3.fromHex("#3F7276"),
			positive = Color3.fromHex("#5CC584"), negative = Color3.fromHex("#F07A64"),
			accent = Color3.fromHex("#E8661E"), onAccent = Color3.fromHex("#FFFFFF"),
		},
		-- dentro dos cartões creme: texto escuro, laranja de sinalização
		claro = { accent = Color3.fromHex("#E8661E"), onAccent = Color3.fromHex("#FFFFFF") },
		-- painel.png (468 x 692): aro de 21 px com parafusos nos cantos
		painel = { id = "rbxassetid://104261795075604", slice = Rect.new(40, 40, 428, 652), escala = 0.7, borda = 6 },
		-- cartao.png (489 x 687): aro + filete verde, miolo creme
		cartao = { id = "rbxassetid://119690855507683", slice = Rect.new(70, 70, 419, 617), escala = 0.2 },
		-- cabecalho.png (698 x 149): faixa verde clara com bloco laranja à esquerda
		cabecalho = { id = "rbxassetid://71783122573500", slice = Rect.new(60, 60, 638, 89), escala = 1, borda = 0 },
		divisor = { id = "rbxassetid://70421255292879", largura = 683, altura = 98 },
		-- botao.png (683 x 210) e botao_discreto.png (693 x 207): pílulas; as pontas ocupam a altura toda
		botao = { id = "rbxassetid://71341439254798", slice = Rect.new(110, 100, 573, 110), escala = 1, borda = 0 },
		botao_discreto = { id = "rbxassetid://130238144743071", slice = Rect.new(110, 100, 583, 107), escala = 1, borda = 0 },
		-- aba.png (731 x 237, creme) e aba_ativa.png (686 x 188, verde com filete laranja)
		aba = { id = "rbxassetid://97047927863286", slice = Rect.new(50, 110, 681, 127), escala = 1, borda = 0 },
		aba_ativa = { id = "rbxassetid://95941319180467", slice = Rect.new(100, 90, 586, 98), escala = 1, borda = 0 },
		botao_redondo = { id = "rbxassetid://139642214874567", slice = Rect.new(1, 1, 690, 689), escala = 1, borda = 0, redondo = true },
		-- barra_fundo.png (700 x 136): canal creme entre as pontas laranja
		barra_fundo = { id = "rbxassetid://130330154754315", slice = Rect.new(70, 60, 630, 76), escala = 1, borda = 0, largura = 700,
			canal = { x = 48 / 700, topo = 24 / 136, base = 112 / 136 } },
		-- barra_cheia.png (620 x 22): cápsula clara, tingida no jogo
		barra_cheia = { id = "rbxassetid://74585385523884", slice = Rect.new(11, 10, 609, 12), escala = 1, borda = 0 },
		-- barra de medalhões: medalhão laranja (662 x 662), base verde (701 x 107), plaquinha creme (688 x 125)
		medalhao = { id = "rbxassetid://124097729945680" },
		base_medalhoes = { id = "rbxassetid://123129169660105", slice = Rect.new(30, 25, 671, 85), altura = 107 },
		placa_nome = { id = "rbxassetid://80977521036351", slice = Rect.new(70, 40, 618, 85), altura = 125 },
		icones = {
			linhas = "rbxassetid://85393785842125", projetos = "rbxassetid://91279992232316", metas = "rbxassetid://73217979775880", jornal = "rbxassetid://107757684115810",
			banco = "rbxassetid://120934664683423", companhia = "rbxassetid://121237617541090", ajustes = "rbxassetid://83128418319280", tarifas = "rbxassetid://132348330715099",
			trens = "rbxassetid://78959096146433", passageiros = "rbxassetid://133137813160664", satisfacao = "rbxassetid://80084517003035", carga = "rbxassetid://77203171847456",
			decisao = "rbxassetid://127861378694056", dinheiro = "rbxassetid://118642541903059",
		},
		-- barra de cima de alumínio escovado: pontas (60 x 122) e miolo que se repete (320 x 122)
		barra_topo = { esq = "rbxassetid://77556622655051", meio = "rbxassetid://121101497027510", dir = "rbxassetid://100092499959279", altura = 122, ponta = 60, largMeio = 320 },
		aba_lateral = { id = "rbxassetid://80321106075672", slice = Rect.new(40, 110, 200, 555), largura = 258 },
		-- placa de estação (686 x 208): o bloco verde da esquerda ocupa 130 px
		placa_cidade = { id = "rbxassetid://80797652274775", slice = Rect.new(130, 50, 640, 158), altura = 208, margem = 130 },
		vinheta = { id = "rbxassetid://112862034031597" },
		-- textos sobre as peças claras: barra de cima (alumínio) e plaquinhas/medalhões
		coresTopo = { forte = Color3.fromHex("#1F2B2E"), fraco = Color3.fromHex("#4E6A6E"), verde = Color3.fromHex("#1E7D4F"),
			vermelho = Color3.fromHex("#C0392B"), separador = Color3.fromHex("#2F6E73") },
		coresMedalhao = { nome = Color3.fromHex("#1F2B2E"), ativo = Color3.fromHex("#E8661E"), simbolo = Color3.fromHex("#1F2B2E"), fonte = "label" },
	},
} :: { [string]: { [string]: any } }

-- Ilustrações das decisões (arte/decisoes/<id>.jpg, 16:9). Decisão sem imagem mostra só o emoji.
Assets.Decisoes = {} :: { [string]: string } -- id da decisão -> imagem
Assets.Paisagens = {
	cafe = "rbxassetid://89059490606207",
	canavial = "rbxassetid://103359671020446",
	cerrado = "rbxassetid://70621750823885",
	litoral = "rbxassetid://102904556810309",
	serra = "rbxassetid://115932616309235",
	sertao = "rbxassetid://90123016159292",
	sul = "rbxassetid://85172850577106",
	-- falta: amazonia
} :: { [string]: string } -- paisagem genérica (campo "paisagem" das cidades) -> imagem

-- Configuração de 9-slice e tiles.
Assets.Slice = {
	moldura_dupla = Rect.new(12, 12, 116, 116),
	bilhete_fundo = Rect.new(18, 18, 110, 110),
	bilhete_contorno = Rect.new(18, 18, 110, 110),
	sombra_painel = Rect.new(64, 64, 96, 96),
	pilula_fundo = Rect.new(32, 32, 96, 32),
	pilula_contorno = Rect.new(32, 32, 96, 32),
}

Assets.Tile = {
	perfuracao = UDim2.fromOffset(16, 8),
	tracejado = UDim2.fromOffset(24, 4),
	mar_hachura = UDim2.fromOffset(128, 128),
	mar_ondas = UDim2.fromOffset(128, 64),
	mar_pontos = UDim2.fromOffset(96, 96),
	papel_grao = UDim2.fromOffset(512, 512),
}

return Assets
