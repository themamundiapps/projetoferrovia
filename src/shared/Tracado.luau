--!strict
-- Traçado das linhas no mapa: os desvios ("via") de um trecho viram curvas arredondadas.
-- Cada ponto de desvio é trocado por um arco curto (curva de Bézier com o próprio ponto como
-- controle), para as dobras não ficarem em ponta. Usado pelo desenho das linhas (MapaView) e pelos
-- trens (init.client), que precisam andar exatamente pelos mesmos pontos.

local Tracado = {}

local RAIO = 16 -- px do mapa: até onde o arco começa antes do ponto de desvio
local PASSOS = 4 -- pedaços de reta em cada arco
local ANGULO_MIN = math.rad(10) -- dobras mais suaves que isso ficam como estão

-- Pontos do trecho (sem as estações das pontas): os desvios já arredondados.
function Tracado.via(de: Vector2, via: { Vector2 }?, para: Vector2): { Vector2 }
	local v = via or {}
	if #v == 0 then
		return {}
	end
	local pts: { Vector2 } = { de }
	for _, p in v do
		table.insert(pts, p)
	end
	table.insert(pts, para)
	local saida: { Vector2 } = {}
	for i = 2, #pts - 1 do
		local a, b, c = pts[i - 1], pts[i], pts[i + 1]
		local ba, bc = a - b, c - b
		local la, lc = ba.Magnitude, bc.Magnitude
		if la < 1e-3 or lc < 1e-3 then
			table.insert(saida, b)
			continue
		end
		local cos = math.clamp(ba.Unit:Dot(bc.Unit), -1, 1)
		local dobra = math.pi - math.acos(cos)
		if dobra < ANGULO_MIN then
			table.insert(saida, b)
			continue
		end
		-- o arco não passa da metade de cada pedaço (para não invadir o arco vizinho)
		local r = math.min(RAIO, la * 0.45, lc * 0.45)
		local p1 = b + ba.Unit * r
		local p2 = b + bc.Unit * r
		for k = 0, PASSOS do
			local t = k / PASSOS
			local u = 1 - t
			table.insert(saida, p1 * (u * u) + b * (2 * u * t) + p2 * (t * t))
		end
	end
	return saida
end

return Tracado
