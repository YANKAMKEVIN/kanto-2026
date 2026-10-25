# J25 — Le secret du Manoir Pokémon : passe d'alignement de la V2 (ChatGPT)

> **Arbitrages X-1 à X-24 validés par Kevin le 2026-10-16 (recommandations suivies) → dossier 28.**
>
> Claude, 2026-10-16. **Conception et audit seulement : aucune ligne de code.** V2 reproduite dans
> `j25-v2-chatgpt.md`. Relue contre `vision.md`, la roadmap, les dossiers 04, 06, 12, 15 et 17, les
> passes des J22 à J24 et le code réel d'`origin/main` (`440f9b17`, J15 fusionné) et des branches
> `jalon-16` à `jalon-21`. Audit en lecture seule (`git show` / `git grep`).
>
> **Faits Rouge/Bleu** : désassemblage `pret/pokered` (cartes, scripts, `data/trainers/parties.asm`,
> `data/wild/maps/PokemonMansion*.asm`, `engine/events/in_game_trades.asm`,
> `engine/events/cinnabar_lab.asm`, `engine/events/hidden_events/cinnabar_gym_quiz.asm`) ; noms et
> textes français : Poképédia. Relevé complet, fichier par fichier, avec croquis ASCII tirés des
> blocs de carte : **`j25-annexe-rb-cramois.md`** (en anglais, comme une note de recherche).
>
> Origine des règles : **RB** Rouge/Bleu · **G+** génération ultérieure · **K26** adaptation Kanto
> 2026 · **[D]** valeur par défaut (règle 4), modifiable sans débat.
>
> Les **7 décisions verrouillées** ne sont pas rouvertes. Mes arbitrages sont numérotés **X-1 à
> X-24** (§17 ; lettres libres vérifiées sur toutes les branches). Réponds par numéro ; j'écris
> ensuite le dossier 28 et le plan `jalon-25.md`.
>
> **Numéro** : 26 = J23, 27 = J24 → **28 = J25**, branche `docs/dossier-28-j25`.

## 0. État réel du dépôt (2026-10-16)

| Point | Constat |
|---|---|
| `origin/main` | `440f9b17`, **J15 terminé**. Sauvegarde **v7**. (Le `main` local est encore au J14.) |
| `jalon-16` à `jalon-21` | Non fusionnés ; chacun part de `jalon-15` séparément. |
| J22, J23 | Passes d'alignement écrites (`docs/dossier-25-j22`, `docs/dossier-26-j23`), **aucun code**. |
| **J24** | Branche `docs/dossier-27-j24` : **seule la V2 de ChatGPT** (non commitée). Ni passe, ni dossier, ni grille. |
| **Cramois'Île** | **Rien, sur aucune branche** : pas de carte, pas de grille, pas de dossier. `data/badges.json` déclare déjà `volcano` (« Auguste, Cramois'Île »). |

**Conséquence** : le J25 repose sur un J24 qui n'est pas encore conçu (ville, bâtiments, Surf,
Routes 20 et 21). Comme pour les J19 à J23, le dossier 28 écrira un **contrat d'entrée** (§2) ; les
données, la logique pure, les grilles, les vues peintes et l'art peuvent avancer dès la
validation ; **les cartes attendent une branche d'intégration qui contient le J24** (X-2).

## 1. Les 7 décisions de la V2

| # | V2 | Avis |
|---|---|---|
| 1 | Manoir + Laboratoire + Arène | Oui. C'est **trois systèmes neufs** (portes à interrupteur, chutes, échanges) plus la résurrection des fossiles : découpage X-24. |
| 2 | Quatre niveaux, statues, portes, trous, journaux | Oui. **Vérifié** : le puzzle RB fonctionne avec un seul interrupteur global, la Clé est inatteignable sans interrupteur, et aucun état atteignable n'empêche de ressortir (§4.3). |
| 3 | Journaux fidèles, sans Mewtwo | Oui. Les journaux RB **nomment Mew et Mewtwo**. Compatible avec le dossier 04 §17 (Mew reste un secret à trouver) et le dossier 06 (Mewtwo = épilogue). Deux détails à trancher : lieu réel (« Guyana ») et Pokédex (X-10, X-11). |
| 4 | Échanges et fossiles | Oui. **Aucun système d'échange n'existe** ; plusieurs dossiers ont jusqu'ici exclu les échanges (11, 12, 18, 20) : le J25 est le premier. Le Vieil Ambre n'existe nulle part (X-3). |
| 5 | Six quiz ou combats | Oui. Les six réponses RB restent **justes dans Kanto 2026** (§9.2), y compris avec les types modernes. |
| 6 | Auguste à quatre Pokémon RB | Oui. Trois de ses capacités n'existent pas ou sont « sans effet » dans le moteur (§10) → X-18. |
| 7 | Fin libre | Oui. Rien de nouveau au tableau de bord. |

## 2. Contrat d'entrée J24 → J25

Ce que le J25 **suppose livré** (hypothèses : rien n'est fusionné ni validé sur téléphone).

| Origine | Élément | État au 2026-10-16 |
|---|---|---|
| **J24** | Carte de Cramois'Île, raccords Route 20 (est) et Route 21 (nord), **Surf** et sa conservation entre cartes | **Non conçu.** À demander à la session du J24 : la ville RB fait 20 × 18 pas, portes du Manoir (6,3), de l'Arène (18,3), du Labo (6,9), du Centre (11,11), de la Boutique (15,11). |
| **J24** | Portes du Manoir, du Labo et de l'Arène **réservées** (« Plus tard » ou fermées), Centre et Boutique ouverts | Idem. La porte de l'Arène doit porter la règle de la Clé (§7) dès qu'elle existe. |
| J23 | Badge Âme, CS03 Surf | Passe écrite, pas de code |
| J20 | `PokemonGift.give` (cadeau → équipe sinon stockage, en un bloc), espèces Saquedeneu, Caninos, Arcanin, Goupix, Feunard, Rappel, Super Ball, Pierre Foudre, Écrasement | Codé sur `jalon-20` |
| J17 | Magnéti, Magnéton, Caninos, Goupix | Codé sur `jalon-17` |
| J16 | **Coupe** (`field_moves.gd`, buissons), `switch_puzzle.gd` (poubelles de Carmin), `key_item_repair.gd` | Codé sur `jalon-16` |
| J14 (`main`) | CT28 Tunnel (combat « deux tours ») ; `trade_cord` **réservé** sans source | Codé |
| J12 (`main`) | Un seul fossile, choix définitif : `dome_fossil` / `helix_fossil` (objets clés), drapeaux `mt_moon_got_*_fossil` | Codé |
| J10 (`main`) | Musée d'Argenta : vitrines, porte « LABORATOIRE — Personnel autorisé » fermée | Codé |
| Système | `StoryFlags`, `got_<carte>_item_N`, `got_<carte>_hidden_N`, `beaten_<id>`, étapes de scène `champion_card` / `battle` / `badge` / `give` / `moment`, choix OUI/NON (`dialogue_choice.gd`), autosave seulement aux moments stables (arrivée sur une carte, fin de scène, fin de combat) | Codé |

**Ce que le J25 ne doit pas toucher** : Îles Écume, Artikodin, Surf (on les lit), Route 21 (J24),
Giovanni et Jadielle (J26).

## 3. Topologie Rouge/Bleu (vérifiée)

| Carte | RB (pas) | Raccords | Contenu RB |
|---|---|---|---|
| Manoir 1F | 30 × 28 | porte principale (sud), **2ᵉ sortie sud-est** derrière une porte à interrupteur ; escalier ↑ 2F (5,10), escalier ↓ B1F (21,23) | 1 Scientifique, Corde Sortie, Carbone, Pierre Lune cachée, 1 interrupteur |
| Manoir 2F | 30 × 28 | ↓ 1F, **trois** escaliers vers 3F | 1 Pillard, Calcium, **2 journaux** (5 et 10 juillet), 1 interrupteur |
| Manoir 3F | 30 × 18 | trois escaliers vers 2F ; **3 trous** : deux vers 1F (16,14), un vers 2F (18,14) | 1 Pillard, 1 Scientifique, Potion Max, Fer, Rappel Max caché, **journal** (6 février), 1 interrupteur |
| Manoir B1F | 30 × 28 | ↑ 1F seulement | 1 Pillard, 1 Scientifique, Super Bonbon (+ un caché), Guérison, CT14 Blizzard, CT22 Lance-Soleil, **Clé Secrète** (5,13), **journal** (1ᵉʳ septembre), **2 interrupteurs** |
| Laboratoire | hall 18 × 8 + 3 salles 8 × 8 | hall → Salle de réunion, Recherche et Développement, Salle de test | photo du Dr Fuji ; 3 échanges ; CT35 Métronome ; mail du PC sur les oiseaux légendaires ; scientifique des fossiles |
| Arène | 20 × 18 | porte fermée sans la Clé | 6 machines, 7 Dresseurs (le n° 1 sans machine), Auguste, guide |

## 4. Le Manoir

### 4.1 Plans fonctionnels (sans level design)

Proposition [D] : **grille RB à 1 case = 1 pas** (1F, 2F, B1F 30 × 28 ; 3F 30 × 18), soit
2 880 px de large ; l'écran en montre environ 24 × 11. Les grilles `tools/plans/manoir_*.txt`
feront foi ; la topologie (pièces, portes, escaliers, trous, interrupteurs) suit RB, l'habillage
suit la DA (manoir brûlé, golden hour par les fenêtres crevées, orthogonal). Croquis RB dans
l'annexe §1.9 (approximatifs : collisions lues sur une seule tuile par pas).

```
            ┌──────────── 3F (30×18) ────────────┐
            │ 3 escaliers ⇅ 2F   trous ▼▼ → 1F    │
            │ interrupteur (10,5) trou ▼ → 2F     │
            └─────────────────────────────────────┘
            ┌──────────── 2F (30×28) ────────────┐
            │ ⇅ 1F  journaux 5 et 10 juillet      │
            └─────────────────────────────────────┘
 Cramois ◀▶ ┌──────────── 1F (30×28) ────────────┐
   (porte)  │ ↑ 2F (5,10)   ↓ B1F (21,23) isolé   │
   (2ᵉ porte│ sud-est, derrière une porte « = »)  │
            └─────────────────────────────────────┘
            ┌──────────── B1F (30×28) ───────────┐
            │ ↑ 1F seulement ; 2 interrupteurs    │
            │ Clé Secrète (5,13) ; journal 1/9    │
            └─────────────────────────────────────┘
```

### 4.2 Interrupteurs (statues) et portes

**RB** : chaque étage a un interrupteur caché dans une **statue** (B1F en a deux). On l'actionne
face à elle : « Un interrupteur secret ! » / « L'actionner ? » OUI/NON. Tous basculent **le même
drapeau global**. Chaque étage a deux jeux de portes : le jeu A est fermé quand l'interrupteur est
sur ARRÊT, le jeu B quand il est sur MARCHE. Le drapeau **revient à ARRÊT dès qu'on remet le pied
sur Cramois'Île**. Le Pillard du 2F l'explique : les interrupteurs ouvrent et ferment des portes en
alternance.

| Étage | Jeu A (fermé sur ARRÊT) | Jeu B (fermé sur MARCHE) |
|---|---|---|
| 1F | 3 portes, dont celle de la 2ᵉ sortie | 1 porte |
| 2F | 2 portes | 1 porte |
| 3F | 1 porte | 1 porte |
| B1F | 2 portes | 2 portes |

**K26** (X-5) : même règle, drapeau sauvegardé `mansion_switch_on` ; remis à ARRÊT **en entrant
dans le Manoir depuis Cramois'Île** (équivalent RB, et un chargement en plein Manoir retrouve les
portes telles qu'on les a laissées). Statue = objet peint (statue de Pokémon) ; portes = grilles
basses peintes en deux états, collision et image pilotées par le drapeau (modèle `FlagGate` à
`blocking_cells`). Petit bruit mécanique et léger tremblement des portes de l'écran au moment du
basculement [D] ; aucune flèche, aucun marqueur.

### 4.3 Vérification du puzzle (faite sur les données RB)

Script de recherche en largeur sur les croquis de l'annexe (états = étage, case, interrupteur ;
transitions = marche, escaliers, trous, basculement) — dans le bloc-notes de la session, **pas dans
le dépôt** :

- **Clé atteignable** : oui. Chemin minimal : 1F → 2F → 3F, **interrupteur du 3F sur MARCHE**,
  **trou → 1F (16,14)**, escalier ↓ B1F, interrupteur du B1F (sud) **ARRÊT**, interrupteur du B1F
  (nord) **MARCHE**, salle ouest → Clé.
- **Sans toucher aux interrupteurs** : ni la Clé ni même le B1F ne sont atteignables. Le puzzle est
  donc réellement nécessaire.
- **Anti-blocage** : sur les 3 030 états atteignables, **aucun** n'empêche de revenir à une sortie.
- Les chutes du 3F tombent sur des cases praticables (1F (16,14), 2F (18,14)).

En 25.0, le même contrôle tournera sur **nos** grilles (`tools/art/plan_check_manoir.py`, modèle des
`plan_check_*` existants) : clé atteignable, aucun état sans retour, chutes sur case praticable et
non enfermée, Dresseurs inévitables comptés.

### 4.4 Trous

**Aucun système de chute n'existe**, sur aucune branche (`warp.gd` : `STEP_ON` et `PUSH`). Proposé
[D] : un `Warp` de type **chute** (case du trou praticable, déclenchement à l'entrée) avec
présentation courte : le joueur s'enfonce, fondu au noir 0,3 s, il « atterrit » (petit rebond,
poussière) sur la case d'arrivée, regard vers le bas. Le compagnon rentre dans sa Ball pendant la
chute et ressort à l'arrivée [D]. Les trous sont **peints** (plancher effondré, bords nets) et lisibles
de loin. Le J24 aura besoin de trous pour ses rochers : à mettre en commun avec sa session (X-6).

### 4.5 Dresseurs du Manoir (RB)

| Étage | Classe | Équipe RB | Vue | Réplique RB (sens) |
|---|---|---|---|---|
| 1F | Scientifique | Électrode 29, Smogogo 29 | 3 | « Qui êtes-vous ? Personne ne devrait être ici. » |
| 2F | Pillard | Salamèche 34, Reptincel 34 | 0 (on lui parle) | « Je n'arrive pas à sortir ! Ce manoir est un vrai casse-tête ! » |
| 3F | Pillard | Feunard 38 | 0 | « Cet endroit est immense ! » |
| 3F | Scientifique | Magnéti 33, Magnéton 33, Voltorbe 33 | 2 | « Mon mentor vivait ici. » |
| B1F | Pillard | Caninos 34, Ponyta 34 | 0 | « Oh oh. Où suis-je ? » |
| B1F | Scientifique | Magnéti 34, Électrode 34 | 3 | « Cet endroit est idéal pour un labo. » |

Trois Pillards sur six ne voient pas le joueur : la V2 « largement facultatifs » est déjà RB. Les
grilles vérifieront qu'aucun Scientifique ne garde seul un passage obligatoire (X-7).

### 4.6 Rencontres sauvages

RB : 10/256 par pas sur les quatre étages, tables différentes en Rouge et en Bleu (Caninos et plus
de Smogo en Rouge ; Goupix et plus de Tadmorv en Bleu ; **Magmar seulement en Bleu**, 3F et B1F).
**Convention du projet vérifiée** : les tables réunissent les deux versions (Route 24 : Mystherbe
**et** Chétiflor). Proposé [D], par étage (niveaux RB) :

Poids RB additionnés par espèce (créneaux 19,9 / 19,9 / 15,2 / 9,8 / 9,8 / 9,8 / 5,1 / 5,1 /
4,3 / 1,2 %) ; dans l'union, chaque paire Rouge/Bleu (Smogo/Tadmorv, Smogogo/Grotadmorv,
Caninos/Goupix) se partage le poids moitié-moitié :

| Espèce (niveaux RB) | 1F | 2F | 3F | B1F |
|---|---|---|---|---|
| Ponyta (28–36) | 40 % | 25 % | 19 % | 15 % |
| Smogo / Tadmorv (30–35), chacun | 22,5 % | 25 % | 20 % | 27 % |
| Smogogo / Grotadmorv (37–42), chacun | 2,7 % | 2,7 % | 8 % | 7,7 % |
| Caninos / Goupix (32–35), chacun | 4,9 % | 10 % | 10 % | 7,6 % |
| Magmar (Bleu seul : 34 au 3F, 9,8 % ; 38 au B1F, 4,3 %) | — | — | 5 % [D] | 2 % [D] |

Magmar est pris sur la part de Ponyta (3F) et de Grotadmorv (B1F), à moitié de son poids Bleu
[D]. Conversion au format `data/encounters` (`rate`, `ramp`, `slots`) en 25.0.
Terrain « intérieur » : rencontres sur toutes les cases praticables (RB), sauf escaliers et seuils
[D].

### 4.7 Objets (RB → K26)

| Étage | RB | K26 [D] |
|---|---|---|
| 1F | Corde Sortie ; Carbone ; Pierre Lune (cachée) | Corde Sortie ; **Pépite** (pas de vitamines) ; Pierre Lune cachée |
| 2F | Calcium | **Super Bonbon** |
| 3F | Potion Max ; Fer ; Rappel Max (caché) | Potion Max (données seules) ; **Pépite** ; Rappel Max caché (données seules, si Rappel existe — `jalon-20`) |
| B1F | Super Bonbon ; Guérison ; CT14 Blizzard ; CT22 Lance-Soleil ; Super Bonbon (caché) ; **Clé Secrète** | identiques si Blizzard et Lance-Soleil tiennent dans le moteur (Lance-Soleil : charge en deux tours, existe depuis Tunnel au J14) ; sinon remplacées (X-9) |

Remplacement des vitamines : même principe que le J22 (M-16). Tous les objets suivent les drapeaux
`got_<carte>_item_N` / `got_<carte>_hidden_N` : jamais de réapparition.

## 5. Journaux

**RB** (texte EN, quatre objets « carnet ») : 2F « 5 juillet — Guyana, Amérique du Sud. Un nouveau
Pokémon a été découvert au cœur de la jungle. » · 2F « 10 juillet — Nous avons baptisé ce nouveau
Pokémon Mew. » · 3F « 6 février — Mew a donné naissance. Nous avons appelé le nouveau-né Mewtwo. » ·
B1F « 1ᵉʳ septembre — Mewtwo est bien trop puissant. Nous n'arrivons pas à contenir sa violence… ».
La VF de 1999 dit « Jungle X » et « Mew est papa (ou maman ?) ».

**Propositions K26** (deux lignes de 40 caractères au plus par page ; texte à valider en lot dans
le dossier) :

| # | Étage | Page 1 | Page 2 |
|---|---|---|---|
| 1 | 2F | « Journal — 5 juillet. » / « Expédition au cœur d'une jungle lointaine. » | « Un Pokémon inconnu a été découvert. » |
| 2 | 2F | « Journal — 10 juillet. » / « Nous avons baptisé le nouveau Pokémon : » | « Mew. » |
| 3 | 3F | « Journal — 6 février. » / « Mew a donné naissance. » | « Nous avons appelé le petit Mewtwo. » |
| 4 | B1F | « Journal — 1ᵉʳ septembre. » / « Mewtwo est bien trop puissant. » | « Nous n'arrivons plus à maîtriser » / « sa violence… » |

Règles [D] : relisibles à volonté, aucun Grand moment, **aucune entrée Pokédex** (Mew et Mewtwo ne
sont ni « vus » ni nommés dans le Pokédex par la lecture) (X-11), aucun son spécial. Le carnet est un
objet peint (pupitre, carnet ouvert, page brûlée sur les bords).

## 6. Clé Secrète

RB : Poké Ball posée au B1F (5,13), ramassée comme un objet ordinaire. Porte de l'Arène : sans la
Clé dans le Sac, « La porte est verrouillée… » et le joueur recule d'un pas ; **la posséder
suffit**, rien n'est consommé.

**K26** (X-12) :
1. Ramassage au B1F : objet clé `secret_key`, drapeau `got_pokemon_mansion_b1f_item_N` (convention
   existante) ; le nom proposé par la V2 `mansion_secret_key_taken` n'est pas nécessaire.
2. Première arrivée devant la porte avec la Clé : « La Clé Secrète tourne dans la serrure. » /
   « La porte de l'Arène est ouverte ! » → drapeau **`cinnabar_gym_unlocked`**. Ensuite, la porte est
   une porte ordinaire, Clé ou non.
3. La Clé **reste** dans les objets clés (V2). Réparation au chargement (`key_item_repair`, J16) :
   drapeau de ramassage présent et objet absent → objet rendu.
4. Sans la Clé : « La porte est verrouillée. » ; le joueur recule d'une case (RB).

## 7. Laboratoire

### 7.1 Plan (RB)

```
┌────────────┐┌────────────┐┌────────────┐
│  RÉUNION   ││  R. et D.  ││    TEST    │
│ Intello    ││ Scientif.  ││ Scientif.  │
│ (fossile)  ││ (CT35)     ││ (fossiles) │
│ Papi ⇄     ││ Scientif.  ││ Scientif. ⇄│
│ Beauté ⇄   ││ (Évoli) PC ││  PC        │
└────┬───────┘└────┬───────┘└────┬───────┘
═════╧═════════════╧═════════════╧══════ hall (photo du Dr Fuji, guide)
                ▲ sortie
```

K26 [D] : hall à la largeur RB (18 × 8), trois salles à la convention des intérieurs
(15 × 10). Photo du Dr Fuji (« Le fondateur du Laboratoire, le Dr Fuji. ») : lien discret avec le
J19, sans commentaire.

### 7.2 Échanges fixes (RB vérifiés)

| Salle | PNJ | Il veut | Il donne | Surnom RB (VF) |
|---|---|---|---|---|
| Réunion | Papi | Raichu | Électrode | Kourjus |
| Réunion | Beauté | Mimitoss | Saquedeneu | Bigoudi |
| Test | Scientifique | Ponyta | Otaria | Bibi |

La V2 est exacte. **RB** : OUI/NON, puis choix dans l'équipe ; il faut l'espèce exacte ; le Pokémon
reçu prend **le niveau du Pokémon donné**, garde un surnom fixe, a pour dresseur d'origine
« DRESSEUR » ; chaque échange ne se fait qu'une fois ; les Pokémon reçus gagnent plus d'expérience
(×1,5) et désobéissent au-delà du plafond des badges.

**K26 proposé** (X-15) :
- Échange **sur place** : le Pokémon reçu prend la place du Pokémon donné dans l'équipe (pas de
  passage par le stockage, pas d'équipe pleine possible). Sélection avec le sélecteur de cible
  existant (Super Bonbon), limité aux Pokémon de l'espèce demandée.
- Reçu : même niveau, capacités de montée de niveau à ce niveau, PV pleins, sans statut, IV tirés
  normalement, surnom VF RB, **dresseur d'origine = nom du PNJ** [D], origine nouvelle `TRADE`.
- **Pas de bonus d'expérience, pas de désobéissance** (aucun système d'obéissance ; même esprit que
  le Badge Roche sans bonus caché, dossier 12).
- Le Pokémon donné quitte la partie ; s'il était le **compagnon**, la règle du J11 (« compagnon
  retiré ») s'applique avant l'arrivée du nouveau.
- Refus propre : pas de Pokémon de l'espèce → réplique RB (« Ce n'est pas un Raichu ! Reviens quand
  tu en auras un. »), rien ne change. Le dernier Pokémon de l'équipe peut être échangé (l'équipe
  reste à la même taille).
- Atomicité : retrait, ajout, Pokédex (vu + capturé), drapeau `cinnabar_trade_<id>_done` dans **un
  seul bloc synchrone** ; l'autosave n'a lieu qu'à la fin de la scène.
- Mise en scène [D] : « Branchez le câble comme ça ! » puis fondu, puis « <joueur> a échangé Raichu
  contre Kourjus ! » ; pas d'animation de câble.

**Disponibilité des espèces demandées** : Raichu (Pierre Foudre, `jalon-20`), Ponyta (sauvage dans
le Manoir même), **Mimitoss : absente de toutes les branches** (RB : Routes 12 à 15, Parc Safari —
J22/J23). Si elle n'existe pas à l'intégration, l'échange reste proposé et attend le joueur.

### 7.3 Résurrection des fossiles (RB vérifiée)

RB : le scientifique de la Salle de test cherche Fossile Dôme, Nautile, Vieil Ambre ; si le joueur
en a plusieurs, une liste ; un seul à la fois ; OUI → fossile retiré, « Je prends un peu de temps !
Va faire une petite promenade ! » ; **il suffit de ressortir sur Cramois'Île et de revenir** (le
drapeau « en cours » s'efface à chaque passage sur la carte de l'île) ; Pokémon donné **au
niveau 30**, au PC si l'équipe est pleine. On ne peut avoir que **deux fossiles** dans une partie
(Vieil Ambre + Dôme ou Nautile) : c'est déjà le cas dans Kanto 2026 (J12, choix définitif).

**K26 — transaction** (X-16), avec les drapeaux existants (pas de changement de version de
sauvegarde) :

| État | Drapeaux | Entrée | Sortie |
|---|---|---|---|
| disponible | fossile dans le Sac | — | « confier » |
| confié | `cinnabar_lab_fossil_<f>_given` + `cinnabar_lab_reviving` | fossile retiré **dans le même bloc** | entrée sur la carte de Cramois'Île : `cinnabar_lab_reviving` effacé |
| prêt | `_given` sans `reviving` | — | parler au scientifique |
| récupéré | `cinnabar_lab_fossil_<f>_revived` | `PokemonGift.give` (équipe sinon stockage, Pokédex, rencontre, drapeau) en un bloc | — |

- **Fermeture du jeu** : à tout instant, la dernière sauvegarde stable contient soit le fossile
  dans le Sac, soit `_given` (jamais les deux, jamais aucun des deux) ; idem Pokémon / `_revived`.
- Rechargement dans le Labo en état « confié » : il faut encore sortir (RB).
- Le stockage n'a pas de limite : le cas RB « PC plein » disparaît.
- Un deuxième fossile est refusé tant qu'un premier est confié ou prêt : « Je m'occupe déjà d'un
  fossile ! ».
- Réparation au chargement [D] : `_given` sans fossile ni Pokémon → normal (en cours) ; fossile
  **et** `_given` → fossile retiré (ne peut arriver que par une corruption, test dédié).
- Niveau du Pokémon : **30** (RB) ; Kabuto et Amonita évoluent au 40 → **Kabutops et Amonistar**
  doivent exister.

### 7.4 Salle R. et D.

RB : CT35 Métronome, un scientifique sur Évoli, un PC avec un mail sur les trois oiseaux
légendaires (« l'équipe compte explorer la caverne près d'Azuria »). **Métronome n'a pas d'effet
dans le moteur** (`pending_effects: ["metronome"]`) → X-13. Le mail : X-14.

## 8. Vieil Ambre (Argenta)

RB : porte **arrière** du Musée (côté est), atteinte par un arbre à Couper ; un scientifique donne le
Vieil Ambre (« Chut ! Je crois que cet ambre contient l'ADN d'un Pokémon ! »). **Rien n'existe** :
ni objet, ni porte arrière, ni arbre. Le dossier 12 l'annonçait (« Ambre Vieille plus tard ») et
l'écrit **« Ambre Vieille »** ; le nom officiel est **« Vieil Ambre »** (à corriger dans le dossier
12). → X-3.

## 9. Arène d'Auguste

### 9.1 Plan (RB, 20 × 18)

```
┌──────────┬──────────┬──────────┐
│ AUGUSTE  │ Q2  D3   │ D1 (sans │
│          │          │  machine)│
├══ P6 ════┼══ P2 ════┼══ P1 ════┤
│ Q6  D7   │ Q3  D4   │ Q1  D2   │
├══ P5 ════┼══ P3 ════┤ guide    │
│ Q5  D6   │ Q4  D5   │ statue   │
│        P4║          │ entrée ▲ │
└──────────┴──────────┴──────────┘
Q = machine (face à elle) · D = Dresseur · P = porte de quiz
```

Ordre : entrée (Q1) → P1 nord → couloir vers Q2 → P2 → Q3 → P3 → Q4 → P4 ouest → Q5 → P5 → Q6 →
P6 → Auguste. K26 [D] : grille RB 1:1 (20 × 18), salles séparées par des murs de pierre
volcanique ; portes de quiz = herses de métal chaud, deux états.

### 9.2 Les six questions

**RB** : introduction « Quiz Pokémon ! Bonne réponse : la porte s'ouvre. Mauvaise réponse : un
Dresseur t'affronte ! ». Mauvaise réponse : « Désolé ! Mauvaise réponse ! », le Dresseur lié vient
au joueur et l'affronte ; le battre ouvre aussi la porte. Les Dresseurs de l'Arène **ne voient pas**
le joueur : on les affronte en leur parlant ou en se trompant.

| # | RB (VF 1999) | Réponse | Valable en K26 ? | Proposition K26 (≤ 40 car.) |
|---|---|---|---|---|
| 1 | « Chenipan évolue en Papilusion ? » | OUI | oui (Chenipan → Chrysacier → Papilusion) | « Chenipan finit par devenir Papilusion ? » |
| 2 | « Il existe 9 Badges Pokémon ? » | NON | oui (8 dans `badges.json`) | « La Ligue délivre-t-elle 9 Badges ? » |
| 3 | « Ptitard évolue 3 fois ? » | NON | oui (deux évolutions dans les 151) | « Ptitard évolue-t-il trois fois ? » |
| 4 | « La foudre est efficace contre les Pokémon du sol ? » | NON | oui (sans effet, en RB comme en G+) | « L'Électrik touche-t-il le type Sol ? » |
| 5 | « Les Pokémon du même type et du même niveau sont différents ? » | OUI | oui (IV tirés au hasard, `pokemon_factory.gd`) | « Deux Pokémon de même espèce et même » / « niveau peuvent-ils être différents ? » |
| 6 | « CT28 contient Fosse ? » | NON | oui : la CT28 est **Tunnel** (J14) | « La CT28 contient-elle Fosse ? » |

Règles K26 (X-17) :
- Machine : objet peint (pupitre à écran), Action face à elle ; OUI/NON avec `dialogue_choice`.
- Bonne réponse : « Exact ! Tu peux passer ! » → drapeau `cinnabar_gym_gate_<n>`, porte ouverte
  pour toujours ; le Dresseur reste affrontable en lui parlant (argent, expérience).
- Mauvaise réponse, Dresseur pas encore battu : il vient au joueur, combat ; victoire → porte
  ouverte ; défaite → Centre, porte fermée, la machine repose la question (RB).
- Mauvaise réponse, Dresseur déjà battu : sa porte est déjà ouverte ; rien ne se passe.
- Parler directement au Dresseur = combat ; victoire → porte ouverte (« combattre au choix », V2).
- La machine déjà résolue répond « Porte ouverte. » [D].

### 9.3 Dresseurs de l'Arène (RB)

| # | Classe | Équipe RB | Lié à |
|---|---|---|---|
| 1 | Intello | Goupix 36, Goupix 36, Feunard 36 | aucune machine (facultatif) |
| 2 | Pillard | Caninos 36, Goupix 36, Feunard 36 | Q1 |
| 3 | Intello | Ponyta 34, Salamèche 34, Goupix 34, Caninos 34 | Q2 |
| 4 | Pillard | Ponyta 41 | Q3 |
| 5 | Intello | Galopa 41 | Q4 |
| 6 | Pillard | Goupix 37, Caninos 37 | Q5 |
| 7 | Intello | Caninos 37, Goupix 37 | Q6 |

Le Dresseur 5 raconte, après le combat, l'histoire d'Auguste perdu en montagne et guidé par un
oiseau de feu (Sulfura, sans le nommer) : à garder, c'est une graine pour plus tard (texte au
dossier).

## 10. Auguste

### 10.1 Équipe et capacités

| Pokémon | Niv. RB | Capacités RB | Moteur | K26 [D] |
|---|---|---|---|---|
| Caninos | 42 | Flammèche, Groz'Yeux, Bélier, Hâte | Bélier : données seulement (`take_down` « sans effet » sur les branches) ; le contrecoup (`RECOIL`) existe dans le moteur | Bélier avec contrecoup ¼ (données) |
| Ponyta | 40 | Mimi-Queue, Écrasement, Rugissement, Danse Flamme | Écrasement : `jalon-20` ; Danse Flamme (piège) : codée | identique |
| Galopa | 42 | idem Ponyta | idem | identique |
| Arcanin | 47 | **Hurlement**, Flammèche, **Déflagration**, Bélier | Déflagration : **absente** ; Hurlement : « sans effet » (`force_switch`) | Déflagration créée (valeurs modernes du projet : 110 / 85 % / brûlure 10 %) ; **Hurlement → Groz'Yeux** (X-18) |

- **Hurlement** : en RB il **échoue toujours** contre un Dresseur ; en G+ il force le changement.
  Le remplacer par Groz'Yeux (la capacité RB que Déflagration a remplacée) évite un tour perdu
  sans créer de mécanique.
- IA `smart` (comme les Champions précédents). Récompense RB 4 653 ₽ (99 × 47) [D].
- **Équilibrage** : simulation en 25.0 sur le modèle de `jalon-13-equilibrage.md`, avec l'équipe
  type attendue après le J24 ; cible **35–60 %** de victoire au premier essai (combat majeur) ; les
  niveaux RB restent la référence, tout écart est soumis à Kevin.

### 10.2 Victoire

Scène RB : « J'ai brûlé tout mon feu ! Tu as gagné le Badge Volcan ! » puis CT38 : « La CT38
contient Déflagration ! Apprends-la à un Pokémon Feu ! » (Reptincel ou Ponyta cités). Après :
« Déflagration est l'arme suprême du Feu ! Ne la gâche pas sur un Pokémon Eau ! ».

K26 : présentation générique des Champions (`champion_card`), étape `badge` (`badge_volcano`,
Grand moment « badge »), **aucun bonus caché** (RB : +9/8 en Spécial ; supprimé comme le Badge
Roche), `give` `tm38` avec `tm38_received` (modèle de la CT11). Le Sac n'a pas de limite : pas de
cas « fais de la place ». Les sept Dresseurs de l'Arène sont marqués battus (RB) [D] — **ou non**
(X-20). Ensuite, rien : pas de message, pas de PNJ qui oriente vers Jadielle, pas d'objectif.

## 11. Drapeaux (sans changement de version de sauvegarde)

| Drapeau | Rôle | V2 |
|---|---|---|
| `mansion_switch_on` | Interrupteur global (remis à ARRÊT à l'entrée du Manoir) | nouveau |
| `got_pokemon_mansion_<étage>_item_N` / `_hidden_N` | Objets, **Clé Secrète** comprise | remplace `mansion_secret_key_taken` |
| `beaten_<id>` | Dresseurs du Manoir et de l'Arène | existant |
| `cinnabar_gym_unlocked` | Porte de l'Arène | = V2 |
| `cinnabar_gym_gate_1` … `_6` | Portes de quiz | nouveau |
| `badge_volcano`, `tm38_received` | Badge et CT | = V2 |
| `cinnabar_trade_electrode_done`, `_tangela_done`, `_seel_done` | Échanges | nouveau |
| `cinnabar_lab_reviving` | Fossile « en cours » (effacé sur la carte de l'île) | nouveau |
| `cinnabar_lab_fossil_dome_given` / `_revived`, `_helix_*`, `_amber_*` | Transaction des fossiles | remplace `fossil_*_revived` |
| `pewter_museum_got_old_amber` | Vieil Ambre (si X-3 = A) | nouveau |

Tout tient dans `StoryFlags` : **sauvegarde v7 inchangée**. Seul ajout de format : l'origine
`TRADE` d'un Pokémon (énumération ; lecture tolérante des anciennes sauvegardes, à vérifier en 25.0).

## 12. Cas limites et anti-duplication

| Cas | Résultat attendu |
|---|---|
| Statue : une porte s'ouvre, une autre se ferme | Toujours une issue (contrôle `plan_check_manoir.py`) |
| Chute | Case praticable, jamais dans une pièce fermée dans les deux états |
| Sauvegarde dans le Manoir, interrupteur MARCHE | Rechargé tel quel ; remis à ARRÊT seulement en rentrant depuis l'île |
| Corde Sortie / Tunnel dans le Manoir | Autorisés (RB) ; ramènent devant la porte principale [D] |
| Objets, Clé | Jamais deux fois (drapeaux) ; Clé rendue si perdue (`key_item_repair`) |
| Porte de l'Arène après rechargement | Ouverte (drapeau) |
| Fermeture du jeu pendant le dépôt d'un fossile | Fossile dans le Sac **ou** confié, jamais perdu ni doublé |
| Fermeture pendant la remise du Pokémon ressuscité | Pokémon **ou** `_given`, jamais les deux |
| Deux fossiles | Un seul en cours |
| Échange sans l'espèce | Refus RB, rien ne change |
| Échange du compagnon | Compagnon retiré (règle J11), puis échange |
| Échange répété | Impossible (drapeau) ; réplique RB d'après échange |
| Défaite contre un Dresseur de quiz | Centre ; porte fermée ; question reposée |
| Défaite contre Auguste | Centre ; portes de quiz ouvertes conservées |
| Après le Badge | Aucun déplacement, aucune scène imposée |
| Lecture des journaux | Pokédex inchangé |

## 13. Art, fonds de combat (CB.3) et données

**Cartes peintes** : Manoir 1F, 2F, 3F, B1F (vue générale + plans, comme le J12) ; Labo (hall,
3 salles) ; Arène. Ville : J24.

**Objets de décor** : statue à interrupteur ; portes de grille (2 états) ; trous ; carnet sur
pupitre ; machine de quiz ; herses de l'Arène (2 états) ; machine de résurrection ; photo du
Dr Fuji ; PC.

**PNJ peints** : Pillard (nouveau), Intello (vérifier si une planche existe déjà), Scientifique
(existe ? à vérifier), Papi, Beauté, guide de l'Arène, **Auguste** (personnage + carte de
Champion).

**Fonds de combat CB.3** : `manoir_salle` (salon brûlé, poussière, lumière de fenêtre) et
`arene_cramois` (roche volcanique, lueur). Aucun pour le Labo (aucun combat).

**Espèces à créer** (absentes de toutes les branches ; illustration officielle de face déjà là
pour les 151) :

| Rôle | Espèces | Dos peint ? |
|---|---|---|
| Sauvages ou reçues (le joueur peut les avoir) | Ponyta, Galopa, Tadmorv, Grotadmorv, Smogogo, Magmar, Électrode, Otaria, **Lamantine** (Otaria évolue au 34), Kabuto, **Kabutops**, Amonita, **Amonistar**, Ptéra | oui (14) |
| Adversaires seulement | aucune de plus (Salamèche, Reptincel, Magnéti, Magnéton, Voltorbe, Caninos, Goupix, Feunard, Arcanin existent sur `main` ou les branches) | — |
| Demandée par un échange | Mimitoss (J22/J23) | — |

C'est le plus gros lot d'espèces depuis le J12 : **14 dos**, à lancer dès 25.0 (pipeline X/Y
repeint, `pokemon-art-source`).

**Capacités** : Déflagration (nouvelle), Bélier (contrecoup), Écrasement (`jalon-20`), Blizzard et
Lance-Soleil (si CT14/CT22 gardées), plus les capacités de montée de niveau des nouvelles espèces
(audit en 25.0 : tout ce qui est « sans effet » est listé et remplacé ou créé).

## 14. Découpage proposé (X-24)

| Lot | Contenu | Validation |
|---|---|---|
| **25.0** | Données (espèces, capacités, objets, Dresseurs, rencontres, textes) ; logique pure (interrupteur global, chute, échange, transaction des fossiles, quiz) et tests ; grilles + `plan_check_manoir.py` ; vues peintes ; lots d'art (14 dos, PNJ, décors, 2 fonds) ; simulation d'Auguste | captures + grilles relues |
| **25A** | Manoir complet : 4 étages, escaliers, **trous**, **interrupteurs et portes**, journaux, objets, Clé, Dresseurs, rencontres | S24 (système : portes + chutes) |
| **25B** | Laboratoire : **échanges** et **fossiles** ; Vieil Ambre à Argenta | S24 **seul** (risque de duplication, règle 1) |
| **25C** | Arène : porte à Clé, quiz, Dresseurs, Auguste, Badge Volcan, CT38 ; clôture | S24 |

La V2 séparait le Manoir en deux lots (A : étages ; B : statues) : impossible de valider des étages
qu'on ne peut pas parcourir sans les interrupteurs. Sauvegardes et tests (V2 25F) vont **dans chaque
lot**, pas à la fin.

## 15. Tests et QA

- **Logique** (GUT) : interrupteur global (bascule, remise à ARRÊT à l'entrée, chargement) ;
  portes A/B synchronisées (image + collision) ; chute (case d'arrivée, compagnon) ; échange (espèce
  exacte, refus, surnom, niveau, compagnon, drapeau, une seule fois, atomicité) ; fossiles (chaque
  transition, fermeture simulée entre chaque étape, deux fossiles, réparation) ; quiz (bonne,
  mauvaise, Dresseur battu/non battu, défaite) ; porte à Clé ; Badge, CT38 unique.
- **Grilles** : `plan_check_manoir.py` (atteignabilité, anti-blocage, chutes), contrôles habituels
  des intérieurs.
- **Sauvegarde** : rechargement à chaque état de la transaction des fossiles et de l'échange.
- **Équilibrage** : simulation d'Auguste (cible 35–60 %) et des Dresseurs (≤ 80 %).
- **QA téléphone** bornée (~30–45 min, départs de débogage) par lot ; captures relues.

## 16. Hors du J25

Mewtwo, Grotte Azurée, Sulfura (seulement évoqué), Îles Écume et Artikodin (J24), Route 21 (J24),
Giovanni (J26), Métronome (si X-13 = B), vitamines, système d'obéissance, bonus d'expérience des
échanges, Cordon d'échange (`trade_cord` : toujours sans source).

## 17. Arbitrages

| N° | Sujet | Options | Recommandation |
|---|---|---|---|
| **X-1** | Numéro et nom du dossier | — | **28**, `dossier-28-cramois-ile.md`, branche `docs/dossier-28-j25`. |
| **X-2** | Base de travail | **A** : 25.0 tout de suite, cartes après une branche d'intégration contenant le J24 · **B** : attendre la conception du J24 pour tout | **A**. La ville et ses portes viennent du J24 ; le J25 lui demande seulement les cinq portes RB (§2). |
| **X-3** | Vieil Ambre | **A** : RB : porte arrière du Musée d'Argenta derrière un arbre à Couper, scientifique qui le donne (le J25 modifie la carte d'Argenta) · **B** : la porte « LABORATOIRE » existante s'ouvre au retour du joueur, sans Coupe · **C** : pas de Vieil Ambre au J25 | **A**, conforme à la V2 (« Accès avec Coupe »). Nom corrigé en **« Vieil Ambre »** dans le dossier 12. |
| **X-4** | Échelle du Manoir et de l'Arène | **A** : grille RB 1:1 · **B** : × 1,5 comme les routes | **A** : un donjon d'intérieur reste lisible à 1:1 (30 cases ≈ 1,2 écran de large) ; × 1,5 donnerait 45 × 42 par étage. |
| **X-5** | Interrupteurs | **A** : RB : un drapeau global, deux jeux de portes par étage · **B** : un interrupteur par étage, indépendant | **A**, vérifié (§4.3). Remise à ARRÊT en entrant depuis l'île. |
| **X-6** | Trous | — | Nouveau `Warp` « chute », présentation courte (§4.4). À partager avec la session du J24 (rochers des Îles Écume) : celle qui code la première le livre. |
| **X-7** | Dresseurs du Manoir | **A** : les 6 RB, équipes RB · **B** : moins | **A**, les grilles garantissent au plus un combat inévitable par étage. |
| **X-8** | Rencontres | — | Union Rouge + Bleu (convention du projet), Magmar rare au 3F et B1F (§4.6). |
| **X-9** | Objets | **A** : RB avec vitamines remplacées, Potion Max et Rappel Max en données, CT14 et CT22 gardées si leurs capacités tiennent · **B** : tout remplacer par des objets existants | **A**. Remplacements [D] du §4.7. |
| **X-10** | Lieu du 1ᵉʳ journal | **A** : « Guyana, Amérique du Sud » (RB anglais) · **B** : « une jungle lointaine » (sans pays réel) | **B** : le monde de Kanto 2026 ne cite aucun pays réel. Textes du §5, en lot au dossier. |
| **X-11** | Journaux et Pokédex | **A** : aucun effet sur le Pokédex · **B** : Mew et Mewtwo « vus » | **A** : le secret de Mew reste entier (dossier 04 §17). |
| **X-12** | Porte de l'Arène | — | Clé gardée ; drapeau `cinnabar_gym_unlocked` au premier passage ; réparation de la Clé (§6). |
| **X-13** | CT35 Métronome (salle R. et D.) | **A** : créer Métronome (tirage d'une capacité au hasard parmi les capacités codées) · **B** : scientifique présent, parle de son invention, **sans CT** · **C** : autre CT | **B** : hors V2, et un tirage au hasard parmi les capacités touche tout le moteur. |
| **X-14** | Mail du PC (oiseaux légendaires) | **A** : RB entier, y compris « la caverne près d'Azuria » · **B** : sans la caverne | **A** : une graine discrète pour l'épilogue de Mewtwo (dossier 06), sans nom ni objectif. |
| **X-15** | Règles des échanges | — | Échange sur place, même niveau, surnom VF RB, dresseur d'origine = nom du PNJ, pas de bonus d'expérience ni de désobéissance (§7.2). |
| **X-16** | Fossiles | — | Transaction du §7.3, niveau 30 (RB), un fossile à la fois, sortie sur l'île = prêt. |
| **X-17** | Quiz | — | Questions K26 du §9.2 (sens RB, réponses RB) ; textes en lot au dossier. |
| **X-18** | Capacités d'Auguste | **A** : RB, Hurlement « échoue » · **B** : RB avec **Hurlement → Groz'Yeux** · **C** : coder le changement forcé (G+) | **B** : aucune mécanique nouvelle, aucun tour perdu ; Déflagration et le contrecoup de Bélier créés par données. |
| **X-19** | Badge Volcan | — | Aucun bonus caché ; Grand moment ; CT38 unique. |
| **X-20** | Dresseurs de l'Arène après la victoire | **A** : tous marqués battus (RB) · **B** : restent affrontables | **A** : l'Arène devient calme, comme RB. |
| **X-21** | Niveaux et équilibrage | — | Niveaux RB ; simulation en 25.0 ; écart > cible → question à Kevin, jamais d'adoucissement silencieux. |
| **X-22** | Lot d'espèces | **A** : les 14 dos dès 25.0 · **B** : dos provisoires (placeholders) pour Lamantine, Kabutops, Amonistar | **A**, mais **B** accepté si le pipeline bloque : ces trois-là n'apparaissent qu'après une évolution. |
| **X-23** | Planches PNJ | — | Pillard, Intello, Papi, Beauté, guide, Auguste (vérifier en 25.0 ce qui existe déjà). |
| **X-24** | Découpage | **A** : V2 (25.0 + 6 lots) · **B** : 25.0, 25A Manoir, 25B Labo (seul), 25C Arène | **B** : trois validations S24, la transaction des fossiles et les échanges validés seuls. |

## 18. Suite

À ta réponse : dossier 28 (décisions, plans, textes à valider en un lot : journaux, quiz, Dresseurs,
Labo, Auguste, porte), grilles `tools/plans/manoir_*.txt`, `cramois_labo*.txt`, `cramois_arene.txt`
et leur contrôle, puis plan `docs/tech/jalon-25.md`. En attendant, rien n'est codé.
