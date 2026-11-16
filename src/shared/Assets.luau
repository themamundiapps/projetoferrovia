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
		botao_discreto = { id = "rbxassetid://0", slice = Rect.new(70, 84, 614, 86), escala = 1, borda = 0 },
		cartao = { id = "rbxassetid://130952075358434", slice = Rect.new(80, 80, 378, 614), escala = 0.3, borda = 0 },
		painel = { id = "rbxassetid://116203976251217", slice = Rect.new(160, 155, 568, 204), escala = 0.42, borda = 9 },
	},
	moderno = {},
} :: { [string]: { [string]: { id: string, slice: Rect, escala: number, borda: number } } }

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
