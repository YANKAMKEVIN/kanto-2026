# Pokemake 0.37.2 — notes de version

Version **0.37.2** (code Android 3702), le 2026-11-14. Elle s'installe **par-dessus la 0.37.1**
(ou une 0.37.0 ou 0.36) et garde la partie en cours.

> Ne désinstalle pas le jeu pour faire la mise à jour : la sauvegarde partirait avec lui.

## Ce qui change pour toi

- **Arènes, plus de murs invisibles.** Les murs peints sont maintenant là où ils bloquent
  vraiment :
  - Argenta, Azuria, Carmin, Céladopole, Cramois'Île et Safrania ;
  - à Cramois'Île et à Safrania, on sort par une ouverture dans le mur du bas.
- **Manoir Pokémon :**
  - les grilles posées dans un mur sont dessinées de profil ;
  - elles ne bloquent plus les cases de sol à côté ;
  - le pupitre et une Poké Ball ne sont plus collés aux murs.
- **Arène de Cramois'Île :** la quatrième herse est elle aussi dessinée de profil.
- **Grottes :**
  - à la Route Victoire et à la Grotte Inconnue, une échelle qui descend est dessinée comme
    une échelle qui descend ;
  - aux Îles Écume et à la Route Victoire, le rocher poussé tombe à l'étage du dessous, et des
    éboulis bouchent le trou.
- **Petites retouches :**
  - Carmin : la barrière est élargie ;
  - Repaire Rocket : les Poké Balls sont posées sur les consoles ;
  - Sylphe SARL 9F : la plante ne cache plus le téléporteur.

## Pour Kevin (technique)

| | |
|---|---|
| Depuis | RC 0.37.1, `d4be6cd1` |
| Contenu | cartes et décors seulement : plans `tools/plans/`, scènes reconstruites, images Codex (grilles et herse de profil, éboulis) ; texte T-15 des Îles Écume |
| Contrôles | `plan_check*.py` conformes ; captures du Mac relues ; test du sens des grilles (`test_gate_orientation.gd`) |
| Essais | tests et captures sur le Mac ; **rien n'a été joué sur téléphone** (Kevin absent, accord du 2026-11-14) |
| Sauvegarde | aucun changement de format (v10) ; à Safrania, les cases sont décalées d'une colonne vers la droite (mur ajouté à gauche) : une partie sauvegardée dans l'arène de Safrania reprend une case plus à gauche, ou sur la case libre la plus proche si c'est un mur (`SceneRouter.start_at` → `find_standing_cell`) |

Paquet : `~/.pokemake/rc/0.37.2/` (APK, `manifest.json`, `SHA256SUMS`). Installation :
`docs/tech/release.md` §4.
