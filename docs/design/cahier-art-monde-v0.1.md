# Cahier des charges de l'art du monde — v0.1

> Rédigé par Claude le 2026-10-03 à la demande de Kevin, après la réception des références J7 (`dossier-09-jadielle.md`, « Références visuelles »). Sert au **prototype de faisabilité de Jadielle** (§5).
>
> **Principe posé par Kevin (2026-10-03)** : **pas de nivellement par le bas.** La qualité des références J7 est la **cible**. Le prototype doit répondre à « **comment reproduire cette qualité au cadrage réel du jeu, de façon cohérente et reproductible ?** », jamais à « quelle version simplifiée peut-on faire facilement ? ». Si un pipeline n'atteint pas la cible, on en cherche un meilleur (§3). Un compromis n'est envisagé **qu'après un test réel sur S24**, et seulement s'il est **techniquement nécessaire**. Si un élément paraît faible à côté des autres, on le fait **monter** ; on ne dégrade jamais les autres pour le rejoindre. L'invariant, c'est l'**identité de Kanto 2026**, pas une résolution de sprite fixée avant d'avoir vu le résultat.

Le document distingue trois choses qui ne se négocient pas de la même façon :

| | Nature | Qui décide |
|---|---|---|
| **1. Qualité cible** | ce qu'on veut voir | Kevin, à partir des références |
| **2. Contraintes techniques** | ce que Godot et le S24 imposent **réellement** (mesuré, pas supposé) | les mesures sur S24 |
| **3. Pipeline de production** | comment on fabrique les assets pour atteindre 1 sous 2 | on itère jusqu'à ce que ça marche |

---

## 1. Qualité cible

### 1.1 Références

Les références J7 : `jadielle-vue-generale-v1`, `jadielle-planche-v1`, `centre-pokemon-v1`, `boutique-jadielle-v1`, `route-22-rival-02-v1` (et pour l'éclairage, `bourg-palette-aplus-v1`).

**Point clé : la cible doit se lire au cadrage du jeu.** Le jeu affiche environ **24 × 11 cases** sur le S24 (1 case = 96 px, personnage ≈ 128 px). Sur la vue générale de Jadielle, une case fait environ 17 px : **en jeu, on la voit environ 5,5 fois plus grande.** La vue générale fixe donc la **composition, la densité, la palette et l'ambiance**. Le **niveau de détail** attendu à l'écran est celui des **vignettes rapprochées**, où un personnage mesure à peu près sa taille en jeu :
- ruelle de Jadielle et entrée de la Route 22 (`jadielle-planche-v1`, en bas) ;
- façade du Centre et de la Boutique, salle, comptoirs (vignettes de `centre-pokemon-v1` et `boutique-jadielle-v1`) ;
- cases du storyboard de la Route 22.

**Conséquence** : un asset découpé dans une vue générale n'aura jamais assez de détail. Chaque asset doit être fabriqué **à sa taille d'affichage en jeu, ou plus grand**.

### 1.2 Qualités à atteindre (grille d'évaluation du prototype)

| Famille | Ce qui fait la qualité des références |
|---|---|
| **Lumière** | soleil chaud et bas, ombres portées douces et cohérentes (même direction pour tous les objets), arêtes éclairées sur les falaises et les toits, intérieurs aux lampes chaudes et sol brillant |
| **Sol** | pavés et chemins texturés, transitions organiques herbe / chemin / pavé (pas de bord de tuile visible), petites variations (fleurs, cailloux, herbe qui déborde) |
| **Végétation** | plusieurs essences d'arbres (feuillus ronds, conifères), buissons, massifs fleuris, haies taillées ; volume net avec ombre interne ; densité élevée sans fouillis |
| **Relief** | falaises stratifiées en plusieurs niveaux, escaliers de pierre, murets ; on lit les hauteurs au premier coup d'œil |
| **Bâtiments** | vue de trois quarts du dessus, façades visibles, toits saturés et lisibles (rouge du Centre, bleu de la Boutique), matériaux détaillés (pierre, bois, verre), enseignes et lampadaires |
| **Vie** | habitants en activité, Pokémon dans le décor (Roucool, Rattata), oiseaux, feuillage qui bouge, reflets, petites particules |
| **Personnages** | silhouette lisible, proportions chibi (environ 3 têtes), détails (casquette, sac, chaussures), ombre au sol, animations riches |
| **Cohérence** | tous les assets semblent peints par la même main : angle, échelle, lumière, saturation et finesse du trait identiques |

### 1.3 Ce que la cible n'impose pas

La **géométrie exacte** des images (le jeu décide où passe le joueur ; grille de 96 px, collisions case par case) et les écarts déjà corrigés par le dossier 09 (pas de mer, Pokémon des PNJ, rayons de la Boutique, etc.).

---

## 2. Contraintes techniques (Godot 4.7 + Galaxy S24)

À **mesurer** sur le prototype, pas à supposer. Les chiffres ci-dessous sont des seuils de départ.

| Sujet | Contrainte | Conséquence pour les assets |
|---|---|---|
| Résolution | référence 1920×1080, S24 ~2340×1080 : environ **1 px d'asset = 1 px d'écran** | assets fabriqués **à l'échelle 1:1** du jeu (un arbre de 2,5 cases = environ 240 px de large), source gardée plus grande si possible |
| Grille | case de 96 px, déplacement case par case, tri en profondeur par les pieds | chaque objet a une **empreinte au sol** en cases et une **origine aux pieds** ; le décor peut déborder visuellement de sa case |
| Fluidité | **60 fps** tenus (moyenne ≥ 58, aucun creux hors chargement), comme au J5 | budget de lumières 2D, de couches transparentes et de shaders à mesurer |
| Mémoire | rendu `mobile`, textures compressées ETC2/ASTC | budget de départ : **≤ 300 Mo de textures par carte** (à mesurer) ; atlas pour les petits props |
| Transparence | le S24 paie chaque pixel transparent superposé (*overdraw*) | nombre de couches qui se recouvrent en plein écran à mesurer ; grands aplats opaques quand c'est possible |
| Lumière dynamique | le jeu prévoit un **jour/nuit** (`vision.md`) | **tension à résoudre** : une lumière dorée peinte dans les assets est belle mais figée. Le prototype teste les deux variantes (§5.3) |
| Chargement | les changements de carte ont déjà des creux au J5 | préchargement et taille des textures à surveiller |
| Taille de l'APK | aucune limite fixée | à mesurer ; ce n'est pas un critère de qualité |

---

## 3. Pipeline de production

Les briques sont classées de la plus rapide à la plus exigeante. **On monte d'un cran dès qu'une famille (§1.2) n'atteint pas la cible**, et pas seulement pour cette famille.

### 3.1 Règle de base : un asset = une image dédiée

On ne découpe jamais une planche de concept. Chaque asset est produit **séparément**, selon une fiche fixe :
- **angle** : trois quarts du dessus, le même que les références (à calibrer sur la première série) ;
- **échelle** : taille finale en cases et en pixels, empreinte au sol ;
- **lumière** : direction unique (par exemple soleil en haut à gauche) ; ombres portées **non peintes** (Godot les ajoute, pour qu'elles restent cohérentes) ;
- **fond** : uni, pour le détourage ;
- **style** : une image de référence imposée, la même pour toute la série.

### 3.2 Les briques

| Cran | Brique | Rôle |
|---|---|---|
| A | **Génération individuelle contrôlée** (fiche ci-dessus + gabarit de prompt + image de référence de style) | bâtiments, arbres, props, rochers |
| A | **Traitement automatique** (scripts : détourage, mise à l'échelle 1:1, étalonnage couleur commun, atlas) | rendre la série homogène |
| A | **Sols en textures continues** (textures peintes qui se répètent sans couture), transitions par masques ou shader plutôt que par tuiles à bords | supprimer la grille visible |
| A | **Compositing en couches dans Godot** : sol → ombres de contact et occlusion → props triés → feuillage de premier plan → lumière (teinte globale, lumières 2D, rayons) → particules | profondeur et lumière cohérentes |
| A | **Animation par shader** : vent dans les feuillages et l'herbe, reflets sur les vitres, scintillement des lampes | vie sans dessiner d'images clés |
| B | **Retouche** des assets générés : corrections de forme, raccords, cohérence de lumière | quand la génération seule ne suffit pas |
| B | **Variantes et détails** : plusieurs versions de chaque arbre ou buisson, décalcomanies (fissures, mousse, feuilles mortes) | casser la répétition |
| B | **Lumière avancée** : textures de normales pour les lumières 2D, cartes d'émission (fenêtres et lampes la nuit) | jour/nuit sans perdre la qualité |
| C | **Artiste** (illustrateur, pixel artist) ou **packs premium** retouchés pour s'adapter | si les crans A et B plafonnent sur une famille |

### 3.3 Qui fait quoi

- **Claude** : fiches d'assets et gabarits de prompt, scripts de traitement, intégration Godot (shaders, couches, lumière, animations), mesures sur S24, comparaisons au cadrage réel.
- **Génération d'images** : je ne peux pas générer d'images moi-même dans ce projet. Il faut une source : Kevin via ChatGPT (ou un autre générateur), ou un outil branché plus tard. **À trancher (Q-1).**
- **Kevin** : juge, famille par famille, si la cible est atteinte.

---

## 4. Personnages

**La taille et la technique des personnages ne sont pas fixées** avant le test (décision de Kevin du 2026-10-03). Aujourd'hui : pixel art de 64 px natifs, affiché ×2. Le `CLAUDE.md` et `vision.md` ne seront modifiés qu'**après** la décision.

Le test compare des personnages **au niveau de la cible**, jamais un personnage volontairement appauvri :

| Variante | Description |
|---|---|
| P1 | pixel art **détaillé**, plus grand en natif (autour de 96 à 128 px), animations plus riches |
| P2 | personnage **peint en HD** comme sur les références |
| Repère | le personnage actuel de 64 px, seulement pour mesurer l'écart |

**Le vrai défi de P2** : garder un personnage **identique d'une image à l'autre** (4 directions × marche, course, etc.). Les générateurs d'images y sont faibles. Pistes : pose de référence fixe, découpage en parties animées (*cut-out*), retouche, ou artiste. Le prototype mesure ce coût : un seul cycle de marche vers le bas suffit pour juger.

---

## 5. Prototype de faisabilité : Jadielle

### 5.1 Périmètre

- La **place centrale** de Jadielle : environ 26 × 14 cases (un écran et demi), au cadrage du jeu. On y trouve :
  - l'arbre central et ses massifs, la façade du Centre et de la Boutique ;
  - deux essences d'arbres, une haie, des fleurs, des lampadaires, une clôture ;
  - un escalier de pierre et un dénivelé (falaise basse) ;
  - deux ou trois habitants, Rattata, Roucool.
- **Une scène isolée** (lancement de débogage `--debug-start proto_da_jadielle`), sur une **branche à part**. Elle ne touche ni au J6 ni au code du J7, et n'est pas la vraie carte de Jadielle.
- Pas d'intérieur au premier tour (le Centre et la Boutique suivront si le monde est concluant).

### 5.2 Livrables

1. Captures au **cadrage réel** (Mac et S24), côte à côte avec la vignette de référence la plus proche (§1.1).
2. Grille §1.2 remplie par Kevin : **cible atteinte / pas encore**, par famille.
3. Mesures S24 : fps (moyenne, creux), mémoire des textures, temps de chargement.
4. Le pipeline **réellement** utilisé, documenté de façon à pouvoir le refaire pour la Route 2.

### 5.3 Variantes testées dans la même scène

- **Lumière** : (a) golden hour **peinte** dans les assets ; (b) assets à **lumière neutre** + lumière et teinte de Godot. Si (b) atteint la qualité de (a), le jour/nuit devient gratuit ; sinon on étudie (a) + cartes d'émission pour la nuit.
- **Personnages** : P1 et P2 (§4), avec le repère de 64 px.

### 5.4 Critère de fin

Le prototype est terminé quand **chaque famille est jugée « cible atteinte » par Kevin sur le S24** avec un pipeline reproductible, ou quand une famille a épuisé les crans A et B : on passe alors au cran C (artiste, packs) **pour cette famille**, sans baisser la cible.

### 5.5 Place dans le planning

En parallèle du J6, sans le ralentir : branche séparée, aucune modification du code du jeu, sessions S24 distinctes de la validation des sous-jalons du J6 (règle 1 : jamais trois systèmes à la fois). Le J6 reste prioritaire.

---

## 6. Questions

- **Q-1 — Source des images** : qui génère les assets du cran A ? Kevin via ChatGPT avec mes fiches et gabarits de prompt (proposition par défaut), un autre générateur, ou un artiste dès le départ ?
