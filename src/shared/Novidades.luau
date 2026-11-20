--!strict
-- Novidades mostradas no menu inicial (as mais recentes primeiro). A cada atualização publicada,
-- acrescente uma entrada no topo; o menu mostra as 3 primeiras.

type Texto = { pt: string, en: string }
export type Novidade = { data: string, titulo: Texto, texto: Texto }

local Novidades: { Novidade } = {
	{
		data = "2026-11-19",
		titulo = { pt = "Som e trilha sonora", en = "Sound and soundtrack" },
		texto = {
			pt = "Cada era tem sua música: ragtime, swing, bossa nova e lo-fi. Os trens apitam e dá para desligar tudo em Ajustes.",
			en = "Each era has its own music: ragtime, swing, bossa nova and lo-fi. Trains blow their whistles, and you can turn it all off in Settings.",
		},
	},
	{
		data = "2026-11-19",
		titulo = { pt = "Cidades contam sua história", en = "Cities tell their story" },
		texto = {
			pt = "A ficha das cidades grandes muda com a era, com fatos de cada época.",
			en = "The big cities' info cards change with each era, with facts from every period.",
		},
	},
	{
		data = "2026-11-19",
		titulo = { pt = "Mapa mais caprichado", en = "A cleaner map" },
		texto = {
			pt = "As linhas não cortam mais o mar, e linhas que dividem o mesmo caminho aparecem lado a lado.",
			en = "Lines no longer cross the sea, and lines that share a route are drawn side by side.",
		},
	},
	{
		data = "2026-11-18",
		titulo = { pt = "Fotos de época", en = "Period photos" },
		texto = {
			pt = "As cidades ganharam fotos reais de cada era, do Diesel à Alta Velocidade.",
			en = "Cities now have real photos from each era, from Diesel to High Speed.",
		},
	},
	{
		data = "2026-11-18",
		titulo = { pt = "Visual da Alta Velocidade", en = "High Speed look" },
		texto = {
			pt = "Interface nova para a Era da Alta Velocidade e o jogo inteiro adaptado para celular.",
			en = "A new interface for the High Speed era, and the whole game adapted for phones.",
		},
	},
}

return Novidades
