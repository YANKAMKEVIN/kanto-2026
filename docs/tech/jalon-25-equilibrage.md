# Jalon 25 — équilibrage de l'Arène de Cramois'Île et d'Auguste (25.0, T9)

> 2026-10-19. Simulation `tools/simulate_mt_moon.gd` sur `tools/sim/cinnabar_scenario.json` (500
> parties par ligne) et `cinnabar_essai_plus6.json` (300). Copie **jetable** qui fusionne `jalon-20`
> (Arcanin, Feunard, Écrasement) et le paquet `docs/tech/jalon-25-donnees/` (Ponyta, Galopa,
> Déflagration) ; rien n'est changé dans `data/`. Bélier sans contrecoup (`recoil_damage` encore
> « pending » dans les données du J17). Joueur « attentif » sauf mention.

## 1. Hypothèses et limite

Équipes **estimées** à l'arrivée après le J24 (aucune partie réelle) : starter final N46, Roucarnage
N42, Nidoking N42, Raichu N40 ; et une arrivée basse (N38–43). **Limite forte** : aucune n'a de
Pokémon qui Surfe (obligatoire pour atteindre Cramois'Île). Les espèces probables (Tentacruel,
Lokhlass, Otaria…) viennent des J21 à J24, pas encore fusionnés. Les chiffres d'Auguste dépendent
surtout de ce choix : à **refaire** avec des équipes réalistes après la fusion du J24.

## 2. Résultats (niveaux Rouge/Bleu)

| Équipe | Auguste seul (quiz parfait) | 6 Dresseurs puis Auguste sans soin | 6 Dresseurs, soin, Auguste |
|---|---|---|---|
| Florizarre 46… | 15 % | 3 % | 14 % |
| Tortank 46… | 88 % | 82 % | 88 % |
| Dracaufeu 46… | 81 % | 29 % | 76 % |
| Dracaufeu 43… (basse) | 31 % | 1 % | 19 % |
| Dracaufeu 46…, joueur naïf | 11 % | — | — |

- **Dresseurs de l'Arène aux niveaux RB (N34–41) : 100 % de victoires**, pour toutes les équipes.
- Avec **+6 niveaux** (N40–47) : on franchit les six Dresseurs d'affilée, sans soin, dans 58 %
  (Florizarre), 95 % (Dracaufeu), 100 % (Tortank) et 65 % (arrivée basse) des parties ; Auguste
  juste après, sans soin : 0 % ; après un soin : 10 %, 69 %, 68 %, 7 %.

## 3. Lecture

- Tortank à 82–88 % : avantage de type choisi par le joueur → **exception validée** (mémoire
  « difficulté des combats »), pas de correction.
- Dresseurs de l'Arène trop faciles aux niveaux RB (100 % > 80 %) : il faut monter.
- Auguste : la cible 35–60 % est atteinte « au milieu » (Dracaufeu 76–81 %, Florizarre 14–15 %)
  mais l'écart entre équipes est trop grand pour trancher sans les équipes réelles du J24.

## 4. Décisions de Kevin (2026-10-19) : E-1 à E-3 selon les recommandations

E-1 : Dresseurs de l'Arène **+4 niveaux** (appliqué au scénario et au dossier 28 §8.3) ; E-2 : Auguste aux niveaux RB, simulation à refaire avec les équipes réelles après la fusion du J24 ; E-3 : contrecoup de Bélier corrigé à l'intégration.

| N° | Question | Recommandation |
|---|---|---|
| **E-1** | Dresseurs de l'Arène : RB (N34–41, 100 %) ou relevés ? | **+4 niveaux** [D] (N38–45), à confirmer par une nouvelle simulation avec les équipes réalistes ; +6 rend la suite des six combats déjà dure pour une arrivée basse. |
| **E-2** | Auguste | **Garder les niveaux RB** pour l'instant ; refaire la simulation après la fusion du J24 avec des équipes contenant un Pokémon qui Surfe ; n'ajuster qu'avec ton accord. |
| **E-3** | Contrecoup de Bélier (`take_down`, données du J17 « sans effet ») | Le corriger (le moteur sait faire `RECOIL`) au moment de l'intégration, en accord avec la session qui possède ces données. |
