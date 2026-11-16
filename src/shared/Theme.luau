-- Theme.lua · gerado automaticamente a partir de theme.py (não editar à mão)
-- Cores, fontes nativas do Roblox e formas de cada era.

local Theme = {}

local function F(familia, peso)
	return Font.new("rbxasset://fonts/families/" .. familia .. ".json", (Enum.FontWeight :: any)[peso])
end

Theme.Eras = {
	{
		id = "vapor", kit = "classico", nome = "Era do Vapor", anos = "1830–1930",
		cores = {
			bg = Color3.fromHex("#EFE4CC"),
			panel = Color3.fromHex("#F7F0DE"),
			ink = Color3.fromHex("#3B2A1A"),
			inkMuted = Color3.fromHex("#6B5640"),
			rule = Color3.fromHex("#B8A27A"),
			land = Color3.fromHex("#E4D2AA"),
			sea = Color3.fromHex("#D9CBAA"),
			seaPattern = Color3.fromHex("#C9B992"),
			coast = Color3.fromHex("#3B2A1A"),
			rio = Color3.fromHex("#4E6A78"),
			accent = Color3.fromHex("#8E2B23"),
			onAccent = Color3.fromHex("#F7F0DE"),
			positive = Color3.fromHex("#3F5E3A"),
			negative = Color3.fromHex("#8E2B23"),
			locked = Color3.fromHex("#3B2A1A"),
		},
		linhas = { Color3.fromHex("#8E2B23"), Color3.fromHex("#2E4A6B"), Color3.fromHex("#B5762A"), Color3.fromHex("#5B3A5E"), Color3.fromHex("#3F5E3A"), Color3.fromHex("#6B4A2B"), Color3.fromHex("#7A6A2A"), Color3.fromHex("#2F6B6B") },
		fontes = {
			display = F("AccanthisADFStd", "Bold"),
			label = F("AccanthisADFStd", "Regular"),
			body = F("Merriweather", "Regular"),
			number = F("AccanthisADFStd", "Bold"),
		},
		forma = { canto = 0, traco = 1.5, molduraDupla = true },
		marPadrao = "mar_hachura",
		graoPapel = true,
	},
	{
		id = "diesel", kit = "classico", nome = "Era do Diesel", anos = "1930–1965",
		cores = {
			bg = Color3.fromHex("#E9E2CF"),
			panel = Color3.fromHex("#F5F0E1"),
			ink = Color3.fromHex("#1F2B33"),
			inkMuted = Color3.fromHex("#4E5B63"),
			rule = Color3.fromHex("#B9B39C"),
			land = Color3.fromHex("#D9D4AE"),
			sea = Color3.fromHex("#BFD3D0"),
			seaPattern = Color3.fromHex("#A9C2BF"),
			coast = Color3.fromHex("#1F2B33"),
			rio = Color3.fromHex("#2F6E86"),
			accent = Color3.fromHex("#B8471F"),
			onAccent = Color3.fromHex("#FFF8EC"),
			positive = Color3.fromHex("#2F6B4F"),
			negative = Color3.fromHex("#A63A2A"),
			locked = Color3.fromHex("#1F2B33"),
		},
		linhas = { Color3.fromHex("#C8572B"), Color3.fromHex("#1F5D8C"), Color3.fromHex("#A87708"), Color3.fromHex("#6A4C93"), Color3.fromHex("#2F6B4F"), Color3.fromHex("#8C5A2B"), Color3.fromHex("#A8323E"), Color3.fromHex("#2B7A78") },
		fontes = {
			display = F("JosefinSans", "Bold"),
			label = F("JosefinSans", "SemiBold"),
			body = F("Merriweather", "Regular"),
			number = F("JosefinSans", "Bold"),
		},
		forma = { canto = 6, traco = 2, molduraDupla = false },
		marPadrao = "mar_ondas",
		graoPapel = true,
	},
	{
		id = "eletrico", kit = "moderno", nome = "Era Elétrica", anos = "1965–2000",
		cores = {
			bg = Color3.fromHex("#F4F2EC"),
			panel = Color3.fromHex("#FFFFFF"),
			ink = Color3.fromHex("#1A1A1A"),
			inkMuted = Color3.fromHex("#55595F"),
			rule = Color3.fromHex("#D5D2C8"),
			land = Color3.fromHex("#E8E6DE"),
			sea = Color3.fromHex("#CFE1EA"),
			seaPattern = Color3.fromHex("#B8D2DE"),
			coast = Color3.fromHex("#8C9298"),
			rio = Color3.fromHex("#3B8FC2"),
			accent = Color3.fromHex("#D13A26"),
			onAccent = Color3.fromHex("#FFFFFF"),
			positive = Color3.fromHex("#1E7D4F"),
			negative = Color3.fromHex("#C0392B"),
			locked = Color3.fromHex("#1A1A1A"),
		},
		linhas = { Color3.fromHex("#E2382B"), Color3.fromHex("#0B63B8"), Color3.fromHex("#C28400"), Color3.fromHex("#7B3FA0"), Color3.fromHex("#18A058"), Color3.fromHex("#8B5E3C"), Color3.fromHex("#E5007E"), Color3.fromHex("#00A3AD") },
		fontes = {
			display = F("Montserrat", "ExtraBold"),
			label = F("Montserrat", "SemiBold"),
			body = F("SourceSansPro", "Regular"),
			number = F("RobotoMono", "Medium"),
		},
		forma = { canto = 10, traco = 1, molduraDupla = false },
		marPadrao = nil,
		graoPapel = false,
	},
	{
		id = "alta", kit = "moderno", nome = "Era da Alta Velocidade", anos = "2000–",
		cores = {
			bg = Color3.fromHex("#0C111C"),
			panel = Color3.fromHex("#141D2E"),
			ink = Color3.fromHex("#E8EEF8"),
			inkMuted = Color3.fromHex("#8A9BB8"),
			rule = Color3.fromHex("#2C3D5C"),
			land = Color3.fromHex("#151E30"),
			sea = Color3.fromHex("#0C111C"),
			seaPattern = Color3.fromHex("#24324D"),
			coast = Color3.fromHex("#3A4F75"),
			rio = Color3.fromHex("#3A6EA8"),
			accent = Color3.fromHex("#7CF7FF"),
			onAccent = Color3.fromHex("#0C111C"),
			positive = Color3.fromHex("#3DDC97"),
			negative = Color3.fromHex("#FF5C7A"),
			locked = Color3.fromHex("#8A9BB8"),
		},
		linhas = { Color3.fromHex("#FF5C7A"), Color3.fromHex("#4DA3FF"), Color3.fromHex("#FFB547"), Color3.fromHex("#C77DFF"), Color3.fromHex("#3DDC97"), Color3.fromHex("#FF8A4C"), Color3.fromHex("#E6D85C"), Color3.fromHex("#7CF7FF") },
		fontes = {
			display = F("Michroma", "Regular"),
			label = F("TitilliumWeb", "SemiBold"),
			body = F("TitilliumWeb", "Regular"),
			number = F("RobotoMono", "Medium"),
		},
		forma = { canto = 14, traco = 1, molduraDupla = false },
		marPadrao = "mar_pontos",
		graoPapel = false,
	},
}

Theme.PorId = {}
for i, era in ipairs(Theme.Eras) do
	era.indice = i
	Theme.PorId[era.id] = era
end

-- Linhas com cor clara precisam de contorno escuro (UIStroke 2 px na cor ink) para contraste sobre a terra.
Theme.ContornoLinha = 2

return Theme
