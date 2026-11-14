# Exptrail

Addon de guia de leveling para World of Warcraft: Forever. Mostra o próximo passo da rota, aponta uma seta até ele e avança sozinho conforme você joga.

## Instalação

Copie a pasta `Exptrail` para `World of Warcraft/<pasta do Forever>/Interface/AddOns/` e reinicie o jogo. A pasta `Exptrail_RXP` é um pacote de rotas opcional; copie-a para o mesmo lugar se quiser usá-lo.

O arquivo `Exptrail/Exptrail.toc` declara `Interface: 16001`. Se o jogo listar o addon como desatualizado, troque esse número pelo que `/dump select(4, GetBuildInfo())` mostrar.

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

## Guias

O addon principal não traz rotas: elas vêm de pacotes ou do gravador.

O pacote opcional `Exptrail_RXP` tem as rotas públicas do [RestedXP Guides](https://github.com/RestedXP/RXPGuides) para a Aliança, de 1 a 21. Ele tem licença própria (CC BY-NC-SA 4.0); veja o README da pasta. Com ele instalado, o Exptrail escolhe a rota inicial pela raça, aplica os filtros de classe e passa para o guia seguinte sozinho.

## Escrevendo guias

O Exptrail lê dois formatos.

**Formato RestedXP**: o mesmo texto usado pelo RXPGuides, registrado com `Exptrail.RegisterRXP([[ ... ]])`. São entendidos os comandos `.goto`, `.accept`, `.turnin`, `.complete`, `.xp`, `.collect`, `.train`, `.zone`, `.subzone`, `.home`, `.hs`, `.fp`, `.fly`, as condições (`.isOnQuest`, `.isQuestComplete`, `.isQuestTurnedIn`, `.isQuestAvailable`, `.itemcount`, `.money`, `.zoneskip`, `.subzoneskip`), os filtros `<<` e as marcas `#completewith`, `#sticky`, `#label`, `#season`, `#xprate`, `#hardcore` e `#ssf`. Os demais comandos aparecem só como texto. Passos `#completewith` e `#sticky` viram lembretes ("Enquanto isso") em vez de passos paralelos.

**Formato nativo**: uma tabela Lua, que é o que o gravador exporta:

```lua
Exptrail.RegisterGuide({
    name = "Minha rota",
    steps = {
        { type = "accept", quest = 783, name = "A Threat Within", map = 1429, x = 48.2, y = 42.9 },
        { type = "complete", quest = 7, obj = 1 },
        { type = "turnin", quest = 783 },
        { type = "goto", x = 42.1, y = 65.9, text = "Vila d'Ouro" },
        { type = "level", level = 6 },
        { type = "home", text = "Defina a pedra de regresso na estalagem" },
    },
})
```

O caminho mais rápido para rotas novas é gravar: `/et rec`, jogue a rota, `/et export`. A rota gravada também aparece no jogo como o guia `Gravado` após `/reload`.

## Licença e créditos

O código em `Exptrail/` é original deste projeto e não inclui código nem rotas de terceiros. O leitor de guias é compatível com a sintaxe de texto usada pelo RestedXP Guides.

O pacote `Exptrail_RXP/` é conteúdo do RestedXP Guides sob CC BY-NC-SA 4.0 e é distribuído separadamente, com os créditos na própria pasta. O Exptrail não tem vínculo com o RestedXP nem com a Blizzard.
