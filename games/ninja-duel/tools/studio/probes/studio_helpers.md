# Studio film helpers (visual checks, DEC-030)

Not part of any build. After opening a Debug place in Studio (Edit mode), create
them with execute_luau: `ServerStorage.NdStage` (stage.luau),
`ReplicatedStorage.NdLook` (look.luau), `ServerStorage.NdFilm` (film.luau),
`ServerStorage.NdPlayerAgent` (player_agent.luau wrapped as
`return function(FIGHTER, OPPONENT, DURATION, SEED) ... end`).
Film = many `screenshot` actions in one computer_batch (~10-25 fps).
