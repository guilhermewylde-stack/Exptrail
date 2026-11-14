local _, ns = ...

-- RASCUNHO: IDs de quest e coordenadas vêm dos dados clássicos de Elwynn e
-- ainda não foram conferidos dentro do WoW Forever. As coordenadas usam o
-- mapa da zona em que o jogador está. Use o gravador (/et rec) para corrigir.
ns.RegisterGuide({
    name = "Humano 1-10: Vila Norte e Vila d'Ouro",
    faction = "Alliance",
    race = "Human",
    steps = {
        -- Abadia de Vila Norte
        { type = "accept", quest = 783, name = "A Threat Within", x = 48.2, y = 42.9 },
        { type = "turnin", quest = 783, name = "A Threat Within", x = 48.9, y = 41.6 },
        { type = "accept", quest = 7, name = "Kobold Camp Cleanup", x = 48.9, y = 41.6 },
        { type = "accept", quest = 5261, name = "Eagan Peltskinner", x = 48.2, y = 42.9 },
        { type = "turnin", quest = 5261, name = "Eagan Peltskinner", x = 48.9, y = 40.2 },
        { type = "accept", quest = 33, name = "Wolves Across the Border", x = 48.9, y = 40.2 },
        { type = "complete", quest = 33, name = "Wolves Across the Border", x = 46.5, y = 38.5 },
        { type = "complete", quest = 7, name = "Kobold Camp Cleanup", x = 47.2, y = 36.0 },
        { type = "turnin", quest = 33, name = "Wolves Across the Border", x = 48.9, y = 40.2 },
        { type = "turnin", quest = 7, name = "Kobold Camp Cleanup", x = 48.9, y = 41.6 },
        { type = "accept", quest = 15, name = "Investigate Echo Ridge", x = 48.9, y = 41.6 },
        { type = "accept", quest = 18, name = "Brotherhood of Thieves", x = 48.2, y = 42.9 },
        { type = "complete", quest = 15, name = "Investigate Echo Ridge", x = 47.6, y = 32.5 },
        { type = "turnin", quest = 15, name = "Investigate Echo Ridge", x = 48.9, y = 41.6 },
        { type = "accept", quest = 21, name = "Skirmish at Echo Ridge", x = 48.9, y = 41.6 },
        { type = "train", text = "Visite o instrutor da sua classe na abadia" },
        { type = "accept", quest = 3903, name = "Milly Osworth", x = 48.2, y = 42.9 },
        { type = "turnin", quest = 3903, name = "Milly Osworth", x = 50.7, y = 39.2 },
        { type = "accept", quest = 3904, name = "Milly's Harvest", x = 50.7, y = 39.2 },
        { type = "complete", quest = 3904, name = "Milly's Harvest", x = 54.5, y = 48.5 },
        { type = "complete", quest = 18, name = "Brotherhood of Thieves", x = 55.0, y = 46.0 },
        { type = "turnin", quest = 3904, name = "Milly's Harvest", x = 50.7, y = 39.2 },
        { type = "accept", quest = 3905, name = "Grape Manifest", x = 50.7, y = 39.2 },
        { type = "turnin", quest = 18, name = "Brotherhood of Thieves", x = 48.2, y = 42.9 },
        { type = "accept", quest = 6, name = "Bounty on Garrick Padfoot", x = 48.2, y = 42.9 },
        { type = "turnin", quest = 3905, name = "Grape Manifest", x = 49.5, y = 41.6, text = "Irmão Neals, na torre da abadia" },
        { type = "complete", quest = 21, name = "Skirmish at Echo Ridge", x = 48.0, y = 29.5, text = "dentro da mina" },
        { type = "turnin", quest = 21, name = "Skirmish at Echo Ridge", x = 48.9, y = 41.6 },
        { type = "accept", quest = 54, name = "Report to Goldshire", x = 48.9, y = 41.6 },
        { type = "complete", quest = 6, name = "Bounty on Garrick Padfoot", x = 57.5, y = 48.2 },
        { type = "turnin", quest = 6, name = "Bounty on Garrick Padfoot", x = 48.2, y = 42.9 },
        { type = "train", text = "Treine antes de sair de Vila Norte" },

        -- Estrada para Vila d'Ouro
        { type = "accept", quest = 2158, name = "Rest and Relaxation", x = 45.6, y = 47.7 },
        { type = "turnin", quest = 54, name = "Report to Goldshire", x = 42.1, y = 65.9 },
        { type = "accept", quest = 62, name = "The Fargodeep Mine", x = 42.1, y = 65.9 },
        { type = "accept", quest = 47, name = "Gold Dust Exchange", x = 42.1, y = 67.3 },
        { type = "turnin", quest = 2158, name = "Rest and Relaxation", x = 43.8, y = 65.8 },
        { type = "home", x = 43.8, y = 65.8, text = "na estalagem de Vila d'Ouro" },
        { type = "accept", quest = 60, name = "Kobold Candles", x = 43.3, y = 65.7 },

        -- Mina Fargofundo
        { type = "complete", quest = 62, name = "The Fargodeep Mine", x = 39.5, y = 82.0 },
        { type = "complete", quest = 47, name = "Gold Dust Exchange", x = 39.5, y = 82.0 },
        { type = "complete", quest = 60, name = "Kobold Candles", x = 39.5, y = 82.0 },
        { type = "turnin", quest = 47, name = "Gold Dust Exchange", x = 42.1, y = 67.3 },
        { type = "turnin", quest = 60, name = "Kobold Candles", x = 43.3, y = 65.7 },
        { type = "turnin", quest = 62, name = "The Fargodeep Mine", x = 42.1, y = 65.9 },
        { type = "accept", quest = 76, name = "The Jasperlode Mine", x = 42.1, y = 65.9 },
        { type = "complete", quest = 76, name = "The Jasperlode Mine", x = 61.8, y = 53.9 },
        { type = "turnin", quest = 76, name = "The Jasperlode Mine", x = 42.1, y = 65.9 },
    },
})
