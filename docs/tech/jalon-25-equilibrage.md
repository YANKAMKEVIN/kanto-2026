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

## 5. Nouvelle simulation avec des équipes réalistes (clôture, 2026-10-24, E-2)

Kevin (2026-10-22) : « Équilibrage d'Auguste : à resimuler après la fusion des J21–J24 ». Fait sur
`jalon-25` (`2dacecb3`, J21–J24 dans la branche) avec le même outil :

```
godot --headless --path . -s res://tools/simulate_mt_moon.gd -- \
	--scenario tools/sim/cinnabar_j25_realiste.json --donnees
```

500 parties par ligne ; Dresseurs et Auguste = **vraies données** (`data/trainers/cinnabar_gym.json`,
`--donnees` : Dresseurs à +4 niveaux selon E-1, Auguste aux niveaux RB, IA `smart` **qui change**
de Pokémon, Bélier **avec** contrecoup). Mêmes parcours et objets qu'au §2 (Super Potion × 5,
Anti-Brûle × 2). Rien n'est changé dans `data/`.

**Équipes** (estimées : aucune partie réelle de bout en bout) : départ de QA `j25_arene` (perdu au
premier essai sur le S24), puis l'arrivée attendue après Koga (J23, Smogogo N43), les Routes 19–21,
les Îles Écume et le Manoir (Clé Secrète obligatoire) : starter final N48 (N45 pour une arrivée
basse), Roucarnage, **Ronflex** (J21), **Raichu avec Tonnerre** (CT24, J16), et un Pokémon qui
**Surfe** (obligatoire pour atteindre l'île : Tortank, Tentacruel ou Akwakwak du J24).

### 5.1 Auguste aux niveaux RB (données actuelles : Caninos 42, Ponyta 40, Galopa 42, Arcanin 47)

| Équipe | Quiz parfait, attentif | 6 combats sans soin | 6 combats, soin | Quiz parfait, naïf |
|---|---|---|---|---|
| QA : Tortank 46 (Surf…), Raichu 42, Akwakwak 42 | 100 % | 91 % | 100 % | **40 %** |
| QA à +4 : Tortank 50, Raichu 46, Akwakwak 46 | 100 % | 100 % | 100 % | 90 % |
| Tortank 48, Roucarnage 44, Ronflex 42, Raichu 42, Nidoking 42 | 100 % | 100 % | 100 % | 100 % |
| Florizarre 48, Roucarnage 44, Ronflex 42, Raichu 42, Tentacruel 40 | 100 % | 86 % | 100 % | 98 % |
| Dracaufeu 48, Roucarnage 44, Ronflex 42, Raichu 42, Akwakwak 40 | 100 % | 100 % | 100 % | 100 % |
| Florizarre 45, Roucarnage 41, Ronflex 39, Raichu 39, Tentacruel 38 (basse) | 92 % | **37 %** | 91 % | 73 % |
| Dracaufeu 45, Roucarnage 41, Ronflex 39, Raichu 39, Akwakwak 38 (basse) | 100 % | 99 % | 100 % | 98 % |

- **Dresseurs de l'Arène (N38–45) : 100 % chacun**, pour toutes les équipes (au-dessus des 80 %).
- **Défaite de la QA** : cohérente avec un joueur « naïf » (40 %) : Tortank arrive entamé sur
  Arcanin (Bélier, coups critiques) ; un joueur attentif qui Surfe sur chaque Pokémon gagne
  toujours (Surf met K.O. Caninos, Ponyta et Galopa en un coup, Arcanin en deux). Le simulateur
  ne reproduit pas « Tortank K.O. en deux tours » avec un Tortank à pleine santé.

### 5.2 Sondes (copies jetables d'Auguste, 300 parties, joueur attentif ; rien dans `data/`)

| Équipe | +4 (46 / 44 / 46 / 51) : quiz · sans soin · soin | +8 (50 / 48 / 50 / 55) : quiz · sans soin · soin |
|---|---|---|
| QA : Tortank 46, Raichu 42, Akwakwak 42 | 91 · 37 · 91 | 47 · 1 · 51 |
| QA à +4 | 100 · 92 · 100 | 85 · 44 · 85 |
| Tortank 48… | 100 · 100 · 100 | 96 · 93 · 97 |
| Florizarre 48… Tentacruel 40 | 83 · 26 · 75 | 16 · 2 · 18 |
| Dracaufeu 48… Akwakwak 40 | 100 · 99 · 100 | 98 · 66 · 99 |
| Florizarre 45… (basse) | 39 · 3 · 32 | 5 · 0 · 4 |
| Dracaufeu 45… (basse) | 100 · 74 · 100 | 79 · 18 · 76 |

### 5.3 Lecture et recommandation (question **E-4** : option A retenue par Kevin le 2026-10-26)

- Aux niveaux RB, Auguste est **trop facile** pour un joueur attentif (90–100 % presque partout,
  au-dessus des 35–60 % visés pour un Champion). Cause structurelle, comme dans RB : on ne rejoint
  Cramois'Île qu'en Surfant, donc **toute** équipe a un Pokémon Eau, et Tonnerre (CT24) est
  courant. Les niveaux seuls ne ramènent pas toutes les équipes dans la cible : l'écart entre un
  Tortank (≥ 92 % même à +8) et un Florizarre (5–18 % à +8) reste énorme.
- **E-4** — Auguste : **A** garder les niveaux RB (≈ 100 % attentif, 40 % naïf ; exception « le Surf
  impose l'avantage de type », comme Tortank contre Pierre) · **B** +4 niveaux (Caninos 46,
  Ponyta 44, Galopa 46, Arcanin 51) : 83–100 % attentif pour les arrivées N48, 32–39 % pour une
  arrivée basse avec Florizarre · **C** +8 : trop dur pour Florizarre (≤ 18 %).
  **Recommandation : A**, en l'acceptant comme exception de type (l'écart de B ne rapproche de la
  cible que l'équipe Florizarre, déjà la plus exposée, et punit l'arrivée basse) ; si Kevin veut un
  vrai mur, plutôt **B** que C. Les Dresseurs de l'Arène restent à 100 % même à +4 (E-1) : le quiz
  les rend facultatifs, recommandation de les laisser tels quels. **Aucun changement fait sans ton
  accord.**
