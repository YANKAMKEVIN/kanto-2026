# Série 25 — deux chemins vers Parmanie (jalon 22, lumière NE) : personnages, Pokémon, icônes

> Rédigée au **J22 T7–T8** (2026-10-19, branche `j22-t7-art` depuis `jalon-22`). Plan :
> `docs/tech/jalon-22.md` §2.12, §2.15, T7, T8 ; conception : `dossier-25-deux-chemins-parmanie.md`
> §6, §7, §10.3, §15. Génération Codex (Mac, sans API payante), planche de contact pour Kevin :
> `docs/design/reference/serie-25-contact-v1.png`. **Rien n'est intégré** avant sa validation.
>
> **Numéro : 25.** Constaté le 2026-10-19 (`git fetch`, puis `git ls-tree` de toutes les branches
> `origin/*` sous `tools/art` et `docs/design/fiches-assets`) : 01, 06 à 24 pris, 25 libre. À
> revérifier au push (fiche, `tools/art/serie25.py`, `tools/art/prompts/serie25/`).

Outil : `tools/art/serie25.py` (`--prompts`, `--ancres`, `--commandes`, `--contact`, `--manifeste`
qui **affiche** les entrées prévues sans rien écrire, génération par vagues). Prompts versionnés :
`tools/art/prompts/serie25/`, `tools/art/attente/prompts/<NOM>_ATTENTE.txt`. Règle de Kevin pour
Codex : AVEC les ancres (2 essais), puis SANS pièce jointe (2 essais) ; refus consignés dans
`$ART/refus_serie25.log`. Images brutes : `build/art/` de la copie (comme les séries 17 à 19).

**Hors de cette passe** (attendent les grilles du T6) : vues générales des Routes 12 sud à 18 et de
Parmanie, intérieurs, fonds de combat CB.3 (`route_12_ponton`, `route_13_15_prairie`,
`route_16_18_piste`, `parmanie_ville`).

## Liste

**A. Réemplois (rien à générer)**

| Rôle | Modèle existant |
|---|---|
| Pêcheurs Dresseurs (classe `fisherman`) et pêcheur de Carmin | `pecheur` (`haru`) |
| Président du club du Parc Safari (Salle de réunion) | `gentleman` (décision : réemploi) |
| Vieil homme (maison du grand-père) | `vieil_homme` (`old_man`) |
| Membre du club, habitants de Parmanie | modèles existants, choisis à la carte (T19) |

**B. Nouveaux : 18 images**

| Fiche → asset prévu | Rôle | Taille en jeu | Vague |
|---|---|---|---|
| `HEROS_VELO` → `heros_bike_sheet.png` | pédalage 4 directions × 4 images | 128 px (héros) | 1 |
| `HEROS_VELO_ARRET` → `heros_bike_idle_sheet.png` | arrêt en selle, pied gauche au sol | 128 px | 2 |
| `HEROS_PECHE_LANCER` → `heros_fish_cast_sheet.png` | lancer, 4 directions | 128 px + canne | 1 |
| `HEROS_PECHE_ATTENTE` → `heros_fish_wait_sheet.png` | attente, fil tendu, 4 directions | 128 px + canne | 2 |
| `PNJ_MOTARD` + attente → `motard` (`biker`) | Motards (Routes 16 à 18) | 128 px | 1, 2 |
| `PNJ_ORNITHOLOGUE` + attente → `ornithologue` (`bird_keeper`) | Ornithologues | 128 px | 1, 2 |
| `PNJ_LOUBARD` + attente → `loubard` (`cue_ball`) | Loubards (crâne rasé, costaud) | 128 px | 1, 2 |
| `PNJ_PECHEUR_PARMANIE` + attente → `pecheur_parmanie` (`fisher_fuchsia`) | frère cadet, Super Canne | 130 px | 1, 2 |
| `PNJ_PECHEUR_ROUTE12` + attente → `pecheur_route_12` (`fisher_route_12`) | frère aîné, Méga Canne | 130 px | 1, 2 |
| `POKE_KANGOUREX_FIXE` → `kangourex` | enclos de Parmanie : repos / le bébé sort de la poche | 150 px | 1 |
| `POKE_RAMOLOSS_FIXE` → `ramoloss` | enclos : assis / bâille, tête penchée | 64 px | 1 |
| `UI_OBJETS_J22_PLANCHE_A` → `bike_voucher`, `bicycle`, `old_rod`, `good_rod` | icônes du Sac | 256 px | 1 |
| `UI_OBJETS_J22_PLANCHE_B` → `super_rod`, `hyper_potion`, `hyper_ball` | icônes du Sac | 256 px | 1 |

**C. Écrit à la main** : bouton rond « Vélo » du HUD, `tools/art/serie25/bike.svg` (blanc plein,
64 × 64, même famille que `run_shoe.svg`) ; sortie prévue `assets/ui/icons/hud/bike.svg` (plan
§2.4), copiée au T15.

**D. Dos de combat (13 espèces)** : la chaîne documentée (`serie-combat-dos-pilote.md` §7 : rendu
Blender X/Y puis repeint) **ne tourne pas sur ce Mac** : le repeint se fait sur Colab, et seuls les
modèles de Magicarpe sont installés (les 12 autres sont à télécharger depuis The Models Resource).
Repli : **dos provisoires** pixel art 64 px `assets/sprites/pokemon/placeholder/<id>_back.png` (et
`_front.png`), outil `tools/gen_placeholder_battlers_j22.gd`, méthode de
`gen_placeholder_battlers.gd` et de `_j24.gd`. Espèces : `magikarp`, `krabby`, `seaking`, `venonat`
(Mimitoss, ajouté le 2026-10-19 : T4 le crée), `venomoth`, `doduo`, `dodrio`, `farfetchd`, `grimer`,
`muk`, `weezing`, `electrode`, `machoke`. **Magicarpe, Krabby et Poissoroy sont recopiés à
l'identique du J24** (`gen_placeholder_battlers_j24.gd`) : mêmes octets, aucune collision à la fusion.
Le prototype `battle_proto/dos_ia_129.png` (Magicarpe repeint) reste disponible.

## Décisions par défaut (règle 4)

- Joueur : **garçon seul** (`GameState.PLAYER_LOOKS = [&"hero"]`, l'héroïne n'existe pas encore).
- Vélo : bicyclette pliante de ville, **cadre rouge**, garde-boue blancs, sans panier.
- Une seule canne dans l'animation de pêche (gris-bleu, poignée de liège), quelle que soit la canne
  utilisée ; les trois cannes ne se distinguent que dans le Sac (bambou, bleu roi, noir et or).
- Planche vélo : colonnes = cycle de pédalage ; l'arrêt en selle est une planche d'attente 4 × 1
  (plan §2.2 : `idle` = arrêt en selle).
- Pêche : deux planches 4 × 1 (lancer, attente) ; pas d'eau ni de bouchon peints (le jeu les ajoute).
- Frères : même famille que le pêcheur (visage, barbe), couleurs différentes ; le cadet (Parmanie)
  tient une épuisette, l'aîné (Route 12) une canne plantée.
- Kangourex 150 px (plus grand que le héros), Ramoloss 64 px (Rattata 56 px).

## Intégration (après validation de Kevin)

`python3 tools/art/serie25.py --manifeste` affiche les entrées prévues : sections `personnages`,
`attentes`, `pokemon_fixes` du manifeste (en fin), `preparer_menu.PLANCHES_OBJETS_SUIVANTES` (en
fin), looks en fin de `build_character_frames.gd`, SVG du HUD. Les planches du joueur à vélo et à la
pêche dépassent la largeur du héros (vélo, canne) : boîte de cellule à régler sur capture au T14.

## Génération (2026-10-19)

18 images obtenues (vagues 1 et 2, puis Ramoloss en vague 3). **Refus de Codex** (filtre de
sécurité, `build/art/refus_serie25.log`) :
- `POKE_KANGOUREX_FIXE_NE_r1` : 1 refus avec ancres, obtenu au 2e essai avec ancres.
- `POKE_RAMOLOSS_FIXE` : r1 (« Ramoloss, fidèle à son design officiel ») refusé 4 fois (avec et sans
  pièces jointes) ; r2 (« créature de dessin animé … c'est Ramoloss ») refusé 4 fois ; **r3** (ni nom
  ni « Pokémon », réaction sans bouche ouverte) refusé 3 fois puis **obtenu sans pièce jointe** : son
  rendu suit l'artwork officiel plutôt que la main peinte du monde (à juger).

Planche de contact : `docs/design/reference/serie-25-contact-v1.png` (`--contact`).

**Kangourex refait (2026-10-19, branche `j22-t7b-kangourex`)** : Kevin a validé la planche v1 sauf Kangourex (tête casquée grise). Prompt **r2** : ancres = artwork officiel `assets/sprites/pokemon/official/115.png` (design) + Ramoloss r3 et Rattata (rendu), tête brune sans casque, poche crème avec le petit. Codex : limite d'usage à 15 h 20 et 15 h 56 (pas des refus), puis 3 refus avec ancres (`moderation_blocked`), **obtenu sans pièce jointe** (1er essai). r2 retenu ; r3 (sans nom de licence) écrit mais non lancé. Planche `docs/design/reference/serie-25-contact-v2.png` (même mise en page, seul le Kangourex change ; v1 conservée).

## À faire valider par Kevin

1. Héros à vélo : cadre rouge [D] ; les poses de profil du pédalage débordent un peu de leur
   cellule (recadrage à la préparation) ; arrêt en selle, pied gauche au sol.
2. Pêche : une seule canne dans l'animation [D] ; le fil long du lancer (à raccourcir ou couper à la
   préparation ?).
3. Frères pêcheurs : cadet de Parmanie (bob olive, carreaux rouges, épuisette), aîné de la Route 12
   (ciré jaune, bonnet rouge, barbe blanche).
4. Kangourex : r2 (planche v2) à revoir, tête brune sans casque, oreilles un peu pointues ; Ramoloss : rendu « artwork » (r3 sans ancre).
5. Icônes : la Bicyclette a un porte-bagages (le prompt n'en voulait pas) ; le Bon porte un vélo rouge
   et un tampon bleu.
6. Dos de combat : provisoires pixel art (la chaîne Colab n'a pas tourné).

## Intégration (DAF.5, 2e partie, 2026-10-26)

Originaux retrouvés dans `j22-t7b/build/art` (mêmes octets que `j22-t7`, plus Kangourex r2) ; intégrés par
`tools/art/daf5_reliquats.py` et `build_character_frames.gd` (`BIKE`, `POSES`) : héros à vélo (animations
`bike_*` de `player`), héros qui pêche (`fish_cast_*`, `fish_wait_*`, découpe à part : le fil long est gardé,
la canne dépasse dans une cellule plus haute), `biker`, `bird_keeper`, `cue_ball`, `fisher_fuchsia`,
`fisher_route_12`, `pokemon/kangaskhan` et `pokemon/slowpoke` (enclos de Parmanie). Icônes (planches A et B) non
reprises : peintes par la 1re partie du DAF.5. Planche : `fiches-assets/daf-5-reliquats/planche.png`.
