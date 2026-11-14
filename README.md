# Exptrail

Addon de guia de leveling para World of Warcraft: Forever. Mostra o próximo passo da rota, aponta uma seta até ele e avança sozinho conforme você joga.

## Instalação

Copie a pasta inteira para `World of Warcraft/<pasta do Forever>/Interface/AddOns/Exptrail` e reinicie o jogo.

O arquivo `Exptrail.toc` declara `Interface: 16001`. Se o jogo listar o addon como desatualizado, troque esse número pelo que `/dump select(4, GetBuildInfo())` mostrar.

## O que faz

- **Janela de guia**: passo atual, objetivos da quest e os próximos quatro passos. Arraste para mover.
- **Seta**: direção e distância até o passo atual.
- **Avanço automático**: aceitar, completar e entregar quests, chegar a um local ou subir de nível conclui o passo.
- **Automação**: aceita e entrega sozinho as quests que fazem parte do guia. Segure Shift para impedir. Recompensas com escolha ficam com você.
- **XP por hora** e tempo estimado até o próximo nível.
- **Gravador de rotas**: transforma o que você joga em um guia.

## Comandos

| Comando | Efeito |
| --- | --- |
| `/et` | Mostra ou oculta a janela |
| `/et list` | Lista os guias |
| `/et load <nome>` | Carrega um guia do início |
| `/et skip`, `/et back` | Pula ou volta um passo |
| `/et reset` | Recomeça o guia atual |
| `/et auto` | Liga ou desliga aceitar/entregar automático |
| `/et arrow` | Liga ou desliga a seta |
| `/et rec` | Liga ou desliga o gravador |
| `/et mark <texto>` | Grava um ponto de passagem na posição atual |
| `/et export` | Abre a rota gravada como Lua para copiar |
| `/et clear` | Apaga a rota gravada |

## Escrevendo guias

Um guia é um arquivo Lua em `Guides/`, listado no `Exptrail.toc`:

```lua
Exptrail.RegisterGuide({
    name = "Minha rota",
    faction = "Alliance", -- opcional
    race = "Human",       -- opcional
    next = "Nome do guia seguinte", -- opcional
    steps = {
        { type = "accept", quest = 783, name = "A Threat Within", map = 37, x = 48.2, y = 42.9 },
        { type = "complete", quest = 7, obj = 1 },
        { type = "turnin", quest = 783 },
        { type = "goto", x = 42.1, y = 65.9, text = "Vila d'Ouro" },
        { type = "level", level = 6 },
        { type = "home", text = "na estalagem" },
        { type = "train" },
    },
})
```

- `quest` é o ID da quest; `name` é o título, usado quando o ID não bate.
- `map` é o ID do mapa; sem ele, as coordenadas valem para a zona atual.
- Passos `home` e `train` sem detecção automática são concluídos com o botão `>`.

O caminho mais rápido é gravar: `/et rec`, jogue a rota, `/et export`. A rota gravada também aparece no jogo como o guia `Gravado` após `/reload`.

## Estado atual

O guia incluído (Humano, Vila Norte e Vila d'Ouro) é um rascunho baseado nos dados clássicos de Elwynn. IDs e coordenadas ainda não foram conferidos dentro do WoW Forever.
