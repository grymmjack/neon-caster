''
' NEON-CASTER - GAME/SECRETS.BI
' =============================================================================
' Secrets (? on the map): walls that slide away, and what's behind them.
'

' SECRETS (? on the map - chapter 22): walls that look like the walls
' beside them, on the map too, until you find them. Space on one and it
' slides away - "YOU FOUND A SECRET!" - and the tally counts it. Touching
' ? cells are one secret. One a trigger opens (its commands say "secret
' X Y" - a switch you shoot, say: secretShot) won't open to Space. And a
' monster closet hides a stash: once its monsters are all dead, a loose
' panel at the back of it (secretNeedEv: the closet) opens on loot.
CONST MAX_SECRETS = 32
DIM SHARED secretCell(MAP_SIZE, MAP_SIZE) AS INTEGER ' (a secret wall: which secret it's part of)
DIM SHARED closetIn(MAP_SIZE, MAP_SIZE) AS INTEGER ' (the floor inside a monster closet: which closet event)
DIM SHARED secretArea(MAP_SIZE, MAP_SIZE) AS INTEGER ' (floor you can only get to through a secret - or a closet: the map pickup draws it as this wall's colour, not floor, until you've seen it)
DIM SHARED numSecrets AS INTEGER, secretsFound AS INTEGER, secretFound(MAX_SECRETS) AS INTEGER
DIM SHARED secretShot(MAX_SECRETS) AS INTEGER, secretNeedEv(MAX_SECRETS) AS INTEGER, secretHint(MAX_SECRETS) AS INTEGER
DIM SHARED sndSecret&
