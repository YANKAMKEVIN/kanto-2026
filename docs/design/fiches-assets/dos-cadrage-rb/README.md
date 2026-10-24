# Dos de combat : essai du cadrage « façon Rouge/Bleu » (2026-10-24)

Question de Kevin : les dos actuels (corps entier, souvent de profil) paraissent bizarres et
Onix paraît minuscule. Faut-il un cadrage RB (trois quarts arrière, légère plongée, corps coupé
par le bas de l'écran), et des dos demandés ainsi à Codex seraient-ils moins refusés ?

## Images

- `apercu-dos-81.webp` : les 81 espèces à dos peint de `art-dos-combat-maj` @ `53fcf867`
  (IA de préférence, sinon 3D brut encadré en orange). Sur `main`, aucun dos peint n'est lu
  par le jeu (pixel 64 px ; Osselait et Ossatueur : artwork officiel de face).
- `apercu-dos-pokemon.webp` : les 27 dos IA et 4 dos 3D de `main` (`battle_proto/`).
- `comparaison-dos-rb.webp` : ces 31 dos à côté des dos Rouge/Bleu (PokeAPI, 32 px agrandis).
- `echantillon-cadrage-dos.webp` : montage A (cadrage actuel, `BattleLayout`) / B (dos existants
  agrandis et coupés par le bas) dans le décor de la Route 1, Rattata en face. Sans HUD.
- `test-dos-rb-codex.webp` : Carapuce et Onix, dos actuel contre nouveau dos Codex en cadrage RB.

## Test Codex (prompts `tools/art/prompts/dos_rb/`, sorties `build/art/DOS_RB_*.png`, 1254 px RGBA)

| Espèce | Avec artwork joint (r1) | Sans image (r2) |
|---|---|---|
| Salamèche (004) | refus | refus |
| Carapuce (007) | refus | **accepté** |
| Pikachu (025) | refus | refus |
| Onix (095) | **accepté** | — |

Tous les refus sont `moderation_blocked` à l'étape **output** : l'image produite est reconnue,
quel que soit le cadrage. Le cadrage serré ne fait donc pas tomber les refus des espèces très
connues ; il ne les aggrave pas non plus. Les deux images acceptées sont propres (vrai dos,
plongée, coupe nette en bas) et, en situation, nettement plus lisibles qu'en corps entier ;
Onix gagne sa taille (tête et blocs qui sortent par le bas).

## Décision attendue de Kevin

Cadrage A (actuel) ou B (façon RB). B toucherait `BattleLayout` (ancre et coupe du dos) et
la production des dos restants (session DAF.1, branche `art-dos-combat-maj`), voire la reprise
des 81 dos existants : à lui transmettre une fois la décision prise.
