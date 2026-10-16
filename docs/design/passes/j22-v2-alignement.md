# J22 — Les deux chemins vers Parmanie : passe d'alignement de la V2 (ChatGPT)

> Claude, 2026-10-16. **Conception seulement : aucune ligne de code.** V2 reproduite dans
> `j22-v2-chatgpt.md`. Relue contre `vision.md`, la roadmap, le dossier 06, les dossiers et passes des
> J15 à J21 et le code réel des branches `main` (`2bd6bbf7`, J14), `jalon-15` à `jalon-21`, plus
> `j21-t5-donnees`. Audit fait en lecture seule (`git show` / `git grep`), sans rien extraire.
>
> **Faits Rouge/Bleu** : désassemblage `pret/pokered` (`af51989`) ; les fichiers cités sont vérifiés.
> Origine des règles : **RB** Rouge/Bleu · **G3+** génération ultérieure (RFVF surtout) · **K26**
> adaptation de Kanto 2026. **[D]** = valeur par défaut (règle 4 du projet), modifiable sans débat.
>
> Les **7 décisions verrouillées** de la V2 ne sont pas rouvertes. Deux demandent une précision de
> géométrie ou de calendrier (§1). Mes arbitrages sont numérotés **M-1 à M-24** (§17) : les lettres A
> à L et V sont prises. Réponds par numéro ; j'écris ensuite le dossier 25 et le plan `jalon-22.md`.
>
> **Numéro** : 22 = J19, 23 = J20, 24 = J21 → **25 = J22**, branche `docs/dossier-25-j22`. Le prompt
> Safrania du 2026-10-15 sur cette branche est **reporté** (en-tête ajouté) : Safrania reviendra plus tard.

## 0. État réel du dépôt (2026-10-16)

| Point | Constat |
|---|---|
| `main` | `2bd6bbf7`, **J14 terminé**. Sauvegarde **v6**. |
| `jalon-15` | Carmin, Routes 5–6, Pension, sauvegarde **v7**. Pas fusionné dans `main`. |
| `jalon-16` à `jalon-21` | **Chacun part de `jalon-15` séparément** : aucun ne contient l'autre. Coupe (J16), Route 11 et Flash (J17), Lavanville (J18), Tour (J19), Céladopole (J20) et Flûte (J21) ne sont **réunis nulle part**. |
| J20 | Grilles validées, **aucune scène** de Céladopole ni des Routes 7–8. |
| J21 | Codé : `poke_flute_rules.gd`, `flute_target.gd`, données `poke_flute`, `tm39`, `amnesia`, grilles `route_12.txt` (39 × 102), `route_16.txt` (44 × 28), `celadopole_j21.txt`. **Pas de scène** Route 12 ni Route 16, **pas d'espèce Ronflex** (sauf la branche `j21-t5-donnees` : Ptitard, Tentacool, Ronflex). |
| Conception J23 / J24 | Branches `docs/dossier-26-j23` et `docs/dossier-27-j24` créées, **encore vides** (= `main`). |

**Conséquence** : le J22 repose sur sept jalons dont aucun n'est dans `main`. Comme pour les J19 à J21,
le dossier 25 écrira un **contrat d'entrée** (§2). Les données, la logique pure, les grilles, les vues
peintes et l'art peuvent avancer dès la validation ; **les cartes attendent une branche d'intégration
qui réunit J15 → J21** (M-2).

## 1. Les 7 décisions de la V2

| # | V2 | Avis |
|---|---|---|
| 1 | Routes 12 à 18 et Parmanie | Oui. **Taille** : RB compte **56 Dresseurs**, 7 routes, 4 postes, 3 maisons et une ville. C'est le plus gros jalon du projet en surface → découpage M-24. |
| 2 | Deux itinéraires indépendants | Oui, conforme à RB. **Trou dans la géométrie du J21** : depuis Lavanville, la Route 12 nord mène au croisement **sans passer par Ronflex**, qui dort sur la carte de la Route 11 (L-2 du J21). La Route 12 sud serait donc ouverte **sans la Flûte**, ce qui contredit « Ronflex Route 12 : sa disparition ouvre l'accès est ». Le J21 l'a signalé sans trancher (dossier 24 §10.3) → **M-3**. |
| 3 | Pêche fonctionnelle selon les cannes | Oui. **Aucun système de pêche n'existe** (§6). Trois cannes, trois donneurs, une nouvelle famille de tables de rencontres → M-8 à M-11. |
| 4 | Vélo utilisable, Piste Cyclable | Oui. **Ni Bon de Commande, ni objet Bicyclette, ni mode vélo** (§5). La chaîne RB (Carmin → Azuria) touche deux villes déjà livrées → M-4 à M-7. |
| 5 | Difficulté modérée, Dresseurs facultatifs | Oui. RB force beaucoup de combats en couloir (Route 17 surtout) : les plans doivent les rendre évitables → M-14. |
| 6 | Parmanie, Safari et Koga au J23 | Oui. Je propose aussi de réserver au J23 la **Maison du Gardien** (Dents d'Or → Force, quête du Safari) → M-19. |
| 7 | Arrivée libre | Oui. Aucun objectif imposé ; le tableau de bord n'affiche rien de nouveau (M-22). |

## 2. Contrat d'entrée J15 → J21 → J22

Ce que le J22 **suppose livré** (hypothèses ; rien n'est fusionné ni validé sur téléphone) :

| Origine | Élément | État au 2026-10-16 |
|---|---|---|
| J13 (`main`) | Boutique de Vélos d'Azuria, vendeur `cerulean_bike_clerk` (1 000 000 ₽, « Pour regarder. ») | Codé, **décor seulement** (dossier 16 D-11) |
| J15 | Fan Club de Carmin, président (parle de son Ponyta) ; maison du pêcheur de Carmin (« Un jour, je t'apprendrai. ») | Codé sur `jalon-15` ; **ni Bon de Commande ni Canne** (F-8 et V-4 : remise « à la visite suivante », drapeaux `got_bike_voucher`, `got_old_rod` prévus) |
| J16 | Coupe : `field_moves.gd`, buisson `InteractPoint` + drapeau, contrôle CS → Badge Cascade → Pokémon compatible | Codé sur `jalon-16` |
| J17 | Route 11, Ronflex au bout est (`FlagGate` + `InteractPoint` 2 × 2), raccord est vers la Route 12 | Codé sur `jalon-17` ; le drapeau s'appelle encore `snorlax_route_11_awake` (le J21 T20 l'aligne) |
| J18 | Lavanville, bord sud `coming_soon=route_12` | Codé sur `jalon-18` |
| J20 | Céladopole 70 × 46, sortie ouest | Grilles seulement |
| J21 | Poké Flûte (objet clé utilisable, `key_use` prévu T17), deux Ronflex N30 (`*_woken`, `*_caught`, `*_done` ; le `FlagGate` s'ouvre sur `*_done`), Amnésie, **Route 12 nord** jusqu'au croisement (poste et CT39, 4 Pêcheurs), **Route 16 est** (Ronflex, façade du poste porte fermée, voie haute et arbre en décor) | Logique de la Flûte codée ; cartes et Ronflex **pas encore** |
| Système | Drapeaux génériques (`story_flags`), Dresseurs `beaten_<id>` / `lost_<id>`, objets `got_<carte>_item_N`, cachés `got_<carte>_hidden_N`, rebords (`Ledge.DOWN`), eau comme obstacle (`is_water`) | Codé |

**Ce que le J22 ne doit pas toucher** : postes de garde de Safrania (Routes 5 à 8 : règles sans
drapeau, aucune ouverture possible par accident ; aucune carte du J22 ne les borde), Tour Pokémon,
Fuji, Flûte (on la lit, on ne la redéfinit pas).

## 3. Topologie Rouge/Bleu (vérifiée)

Tailles RB en cases ; colonne « × 1,5 » = échelle des grilles du projet (Route 12 nord du J21 :
vue de RB × 1,5, portée de vue 6 = 4 × 1,5).

| Carte | RB (cases) | × 1,5 | Raccords | Contenu RB |
|---|---|---|---|---|
| Route 12 | 20 × 108 | 30 × 162 | N Lavanville · O Route 11 (à hauteur de Ronflex) · S Route 13 | Poste (2F : CT39), **Ronflex (10, 62) au croisement**, 5 Pêcheurs, Jeune Dresseur, Rockeur ; CT16 Jackpot (îlot), Fer ; caché : Hyper Potion ; **maison de la Méga Canne** (11, 77), au sud de Ronflex |
| Route 13 | 60 × 18 | 90 × 27 | N Route 12 · O Route 14 | Labyrinthe de clôtures, 10 Dresseurs ; cachés : PP Plus, Calcium |
| Route 14 | 20 × 54 | 30 × 81 | E Route 13 · O Route 15 | 10 Dresseurs (Ornithologues, Motards) |
| Route 15 | 60 × 18 | 90 × 27 | E Route 14 · O Parmanie | Poste (2F : assistant, **Multi Exp à 50 espèces**, jumelles), 10 Dresseurs, CT20 Frénésie |
| Route 16 | 40 × 18 | 60 × 27 | E Céladopole · S Route 17 | Ronflex (26, 10) ; **poste à deux étages de passage** : voie basse = Piste (Vélo exigé), voie haute = passage à pied ; **maison de Vol** derrière un arbre à Couper ; 6 Dresseurs (Motards, Loubards) |
| Route 17 | 20 × 144 | 30 × 216 | N Route 16 · S Route 18 | **Piste Cyclable** : descente forcée, 10 Dresseurs ; 5 cachés (Super Bonbon, Guérison, PP Plus, Rappel Max, Max Élixir) |
| Route 18 | 50 × 18 | 75 × 27 | N Route 17 · E Parmanie | Poste (Vélo exigé côté Piste), 3 Ornithologues |
| Parmanie | 40 × 36 | 60 × 54 | O Route 18 · E Route 15 · S Route 19 (mer, Surf) | Centre, Boutique, Arène, Parc Safari, Maison du Gardien, Salle de réunion (club du Safari), maison de la Super Canne, maison du grand-père de Léo ; **enclos** du Safari (Leveinard, Kangourex, Ramoloss, Lokhlass, Voltorbe, fossile) |

- **Ronflex de la Route 12 en RB** : il bloque **à la fois** Lavanville → sud et Route 11 → Route 12
  (`data/maps/headers/Route11.asm` : raccord est à la hauteur de Ronflex).
- **Piste Cyclable en RB** (`home/overworld.asm` l. 1827-1833) : sur la Route 17, si le joueur ne
  touche à rien et qu'aucun Dresseur ne le voit, le jeu **simule un appui vers le bas**. On peut aller
  à gauche, à droite et remonter. Descendre du vélo y est impossible (`BIT_ALWAYS_ON_BIKE`) ; le poste
  remet le joueur en selle (`data/maps/force_bike_surf.asm`).
- **Poste de la Route 16** (`text/Route16Gate1F`) : sans vélo, le garde refuse l'accès à la Piste.

## 4. Plans fonctionnels (sans level design)

| Carte | Proposition K26 | Taille [D] |
|---|---|---|
| Route 12 sud | Suite de la grille du J21 au sud du croisement : ponton et berges pêchables, maison de la Méga Canne, 1 Pêcheur, Rockeur, Jeune Dresseur, Fer, Hyper Potion cachée ; virage vers l'ouest | 30 × 70 |
| Route 13 | Clôtures (labyrinthe ouvert, plusieurs passages), herbes hautes, berge pêchable au nord | 90 × 27 |
| Route 14 | Couloir nord-sud, herbes, Dresseurs sur les côtés | 30 × 81 |
| Route 15 | Poste à deux sorties, herbes, CT20 au bout d'un détour | 90 × 27 |
| Route 16 ouest | Poste complet (2 voies), maison de Vol derrière l'arbre (devient coupable), Motards | 60 × 27 (avec la partie est du J21) |
| Route 17 | Piste en **sections** séparées par des **paliers** (zones de repos sans pente), voies latérales, Dresseurs en retrait | 30 × **150** [D, compressée] |
| Route 18 | Partie ouest (sortie de Piste), poste, partie est à pied jusqu'à Parmanie | 75 × 27 |
| Parmanie | Ville + 4 intérieurs ouverts, 3 portes réservées au J23 (M-19) | 60 × 54 |

Les grilles `tools/plans/*.txt` feront foi, comme d'habitude ; vues peintes après la validation des
grilles.

## 5. Vélo et pente

**Ce qui existe** : marche 0,27 s par case, course 0,16 s (`game/world/grid.gd`), rebords (saut
0,40 s), `step_started(kind)` relayé au compagnon. **Ce qui manque** : objet, mode, vitesse, planches,
règles de lieu, pente.

| Règle | Origine | Proposition |
|---|---|---|
| Obtention | RB | Bon de Commande au Fan Club de Carmin → Bicyclette à Azuria (M-4, M-5). Jamais donnée automatiquement. |
| Monter / descendre | RB + K26 | Sac → UTILISER (`key_use` du J21) **et** bouton rond « Vélo » dans le HUD une fois l'objet obtenu (M-6). |
| Vitesse | RB (vélo = 2 × la marche) | **0,12 s par case** [D] ; la touche Course n'a pas d'effet à vélo. |
| Lieux | RB | Extérieurs et grottes ; **pas en intérieur** (« Ce n'est pas le moment ! ») ; entrer dans un bâtiment fait descendre [D]. |
| Compagnon | K26 | **Rentre dans sa Ball** quand le joueur monte, ressort quand il descend (modèle des dalles du J20) (M-7). |
| Rebords | RB | Sautés à vélo comme à pied. |
| Musique | RB | Thème du vélo (intention notée, sons hors périmètre si non produits). |
| Piste : entrée | RB | Poste des Routes 16 et 18 : sans vélo, le garde refuse ; avec, le joueur **sort en selle**. |
| Piste : pente | RB + K26 | Sur la Route 17, sans appui et sans Dresseur en vue, le joueur **avance d'une case vers le bas** au rythme du vélo ; gauche, droite et haut restent libres. Sur les **paliers** (K26), pas de pente (M-13). |
| Piste : descente du vélo | RB | Impossible sur la Route 17 (« Pas de marche à pied sur la Piste ! » [D]). |
| Pas de chrono | V2 | Aucun mini-jeu, aucun temps affiché. |

## 6. Pêche et cannes

**Ce qui existe** : eau comme obstacle (`is_water`), tables de rencontres `grass` et `rubble`
(`encounter_table.gd`), une table par (carte, terrain). **Rien** sur la pêche, les cannes ou l'eau
comme terrain de rencontre.

| Canne | Donneur | RB (vérifié) | Proposition |
|---|---|---|---|
| Canne | Pêcheur de Carmin (`VermilionOldRodHouse`) | Magicarpe N5, toujours | Remise à la **visite suivante** (V-4 du J15) : drapeau `got_old_rod` |
| Super Canne | Frère du pêcheur, **Parmanie** (`FuchsiaGoodRodHouse`) | Poissirène N10 ou Ptitard N10, une touche sur deux | `got_good_rod` |
| Méga Canne | Frère, **Route 12 sud** (`Route12SuperRodHouse`) | Table par carte. Routes 12, 13, 17, 18 : Tentacool 5, Krabby 15, Poissirène 15, Magicarpe 15 ; Parmanie : Poissoroy 23, Krabby, Poissirène, Magicarpe (`data/wild/super_rod.asm`) | `got_super_rod` |

Déroulé [RB, sans mini-jeu, conforme à la V2] : face à une case d'eau **pêchable**, toucher Action
(si une canne est dans le Sac) ou Sac → UTILISER → lancer (animation courte) → attente → « Oh ! Ça
mord ! » → combat sauvage, ou « Rien ne mord… ». **La meilleure canne** est utilisée d'office (M-9).

Terrain : nouveau terrain de rencontre **`water_rod`**, une table par canne : `old_rod` et `good_rod`
**globales** (comme RB), `super_rod` **par carte**, avec une table par défaut [D] pour les cartes
d'eau qui n'en ont pas (M-10). Les cases pêchables : eau bordée par une berge ou un ponton, marquées
dans la grille (M-8).

## 7. Dresseurs

RB : **56 Dresseurs**, niveaux 21 à 34, aucun combat en duo. Classes absentes des données :
**Pêcheur, Motard, Ornithologue, Loubard** (Cue Ball). Jeune Dresseur(se), Beauté et Rockeur existent.

| Route | RB | Équipes RB (résumé) |
|---|---|---|
| 12 sud | 3 (Pêcheur ×1, Jeune Dresseur, Rockeur) | Magicarpe ×2 N24 ; Nidoran♂, Nidorino N29 ; Voltorbe, Électrode N29 |
| 13 | 10 | Ornithologues (Roucool, Piafabec, Rapasdepic), Jeunes Dresseuses (Ptitard ×2 N30 ; Poissirène, Ptitard, Hypotrempe N28…), Beautés, 1 Motard (Smogo ×3) |
| 14 | 10 | 6 Ornithologues (Canarticho N33 ; Doduo…), 4 Motards (Smogo, Tadmorv, Grotadmorv) |
| 15 | 10 | Jeunes Dresseuses (Mélofée N33 ; Boustiflor, Saquedeneu…), Beautés (Bulbizarre, Herbizarre), Ornithologues (Dodrio), Motards (Smogogo) |
| 16 | 6 | Motards (Tadmorv ×4, Smogogo N33), Loubards (Machoc, Férosinge) |
| 17 | 10 | Motards (Grotadmorv N33, Électrode), Loubards (Machopeur N33, Colossinge) |
| 18 | 3 | Ornithologues (Dodrio N34 ; Rapasdepic) |

Format existant : `data/trainers/<carte>.json`, IA `random` ou `smart`, `prize_per_level`, portée de
vue 1 à 8. **Évitable** = géométrie (aucun champ). Les « paires » RB deviennent deux combats voisins
(précédent J15). Proposition : garder les équipes RB, **réduire le nombre** et ne rendre inévitable
qu'un Dresseur par route au plus (M-14, M-15).

## 8. Rencontres sauvages et espèces nouvelles

| Lieu | RB (version Rouge, vérifiée) |
|---|---|
| Routes 12–15 (herbes) | Mystherbe / Ortide, Roucool, **Aéromite**, **Métamorph** (13–15), Boustiflor N28–30, Chétiflor |
| Routes 16–18 (herbes) | Piafabec, Rapasdepic, Rattata, Rattatac, **Doduo** |
| Eau (cannes) | **Magicarpe**, Poissirène, Ptitard, Tentacool, **Krabby**, **Poissoroy** |

**Espèces absentes de toutes les branches** et nécessaires si l'on suit RB (données, capacités, dos
de combat ; l'artwork officiel de face existe pour les 151) :

| Pour | Espèces |
|---|---|
| Rencontres | Magicarpe, Krabby, Poissoroy, Aéromite, Doduo, **Métamorph** (M-12) |
| Dresseurs | Dodrio, Canarticho, Tadmorv, Grotadmorv, Smogogo, Électrode, Machopeur |
| Ailleurs | Ptitard, Tentacool, Ronflex : branche `j21-t5-donnees` (J21) ; Saquedeneu, Kangourex : `jalon-20` |

Soit **13 espèces** à créer (12 sans Métamorph), plus celles des J20–J21 à fusionner. **Métamorph**
exige **Morphing**, une mécanique nouvelle (copie du Pokémon adverse en combat) → M-12. La règle de la
V2 (« pas d'espèce sans données ni art ») est tenue si chaque espèce a ses données, ses capacités et
un dos (le test `test_battle_art.gd` l'exige déjà).

## 9. Objets

| Lieu | RB | Problème | Proposition |
|---|---|---|---|
| Route 12 | CT16 Jackpot (îlot) | Surf exigé | Reste en décor, comme au J21 |
| Route 12 sud | Fer ; Hyper Potion cachée | **Aucune vitamine n'existe** ; Hyper Potion absente | M-16 |
| Route 13 | PP Plus, Calcium cachés | PP Plus et vitamines absents | M-16 |
| Route 15 | CT20 Frénésie ; poste 2F : Multi Exp | Frénésie absente ; **Multi Exp exclue** (`jalon-05.md`) | M-16, M-17 |
| Route 16 | maison : CS02 Vol | **Aucun système de Vol** | M-18 |
| Route 17 | 5 cachés : Super Bonbon, Guérison, PP Plus, Rappel Max, Max Élixir | Guérison et Super Bonbon existent ; les autres non | M-16 |
| Parmanie | Boutique RB : Hyper Ball, Super Ball, Super Potion, Rappel, Total Soin, Super Repousse | Hyper Ball, Rappel, Repousse absents | M-16 |

Règle du projet : **aucun objet pour une mécanique qui n'existe pas**. Créer Hyper Potion et Hyper
Ball ne demande que des données (soin et capture existent). Vitamines, PP Plus, Élixirs, Repousse et
Multi Exp sont des mécaniques.

## 10. Parmanie

| Bâtiment | RB | Proposition |
|---|---|---|
| Centre Pokémon | Soin, PC | Ouvert (modèle existant) |
| Boutique | Voir §9 | Ouverte, stock M-16 |
| Maison de la Super Canne | Frère du pêcheur | Ouverte, **Super Canne** |
| Salle de réunion | Club du Safari (textes) | Ouverte, textes qui **annoncent** le Safari sans l'ouvrir |
| Maison du grand-père | PNJ (textes) | Ouverte [D] |
| Arène de Koga | — | **Façade, porte réservée au J23** (V2) |
| Parc Safari | — | **Entrée visible, porte réservée au J23** (V2) |
| Maison du Gardien | Dents d'Or → CS04 Force | **Réservée au J23** (M-19) |
| Enclos | 6 « vitrines » du Safari | M-20 |
| Sud (Route 19, mer) | Surf | Bord fermé (eau, sans Surf) |

Fermeture des portes réservées : mécanisme `coming_soon` existant (étiquette « À venir » en
développement) [D].

## 11. Dialogues

Les répliques exactes (≈ 120 : 56 Dresseurs avant / après, PNJ, postes, maisons) seront écrites dans
le **dossier 25 §textes**, au ton du projet, après les arbitrages : leur nombre dépend de M-14. Voici
dès maintenant les **textes de système** à valider avec les arbitrages :

| N° | Contexte | Proposition |
|---|---|---|
| S-1 | Monter à vélo | « {player} enfourche la Bicyclette ! » |
| S-2 | Descendre | « {player} descend de la Bicyclette. » |
| S-3 | Vélo en intérieur | « Ce n'est pas le moment de pédaler ! » |
| S-4 | Descente refusée sur la Piste | « Pas de marche à pied sur la Piste Cyclable ! » |
| S-5 | Garde de la Piste, sans vélo | « Désolé ! La Piste Cyclable est réservée aux vélos. » |
| S-6 | Garde de la Piste, avec vélo | « La Piste descend jusqu'à Parmanie. Bonne route ! » |
| S-7 | Lancer la ligne | « {player} lance sa ligne… » |
| S-8 | Touche | « Oh ! Ça mord ! » |
| S-9 | Rien | « Rien ne mord… » |
| S-10 | Pas d'eau pêchable | « On ne peut pas pêcher ici. » |
| S-11 | Président du Fan Club (remise) | « Tiens, prends ça. C'est un Bon pour une Bicyclette. Je n'en ai plus l'usage ! » |
| S-12 | Vendeur d'Azuria (échange) | « Un Bon pour une Bicyclette ? … Elle est à toi ! » |
| S-13 | Pêcheur de Carmin (Canne) | « Je t'avais promis. Voilà ma vieille Canne. Bonne pêche ! » |

## 12. Drapeaux et cas limites (sans changement de version)

Tout passe par le magasin de drapeaux existant : **sauvegarde v7 inchangée**.

| Drapeau | Posé par |
|---|---|
| `got_bike_voucher`, `got_bicycle` | Président du Fan Club ; vendeur d'Azuria (remises idempotentes) |
| `riding_bicycle` | Montée / descente (enregistré : on recharge en selle, comme RB) |
| `got_old_rod`, `got_good_rod`, `got_super_rod` | Les trois pêcheurs |
| `snorlax_route_12_*` ou `snorlax_route_11_*` | J21 (selon M-3) |
| `cut_route_16_tree` | Coupe (J16), arbre de la Route 16 |
| `beaten_<id>`, `lost_<id>` | Dresseurs (existant) |
| `got_<carte>_item_N`, `got_<carte>_hidden_N` | Objets (existant) |

| Cas limite | Comportement attendu |
|---|---|
| Sauvegarde sur la Route 17 | Rechargée **à vélo**, compagnon rentré ; si `riding_bicycle` manque (ancienne donnée), on remet le joueur en selle sur la Piste. |
| Défaite sur la Piste | Retour au dernier Centre, à pied (comme toute défaite). |
| Arrivée à Parmanie par l'est sans vélo | La Route 18 est accessible à pied jusqu'au poste ; le garde refuse la Piste (S-5). |
| Vélo vendu ou perdu | Impossible (objet clé). |
| Bon de Commande avant le J22 | Les parties déjà avancées le reçoivent à la prochaine visite au Fan Club (règle du J15). |
| Ronflex fuit ou bat le joueur | Il se rendort, le passage reste fermé (L-11 du J21). |
| Safrania | Aucun drapeau du J22 n'est lu par les postes de garde. |
| Dresseur battu, objet ramassé | Persistants (existant). |

## 13. Art, animations et fonds de combat

| Poste | Besoin | Coût |
|---|---|---|
| Joueur à vélo | Planche peinte, 4 directions (arrêt + pédalage), garçon et fille si le profil l'exige | **Élevé** : nouvelle pose du personnage principal |
| Pêche | Pose « lancer » et « attente » du joueur, 4 directions, ou une seule pose par direction [D] ; bulle « ! » existante | Moyen |
| Nouvelles classes | Pêcheur, Motard, Ornithologue, Loubard (planches PNJ) | Moyen (4 planches) |
| Nouvelles espèces | 12–13 dos de combat (chaîne X/Y + retouche, ou repli artwork officiel) | Moyen ; Magicarpe a déjà un dos prototype |
| Décors | 7 routes, 4 postes (modèle commun), 3–4 maisons, Parmanie (vues générales peintes) | Élevé, comme chaque jalon |
| Fonds de combat CB.3 | **Aucun fond d'eau n'existe** (le plus proche : `route_11_coast`) | 4 fonds proposés : `route_12_ponton` (eau, utilisé aussi pour la pêche), `route_13_15_prairie`, `route_16_18_piste`, `parmanie_ville` |
| Pokémon du monde | Enclos de Parmanie (M-20) | Selon M-20 |

DA : 2D HD peinte, vue de dessus orthogonale, quatre directions ; ni pixel art, ni isométrie, ni minicarte.

## 14. Découpage proposé

Règle du projet : une validation S24 par sous-jalon, **jamais trois systèmes à la fois**. La V2 met
pêche (22C) et Routes 12–15 (22A) dans deux lots, et le Vélo avec sa Piste (22B) : je propose de
ranger chaque système avec les cartes qui s'en servent (M-24).

| Sous-jalon | Contenu | Systèmes neufs | Validation |
|---|---|---|---|
| **22.0** | Audit (fait ici), grilles, vues peintes, données (espèces, capacités, objets, Dresseurs), logique pure testée sans scène (`BikeRules`, `CyclingSlope`, `FishingRules`, tables `water_rod`) | — | Captures et tests |
| **22A** « le chemin des pêcheurs » | Route 12 sud, 13, 14, 15 et poste ; Canne (Carmin), Méga Canne (Route 12 sud) ; pêche | **Pêche** | S24 |
| **22B** « la Piste » | Bon de Commande, Bicyclette, mode vélo et HUD ; Route 16 ouest et poste, arbre et maison, Routes 17 et 18, poste | **Vélo**, **pente** | S24 |
| **22C** « Parmanie » | Ville, intérieurs, Super Canne, raccords des deux chemins, portes réservées au J23 ; QA de bout en bout par les deux chemins | — | S24 (clôture) |

V2 → proposition : 22.0 → 22.0 ; 22A + 22C → 22A ; 22B → 22B ; 22D → 22C ; 22E (raccords et
persistance) réparti dans chaque lot ; 22F (QA) à la fin de chaque sous-jalon, plus la QA finale de 22C.

## 15. Tests et QA

**Automatisés (GUT)** : règles du vélo (lieux, vitesse, descente impossible sur la Piste, rechargement
en selle) ; pente (dérive seulement sans appui et sans Dresseur en vue, arrêt sur palier) ; pêche
(meilleure canne, tables globales et par carte, repli par défaut, aucune espèce sans données) ;
remises idempotentes (Bon, Bicyclette, trois cannes) ; Ronflex : passage ouvert sur `*_done`
seulement ; **aucun drapeau du J22 ne débloque Safrania** ; **atteindre Parmanie par chaque chemin**
(simulation de grille) ; objets et Dresseurs persistants ; chaque Dresseur évitable sauf ceux marqués
inévitables.

**QA S24** (bornée à 30–45 min, départs de débogage) : un départ par sous-jalon ; Piste descendue au
doigt (confort du joystick, paliers, Dresseurs) ; pêche sur berge et ponton ; vélo dans Céladopole et
refus en intérieur ; arrivée à Parmanie par l'est puis par l'ouest.

## 16. Ce qui reste hors du J22 (et conflits avec le J23)

| Élément | Où |
|---|---|
| Parc Safari, Arène de Koga, Badge Âme | J23 (V2) |
| Maison du Gardien, Dents d'Or, CS04 Force | J23 (M-19) |
| CS02 Vol et voyage rapide | J23, jalon des CS (M-18) |
| Surf, Route 19, îlot de la CT16 | Jalon du Surf |
| Multi Exp, vitamines, Repousse | Mécaniques non prévues (M-16, M-17) |
| Safrania | Jalon de Safrania (prompt reporté) |
| Re-combats de Dresseurs | Non prévus |

**Conflit possible avec le J23** : la Maison du Gardien et la maison de Vol. En les réservant (M-18,
M-19), le J22 ne pose aucun drapeau que le J23 devrait reprendre, sauf `cut_route_16_tree`.

## 17. Arbitrages

| N° | Sujet | Options | Recommandation |
|---|---|---|---|
| **M-1** | Numéro et nom du dossier | — | **25**, `dossier-25-deux-chemins-parmanie.md`, branche `docs/dossier-25-j22`. Prompt Safrania marqué « reporté ». |
| **M-2** | Base de travail | **A** : le code du J22 attend une branche d'intégration J15 → J21 · **B** : le J22 part de `jalon-21` et fusionne lui-même J16 à J20 | **A**. Le J22 touche Carmin (J15), Coupe (J16), Route 11 (J17), Lavanville (J18), Céladopole (J20) et Routes 12 / 16 (J21) : fusionner six branches dans une session de contenu est risqué. 22.0 (données, logique, grilles, art) peut commencer tout de suite. |
| **M-3** | Ce qui ferme la Route 12 sud avant la Flûte | **A** : **déplacer Ronflex au croisement**, sur la carte de la Route 12, comme RB : il bloque à la fois la Route 11 et le sud (rouvre L-2 du J21 ; la Route 12 du J21 n'est pas encore construite et le Ronflex du J17 n'est qu'un `FlagGate` à déplacer) · **B** : garder L-2 et ajouter au sud du croisement un second obstacle lié au même drapeau (artificiel) · **C** : Route 12 sud ouverte sans Flûte (contraire à la V2) | **A**, à décider **avec la session du J21** avant qu'elle ne construise la Route 12. Drapeaux renommés `snorlax_route_12_*` [D]. |
| **M-4** | Bon de Commande | **A** : RB : le président du Fan Club le donne après qu'on a **écouté son histoire** (OUI) · **B** : sans condition à la visite suivante | **A**, conforme au J15 (F-8) : réplique d'écoute courte, puis S-11. |
| **M-5** | Boutique d'Azuria | — | Le vendeur échange le Bon contre la Bicyclette (S-12) ; prix affiché inchangé. La carte d'Azuria (J13, `main`) reçoit une condition, rien d'autre. |
| **M-6** | Monter à vélo sur téléphone | **A** : Sac → UTILISER seulement (RB) · **B** : A + **bouton rond « Vélo »** dans le HUD une fois la Bicyclette obtenue | **B**. Ouvrir le Sac à chaque bâtiment serait pénible au doigt. Le HUD a déjà des boutons ronds (`ui-reference.md`). |
| **M-7** | Compagnon à vélo | **A** : il rentre dans sa Ball · **B** : il suit à la vitesse du vélo | **A**. Pas de planche de course pour le compagnon, et la Piste serait illisible. Il ressort quand le joueur descend. |
| **M-8** | Où pêcher | **A** : toute eau bordant une case praticable · **B** : seulement les cases marquées « pêchable » dans les grilles | **B**, sur les nouvelles cartes **et** sur l'eau des cartes déjà livrées (Carmin, Azuria, Routes 6, 11, 24, 25), avec la table par défaut : la Canne sert dès qu'on l'a. |
| **M-9** | Choix de la canne | **A** : le joueur choisit dans le Sac (RB) · **B** : la meilleure d'office, Action face à l'eau | **B**, plus Sac → UTILISER pour une canne précise. |
| **M-10** | Tables de pêche | **A** : RB exact : Canne et Super Canne globales, Méga Canne par carte · **B** : par carte pour toutes | **A**, avec une table par défaut pour la Méga Canne sur les cartes sans table (RB : Groupe 7). |
| **M-11** | Combat après une touche | — | Combat sauvage ordinaire, fond de combat d'eau (`route_12_ponton`) ; fuite normale. |
| **M-12** | Métamorph (Routes 13–15) | **A** : présent, avec **Morphing** (mécanique nouvelle) · **B** : absent du J22, ses créneaux redistribués ; introduit plus tard | **B**. Le J22 porte déjà deux systèmes ; Morphing touche le moteur de combat (types, statistiques, capacités copiées, image). |
| **M-13** | Pente de la Piste | **A** : RB pur (dérive partout sur la Route 17) · **B** : RB + **paliers** sans pente (V2 « zones de repos ») | **B**, 3 paliers [D] ; la dérive s'arrête quand un Dresseur voit le joueur (RB). |
| **M-14** | Nombre de Dresseurs | **A** : les 56 de RB · **B** : **≈ 40**, en gardant chaque classe et les équipes RB | **B** (« difficulté modérée »). Répartition [D] : 12 sud 3 · 13 7 · 14 7 · 15 7 · 16 5 · 17 8 · 18 3. |
| **M-15** | Combats inévitables | — | Au plus **un** par route, jamais deux de suite ; sur la Piste, Dresseurs en retrait des voies. |
| **M-16** | Objets sans mécanique | **A** : créer les mécaniques (vitamines, PP Plus, Élixirs, Repousse) · **B** : remplacer par des objets existants ou créés par données seulement (Hyper Potion, Hyper Ball, Super Bonbon, Pépite, Guérison) | **B**. Remplacements [D] : Fer → Pépite ; Calcium → Hyper Potion ; PP Plus → Super Bonbon ; Rappel Max et Max Élixir → Guérison et Pépite. Boutique de Parmanie : Hyper Ball, Super Ball, Super Potion, Hyper Potion, Total Soin si l'objet existe [D]. **CT20 Frénésie** : remplacée par une CT existante [D] ou créée par données si sa règle tient dans le moteur (à vérifier en 22.0). |
| **M-17** | Assistant du poste de la Route 15 | **A** : Multi Exp RB (rouvre `jalon-05`) · **B** : assistant présent, **sans cadeau** (texte sur le Pokédex) · **C** : un autre cadeau à 50 espèces (K26) | **B**. Jumelles en décor avec texte. |
| **M-18** | Maison de Vol (Route 16) | **A** : arbre coupable (la V2 cite la Coupe sur la Route 16), maison ouverte, **CS02 réservée au J23** (la fille en parle) · **B** : arbre en décor comme au J21, maison au J23 · **C** : arbre coupable, voie haute ouverte (objet caché, vue sur la Piste), **porte de la maison réservée au J23** | **C**. La Coupe sert, comme le veut la V2, sans promesse vide : le J23 (CS) ouvrira la maison avec le système de Vol. |
| **M-19** | Maison du Gardien | **A** : ouverte, texte incompréhensible (RB) sans quête · **B** : porte réservée au J23 | **B**. Sa quête (Dents d'Or) est dans le Safari. |
| **M-20** | Enclos de Parmanie | **A** : Pokémon peints dans le monde (RB) · **B** : enclos et panneaux sans Pokémon · **C** : 2 enclos animés, les autres en panneaux | **C** [D] : Kangourex (existe au J20) et Ramoloss ; panneaux pour les autres. |
| **M-21** | Classes de Dresseurs | — | Pêcheur, Motard, Ornithologue, **Loubard** (Cue Ball, nom à confirmer) : 4 planches PNJ. |
| **M-22** | Tableau de bord | — | Aucun objectif nouveau (V2 décision 7). |
| **M-23** | Version Rouge / Bleu des rencontres | — | Suivre la convention des jalons précédents (vérifiée en 22.0) [D]. |
| **M-24** | Découpage | **A** : V2 (22.0 + 6 lots) · **B** : **22.0**, **22A** (chemin est + pêche), **22B** (vélo + Piste), **22C** (Parmanie + clôture) | **B**, trois validations S24 ; chaque système neuf est validé avec les cartes qui s'en servent, un seul par sous-jalon sauf la pente, liée au vélo. |

## 18. Suite

1. Kevin tranche M-1 à M-24 (par numéro). **M-3 se décide avec la session du J21.**
2. Claude écrit `docs/design/dossier-25-deux-chemins-parmanie.md` (textes complets, numérotés), puis
   `docs/tech/jalon-22.md`.
3. 22.0 peut commencer dès la validation : grilles, vues peintes, données, logique pure. Les cartes
   attendent la branche d'intégration (M-2).
