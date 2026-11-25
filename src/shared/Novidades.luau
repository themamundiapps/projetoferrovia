--!strict
-- Novidades mostradas no menu inicial (as mais recentes primeiro). A cada atualização publicada,
-- acrescente uma entrada no topo; o menu mostra as 3 primeiras.

type Texto = { pt: string, en: string }
export type Novidade = { data: string, titulo: Texto, texto: Texto }

local Novidades: { Novidade } = {
	{
		data = "2026-11-25",
		titulo = { pt = "O jogo lançou hoje!", en = "The game launched today!" },
		texto = {
			pt = "Primeira versão do Ferrovia Tycoon: três mapas, quatro eras e ferrovias para construir do zero.",
			en = "First version of Railway Tycoon: three maps, four eras and railways to build from scratch.",
		},
	},
}

return Novidades
