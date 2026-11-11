# Pokemake 0.36.2 — notes de version

Version **0.36.2** (code Android 3602), le 2026-11-11. Elle s'installe **par-dessus la 0.36.1**
(ou la 0.36.0) et garde la partie en cours.

> Ne désinstalle pas le jeu pour faire la mise à jour : la sauvegarde partirait avec lui.

## Ce qui change pour toi

- **Le jeu est deux fois plus léger** : environ 410 Mo au lieu de 960 Mo. Le téléchargement et
  l'installation sont plus rapides, et le jeu prend moins de place sur le téléphone.
- Rien d'autre ne change : même contenu que la 0.36.1 (voir `notes-version-0.36.1.md`).

## Pour Kevin (technique)

| | |
|---|---|
| Depuis | RC 0.36.1, `bff44c47` |
| Changement | 3 403 images peintes importées avec perte (WebP qualité 90) au lieu de sans perte |
| Restent sans perte | masques de données de `assets/world/maps`, atlas du Pokédex, icônes SVG, icône de l'app, tuiles provisoires |
| Mesures | images importées ~730 → ~205 Mo ; transparence identique au pixel près ; comparaison avant/après relue et validée par Kevin le 2026-11-11 |
| Garde-fou | `tests/unit/test_texture_import.gd` : masques sans perte, toute nouvelle image peinte avec perte |
| Sauvegarde | aucun changement de format |
| Retour arrière | annuler le commit des `.import` (les images sources n'ont pas changé), puis version 0.36.3 |

Paquet : `~/.pokemake/rc/0.36.2/` (APK, `manifest.json`, `SHA256SUMS`). Installation :
`docs/tech/release.md` §4.
