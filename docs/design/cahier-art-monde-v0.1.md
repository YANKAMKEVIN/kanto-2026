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

### 1.3 ADN visuel Kanto 2026 (invariant, v1)

Ce bloc est **recopié mot pour mot** dans chaque prompt de production (`fiches-assets/`). On ne le modifie jamais dans un prompt isolé : une évolution donne une **v2** de l'ADN, et la série concernée est réévaluée. Il est aussi la base de la grille §1.2.

```text
ADN VISUEL KANTO 2026 — v1 (à respecter strictement)
- Rendu : illustration 2D peinte numériquement, dans l'esprit d'un RPG Pokémon moderne au rendu « HD-2D peint » : formes simples, lisibles et arrondies, détails fins mais ordonnés. Ni pixel art, ni 3D, ni photo, ni aquarelle, ni cartoon en aplats.
- Perspective : vue de dessus de trois quarts, en projection oblique frontale, sans aucun point de fuite. Les verticales restent strictement verticales et les horizontales strictement horizontales. On voit le dessus des objets et leur face avant (côté sud), jamais leurs côtés. Pas de vue isométrique, pas de rotation. Le sol est vu à plat, comme sur un plan.
- Proportions : légèrement stylisées, trapues et rassurantes. Échelle commune : 1 case de jeu = 1 mètre environ ; un adulte mesure 1,33 case ; une porte simple mesure 1 case de large et 1,5 case de haut.
- Contours : aucun trait noir. Contour fin et doux, d'une teinte plus sombre et plus saturée que la couleur locale, qui s'efface presque du côté éclairé.
- Volumes : trois valeurs nettes par matériau (lumière, ombre propre, reflet ambiant), transitions douces, petits accents de lumière sur les arêtes.
- Matériaux : reconnaissables (bois, pierre, tuile, feuillage, verre) à leur forme et à quelques touches de texture, jamais à une texture photographique.
- Couleurs : chaudes, lumineuses et saturées sans être fluo. Verts allant du vert-jaune ensoleillé au vert sapin. Ombres colorées tirant vers le bleu-vert ou le violet froid, jamais grises ni noires. Couleurs franches pour les toits.
- Texture : pinceau net et propre, légère granularité picturale ; pas de bruit, pas de flou, pas de netteté artificielle.
- Lumière : une seule source, le soleil, en haut à gauche de l'image (la fiche précise la variante).
- Ombres : aucune ombre portée au sol (le jeu l'ajoute lui-même). Les ombres propres et internes (sous le feuillage, sous un avant-toit) sont peintes.
- Isolement : un seul objet, entier, centré, sur fond transparent ; rien autour : ni sol, ni herbe, ni décor, ni personnage.
- Interdits partout : texte, lettres, chiffres, logo (sauf l'emblème demandé), signature, filigrane, cadre, personnage, Pokémon, ombre portée, sol sous l'objet, flou de profondeur, vignettage.
```

**Variantes de lumière** (bloc recopié mot pour mot selon la variante, §5.3) :

```text
LUMIÈRE GH (golden hour) : lumière de fin d'après-midi ; soleil chaud, doré et bas, en haut à gauche ; les faces tournées vers le haut et la gauche sont éclairées en jaune-orangé ; ombres propres bleu-violet ; fin liseré lumineux chaud sur les contours éclairés.
```

```text
LUMIÈRE NE (neutre) : lumière de milieu de journée, diffuse et blanche, venant légèrement du haut à gauche ; volumes conservés par un ombrage doux ; aucune teinte dorée ou orangée, aucun liseré chaud ; ombres propres neutres, légèrement bleutées.
```

### 1.4 Ce que la cible n'impose pas

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

Les briques sont classées de la plus rapide à la plus exigeante. **On monte d'un cran, pour cette famille, dès qu'elle (§1.2) n'atteint pas la cible.** Le cran A est une **méthode de production**, pas un niveau de qualité : un asset qui n'atteint pas les références J7 n'est **jamais** validé « parce que c'est assez bien pour un jeu ». On le corrige, ou on passe au cran B.

### 3.1 Règle de base : un asset = une image dédiée

On ne découpe jamais une planche de concept. Chaque asset est produit **séparément**, selon une fiche fixe :
- **angle** : trois quarts du dessus, le même que les références (à calibrer sur la première série) ;
- **échelle** : taille finale en cases et en pixels, empreinte au sol ;
- **lumière** : direction unique (par exemple soleil en haut à gauche) ; ombres portées **non peintes** (Godot les ajoute, pour qu'elles restent cohérentes) ;
- **fond** : uni, pour le détourage ;
- **style** : l'**ADN visuel** (§1.3) recopié mot pour mot, une référence J7 jointe, puis l'**ancre de style** : dès qu'un asset de la série est validé, il est joint à tous les prompts suivants (« respecte exactement le style de l'image jointe »). On ne génère jamais deux assets avec des prompts indépendants et sans référence commune ;
- **identifiant stable** (`WORLD_TREE_A_01`…) et fichiers nommés `ID_VARIANTE_rN.png` (`WORLD_TREE_A_01_GH_r2.png`) pour demander une correction sans ambiguïté.

Fiches de production : `docs/design/fiches-assets/` (série 01 : place centrale de Jadielle).

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

**Verdict de Kevin (2026-10-03) : personnages et Pokémon PEINTS SIMPLIFIÉS.** Test en mouvement sur S24, côte à côte : héros (marche et course), enfant de Jadielle et son Rattata, en pixel art 64 px ×2 et en peint 128 px. Le peint se fond dans le décor et garde les petits Pokémon lisibles ; les deux pistes étaient industrialisables (planches 4 directions × 4 images générées du premier coup par Codex, découpées par `tools/art/decouper_perso.py`).

Règles de production :
- une planche 4 × 4 par animation (lignes bas, gauche, droite, haut ; colonnes passage, pas gauche, passage, pas droit), même personnage, pieds sur une même ligne ;
- héros 128 px de haut affichés à 1:1, filtre `linear` ; enfant ≈ 108 px ; petit Pokémon ≈ 56 px ;
- l'identité est tenue par une planche de référence jointe (la marche validée sert d'ancre à la course, etc.).

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
