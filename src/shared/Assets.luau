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

-- A mesma cidade em outras épocas (fotos do Wikimedia Commons, baixadas por tools/assetgen/baixar_commons.py
-- para arte/cidades_jogo/<id>_<era>.jpg): a ficha e o jornal mostram a da era
-- atual; sem ela, a da era anterior mais perto; sem nenhuma, a de Assets.Cidades (a do Vapor).
-- Créditos e licenças em arte/cidades/CREDITOS.md.
Assets.CidadesPorEra = {
	-- REGRA: nada de foto com texto, legenda, marca-d'água, site ou marca comercial legível (a moderação
	-- do Roblox pune; em 18/11 uma foto com "www.prati.com.br" gerou advertência na conta). Conferir antes de subir.
	diesel = { -- anos 1940 a 60
		rio = "rbxassetid://135579898289241",
		bh = "rbxassetid://123753631123145",
		recife = "rbxassetid://135225194485484",
		curitiba = "rbxassetid://126531802998455",
		brasilia = "rbxassetid://101632991045395",
		campinas = "rbxassetid://81664618257487",
	},
	eletrico = { -- anos 1970 a 90
		sao_paulo = "rbxassetid://106681665662907",
		bh = "rbxassetid://91389403186756",
		recife = "rbxassetid://102108774045832",
		salvador = "rbxassetid://128570153136771",
		brasilia = "rbxassetid://117131966493901",
		fortaleza = "rbxassetid://98520877535882",
	},
	alta = { -- de 2000 em diante
		rio = "rbxassetid://89155604362901",
		sao_paulo = "rbxassetid://108146991216183",
		bh = "rbxassetid://123823193311155",
		recife = "rbxassetid://72280178716241",
		salvador = "rbxassetid://123312769953240",
		curitiba = "rbxassetid://90022407904638",
		porto_alegre = "rbxassetid://70673635621415",
		belem = "rbxassetid://72142297258488",
		manaus = "rbxassetid://116102566634775",
		brasilia = "rbxassetid://89282537299919",
		fortaleza = "rbxassetid://94496300521866",
		juiz_de_fora = "rbxassetid://109098449030455",
		santos = "rbxassetid://133661609932272",
		campinas = "rbxassetid://70775832729419",
		vitoria = "rbxassetid://133560219564941",
		sao_jose_campos = "rbxassetid://96992870357437",
		sorocaba = "rbxassetid://109809768642866",
		ponta_grossa = "rbxassetid://130706239662377",
		santa_maria = "rbxassetid://78392111626781",
		campo_grande = "rbxassetid://113099857840426",
		florianopolis = "rbxassetid://107658690090247",
		maceio = "rbxassetid://133495915599319",
		natal = "rbxassetid://140368768553861",
	},
} :: { [string]: { [string]: string } }

local ORDEM_ERAS = { "vapor", "diesel", "eletrico", "alta" }
function Assets.imagemCidade(id: string, eraId: string?): string?
	local ate = table.find(ORDEM_ERAS, eraId or "vapor") or 1
	for i = ate, 2, -1 do
		local img = Assets.CidadesPorEra[ORDEM_ERAS[i]][id]
		if img and img ~= "rbxassetid://0" then
			return img
		end
	end
	return Assets.Cidades[id]
end
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
	alta = {
		-- Era da Alta Velocidade (arte/ui/alta/, referencia.png): vidro azul-marinho, aro grafite com cantos
		-- chanfrados e frisos de neon ciano. Peças preparadas por tools/assetgen/kit_alta.py.
		-- Tudo é escuro, até os cartões: o texto fica claro em todo lugar (escuro e claro com o gelo da era).
		escuro = {
			panel = Color3.fromHex("#121A29"), bg = Color3.fromHex("#0C111C"),
			ink = Color3.fromHex("#E8EEF8"), inkMuted = Color3.fromHex("#8A9BB8"), rule = Color3.fromHex("#2C3D5C"),
			positive = Color3.fromHex("#3DDC97"), negative = Color3.fromHex("#FF5C7A"),
			accent = Color3.fromHex("#7CF7FF"), onAccent = Color3.fromHex("#0C111C"),
		},
		claro = { ink = Color3.fromHex("#E8EEF8"), inkMuted = Color3.fromHex("#A9B7CE"), accent = Color3.fromHex("#7CF7FF") },
		-- o botão principal é vidro escuro com contorno ciano: texto claro (não o onAccent)
		textoPrincipal = Color3.fromHex("#E8EEF8"),
		-- painel.png (372 x 700): aro grafite chanfrado com filete ciano por dentro
		painel = { id = "rbxassetid://72284683473934", slice = Rect.new(40, 40, 332, 660), escala = 0.7, borda = 6 },
		-- cartao.png (362 x 694): vidro um tom acima do painel
		cartao = { id = "rbxassetid://108152316396044", slice = Rect.new(50, 50, 312, 644), escala = 0.2 },
		-- cabecalho.png (716 x 130): faixa chanfrada com o filete ciano à esquerda
		cabecalho = { id = "rbxassetid://93808167629835", slice = Rect.new(130, 60, 656, 70), escala = 1, borda = 0 },
		divisor = { id = "rbxassetid://88475529921027", largura = 768, altura = 21 },
		-- botao.png (699 x 287, com o brilho em volta) e botao_discreto.png (694 x 219, pílula de aro grafite)
		botao = { id = "rbxassetid://120400951359545", slice = Rect.new(120, 140, 579, 147), escala = 1, borda = 0 },
		botao_discreto = { id = "rbxassetid://116485315073509", slice = Rect.new(115, 100, 579, 119), escala = 1, borda = 0 },
		-- aba.png (694 x 219, aro grafite) e aba_ativa.png (690 x 174, aro ciano)
		aba = { id = "rbxassetid://137056185562505", slice = Rect.new(50, 100, 644, 119), escala = 1, borda = 0 },
		aba_ativa = { id = "rbxassetid://92455075034293", slice = Rect.new(50, 80, 640, 94), escala = 1, borda = 0 },
		botao_redondo = { id = "rbxassetid://79957157289699", slice = Rect.new(1, 1, 684, 684), escala = 1, borda = 0, redondo = true },
		-- barra_fundo.png (693 x 137): canal de vidro entre os aros
		barra_fundo = { id = "rbxassetid://133198570605129", slice = Rect.new(75, 62, 618, 75), escala = 1, borda = 0, largura = 693,
			canal = { x = 40 / 693, topo = 16 / 137, base = 121 / 137 } },
		-- barra_cheia.png (620 x 22): cápsula clara gerada, tingida no jogo
		barra_cheia = { id = "rbxassetid://104094739145441", slice = Rect.new(11, 10, 609, 12), escala = 1, borda = 0 },
		-- barra de medalhões: medalhão de aro ciano (686 x 686), base chanfrada (721 x 106), plaquinha (698 x 200)
		medalhao = { id = "rbxassetid://115395087493828" },
		base_medalhoes = { id = "rbxassetid://94685708515932", slice = Rect.new(85, 30, 636, 76), altura = 106 },
		placa_nome = { id = "rbxassetid://138416525934399", slice = Rect.new(45, 60, 653, 140), altura = 200 },
		-- ícones em traço claro (arte/ui/alta/icones/, 256 x 256)
		icones = {
			linhas = "rbxassetid://101087471621557", projetos = "rbxassetid://75869290254947", metas = "rbxassetid://91814380112470", jornal = "rbxassetid://91573003851306",
			banco = "rbxassetid://113317883188764", companhia = "rbxassetid://75018367266315", ajustes = "rbxassetid://124375020468860", tarifas = "rbxassetid://122981018243405",
			trens = "rbxassetid://75920150833923", passageiros = "rbxassetid://95006154184330", satisfacao = "rbxassetid://120825840140428", carga = "rbxassetid://98847533496613",
			decisao = "rbxassetid://135175366130531", dinheiro = "rbxassetid://126937211757792",
		},
		-- barra de cima de vidro com friso ciano: pontas chanfradas (60 x 98) e miolo que se repete (320 x 98)
		barra_topo = { esq = "rbxassetid://121541487540547", meio = "rbxassetid://125122002476431", dir = "rbxassetid://105582098588796", altura = 98, ponta = 60, largMeio = 320 },
		aba_lateral = { id = "rbxassetid://123503997998608", slice = Rect.new(40, 100, 118, 586), largura = 168 },
		-- placa de cidade (694 x 212): o friso ciano da esquerda ocupa 60 px
		placa_cidade = { id = "rbxassetid://95426146631147", slice = Rect.new(60, 60, 649, 152), altura = 212, margem = 60 },
		vinheta = { id = "rbxassetid://92534481569643" },
		-- textos sobre a barra de cima e as plaquinhas (escuras): gelo, com o ciano de destaque
		coresTopo = { forte = Color3.fromHex("#E8EEF8"), fraco = Color3.fromHex("#8A9BB8"), verde = Color3.fromHex("#3DDC97"),
			vermelho = Color3.fromHex("#FF5C7A"), separador = Color3.fromHex("#3A4F75") },
		coresMedalhao = { nome = Color3.fromHex("#C9D3E3"), ativo = Color3.fromHex("#7CF7FF"), simbolo = Color3.fromHex("#7CF7FF"), fonte = "label" },
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

-- Som (Som.luau). REGRA: só áudios licenciados pelo próprio Roblox (APM Music e Pro Sound Effects,
-- da Creator Store) ou os sons embutidos do Roblox (rbxasset://sounds/...). Nada enviado por
-- usuários: pode ser privado (não toca em outro jogo) ou ter direito autoral de terceiros.
Assets.Musicas = {
	vapor = { -- ragtime e piano dos anos 1910-20 (APM, álbum "Ragtime Piano / Cinema Organ")
		"rbxassetid://1842259245", -- Klassicle Rag
		"rbxassetid://1842259180", -- Straw Hat And Cane
		"rbxassetid://1842259219", -- Itchy Feet
		"rbxassetid://1842259058", -- Striding Stomp
		"rbxassetid://1842259252", -- Mississippi Paddle Wheel
	},
	diesel = { -- swing, big band e música ligeira dos anos 1940-60 (APM)
		"rbxassetid://9047001422", -- Swing Shift (d)
		"rbxassetid://1838894724", -- Scat Express
		"rbxassetid://1845448260", -- Doing The Town
		"rbxassetid://1845439658", -- City Gent
		"rbxassetid://1839284362", -- Americano
	},
	eletrico = { -- bossa nova (APM; "A Dream Of Bossa Nova" é gravação de 1970)
		"rbxassetid://9043921564", -- A Dream Of Bossa Nova
		"rbxassetid://1837070127", -- Prima Bossa Nova
		"rbxassetid://1846207861", -- A Touch Of Bossa Nova
		"rbxassetid://1843640051", -- Nova Bossa Nova
		"rbxassetid://1839331078", -- Bossa Nova
	},
	alta = { -- lo-fi e chill hop atuais (APM)
		"rbxassetid://9047105533", -- No Smoking
		"rbxassetid://9046863253", -- Poolside
		"rbxassetid://9044565681", -- Low Rider (c)
		"rbxassetid://9048511378", -- Just Chilling
		"rbxassetid://1837796200", -- Beach Vibes (b)
	},
} :: { [string]: { string } }

Assets.Sons = {
	clique = "rbxasset://sounds/clickfast.wav", -- embutido no Roblox
	compra = "rbxassetid://9113728042", -- Cash Register 1 (Pro Sound Effects)
	apito = "rbxassetid://9119628070", -- Steam Train Whistle Single Blows Airy 2 (Pro Sound Effects)
	sinal = "rbxasset://sounds/electronicpingshort.wav", -- embutido: trem novo nas eras Elétrica e Alta
	premio = "rbxassetid://9125509503", -- moeda caindo (Pro Sound Effects)
	conquista = "rbxassetid://1840101410", -- Orchestral Effect (F) (APM): nível, linha completa; corta em 2,5 s com fade
	era = "rbxassetid://9119628070", -- apito a vapor (o mesmo da compra de trem): era nova; o Leonardo preferiu à vinheta
	jornal = "rbxassetid://9118835414", -- páginas virando (Pro Sound Effects)
	erro = "rbxasset://sounds/switch.wav", -- embutido
} :: { [string]: string }

return Assets
