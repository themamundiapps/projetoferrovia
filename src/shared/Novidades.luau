--!strict
-- Novidades mostradas no menu inicial (as mais recentes primeiro). A cada atualização publicada,
-- acrescente uma entrada no topo; o menu mostra as 3 primeiras.

type Texto = { pt: string, en: string }
export type Novidade = { data: string, titulo: Texto, texto: Texto }

local Novidades: { Novidade } = {
	{
		data = "2026-11-20",
		titulo = { pt = "Novo mapa: Estados Unidos", en = "New map: United States" },
		texto = {
			pt = "33 ferrovias, do Baltimore and Ohio de 1830 à Primeira Transcontinental, com carvão, petróleo e aço. Cada mapa é uma companhia separada.",
			en = "33 railroads, from the 1830 Baltimore and Ohio to the First Transcontinental, with coal, oil and steel. Each map is a separate company.",
		},
	},
	{
		data = "2026-11-20",
		titulo = { pt = "Trilha de bossa nova", en = "Bossa nova soundtrack" },
		texto = {
			pt = "O mapa do Brasil agora toca bossa nova em todas as eras: 15 faixas.",
			en = "The Brazil map now plays bossa nova in every era: 15 tracks.",
		},
	},
	{
		data = "2026-11-20",
		titulo = { pt = "Ranking do servidor", en = "Server leaderboard" },
		texto = {
			pt = "No canto da tela, quem está no servidor com você: foto, companhia e quanto dinheiro cada um tem.",
			en = "In the corner of the screen, everyone on your server: picture, company and how much money each one has.",
		},
	},
	{
		data = "2026-11-20",
		titulo = { pt = "Trens levam a carga", en = "Trains carry the cargo" },
		texto = {
			pt = "Os trens pegam o café, os grãos e o minério das cidades e levam até o começo da linha. Linhas da mesma cor ganharam textura.",
			en = "Trains pick up coffee, grain and ore from the cities and carry it to the start of the line. Lines of the same color got a texture.",
		},
	},
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
