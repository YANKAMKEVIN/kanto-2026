# Pokemake 0.37.4 — notes de version

Version **0.37.4** (code Android 3704), le 2026-11-20. Elle s'installe **par-dessus la 0.37.3**
(ou une 0.37.x ou 0.36) et garde la partie en cours.

> Ne désinstalle pas le jeu pour faire la mise à jour : la sauvegarde partirait avec lui.

## Ce qui change pour toi

- **Multi Exp moderne :** le Pokémon qui combat garde toute son expérience, et chaque autre
  membre de l'équipe en reçoit la moitié.
- **Mew** t'attend au niveau 70 (au lieu de 30) ; il faut toujours les 150 autres espèces.
- **CT :**
  - Électhor, Sulfura, Mewtwo, Mew, les dragons et d'autres espèces oubliées peuvent enfin
    apprendre des CT ;
  - les Pokémon de Johto apprennent les CT et CS de Kanto qu'ils pouvaient apprendre dans
    Or et Argent.

## Pour Kevin (technique)

| | |
|---|---|
| Depuis | RC 0.37.3, `370d05d8` |
| Contenu | Mew niveau 70 ; Multi Exp moderne ; table des CT régénérée (15 espèces de Kanto ajoutées tard, espèces de Johto sur Or / Argent) (décisions du 2026-11-20) |
| Contrôles | CI GitHub verte sur `main` |
| Essais | tests sur le Mac ; **rien n'a été joué sur téléphone** |
| Sauvegarde | aucun changement de format (v10) |

Paquet : `~/.pokemake/rc/0.37.4/` (APK, `manifest.json`, `SHA256SUMS`). Installation :
`docs/tech/release.md` §4.
