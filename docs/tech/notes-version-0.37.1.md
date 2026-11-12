# Pokemake 0.37.1 — notes de version

Version **0.37.1** (code Android 3701), le 2026-11-12. Elle s'installe **par-dessus la 0.37.0**
(ou une 0.36) et garde la partie en cours.

> Ne désinstalle pas le jeu pour faire la mise à jour : la sauvegarde partirait avec lui.

## Ce qui change pour toi

- **Parc Safari, l'accueil a une porte.** Après avoir payé, on entre dans le Parc par une ouverture
  dans le mur du fond, et plus en traversant le mur.
- **Parc Safari, la capture est plus facile.**
  - La Safari Ball attrape mieux.
  - Les Pokémon s'enfuient deux fois moins souvent.
  - L'appât ne gêne plus la capture que pendant que le Pokémon mange. Avant, chaque appât la
    rendait plus dure pour tout le reste de la rencontre.
  - Le caillou ne change pas : capture plus facile, fuite plus fréquente.

## Pour Kevin (technique)

| | |
|---|---|
| Depuis | RC 0.37.0, `33059d35` |
| Porte | enveloppe propre à l'accueil, `int_safari_porte_coque.png`, ouverture dérivée du poste de la Forêt [D] ; revue des 117 sorties hors sud des intérieurs : aucun autre cas |
| Capture | `data/safari/safari.json` : `ball_bonus` 3.0 (2.0 avant), `flee_factor` 0.5 (nouveau) ; appât sans cumul (`SafariRules`) ; valeurs [D] |
| Mesures (Balls seules, par rencontre) | Insécateur 23 → 48 %, Leveinard 25 → 52 %, Rhinocorne 75 → 91 %, Noeunoeuf 60 → 82 % |
| Essais | tests et simulation sur le Mac ; rien n'a été joué sur téléphone |
| Sauvegarde | aucun changement de format (v10) |

Paquet : `~/.pokemake/rc/0.37.1/` (APK, `manifest.json`, `SHA256SUMS`). Installation :
`docs/tech/release.md` §4.
