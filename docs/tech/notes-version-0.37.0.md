# Pokemake 0.37.0 — notes de version

Version **0.37.0** (code Android 3700), le 2026-11-12. Elle s'installe **par-dessus la 0.36.2**
(ou une 0.36 plus ancienne) et garde la partie en cours.

> Ne désinstalle pas le jeu pour faire la mise à jour : la sauvegarde partirait avec lui.

## Ce qui change pour toi

- **Le Sac est plus lisible.** On voit plus d'objets à la fois, les noms ne sont plus coupés, les
  catégories tiennent toutes à l'écran et le message de résultat ne cache plus le choix du Pokémon.
- **En combat, le Sac montre plus d'objets** : deux colonnes dès qu'il y en a plus de trois.
- **« Utiliser à nouveau »** n'est proposé que si l'objet peut encore servir au même Pokémon.

## Pour Kevin seulement : le mode auto

- **L'activer** : Paramètres, toucher sept fois de suite le titre « Paramètres », puis cocher
  « Mode auto en combat ».
- **En combat** : interrupteur **AUTO** en haut à droite, contre un Pokémon sauvage seulement
  (jamais contre un Dresseur, un Champion, au Parc Safari ni contre le SPECTRE).
- Le Pokémon en jeu attaque seul, environ quatre fois plus vite, sans jamais être changé, jusqu'à
  la fin du combat ou jusqu'à son K.O. Le mode se coupe alors, et il est coupé au début de chaque
  combat.
- Il choisit son attaque la plus utile et n'utilise jamais une attaque qui le met K.O.

## Pour Kevin (technique)

| | |
|---|---|
| Depuis | RC 0.36.2, `473943d1` |
| Contenu | mode auto en combat sauvage, ergonomie du Sac (cinq défauts de la QA du 2026-11-12) |
| Essais | tests et QA sur le Mac seulement ; **rien n'a été essayé sur téléphone** (décision de Kevin du 2026-11-12) |
| À regarder en jouant | sons du mode auto à vitesse ×4, taille de l'interrupteur AUTO, glisser lent dans le Sac qui pourrait mettre un objet en favori |
| Sauvegarde | aucun changement de format (v10) ; un réglage de plus, absent = désactivé |

Paquet : `~/.pokemake/rc/0.37.0/` (APK, `manifest.json`, `SHA256SUMS`). Installation :
`docs/tech/release.md` §4.
