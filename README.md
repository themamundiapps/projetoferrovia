# Projeto Ferrovia (Ferrovia Tycoon, nome provisório)

Tycoon idle de ferrovias no Roblox. O jogador constrói redes históricas reais sobre mapas estilizados dos EUA, do Brasil e da Europa.

O código fica neste repositório e é sincronizado com o Roblox Studio pelo [Rojo](https://rojo.space).

## Primeira vez (cada um no seu PC)

1. **Instale o Rokit**, o gerenciador de ferramentas: siga as instruções em [github.com/rojo-rbx/rokit](https://github.com/rojo-rbx/rokit).
2. **Clone o repositório** e entre na pasta:
   ```
   git clone https://github.com/themamundiapps/projetoferrovia.git
   cd projetoferrovia
   ```
3. **Instale o Rojo** na versão do projeto (definida em `rokit.toml`):
   ```
   rokit install
   ```
4. **Instale o plugin do Rojo no Studio:**
   ```
   rojo plugin install
   ```

## No dia a dia

1. Na pasta do projeto, rode:
   ```
   rojo serve
   ```
2. No Studio, abra o place do jogo, vá na aba **Plugins → Rojo** e clique em **Connect**.
3. Aperte Play. No Output devem aparecer duas linhas começando com `[Ferrovia]`, uma do servidor e uma do cliente. Se aparecerem, a sincronização está funcionando.

Qualquer arquivo salvo em `src/` aparece no Studio na hora.

## Regras para não perder trabalho

- **Scripts só se editam pelos arquivos do repositório**, nunca dentro do Studio. O Rojo sobrescreve o que foi mudado direto no Studio nas pastas que ele controla.
- O Rojo controla só `ReplicatedStorage.Shared`, `ServerScriptService.Server` e `StarterPlayer.StarterPlayerScripts.Client`. O resto do place (Workspace, iluminação etc.) continua sendo editado no Studio normalmente.
- Antes de começar a mexer: `git pull`. Ao terminar: `git add`, `git commit` e `git push`.
- Para algo maior, crie uma branch (`git checkout -b nome-da-tarefa`) e abra um Pull Request.

## Onde fica cada coisa

| Pasta | Vai para | Conteúdo |
| --- | --- | --- |
| `src/shared/` | `ReplicatedStorage.Shared` | Módulos usados por servidor e cliente: `Theme` (eras, cores, fontes), `Assets` (ids das imagens), `Mapas` (tiles e projeção), `Emojis` |
| `src/server/` | `ServerScriptService.Server` | Economia, save, compras (servidor manda em tudo que vale dinheiro) |
| `src/client/` | `StarterPlayerScripts.Client` | Interface: mapa 2D, painéis, menu |
| `arte/` | não vai para o jogo | Pacote gráfico: imagens para subir no Studio e o guia de uso (`arte/LEIA-ME.md`) |
| `tools/assetgen/` | não vai para o jogo | Scripts que geraram o pacote gráfico (Python + Node) |

## Imagens

As 51 imagens de `arte/` precisam ser enviadas pelo **Asset Manager → Bulk Import** do Studio. Depois, os ids entram em `src/shared/Assets.luau` e `src/shared/Mapas.luau`, no lugar de `rbxassetid://0`. O passo a passo está em `arte/LEIA-ME.md`.

## Pendências visuais (para depois)

- [ ] Estender a região de detalhe do Sudeste para o sul (litoral do Paraná fica grosso fora dela)
- [ ] Afinar os rios do mapa base no zoom intermediário (1x a 1,8x)
- [ ] Estações encolherem com o zoom (no Brasil inteiro, as do Sudeste se amontoam)
- [ ] Posição manual dos nomes de estações muito próximas (Rio, Porto Mauá, Fragoso)

## Andamento do MVP

- [x] GDD aprovado
- [x] Pacote gráfico (v2, com emojis)
- [x] Estrutura do projeto com Rojo
- [x] Dados do Brasil (5 linhas históricas, 21 estações, 17 trechos; economia provisória)
- [x] Mapa 2D com zoom e arrastar, rios, divisas, nomes e Sudeste em alta resolução (falta testar no celular)
- [x] Compra de trechos, desbloqueio histórico e renda por segundo
- [x] Trens por linha e porcentagem de serviço
- [ ] Uma carga (café → porto de Santos) e uma escolha de traçado
- [ ] Duas eras (vapor e diesel)
- [x] Save com DataStore e ganho offline (falta testar com as APIs ligadas no Studio)
- [ ] Um gamepass e um developer product
