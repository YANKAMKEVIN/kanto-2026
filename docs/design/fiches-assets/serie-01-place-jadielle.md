# Fiches d'assets — série 01 : place centrale de Jadielle

> Prototype de faisabilité (`cahier-art-monde-v0.1.md` §5). Producteur du cran A : **ChatGPT**, piloté par Kevin (décision du 2026-10-03). Fichier **généré** à partir de l'ADN du cahier (§1.3) : l'ADN et les blocs de lumière y sont recopiés **mot pour mot** ; pour les modifier, on modifie le cahier (nouvelle version de l'ADN) puis on régénère ce fichier.
>
> **Le cran A est une méthode, pas un niveau de qualité.** Un asset qui n'atteint pas les références J7 n'est jamais validé « parce que c'est assez bien » : on le corrige (nouvelle révision), ou on passe au cran B pour sa famille.

## Mode d'emploi

1. **Une conversation ChatGPT pour toute la série** (« Kanto 2026 — série 01 »), pour garder le contexte visuel.
2. Pour chaque fiche, dans l'**ordre de production** : joindre les images citées dans « Images jointes », puis coller le prompt **tel quel**. On ne réécrit jamais l'ADN à la main.
3. **Ancre de style** : `WORLD_TREE_A_01` est produit en premier. Une fois validé (GH), il est joint à **tous** les prompts suivants. Le Centre validé devient en plus l'ancre de la Boutique ; les pavés et l'herbe validés, celle des transitions.
4. **Lumière** : chaque objet est produit d'abord en **GH** (golden hour), puis rééclairé en **NE** (neutre) avec le prompt de rééclairage, **dans la même conversation**, pour garder exactement la même forme. Le sol n'est produit qu'en **NE** : un sol plat n'a pas de volume à rééclairer, sa variante GH se fait par étalonnage dans Godot.
5. **Nommage des fichiers** : `ID_VARIANTE_rN.png`, par exemple `WORLD_TREE_A_01_GH_r1.png`, puis `_r2` après une correction. Pour demander une correction : « `WORLD_TREE_A_01_GH_r1` : tronc trop long, feuillage trop saturé ».
6. **Tolérances** : ChatGPT ne respecte pas toujours au pixel près les dimensions, les marges ou la transparence. Je normalise (détourage, recadrage sur le pied, mise à l'échelle 1:1, étalonnage commun). Ce qui doit être juste : **l'angle, les proportions, le style, la lumière, l'absence d'ombre portée et d'éléments interdits**.
7. **Validation** : premier regard de Kevin sur l'image seule, puis **jugement au cadrage du jeu**, dans la scène prototype (grille §1.2 du cahier). C'est le second qui compte.

## Ordre de production

| # | Identifiant | Ancre jointe |
|---|---|---|
| 1 | `WORLD_TREE_A_01` | — (c'est l'ancre) |
| 2 | `WORLD_TREE_B_01` | `WORLD_TREE_A_01` |
| 3 | `WORLD_TREE_CENTRAL_01` | `WORLD_TREE_A_01` |
| 4a–4e | `WORLD_GROUND_HERBE_A_01`, `WORLD_GROUND_PAVE_A_01_CENTRE`, `_BORD`, `_COIN_EXT`, `_COIN_INT` | `WORLD_TREE_A_01`, puis l'herbe et les pavés validés |
| 5 | `WORLD_BLDG_CENTRE_01` | `WORLD_TREE_A_01` |
| 6 | `WORLD_BLDG_BOUTIQUE_01` | `WORLD_BLDG_CENTRE_01` |

---

## WORLD_TREE_A_01 — feuillu rond (arbre courant des villes et des routes)

| | |
|---|---|
| Ordre de production | 1 — c'est l'**ancre de style** de toute la végétation : une fois validé, il est joint à tous les prompts suivants. |
| Production | PNG carré 1024 × 1024, fond transparent. |
| En jeu | 3 × 4 cases (288 × 384 px). Collision : 1 case, celle du pied du tronc. |
| Cadrage de production | Arbre de 940 px de haut (du sommet du feuillage, y ≈ 42, au pied du tronc, y = 982), centré horizontalement, feuillage de 705 px de large au plus. Marge ≥ 40 px partout. |
| Point d'ancrage (pivot) | Centre du pied du tronc : (512, 982) en production → bas-centre de la case de collision en jeu. |
| Angle et orientation | ADN v1 : trois quarts du dessus, oblique frontal, face avant vers le bas de l'image (sud). |
| Matériau | feuillage dense et lumineux, écorce lisse et chaude. |
| Lumière | GH puis NE (rééclairage de la même image). |
| Ombre | aucune ombre portée (Godot) ; ombres internes du feuillage peintes. |
| Fond | transparent. |
| Raccords | aucun raccord de bord ; l'arbre doit pouvoir être répété en rangée sans paraître cloné (variantes WORLD_TREE_A_02/03 plus tard). |
| Couches | une seule image. Le vent est ajouté par un shader dans Godot (pas de couche séparée). |
| Référence J7 | `jadielle-planche-v1` (rue en bas à gauche), `jadielle-vue-generale-v1` (arbres de bordure). |

**Prompt (variante GH)** — joindre les images citées dans « Images jointes » :

```text
Génère UNE seule image : un asset de jeu isolé, pas une scène.

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

LUMIÈRE GH (golden hour) : lumière de fin d'après-midi ; soleil chaud, doré et bas, en haut à gauche ; les faces tournées vers le haut et la gauche sont éclairées en jaune-orangé ; ombres propres bleu-violet ; fin liseré lumineux chaud sur les contours éclairés.

ASSET : WORLD_TREE_A_01 — feuillu rond (arbre courant des villes et des routes)
Format : PNG carré 1024 × 1024, fond transparent.
Cadrage : l'arbre entier mesure 940 px de haut, du sommet du feuillage jusqu'au pied du tronc, qui touche la ligne y = 982 ; il est centré horizontalement ; son feuillage ne dépasse pas 705 px de large ; au moins 40 px de vide transparent tout autour.
Échelle : 1 case de jeu = 235 px dans cette image. L'arbre fait 4 cases de haut et 3 cases de large au plus ; le tronc fait environ 0,35 case de large.
Description : feuillu de parc (type jeune tilleul ou chêne), houppier arrondi formé de 5 à 7 grosses masses de feuillage en boule, bien lisibles, aux contours festonnés en grappes de feuilles ; quelques trouées sombres entre les masses donnent de la profondeur. Tronc court et trapu, brun chaud, visible sur environ 0,9 case sous le feuillage, légère base de racines (moins d'1 case de large) qui s'arrête net, sans sol.
Niveau de détail : feuillage peint par grappes de feuilles (chaque grappe ≈ 25 à 40 px dans cette image), jamais feuille par feuille ; écorce lisse avec quelques stries ; silhouette qui reste lisible réduite à 288 px de large.
Palette indicative : feuillage clair #A8D25A, moyen #5FA03C, ombre #2E6B47, ombre profonde #1F4A4A ; tronc #7A5236, ombre du tronc #4A3326.
Images jointes : jadielle-planche-v1 = référence de style et de matériaux seulement (arbres ronds de la rue, en bas à gauche) ; ne copie ni son cadrage ni sa composition.
Interdit pour cet asset : fleurs, fruits, mousse, oiseaux, sol ou herbe au pied, ombre portée, tronc coupé par le bord de l'image, silhouette trop singulière (l'arbre sera répété en rangée).
```

**Prompt de rééclairage (variante NE)** — dans la même conversation, juste après la validation de la GH :

```text
Reprends exactement l'image précédente : même objet, même silhouette, même cadrage, mêmes détails, même format, même fond transparent. Change UNIQUEMENT la lumière :

LUMIÈRE NE (neutre) : lumière de milieu de journée, diffuse et blanche, venant légèrement du haut à gauche ; volumes conservés par un ombrage doux ; aucune teinte dorée ou orangée, aucun liseré chaud ; ombres propres neutres, légèrement bleutées.
```

---

## WORLD_TREE_B_01 — conifère (sapin des lisières et des routes)

| | |
|---|---|
| Ordre de production | 2. |
| Production | PNG portrait 1024 × 1536, fond transparent. |
| En jeu | 3 × 5 cases (288 × 480 px), feuillage de 2,4 cases de large au plus. Collision : 1 case, celle du pied du tronc. |
| Cadrage de production | Arbre de 1420 px de haut (pointe y ≈ 58, pied du tronc y = 1478), centré, feuillage de 680 px de large au plus. Marge ≥ 50 px. |
| Point d'ancrage (pivot) | Centre du pied du tronc : (512, 1478). |
| Angle et orientation | ADN v1 : trois quarts du dessus, oblique frontal, face avant vers le bas de l'image (sud). |
| Matériau | aiguilles denses, écorce brune. |
| Lumière | GH puis NE. |
| Ombre | aucune ombre portée ; ombres propres entre les étages peintes. |
| Fond | transparent. |
| Raccords | aucun ; répétable en rangée dense (lisière de forêt). |
| Couches | une seule image (vent par shader). |
| Référence J7 | `route-22-rival-02-v1` (sapins de la vue haute), `jadielle-vue-generale-v1` (sapins des bords) ; ancre `WORLD_TREE_A_01`. |

**Prompt (variante GH)** — joindre les images citées dans « Images jointes » :

```text
Génère UNE seule image : un asset de jeu isolé, pas une scène.

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

LUMIÈRE GH (golden hour) : lumière de fin d'après-midi ; soleil chaud, doré et bas, en haut à gauche ; les faces tournées vers le haut et la gauche sont éclairées en jaune-orangé ; ombres propres bleu-violet ; fin liseré lumineux chaud sur les contours éclairés.

ASSET : WORLD_TREE_B_01 — conifère (sapin des lisières et des routes)
Format : PNG portrait 1024 × 1536, fond transparent.
Cadrage : l'arbre entier mesure 1420 px de haut, de la pointe jusqu'au pied du tronc, qui touche la ligne y = 1478 ; il est centré horizontalement ; son feuillage ne dépasse pas 680 px de large ; au moins 50 px de vide transparent tout autour.
Échelle : 1 case de jeu = 284 px dans cette image. L'arbre fait 5 cases de haut et 2,4 cases de large au plus ; le tronc fait environ 0,3 case de large.
Description : sapin stylisé, silhouette en cône franc formée de 5 à 6 étages de branches aux bords en dents arrondies, pointe légèrement souple ; chaque étage projette une ombre propre sur celui du dessous. Tronc visible sur environ 0,4 case sous les branches basses, base qui s'arrête net, sans sol.
Niveau de détail : aiguilles suggérées par touches groupées au bord de chaque étage, jamais une par une ; silhouette lisible réduite à 288 px de large.
Palette indicative : vert sapin clair #6FAF5A, moyen #2F7A4A, ombre #1E5545, ombre profonde #173B40 ; tronc #7A5236, ombre du tronc #4A3326.
Images jointes : WORLD_TREE_A_01 validé = ancre de style : respecte exactement son trait, sa saturation, sa lumière et sa finesse ; route-22-rival-02-v1 = référence des sapins (vue haute) seulement, ne copie ni son cadrage ni son angle.
Interdit pour cet asset : neige, pommes de pin visibles, décorations, oiseaux, sol ou herbe au pied, ombre portée, pointe coupée par le bord de l'image.
```

**Prompt de rééclairage (variante NE)** — dans la même conversation, juste après la validation de la GH :

```text
Reprends exactement l'image précédente : même objet, même silhouette, même cadrage, mêmes détails, même format, même fond transparent. Change UNIQUEMENT la lumière :

LUMIÈRE NE (neutre) : lumière de milieu de journée, diffuse et blanche, venant légèrement du haut à gauche ; volumes conservés par un ombrage doux ; aucune teinte dorée ou orangée, aucun liseré chaud ; ombres propres neutres, légèrement bleutées.
```

---

## WORLD_TREE_CENTRAL_01 — arbre central de la place de Jadielle

| | |
|---|---|
| Ordre de production | 3. |
| Production | PNG portrait 1024 × 1536, fond transparent (corrigé après la r1 : le carré pousse ChatGPT à élargir). |
| En jeu | 5 × 6 cases (480 × 576 px). Collision : 1 case (tronc) ; le massif circulaire qui l'entoure est un autre asset (`WORLD_PROP_PLANTER_01`, série 02) qui porte sa propre collision. |
| Cadrage de production | Arbre de 940 px de haut (sommet y ≈ 42, pied y = 982), centré, 783 px de large au plus. Marge ≥ 40 px. |
| Point d'ancrage (pivot) | Centre du pied du tronc : (512, 982). |
| Angle et orientation | ADN v1 : trois quarts du dessus, oblique frontal, face avant vers le bas de l'image (sud). |
| Matériau | feuillage dense, écorce ancienne et noueuse. |
| Lumière | GH puis NE. |
| Ombre | aucune ombre portée ; ombres internes peintes. |
| Fond | transparent. |
| Raccords | aucun ; asset unique. |
| Couches | une seule image (vent par shader, plus lent que pour les petits arbres). |
| Référence J7 | `jadielle-vue-generale-v1` (arbre de la place), `jadielle-planche-v1` ; ancre `WORLD_TREE_A_01`. |

**Prompt (variante GH)** — joindre les images citées dans « Images jointes » :

```text
Génère UNE seule image : un asset de jeu isolé, pas une scène.

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

LUMIÈRE GH (golden hour) : lumière de fin d'après-midi ; soleil chaud, doré et bas, en haut à gauche ; les faces tournées vers le haut et la gauche sont éclairées en jaune-orangé ; ombres propres bleu-violet ; fin liseré lumineux chaud sur les contours éclairés.

ASSET : WORLD_TREE_CENTRAL_01 — arbre central de la place de Jadielle
Format : PNG carré 1024 × 1024, fond transparent.
Cadrage : l'arbre entier mesure 940 px de haut, du sommet du feuillage jusqu'au pied du tronc, qui touche la ligne y = 982 ; il est centré horizontalement ; il ne dépasse pas 783 px de large ; au moins 40 px de vide transparent tout autour.
Échelle : 1 case de jeu = 157 px dans cette image. L'arbre fait 6 cases de haut et 5 cases de large au plus ; le tronc fait environ 0,6 case de large.
Description : grand feuillu vénérable, point focal de la place : plus vieux, plus ample et plus noble que l'arbre courant. Houppier large en dôme formé de 8 à 10 masses de feuillage, quelques branches maîtresses visibles entre les masses ; tronc épais et légèrement noueux, visible sur environ 1,3 case, base de racines épatée (1,6 case de large au plus) qui s'arrête net, sans sol.
Niveau de détail : même finesse que WORLD_TREE_A_01 une fois réduit au jeu (grappes de feuilles ≈ 15 à 25 px dans cette image) ; écorce plus marquée, quelques nœuds ; silhouette majestueuse et symétrique sans être parfaite.
Palette indicative : feuillage clair #A8D25A, moyen #5FA03C, ombre #2E6B47, ombre profonde #1F4A4A ; tronc #7A5236, ombre #4A3326, écorce claire #9A7050.
Images jointes : WORLD_TREE_A_01 validé = ancre de style : respecte exactement son trait, sa saturation, sa lumière et sa finesse ; jadielle-vue-generale-v1 = référence de l'arbre de la place seulement, ne copie ni son cadrage ni son angle.
Interdit pour cet asset : massif de fleurs, bordure de pierre, banc, guirlandes, lanternes, balançoire, cabane, sol ou herbe au pied, ombre portée, bord de l'image qui coupe l'arbre.
```

**Prompt de rééclairage (variante NE)** — dans la même conversation, juste après la validation de la GH :

```text
Reprends exactement l'image précédente : même objet, même silhouette, même cadrage, mêmes détails, même format, même fond transparent. Change UNIQUEMENT la lumière :

LUMIÈRE NE (neutre) : lumière de milieu de journée, diffuse et blanche, venant légèrement du haut à gauche ; volumes conservés par un ombrage doux ; aucune teinte dorée ou orangée, aucun liseré chaud ; ombres propres neutres, légèrement bleutées.
```

---

## WORLD_GROUND_PAVE_A_01 — sol de la place (pavés, herbe, transitions)

**Ce dont Godot a besoin.** Un terrain à deux matières (herbe / pavé) qui suit la grille de 96 px, sans bord de tuile visible :
- deux **textures continues** (centre de l'herbe, centre des pavés), chacune de 4 × 4 cases pour que la répétition ne se voie pas ;
- les **transitions** : un **bord** droit, un **coin extérieur**, un **coin intérieur**.

Dans Godot, je découpe ces images en tuiles de 96 px pour une **grille duale** (16 combinaisons de coins, 6 formes uniques par rotation). Un sol plat vu de dessus et éclairé de façon neutre se tourne sans fausser la perspective : c'est pourquoi le pavé est **au niveau de l'herbe**, sans bordure surélevée. Les raccords exacts sont faits par script. Si les morceaux générés ne raccordent pas proprement, le même jeu de textures passe dans un **mélange par masque** (shader) : on change de technique, pas de matière.

| | |
|---|---|
| Production | 5 images PNG carrées 1024 × 1024, opaques. |
| En jeu | 384 × 384 px chacune (4 × 4 cases) ; tuiles de 96 px découpées ensuite. Pas de collision (sol marchable). |
| Pivot | coin haut-gauche, aligné sur la grille. |
| Angle | sol vu parfaitement de dessus (ADN v1 : « le sol est vu à plat »). |
| Lumière | **NE seulement** ; GH par étalonnage dans Godot. |
| Ombre | aucune ombre portée ; seul le léger bombé de chaque pavé est peint. |
| Couches | une par image ; les détails (fleurs, cailloux, fissures, mousse) seront des **décalcomanies** séparées (série 02) pour casser la répétition. |
| Référence J7 | `jadielle-planche-v1` (rue au premier plan, en bas à gauche : la plus proche du cadrage du jeu), `jadielle-vue-generale-v1` (place pavée). |

### WORLD_GROUND_HERBE_A_01 — herbe rase raccordable (pelouse entretenue de la ville)

Ordre : 4a. · Production : PNG carré 1024 × 1024, image opaque (pas de transparence). · Raccords : raccordable sur les 4 côtés.

```text
Génère UNE seule image : un asset de jeu isolé, pas une scène.

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

LUMIÈRE NE (neutre) : lumière de milieu de journée, diffuse et blanche, venant légèrement du haut à gauche ; volumes conservés par un ombrage doux ; aucune teinte dorée ou orangée, aucun liseré chaud ; ombres propres neutres, légèrement bleutées.

ASSET : WORLD_GROUND_HERBE_A_01 — herbe rase raccordable (pelouse entretenue de la ville)
Format : PNG carré 1024 × 1024, image opaque, sans transparence : exception à la règle « Isolement » de l'ADN, c'est une texture de sol vue de dessus qui remplit toute l'image.
Cadrage : texture continue qui remplit toute l'image, raccordable sans couture sur ses 4 côtés (le bord gauche continue le bord droit, le bord haut continue le bord bas).
Échelle : l'image représente 4 × 4 cases de jeu ; 1 case = 256 px. Les pavés font en moyenne un tiers de case (60 à 110 px dans cette image).
Description : pelouse rase et entretenue, vue parfaitement de dessus, faite de petites touffes courtes et denses ; légères variations de teinte en larges taches douces.
Niveau de détail : lisible réduit à 384 × 384 px : formes des pavés nettes, joints fins ; brins d'herbe groupés en touffes, jamais un par un ; faible contraste général (le sol reste un fond, les objets posés dessus doivent ressortir).
Palette indicative : herbe claire #8CC251, moyenne #6EAA45, sombre #4F8C3E, creux #3B6E44.
Images jointes : WORLD_TREE_A_01 validé = ancre de style (trait, saturation, finesse) ; jadielle-planche-v1 = référence de l'herbe de la rue (en bas à gauche).
Interdit pour cet asset : fleurs, cailloux isolés, feuilles mortes, flaques, taches ou tout élément remarquable (il se répéterait visiblement) ; bordure surélevée ou trottoir (le pavé est au même niveau que l'herbe) ; perspective ; ombre portée ; vignettage ; éclairage plus fort d'un côté que de l'autre (une texture raccordable doit être éclairée uniformément).
```

### WORLD_GROUND_PAVE_A_01_CENTRE — pavés de la place (centre, raccordable)

Ordre : 4b. · Production : PNG carré 1024 × 1024, image opaque (pas de transparence). · Raccords : raccordable sur les 4 côtés.

```text
Génère UNE seule image : un asset de jeu isolé, pas une scène.

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

LUMIÈRE NE (neutre) : lumière de milieu de journée, diffuse et blanche, venant légèrement du haut à gauche ; volumes conservés par un ombrage doux ; aucune teinte dorée ou orangée, aucun liseré chaud ; ombres propres neutres, légèrement bleutées.

ASSET : WORLD_GROUND_PAVE_A_01_CENTRE — pavés de la place (centre, raccordable)
Format : PNG carré 1024 × 1024, image opaque, sans transparence : exception à la règle « Isolement » de l'ADN, c'est une texture de sol vue de dessus qui remplit toute l'image.
Cadrage : texture continue qui remplit toute l'image, raccordable sans couture sur ses 4 côtés.
Échelle : l'image représente 4 × 4 cases de jeu ; 1 case = 256 px. Les pavés font en moyenne un tiers de case (60 à 110 px dans cette image).
Description : pavage de pierre claire vu parfaitement de dessus : pavés irréguliers aux angles arrondis, de tailles variées, posés en appareil libre ; joints fins et sombres avec un peu de terre ; chaque pavé a un léger bombé (lumière douce en haut à gauche, ombre propre en bas à droite).
Niveau de détail : lisible réduit à 384 × 384 px : formes des pavés nettes, joints fins ; brins d'herbe groupés en touffes, jamais un par un ; faible contraste général (le sol reste un fond, les objets posés dessus doivent ressortir).
Palette indicative : pierre #E2D3B5, #CDBB98, #B8A47F ; joints #8C7A62 ; creux des joints #6E6050.
Images jointes : WORLD_TREE_A_01 validé = ancre de style ; jadielle-planche-v1 = référence des pavés de la rue (premier plan, en bas à gauche) ; jadielle-vue-generale-v1 = place pavée.
Interdit pour cet asset : fleurs, cailloux isolés, feuilles mortes, flaques, taches ou tout élément remarquable (il se répéterait visiblement) ; bordure surélevée ou trottoir (le pavé est au même niveau que l'herbe) ; perspective ; ombre portée ; vignettage ; éclairage plus fort d'un côté que de l'autre (une texture raccordable doit être éclairée uniformément).
```

### WORLD_GROUND_PAVE_A_01_BORD — transition pavés / herbe (bord droit)

Ordre : 4c. · Production : PNG carré 1024 × 1024, image opaque (pas de transparence). · Raccords : gauche ↔ droite ; bas contre PAVE_CENTRE, haut contre HERBE.

```text
Génère UNE seule image : un asset de jeu isolé, pas une scène.

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

LUMIÈRE NE (neutre) : lumière de milieu de journée, diffuse et blanche, venant légèrement du haut à gauche ; volumes conservés par un ombrage doux ; aucune teinte dorée ou orangée, aucun liseré chaud ; ombres propres neutres, légèrement bleutées.

ASSET : WORLD_GROUND_PAVE_A_01_BORD — transition pavés / herbe (bord droit)
Format : PNG carré 1024 × 1024, image opaque, sans transparence : exception à la règle « Isolement » de l'ADN, c'est une texture de sol vue de dessus qui remplit toute l'image.
Cadrage : texture qui remplit toute l'image, raccordable sans couture de gauche à droite ; le bord bas doit pouvoir se poser contre WORLD_GROUND_PAVE_A_01_CENTRE et le bord haut contre WORLD_GROUND_HERBE_A_01.
Échelle : l'image représente 4 × 4 cases de jeu ; 1 case = 256 px. Les pavés font en moyenne un tiers de case (60 à 110 px dans cette image).
Description : moitié basse de l'image : les pavés de WORLD_GROUND_PAVE_A_01_CENTRE ; moitié haute : l'herbe de WORLD_GROUND_HERBE_A_01 ; la frontière suit la ligne horizontale du milieu (y = 512, à ± 40 px près) avec un tracé doux et irrégulier : quelques touffes d'herbe débordent sur les premiers pavés, quelques pavés de bordure sont légèrement déchaussés et laissent voir un peu de terre. Pavé et herbe sont au même niveau (aucune marche).
Niveau de détail : lisible réduit à 384 × 384 px : formes des pavés nettes, joints fins ; brins d'herbe groupés en touffes, jamais un par un ; faible contraste général (le sol reste un fond, les objets posés dessus doivent ressortir).
Palette indicative : celle de WORLD_GROUND_PAVE_A_01_CENTRE et de WORLD_GROUND_HERBE_A_01 ; terre #8A6B4A.
Images jointes : WORLD_GROUND_PAVE_A_01_CENTRE et WORLD_GROUND_HERBE_A_01 validés : reprends exactement leurs pavés et leur herbe.
Interdit pour cet asset : fleurs, cailloux isolés, feuilles mortes, flaques, taches ou tout élément remarquable (il se répéterait visiblement) ; bordure surélevée ou trottoir (le pavé est au même niveau que l'herbe) ; perspective ; ombre portée ; vignettage ; éclairage plus fort d'un côté que de l'autre (une texture raccordable doit être éclairée uniformément).
```

### WORLD_GROUND_PAVE_A_01_COIN_EXT — transition pavés / herbe (coin extérieur)

Ordre : 4d. · Production : PNG carré 1024 × 1024, image opaque (pas de transparence). · Raccords : les 4 bords se posent contre HERBE, PAVE_CENTRE ou BORD.

```text
Génère UNE seule image : un asset de jeu isolé, pas une scène.

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

LUMIÈRE NE (neutre) : lumière de milieu de journée, diffuse et blanche, venant légèrement du haut à gauche ; volumes conservés par un ombrage doux ; aucune teinte dorée ou orangée, aucun liseré chaud ; ombres propres neutres, légèrement bleutées.

ASSET : WORLD_GROUND_PAVE_A_01_COIN_EXT — transition pavés / herbe (coin extérieur)
Format : PNG carré 1024 × 1024, image opaque, sans transparence : exception à la règle « Isolement » de l'ADN, c'est une texture de sol vue de dessus qui remplit toute l'image.
Cadrage : la frontière touche le bord bas de l'image exactement à x = 512 et le bord droit exactement à y = 512 ; ailleurs, les bords de l'image sont de l'herbe pure (bords haut et gauche) ou des pavés purs (coin bas-droit).
Échelle : l'image représente 4 × 4 cases de jeu ; 1 case = 256 px. Les pavés font en moyenne un tiers de case (60 à 110 px dans cette image).
Description : les pavés n'occupent que le quart bas-droit de l'image ; l'herbe occupe tout le reste. La frontière est la même que dans WORLD_GROUND_PAVE_A_01_BORD (touffes qui débordent, pavés de bordure légèrement déchaussés) et tourne à angle droit avec un arrondi d'environ 77 px de rayon.
Niveau de détail : lisible réduit à 384 × 384 px : formes des pavés nettes, joints fins ; brins d'herbe groupés en touffes, jamais un par un ; faible contraste général (le sol reste un fond, les objets posés dessus doivent ressortir).
Palette indicative : celle de WORLD_GROUND_PAVE_A_01_CENTRE et de WORLD_GROUND_HERBE_A_01 ; terre #8A6B4A.
Images jointes : WORLD_GROUND_PAVE_A_01_BORD validé : même frontière, mêmes pavés, même herbe.
Interdit pour cet asset : fleurs, cailloux isolés, feuilles mortes, flaques, taches ou tout élément remarquable (il se répéterait visiblement) ; bordure surélevée ou trottoir (le pavé est au même niveau que l'herbe) ; perspective ; ombre portée ; vignettage ; éclairage plus fort d'un côté que de l'autre (une texture raccordable doit être éclairée uniformément).
```

### WORLD_GROUND_PAVE_A_01_COIN_INT — transition pavés / herbe (coin intérieur)

Ordre : 4e. · Production : PNG carré 1024 × 1024, image opaque (pas de transparence). · Raccords : les 4 bords se posent contre HERBE, PAVE_CENTRE ou BORD.

```text
Génère UNE seule image : un asset de jeu isolé, pas une scène.

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

LUMIÈRE NE (neutre) : lumière de milieu de journée, diffuse et blanche, venant légèrement du haut à gauche ; volumes conservés par un ombrage doux ; aucune teinte dorée ou orangée, aucun liseré chaud ; ombres propres neutres, légèrement bleutées.

ASSET : WORLD_GROUND_PAVE_A_01_COIN_INT — transition pavés / herbe (coin intérieur)
Format : PNG carré 1024 × 1024, image opaque, sans transparence : exception à la règle « Isolement » de l'ADN, c'est une texture de sol vue de dessus qui remplit toute l'image.
Cadrage : la frontière touche le bord haut de l'image exactement à x = 512 et le bord gauche exactement à y = 512 ; ailleurs, les bords de l'image sont des pavés purs (bords bas et droit) ou de l'herbe pure (coin haut-gauche).
Échelle : l'image représente 4 × 4 cases de jeu ; 1 case = 256 px. Les pavés font en moyenne un tiers de case (60 à 110 px dans cette image).
Description : l'herbe n'occupe que le quart haut-gauche de l'image ; les pavés occupent tout le reste. La frontière est la même que dans WORLD_GROUND_PAVE_A_01_BORD (touffes qui débordent, pavés de bordure légèrement déchaussés) et tourne à angle droit avec un arrondi d'environ 77 px de rayon.
Niveau de détail : lisible réduit à 384 × 384 px : formes des pavés nettes, joints fins ; brins d'herbe groupés en touffes, jamais un par un ; faible contraste général (le sol reste un fond, les objets posés dessus doivent ressortir).
Palette indicative : celle de WORLD_GROUND_PAVE_A_01_CENTRE et de WORLD_GROUND_HERBE_A_01 ; terre #8A6B4A.
Images jointes : WORLD_GROUND_PAVE_A_01_BORD validé : même frontière, mêmes pavés, même herbe.
Interdit pour cet asset : fleurs, cailloux isolés, feuilles mortes, flaques, taches ou tout élément remarquable (il se répéterait visiblement) ; bordure surélevée ou trottoir (le pavé est au même niveau que l'herbe) ; perspective ; ombre portée ; vignettage ; éclairage plus fort d'un côté que de l'autre (une texture raccordable doit être éclairée uniformément).
```

---

## WORLD_BLDG_CENTRE_01 — façade du Centre Pokémon de Jadielle

| | |
|---|---|
| Ordre de production | 4. |
| Production | PNG carré 1024 × 1024, fond transparent. |
| En jeu | 6 × 6 cases (576 × 576 px). Collision : 6 cases de large × 4 de profondeur (les 4 rangées du bas) ; les 2 rangées du haut (toit) passent devant le joueur. Porte : double porte centrée, colonnes 3 et 4 de la rangée du bas (2 cases de large, 1,5 case de haut) ; le déclencheur d'entrée est sur la case devant. |
| Cadrage de production | Bâtiment de 940 × 940 px (x 42 → 982, y 42 → 982) ; ligne de sol de la façade droite et horizontale à y = 982. Marge ≥ 40 px. |
| Point d'ancrage (pivot) | Milieu de la ligne de sol de la façade : (512, 982) → bas-centre de l'emprise en jeu. |
| Angle et orientation | ADN v1 : trois quarts du dessus, oblique frontal, face avant vers le bas de l'image (sud). |
| Matériau | pierre claire, enduit crème, verre, toit en tôle émaillée ou tuiles plates vernissées. |
| Lumière | GH puis NE. |
| Ombre | aucune ombre portée (Godot) ; ombre de l'avant-toit sur la façade peinte. |
| Fond | transparent. |
| Raccords | ligne de sol droite et horizontale, pour poser le bâtiment sur la grille ; tout ce qui est au sol devant (marches, paillasson, pots) est un asset séparé. |
| Couches | une seule image au premier tour. Plus tard (cran B) : porte ouverte séparée (animation d'entrée) et carte d'émission (vitres et appliques allumées la nuit). |
| Référence J7 | `centre-pokemon-v1` (vignette extérieure, en bas à droite : matériaux et couleurs, **pas l'angle**), `jadielle-vue-generale-v1` (toit vu de dessus) ; ancre `WORLD_TREE_A_01`. |

**Prompt (variante GH)** — joindre les images citées dans « Images jointes » :

```text
Génère UNE seule image : un asset de jeu isolé, pas une scène.

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

LUMIÈRE GH (golden hour) : lumière de fin d'après-midi ; soleil chaud, doré et bas, en haut à gauche ; les faces tournées vers le haut et la gauche sont éclairées en jaune-orangé ; ombres propres bleu-violet ; fin liseré lumineux chaud sur les contours éclairés.

ASSET : WORLD_BLDG_CENTRE_01 — façade du Centre Pokémon de Jadielle
Format : PNG carré 1024 × 1024, fond transparent.
Cadrage : le bâtiment entier occupe un carré de 940 × 940 px centré ; le bas de sa façade est une ligne droite et horizontale à y = 982 (c'est la ligne du sol) ; rien ne dépasse sous cette ligne ; au moins 40 px de vide transparent tout autour.
Échelle : 1 case de jeu = 157 px dans cette image. Le bâtiment fait 6 cases de large. Le mur de façade mesure 2,25 cases du sol à l'avant-toit (≈ 353 px) ; le toit, vu de dessus en trois quarts, occupe les 3,75 cases du haut (≈ 588 px). La double porte fait 2 cases de large (≈ 314 px) et 1,5 case de haut (≈ 235 px) ; un adulte devant elle mesurerait ≈ 209 px.
Description : Centre Pokémon compact et accueillant, symétrique. Toit rouge vif légèrement bombé, bordé d'un bandeau blanc ; au-dessus de l'entrée, un grand emblème en forme de Poké Ball (moitié haute rouge, moitié basse blanche, bande et bouton centraux) sur un fronton arrondi. Murs en enduit crème sur un soubassement de pierre plus sombre. Double porte vitrée coulissante encadrée de montants blancs ; de part et d'autre, deux grandes baies vitrées (reflets bleu ciel, intérieur chaud à peine suggéré) ; deux petites appliques murales à côté de la porte.
Niveau de détail : matériaux lisibles à la taille du jeu (576 px de large) : rangées de tuiles ou de plaques du toit, joints de pierre, montants des vitres, reflets. Pas de micro-détail qui deviendrait du bruit une fois réduit.
Palette indicative : toit #D9443A, ombre du toit #9E2B33, lumière du toit #F06A55 ; bandeau #F7F3EA ; murs #F1E6CF, ombre des murs #C9B79A ; soubassement #B9A27F ; verre #8CC8E8, reflet #D8F0FA ; montants #FFFFFF ; emblème rouge #E2483D, blanc #FFFFFF, bande et bouton #3A3F4A.
Images jointes : WORLD_TREE_A_01 validé = ancre de style : respecte exactement son trait, sa saturation, sa lumière et sa finesse ; centre-pokemon-v1 = référence des matériaux et des couleurs du Centre (vignette extérieure, en bas à droite) : elle est vue à hauteur d'homme, garde ses matériaux et ses couleurs mais PAS son angle ; jadielle-vue-generale-v1 = référence de la forme du toit vu de dessus.
Interdit pour cet asset : texte, lettres ou enseigne écrite ; marches, paillasson, pots de fleurs, plantes, lampadaires, bannières, panneaux, arbres, personnages, sol devant ou autour du bâtiment, ombre portée ; vue à hauteur d'homme ou en contre-plongée.
```

**Prompt de rééclairage (variante NE)** — dans la même conversation, juste après la validation de la GH :

```text
Reprends exactement l'image précédente : même objet, même silhouette, même cadrage, mêmes détails, même format, même fond transparent. Change UNIQUEMENT la lumière :

LUMIÈRE NE (neutre) : lumière de milieu de journée, diffuse et blanche, venant légèrement du haut à gauche ; volumes conservés par un ombrage doux ; aucune teinte dorée ou orangée, aucun liseré chaud ; ombres propres neutres, légèrement bleutées.
```

---

## WORLD_BLDG_BOUTIQUE_01 — façade de la Boutique de Jadielle

| | |
|---|---|
| Ordre de production | 5 — **après** la validation du Centre. |
| Production | PNG carré 1024 × 1024, fond transparent. |
| En jeu | 6 × 6 cases (576 × 576 px). Collision : 6 cases de large × 4 de profondeur (les 4 rangées du bas) ; les 2 rangées du haut (toit) passent devant le joueur. Porte : double porte centrée, colonnes 3 et 4 de la rangée du bas (2 cases de large, 1,5 case de haut) ; le déclencheur d'entrée est sur la case devant. |
| Cadrage de production | Bâtiment de 940 × 940 px (x 42 → 982, y 42 → 982) ; ligne de sol de la façade droite et horizontale à y = 982. Marge ≥ 40 px. |
| Point d'ancrage (pivot) | Milieu de la ligne de sol de la façade : (512, 982) → bas-centre de l'emprise en jeu. |
| Angle et orientation | ADN v1 : trois quarts du dessus, oblique frontal, face avant vers le bas de l'image (sud). |
| Matériau | pierre claire, enduit crème, verre, toit en tôle émaillée ou tuiles plates vernissées. |
| Lumière | GH puis NE. |
| Ombre | aucune ombre portée (Godot) ; ombre de l'avant-toit sur la façade peinte. |
| Fond | transparent. |
| Raccords | ligne de sol droite et horizontale, pour poser le bâtiment sur la grille ; tout ce qui est au sol devant (marches, paillasson, pots) est un asset séparé. |
| Couches | une seule image au premier tour. Plus tard (cran B) : porte ouverte séparée (animation d'entrée) et carte d'émission (vitres et appliques allumées la nuit). |
| Référence J7 | `boutique-jadielle-v1` (vignette extérieure, en bas à gauche : matériaux et couleurs, **pas l'angle**), `jadielle-vue-generale-v1` ; ancre `WORLD_BLDG_CENTRE_01`. |

**Prompt (variante GH)** — joindre les images citées dans « Images jointes » :

```text
Génère UNE seule image : un asset de jeu isolé, pas une scène.

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

LUMIÈRE GH (golden hour) : lumière de fin d'après-midi ; soleil chaud, doré et bas, en haut à gauche ; les faces tournées vers le haut et la gauche sont éclairées en jaune-orangé ; ombres propres bleu-violet ; fin liseré lumineux chaud sur les contours éclairés.

ASSET : WORLD_BLDG_BOUTIQUE_01 — façade de la Boutique de Jadielle
Format : PNG carré 1024 × 1024, fond transparent.
Cadrage : le bâtiment entier occupe un carré de 940 × 940 px centré ; le bas de sa façade est une ligne droite et horizontale à y = 982 (c'est la ligne du sol) ; rien ne dépasse sous cette ligne ; au moins 40 px de vide transparent tout autour.
Échelle : 1 case de jeu = 157 px dans cette image. Le bâtiment fait 6 cases de large. Le mur de façade mesure 2,25 cases du sol à l'avant-toit (≈ 353 px) ; le toit, vu de dessus en trois quarts, occupe les 3,75 cases du haut (≈ 588 px). La double porte fait 2 cases de large (≈ 314 px) et 1,5 case de haut (≈ 235 px) ; un adulte devant elle mesurerait ≈ 209 px.
Description : Boutique sœur du Centre Pokémon : même gabarit, même construction, même mur, même soubassement, même double porte ; seuls le toit, l'emblème et les vitrines changent. Toit bleu franc légèrement bombé, bordé d'un bandeau blanc ; au-dessus de l'entrée, un grand emblème en forme de Poké Ball bleue et blanche sur un fronton arrondi. Deux grandes vitrines de part et d'autre de la porte, où l'on devine des rayonnages colorés (formes floues, aucune étiquette lisible) ; deux petites appliques murales.
Niveau de détail : matériaux lisibles à la taille du jeu (576 px de large) : rangées de tuiles ou de plaques du toit, joints de pierre, montants des vitres, reflets. Pas de micro-détail qui deviendrait du bruit une fois réduit.
Palette indicative : toit #3D6FD1, ombre du toit #27489A, lumière du toit #6C95E8 ; bandeau #F7F3EA ; murs #F1E6CF, ombre des murs #C9B79A ; soubassement #B9A27F ; verre #8CC8E8, reflet #D8F0FA ; montants #FFFFFF ; emblème bleu #3D6FD1, blanc #FFFFFF, bande et bouton #3A3F4A.
Images jointes : WORLD_BLDG_CENTRE_01 validé = ancre de style ET de construction : même gabarit, même mur, même porte, même angle, même lumière ; boutique-jadielle-v1 = référence des matériaux et des couleurs de la Boutique (vignette extérieure, en bas à gauche) : elle est vue à hauteur d'homme, garde ses matériaux et ses couleurs mais PAS son angle.
Interdit pour cet asset : texte, lettres ou enseigne écrite ; marches, paillasson, pots de fleurs, plantes, lampadaires, bannières, panneaux, arbres, personnages, sol devant ou autour du bâtiment, ombre portée ; vue à hauteur d'homme ou en contre-plongée ; produits ou étiquettes lisibles en vitrine, présentoirs ou panneaux à l'extérieur.
```

**Prompt de rééclairage (variante NE)** — dans la même conversation, juste après la validation de la GH :

```text
Reprends exactement l'image précédente : même objet, même silhouette, même cadrage, mêmes détails, même format, même fond transparent. Change UNIQUEMENT la lumière :

LUMIÈRE NE (neutre) : lumière de milieu de journée, diffuse et blanche, venant légèrement du haut à gauche ; volumes conservés par un ombrage doux ; aucune teinte dorée ou orangée, aucun liseré chaud ; ombres propres neutres, légèrement bleutées.
```

---

## Journal de production

### WORLD_TREE_A_01 (2026-10-03)

| Révision | Résultat | Décision |
|---|---|---|
| GH_r1 | beau, mais vu de profil, moitié gauche jaune citron, rendu doux façon aérographe, 1:1 au lieu de 3:4, silhouette d'arbre centenaire | refusé ; gardé comme **piste pour WORLD_TREE_CENTRAL_01** |
| GH_r2 | plus vert, tronc plus court, mais plus large que haut (1,09:1) et toujours doux : ChatGPT a **retouché** la r1 au lieu de redessiner | refusé |
| GH_r3 | **nouvelle image** « comme extraite de la référence », format portrait : proportions justes (0,70), contour coloré, rendu graphique proche des références ; verts encore un peu trop jaunes | **candidat ancre**, avec l'étalonnage automatique ci-dessous |

**Leçons, appliquées aux fiches suivantes :**
1. Pour corriger le style ou la forme, demander une **nouvelle image** (« ne retouche pas l'image précédente ») ; la retouche ne sert qu'au **rééclairage NE**, où l'on veut garder la même forme.
2. Formule qui marche le mieux : dessiner l'asset « **comme s'il avait été extrait de l'image jointe, puis agrandi** », avec un recadrage de la référence J7 au plus près de l'objet (`build/art/REF_*.png`).
3. **Format de production proche des proportions de l'asset** : ChatGPT remplit le cadre. Un asset plus haut que large se produit en portrait 1024 × 1536 (la fiche WORLD_TREE_A_01 indiquait un carré : corrigé par la r3).
4. **Étalonnage commun** (cran A, traitement automatique) : les jaunes et les verts-jaunes sont ramenés vers le vert, et les ombres turquoise vers le vert-bleu, pour coller aux verts émeraude des références. Script : `tools/art/etalonner.py` ; réglage : teintes 25–70 (sur 255) tirées de 45 % vers 70, teintes 95–125 tirées de 35 % vers 95, saturation × 0,95.

**Statut** : GH_r3 étalonnée = **ancre de style validée par Kevin** pour continuer la série (verdict final au cadrage du jeu, dans la scène prototype). NE : à produire (le premier envoi était la r3 elle-même).

### WORLD_TREE_B_01 (2026-10-03)

| Révision | Résultat | Décision |
|---|---|---|
| GH_r1 | du premier coup avec l'ancre et la référence recadrée : étages nets, contour coloré, cohérent avec l'arbre A en rangée ; un peu plus trapu que la fiche (0,60 au lieu de 0,48, soit 2,9 cases de large au lieu de 2,4) | **validé** (étalonné) ; un sapin plus élancé viendra en variante `WORLD_TREE_B_02` pour les lisières de forêt (série 02) |

### WORLD_TREE_CENTRAL_01 (2026-10-03)

| Révision | Résultat | Décision |
|---|---|---|
| GH_r1 | du premier coup : majestueux, même main que l'arbre A et le sapin, rapport 0,77 (fiche : 0,83), feuillage qui frôle les bords de l'image sans être coupé | **validé** (étalonné) ; format de la fiche corrigé en portrait 1024 × 1536 (1 case = 183 px) |

### WORLD_GROUND_PAVE_A_01_CENTRE et WORLD_GROUND_HERBE_A_01 (2026-10-03)

Premier essai à l'échelle du jeu : sol en mosaïque 4 × 4 cases + les trois arbres (`build/art/scene_sol_r1.png`, sans ombres ni transitions).

| Révision | Résultat | Décision |
|---|---|---|
| PAVE_CENTRE_NE_r1 | raccords quasi invisibles (écart de bord 6–8 pour 3 entre pixels voisins), matière juste, répétition invisible ; **trop contrasté** à l'écran (le sol concurrence les objets) | **validé** avec un traitement : contraste × 0,7 (réglage final dans Godot, avec la lumière et les ombres) |
| HERBE_NE_r1 | raccords bons, mais **motif en diagonale** qui se répète visiblement en mosaïque, et vert citron (corrigé par l'étalonnage) | refusé → r2 sans orientation dominante |
| HERBE_NE_r2 | plus de bandes visibles en mosaïque, raccords bons (écart de bord 4–10), vert citron corrigé par l'étalonnage | **validé** (étalonné) |

**Comparaison ChatGPT / Weave (2026-10-03, herbe)** : même prompt et même ancre, passés par Kevin dans ChatGPT et par Claude dans Weave (GPT Image 2.5, canevas « KANTO-2026 », 8 crédits gratuits). Weave dessine des touffes plus lisibles et un vert plus naturel, mais sa texture **ne se raccorde pas** (coutures visibles en mosaïque). Le téléchargement depuis Chrome piloté est bloqué : le résultat n'a pu être récupéré que par capture d'écran. **ChatGPT reste le producteur du cran A** ; Weave est gardé en réserve (pistes : touffes isolées en décalcomanies, ou si ChatGPT plafonne sur une famille).

### WORLD_GROUND_PAVE_A_01_BORD (2026-10-03)

| Révision | Résultat | Décision |
|---|---|---|
| NE_r1 | frontière réussie (touffes qui débordent, terre, pavés déchaussés), même matière que les deux sols ; raccord gauche-droite bon (7–10) ; raccords haut et bas imparfaits (14 et 21–28), invisibles après un fondu de 24 px | **validé** ; fondu des raccords et coupe le long des joints à faire dans Godot |

**Correction de l'étalonnage** : la première version verdissait la pierre beige (teinte voisine des jaunes). Le script ne corrige plus que les pixels saturés (≥ 90/255) de teinte 34 à 70 ; la végétation déjà validée est inchangée (écart moyen < 0,2/255).

### WORLD_GROUND_PAVE_A_01_COIN_EXT (2026-10-03) — changement de technique pour les transitions

| Révision | Résultat | Décision |
|---|---|---|
| NE_r1 | beau pris seul, frontière fidèle au bord ; mais le montage avec le bord et les sols (`build/art/test_COIN_EXT_r1.png`) montre deux limites de fond | gardé comme **référence de rendu** |

**Limites constatées** :
1. **Tourner une tuile peinte ne marche pas** : le bord tourné de 90° pour faire un côté vertical couche les touffes sur le flanc et déplace la lumière. Il faudrait 12 transitions peintes séparément (4 bords, 4 coins extérieurs, 4 coins intérieurs), toutes raccordées entre elles : trop fragile avec un générateur.
2. **Chaque génération repeint l'herbe un peu autrement** (plus claire, plus citron que l'herbe validée) : les bords de tuiles se voient.

**Décision (Claude, technique ; prévue par la fiche du sol)** : on garde la matière, on change la technique. Les transitions sont faites **dans Godot** : les deux textures validées sont mélangées par un **masque** à bord irrégulier (shader), avec une fine bande de terre, puis **décorées de décalcomanies** posées le long de la frontière (touffes qui débordent, pavés déchaussés, plaques de terre). Les décalcomanies sont des objets debout ou à plat qui se posent dans toutes les directions sans rotation. Elles sont produites en une planche : `WORLD_GROUND_DECAL_BORD_01`. `COIN_INT` n'est plus produit.

### WORLD_GROUND_DECAL_BORD_01 (2026-10-03)

| Révision | Résultat | Décision |
|---|---|---|
| NE_r1 | **fausse transparence** : le damier gris et blanc est dessiné dans l'image (aucun canal alpha), le détourage laisse des points gris partout ; touffes trop grandes (0,7–1,2 case) et en grosses rosettes, loin des brins fins de VALIDE_BORD ; pavés et plaques de terre justes | refusé → r2 |

**Leçon** : demander explicitement un canal alpha réel et **interdire le damier** ; à défaut, un fond uni magenta `#FF00FF`, facile à détourer par script.
| NE_r2 | **vraie transparence** (canal alpha), touffes fines du même vert que l'herbe validée, pavés et terre justes ; voile presque invisible (alpha < 30) supprimé par script → `VALIDE_DECAL_BORD.png` | **validé** |

Le sol de la place est complet : herbe, pavés, bord (référence de rendu), décalcomanies de bordure.

### WORLD_BLDG_CENTRE_01 (2026-10-03)

| Révision | Résultat | Décision |
|---|---|---|
| GH_r1 | vraie transparence ; forme fidèle à la référence vue de haut (toit à pans coupés, lanterneau, emblème, portail, brique) ; à 6 cases de large la porte (1,1 case de haut) est plus basse qu'un personnage (1,33) et le Centre paraît à peine plus haut qu'un arbre ; rendu plus lisse et « vectoriel » que les arbres, lumière dorée à peine visible | **forme et échelle retenues** ; style à rapprocher des arbres → r2 par **retouche** (la forme est bonne) |

**Défaut d'échelle (règle 4)** : le Centre est affiché sur **8 cases de large** (environ 8 × 6,9 cases ; porte ≈ 1,8 × 1,5 case) au lieu de 6 × 6. Emprise de collision à recalculer dans la scène prototype (8 de large). Même règle pour la Boutique, qui doit rester sœur du Centre.
**À noter pour le sol** : à côté des bâtiments, les pavés paraissent gros ; essai à × 0,7 dans la scène prototype.
| GH_r2 (retouche) | même forme, rendu peint (grain de pinceau, contour coloré), lumière dorée marquée : le Centre et les arbres semblent de la même main ; pavés à × 0,7 plus justes à côté | **validé** |

### WORLD_BLDG_BOUTIQUE_01 (2026-10-03)

| Révision | Résultat | Décision |
|---|---|---|
| GH_r1 | du premier coup avec le Centre validé comme ancre : vraie sœur du Centre (gabarit, construction, rendu, lumière), toit et emblème bleus, auvents rayés, vitrines sans étiquette lisible | **validé** (affichée sur 8 cases comme le Centre) |

## Bilan de la série 01 (2026-10-03)

Validés en lumière GH : `WORLD_TREE_A_01` (r3), `WORLD_TREE_B_01`, `WORLD_TREE_CENTRAL_01`, `WORLD_BLDG_CENTRE_01` (r2), `WORLD_BLDG_BOUTIQUE_01`. Sol (NE) : herbe, pavés, bord (référence), planche de bordure.
**Reste** : les variantes **NE** des cinq objets (pour la comparaison de lumière du prototype, §5.3 du cahier) ; elles se font par retouche de l'image GH validée.
Ce qui a le mieux marché : nouvelle image « comme extraite de la référence » avec un recadrage au plus près de l'objet ; une ancre validée jointe à chaque prompt ; la retouche réservée aux changements de rendu ou de lumière sur une forme déjà juste ; une vraie transparence exigée explicitement.

## Scène prototype v1 (2026-10-03, branche `proto/da-jadielle`)

`proto/da_jadielle/` (scène construite en code, jetable, scène principale de l'APK **sur cette branche seulement**). Textures préparées par `tools/art/preparer_proto.py` depuis `build/art/`. Sol : herbe et pavés (× 0,7) mélangés par un masque de cases à bord bruité + bande de terre (shader), décalcomanies de bordure le long de la frontière ; objets triés par les pieds ; ombres portées = silhouette retournée, écrasée, inclinée vers le bas à droite ; vent par shader sur les arbres ; sol teinté chaud (GH). Joueur = sprite provisoire 64 px ×2, comme repère d'échelle.
**S24** : 59 fps stables, 18 Mo de textures, aucune erreur. Capture : `build/art/proto_s24_v1.png`.
**Tests** : 1 échec attendu sur cette branche seulement, `test_boot.gd::test_main_scene_is_boot` (la scène principale est le prototype) ; tous les autres passent. La branche ne sera jamais fusionnée telle quelle : seuls les documents et les outils d'art en sortiront.

## J7.1 — tranche de la place (décision de Kevin, 2026-10-03)

1. **Ombres** (fait) : `ombre.gdshader`, silhouette floutée (rayon 10 px), écrasée à 0,26, inclinée à 45°, alpha 0,34 au pied s'effaçant vers l'extrémité. À revoir sur S24.
2. Massif autour de l'arbre central, un banc, un lampadaire (série 02, première partie).
3. **Personnage** : test comparatif des deux pistes (pixel art détaillé 64 px / peint simplifié), même personnage, 4 directions et vrai cycle de marche chacun, intégrés tour à tour dans la place et jugés **en mouvement sur S24** (cohérence, lisibilité, fluidité, stabilité entre images, **reproductibilité pour des dizaines de PNJ**). `CLAUDE.md` inchangé : le 64 px reste la règle jusqu'au verdict.
4. Pas de brume, de rayons ni de vignettage ; au plus une légère harmonisation colorimétrique. Bâtiments, végétation et sols **verrouillés**.
5. **Bâtiments « en suspension »** (Kevin, 2026-10-03) : il manquait l'ombre de contact. Ajout de `contact.gdshader` : la base de la silhouette (12 % du bas pour les bâtiments, 5 % pour les arbres) étirée de 18 px vers le bas et floutée, sous l'objet ; elle épouse la vraie forme de la base (angles coupés compris). Une ellipse générique avait été essayée d'abord : trop étroite, invisible sous les bâtiments.

## Génération automatique par Codex (2026-10-03)

L'app ChatGPT de Kevin embarque **Codex** (`/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex`), qui a un outil de génération d'images **compris dans l'abonnement ChatGPT** : aucune clé API, aucune dépense en plus. Script : `tools/art/generer.sh ID prompt.txt [références...]` → `build/art/ID.png` (vraie transparence). Claude génère, analyse et relance seul ; Kevin valide sur les montages.
Premiers essais : `WORLD_TREE_A_01_NE_r1` et `WORLD_TREE_B_01_NE_r1` (rééclairage NE) : même forme, lumière neutre, fond transparent.

## J7.1 — lot généré par Codex (2026-10-03)

| Identifiant | Résultat |
|---|---|
| `WORLD_TREE_CENTRAL_01_NE_r1`, `WORLD_BLDG_CENTRE_01_NE_r1`, `WORLD_BLDG_BOUTIQUE_01_NE_r1` | rééclairages NE fidèles (forme conservée, vraie transparence) |
| `WORLD_PROP_MASSIF_01_GH_r1` | massif circulaire à bordure de pierre, fleurs rouges/jaunes/blanches/violettes, trou central pour le tronc ; posé sous l'arbre central (non étalonné : les fleurs jaunes verdiraient) |
| `WORLD_PROP_BANC_01_GH_r1`, `WORLD_PROP_LAMPADAIRE_01_GH_r1` | banc bois et fonte verte, lampadaire à lanterne ; même rendu que la série |
| `PERSO_P1_PIXEL_r1`, `PERSO_P2_PEINT_r1` | planches de marche 4 directions × 4 images, même personnage (tenue de la référence `ouverture-storyboard-v1` : casquette rouge, t-shirt blanc, sac jaune, jean, baskets rouges ; **défaut pour le test**, règle 4) |

Prompts conservés dans `build/art/prompts/` (non versionné). Découpage des planches : `tools/art/decouper_perso.py` (recalage tête/pieds, réduction commune ; piste 1 : 64 px, palette de 28 couleurs, alpha net ; piste 2 : 128 px lissé).
**Scène** : le personnage d'essai (`marcheur.gd`) fait le tour de la place case par case à la vitesse de marche du jeu (0,27 s par case) ; **toucher l'écran** passe de la piste 1 à la piste 2 puis au repère provisoire. Lumière neutre : `-- --lumiere=ne`.

## Test personnage côte à côte (2026-10-03)

Générés par Codex : `PERSO_P1_COURSE_r1`, `PERSO_P2_COURSE_r1` (cycles de course), `PNJ_ENFANT_P1_r1`, `PNJ_ENFANT_P2_r1` (l'enfant de Jadielle : cheveux noirs, t-shirt vert, short beige, **défaut pour le test**), `POKE_RATTATA_P1_r1`, `POKE_RATTATA_P2_r1`. Tous exploitables du premier coup.
Scène : à gauche la piste 1 (pixel art ×2 ; héros 64 px, enfant 54 px, Rattata 28 px natifs), à droite la piste 2 (peint ; 128, 108, 56 px). Chaque héros marche et **court** sur le bas de son circuit (0,16 s par case) ; l'enfant et son Rattata qui le suit tournent à l'intérieur. Deux arbres du bas retirés pour la lisibilité ; caméra abaissée (7,3 cases). S24 : 58–59 fps, 22,6 Mo de textures.

## Comparaison de lumière sur S24 (cahier §5.3, 2026-10-03)

Toucher l'écran fait défiler 4 modes : **A** golden hour peinte dans les assets ; **B** assets neutres bruts ; **C** assets neutres + golden hour par Godot (`CanvasModulate` chaud) ; **D** assets neutres + fin de journée par Godot (aperçu de ce que permettrait le jour/nuit). Le massif, les bancs et les lampadaires n'existent qu'en GH (petits objets, effet négligeable). Personnages peints des deux côtés. Capture : `build/art/comparaison_lumieres.png`.

**Verdict (Kevin) : méthode C retenue**, A = référence. Calibration v2 (mode « C2 » du prototype) :
1. `etalonnage.gdshader` : gains par zone de luminance mesurés sur les paires GH/NE de la série 01 (ombres ×1,16/1,07/0,97, tons moyens ×1,06/1,01/0,91, hautes lumières ×1,01/0,97/0,85 en RVB), contours sombres laissés neutres ; pas de teinte uniforme ;
2. `objet.gdshader` : **liseré de soleil** doré sur les bords des objets tournés vers le haut-gauche (ce que la teinte d'écran ne crée pas).
Écart moyen à A (somme RVB, capture plein écran) : C v1 42,8 → C2 ≈ 30. Reste à rapprocher : les hautes lumières internes des feuillages (A plus jaune-vert au sommet des masses) ; piste : légère carte de lumière par asset, plus tard.

## Série 02 — personnages du J7 (2026-10-03, lumière NE, peints)

Générés par Codex du premier coup, ancre = planche du héros `PERSO_P2_PEINT_r1` : `PNJ_INFIRMIERE`, `PNJ_MARCHAND`, `PNJ_LIVREUR`, `PNJ_DRESSEUSE`, `PNJ_VIEIL_HOMME` (canne), `PNJ_VOYAGEUR`, `PNJ_RIVAL` (d'après le storyboard `route-22-rival-02-v1`), `POKE_ROUCOOL` (suffixe `_NE_r1`). Tenues = **valeurs par défaut** (règle 4) tirées du dossier 09 §2 et §19, à valider par Kevin. Tailles en jeu : adultes 132–136 px, Dresseuse 126, vieil homme 122, rival 130, Roucool 50.
Scène : Jadielle peuplée (infirmière devant le Centre, marchand devant la Boutique, livreur qui fait sa tournée, Dresseuse et son Roucool près du banc, vieil homme qui fait les cent pas, voyageur qui traverse vers la Route 1, enfant et Rattata, rival, héros qui marche et court). Lumière par défaut : C2.

## Série 03 — intérieurs du Centre et de la Boutique (2026-10-03, lumière NE)

Générés par Codex du premier coup : enveloppes vides `INT_CENTRE_COQUE`, `INT_BOUTIQUE_COQUE` (15 × 10 cases, mur du fond, épaisseurs des murs, entrée de 2 cases en bas, emblème au sol) et meubles isolés `INT_CENTRE_COMPTOIR` (5 cases, machine de soin, sans infirmière ni Leveinard), `INT_CENTRE_TERMINAL` (Stockage Pokémon, écran sans texte), `INT_CENTRE_BANQUETTE`, `INT_PLANTE`, `INT_BOUTIQUE_CAISSE`, `INT_BOUTIQUE_RAYON_MURAL`, `INT_BOUTIQUE_PRESENTOIR` (aucune étiquette lisible). **Méthode** : enveloppe vide + meubles séparés, pour que le jeu décide de l'agencement et des collisions (le plan n'est pas peint dans l'image). Pas d'escalier (dossier 09).
Scène `proto_interieur.gd` ; `proto_visite.tscn` (scène principale de la branche) fait défiler au toucher : place (C2) → Centre → Boutique. Lumière d'intérieur : neutre, très légèrement chaude.
**Corrigé** : paillasson de la Boutique passé en bleu (`INT_BOUTIQUE_COQUE_NE_r2`, retouche). **À reprendre** : une pièce de 15 × 10 cases ne remplit pas la largeur du S24 (bandes noires sur les côtés) : la taille réelle des intérieurs se décidera avec le cadrage du J7A.

## Série 04 — reste de Jadielle (2026-10-03, lumière NE)

Générés par Codex du premier coup, d'après des recadrages de `jadielle-vue-generale-v1` : `WORLD_BLDG_MAISON_A_01` (toit rouge-orangé), `WORLD_BLDG_MAISON_B_01` (toit bleu ardoise), `WORLD_BLDG_ARENE_01` (Arène fermée, bannières sans texte), `WORLD_PROP_HAIE_01` (haie sur muret, raccordable bout à bout), `WORLD_PROP_CLOTURE_01`, `WORLD_PROP_PANNEAU_01` (tableau vierge), `WORLD_PROP_PORTE_NORD_01` (arche de la sortie nord).
Scène `proto_ville.gd` : Jadielle entière (40 × 28 cases) selon le plan du dossier 09 §1 — sortie nord, place entre le Centre et la Boutique, Arène fermée à l'ouest et départ de la Route 22, quartier sud vers la Route 1, maisons, haies, clôtures, forêt sur les bords — avec les habitants ; la caméra fait le tour en 48 s. Premier lieu de la visite. Plan **jetable** : le vrai plan se dessine au J7A. Mac : 100–145 fps.

## Série 05 — Route 22 (2026-10-03, lumière NE)

Générés par Codex : `WORLD_RELIEF_FALAISE_01` (tronçon raccordable), `WORLD_RELIEF_ESCALIER_01`, `WORLD_PROP_ROCHER_01`, `WORLD_GROUND_HAUTES_HERBES_01` (1 case, deux touffes décalées par case dans la scène pour éviter les rangées), `WORLD_GROUND_CHEMIN_01` (terre battue ; saturation × 0,55 et contraste × 0,55 au traitement : trop orangée), `WORLD_DECOR_PLATEAU_INDIGO_01` (fond peint), `POKE_PIAFABEC`, `POKE_FEROSINGE`, `POKE_NIDORAN_F`, `PNJ_JEUNE_DRESSEUR` (casquette blanche et bleue, t-shirt bleu ciel : **défaut**).
`POKE_NIDORAN_M` : r1 ressemblait à un Rattata (la planche de Rattata jointe pour le style a déteint sur la forme), r2 trop pelucheux (ancre Férosinge), **r3** ancré sur Nidoran femelle (bonne forme : corne, oreilles, épines) mais bleu → teinte décalée vers le violet par script (cran B). **Leçon** : pour un Pokémon, joindre comme ancre de style une espèce de forme proche, sinon la forme déteint.
Scène `proto_route22.gd` (46 × 20 cases) : chemin depuis Jadielle (est) vers l'ouest, falaise et escalier vers un niveau supérieur, trois champs d'herbes hautes avec les Pokémon sur leurs bords (dedans, ils sont invisibles), forêt, et au bout le **point de vue sur le Plateau Indigo** où le rival vient de battre le jeune Dresseur (dossier 09 §13). Deuxième lieu de la visite. **Corrigé** : clairière autour des herbes hautes (2 cases, 5 au sud, où les arbres cacheraient le champ) ; fond peint fondu sur ses bords droit et bas, sous la lisière de forêt.

**Collisions du prototype (remarques de Kevin sur S24, 2026-10-04)** : les personnages traversaient bancs, lampadaires, bâtiments et la falaise de la Route 22 (un trou entre deux tronçons, à côté de l'escalier). Ajout de `emprises.gd` : emprise au sol de chaque objet (règles par type ; l'arche nord ne bloque que ses piliers, l'escalier et les herbes hautes se traversent), murs des intérieurs, personnages immobiles ; les marcheurs suivent le plus court chemin libre (`AStarGrid2D`, 4 directions) entre les coins de leur circuit. Falaise complétée : l'escalier est le seul passage. L'escalier est posé dans la couche du sol (non triée) : trié par ses pieds, il passait devant le personnage pendant la montée. Aucun trajet impossible dans les 5 lieux.

## Série 06 — extérieur de Bourg Palette (2026-10-05, lumière NE)

Cible : `reference/bourg-palette-vue-generale-v1.png` (validée par Kevin) et son plan `bourg-palette-plan-v1.png`. Prompts composés par `tools/art/serie06.py` (ADN v1 + LUMIÈRE NE + fiche ; références = recadrages `REF_BP_*` de la vue générale ; ancres de style `WORLD_BLDG_MAISON_A_01_NE_r1`, `WORLD_TREE_A_01_NE_r1`), générés par Codex trois à la fois, **tous exploitables du premier coup** : `WORLD_BLDG_MAISON_JOUEUR_01`, `WORLD_BLDG_MAISON_RIVAL_01` (cheminée à gauche, porte et volets verts : **défaut** pour distinguer les deux maisons), `WORLD_BLDG_LABO_01`, `WORLD_BLDG_SERRE_01`, `WORLD_TREE_ANCIEN_01` (arbre + îlot de fleurs), `WORLD_PROP_CLOTURE_PIQUETS_01`, `WORLD_PROP_VELO_01`, `WORLD_PROP_CAMIONNETTE_01`, `WORLD_GROUND_CHAMP_01`, `WORLD_PROP_PONTON_01`, `WORLD_PROP_RONCES_01`, `WORLD_PROP_TRONC_COUCHE_01`, `WORLD_PROP_ROCHER_MER_01`, `WORLD_RELIEF_ESCALIER_BOIS_01`, `WORLD_GROUND_SABLE_01`, `WORLD_GROUND_EAU_01`, `WORLD_GROUND_ECUME_01` (non utilisé : l'écume est faite par le shader). Repris : arbres A/B, lampadaire, banc, panneau, clôture en bois, falaise, escalier, hautes herbes, chemin, herbe, pavés ; boîte aux lettres et potager du J7.
Scène `proto_bourg.gd` (48 × 34 cases, taille de `pallet_town`) : premier lieu de la visite. Sol à quatre couches (`sol_bourg.gdshader` : pavés, terre, sable, océan qui ondule avec une frange d'écume). **Défauts (règle 4)** : labo 10 cases de large (à 12, il écrasait la place), maisons 6,5 cases ; place ovale 13 × 5,6 cases ; le joueur fait le tour maison → place → parvis du labo → plage. Pas encore de chercheurs ni de vieille dame (le vieil homme du J7 tient le banc). Mac : rendu conforme à la vue générale ; S24 à faire avec la série 07.

## Série 07 — intérieurs de Bourg Palette (2026-10-05, lumière NE)

Méthode de la série 03 (enveloppe vide + meubles isolés), plans du jalon 2 §4.3 à §4.7. Prompts composés par `tools/art/serie07.py` ; références de contenu = anciennes vues (`chambre-joueur-v1`, `ouverture-storyboard-v1`, `maison-rival-v1`, `labo-chen-v1`, rendu pixel à ne pas copier) ; ancres de style = `INT_CENTRE_COQUE` et `INT_CENTRE_BANQUETTE` (série 03). **Enveloppes** : `INT_CHAMBRE_JOUEUR_COQUE` (haut de l'escalier dessiné dans l'ouverture), `INT_MAISON_JOUEUR_RDC_COQUE`, `INT_MAISON_RIVAL_COQUE`, `INT_LABO_COQUE`. **Meubles** : 41 sur 46, tous exploitables du premier coup (bureau d'angle du rival un peu de biais). **Manquent** (limite d'usage Codex atteinte, reprise le 2026-10-06 à 2 h 21) : `INT_MACHINES_LABO`, `INT_TABOURET`, `INT_ESCALIER_DECO`, `INT_TAPIS_ROUGE`, `INT_TAPIS_LABO_POKEBALL` (remplacés dans la scène par le classeur et les tapis des maisons ; escalier du labo absent).
Scène `proto_interieur_bourg.gd` (chambre, rez-de-chaussée, maison du rival, labo) : lieux 2 à 5 de la visite. **Défauts (règle 4)** : aucune peluche ni figurine de Pokémon ; télé de face contre le mur du fond (les plans la mettaient de côté sur le mur est) ; cloisons du rival en meubles (`INT_CLOISON_V`, `INT_CLOISON_H`).

## Série 06B — habillage de Bourg Palette (2026-10-05, en attente de Codex)

Remarque de Kevin : village « un peu simple et vide » ; on peut créer plus de verdure et diversifier. **Fait avec les assets existants** : jardins fermés (clôture blanche devant, haies sur les côtés), plates-bandes devant les façades, fruitiers, linge chez le rival, pots, tonneau, caisses, buissons à l'entrée de la place et le long des allées du labo, massifs, rochers ; forêt à trois essences ; semis de touffes d'herbe et de buissons épars sur les pelouses (`_semis`).
**À générer** (`tools/art/serie06b.py`, prompts aussi dans `prompts-06b/` pour un usage manuel dans ChatGPT) : clôture blanche latérale, 3 arbres (feuillu clair, bouleau, grand chêne), hortensias, jardinière, mangeoire, épouvantail, barque, casiers de pêche, oyats, matériel du labo, râtelier à vélos, brouette, tas de bois, arrosoir et seau, petites pierres, planches de fleurs sauvages et côtières (papillons retirés : aucune faune non-Pokémon) ; habitants : chercheur, chercheuse, pêcheur, vieille dame, jardinière.

**Arbitrages de Kevin (2026-10-06, dossier 01 « Principes d'habillage »)** : nature dense, objets rares, espaces vides gardés. Retirés du prototype : tonneaux, caisses, massifs ronds et pots génériques ; semis de buissons divisé par deux. Lot Codex de la nuit lancé automatiquement à 2 h 25 (`build/art/reprise.sh`, journal `reprise.log`) : série 06B puis les 5 meubles manquants du labo.

**Lot Codex de la nuit (2026-10-06, 2 h 25 → 2 h 41)** : les 24 assets de la série 06B et les 5 meubles du labo, **tous exploitables du premier coup**. Intégrés : 3 nouvelles essences dans la forêt (feuillu clair, bouleau, grand chêne) ; fleurs sauvages semées avec les touffes (16 %) ; fleurs côtières et oyats sur la bande au-dessus de la falaise et sur la plage ; objets avec propriétaire : tas de bois (maison du rival), hortensias et pots (mère du joueur), épouvantail, brouette et arrosoir (champ de la jardinière), casiers et barque (pêcheur), matériel et vélos (chercheurs), mangeoire (vieille dame). Habitants : `PNJ_CHERCHEUR` (132 px), `PNJ_CHERCHEUSE` (128), `PNJ_PECHEUR` (132), `PNJ_VIEILLE_DAME` (120), `PNJ_JARDINIERE` (128), découpés par `decouper_perso.py`. **Les 4 routines** (dossier 01) : `marcheur.gd` accepte des pauses aux coins (le personnage regarde vers le bas) ; vieille dame maison (provisoirement celle du rival) ↔ banc près de la mangeoire, où un Roucool sautille ; pêcheur sentier côtier ↔ bout du ponton (cases du ponton praticables) ; enfant et Rattata courent sur la place puis reviennent ; chercheur porte du labo ↔ serre. Chercheuse (jardins) et jardinière (champ) immobiles. Le vieil homme et le voyageur de Jadielle sont retirés.
**Écarts** : `WORLD_PROP_CLOTURE_PIQUETS_V_01` fait une colonne blanche peu lisible : haies sur les côtés des jardins à la place (une r2 vue plus de dessus serait à essayer) ; `WORLD_PROP_JARDINIERE_01` non utilisée (objets rares) ; le champ est posé à plat (sinon il cachait l'épouvantail).

**Validation S24 (Kevin, 2026-10-06)** : Bourg Palette (séries 06, 06B) et ses 4 intérieurs (série 07) **validés**. Village à 60 fps stables (relevé `[proto-perf]` par lieu), ≈ 52 Mo de textures.

## Série 08 — Route 1 (2026-10-06, lumière NE)

Cible : `reference/route-1-vue-generale-v1.png` (validée par Kevin, « mix » de la carte du jalon 5 et d'une première vue, dossier 07). Presque tout est repris (arbres A à E et central, bouleau, conifère, buissons, rochers, pierres, fleurs sauvages, hautes herbes, chemin, clôture en bois, banc, panneau, Roucool, Rattata, Voyageur du J7). **Nouveaux** (`tools/art/serie08.py`, tous du premier coup) : `WORLD_TREE_AUTOMNE_01` (le seul arbre orange de la route), `WORLD_PROP_SOUCHE_01` (recoin de la Potion), `WORLD_RELIEF_REBORD_01` (tronçon d'1 case raccordable) ; clôture blanche courte = `WORLD_PROP_CLOTURE_PIQUETS_V_01` réduite à 1,6 case.
Scène `proto_route1.gd` (48 × 44 cases) : la grille de `route_1.tscn` est recopiée case par case (forêt, herbe, fleurs, chemin, hautes herbes, rebord) ; arbres repères aux positions des arbres de la carte. **Règle de la forêt** : un arbre ne pousse que si les cases couvertes par son feuillage (3 au-dessus de son pied) sont aussi de la forêt, sinon il cachait le chemin et les clairières ; les bandes trop étroites (goulet de la bande d'herbes, bords du rebord) sont garnies de buissons ; rien à moins de 2,4 cases d'un arbre repère. Le Voyageur fait sa petite boucle près du chemin (pauses), Roucool dans la prairie, Rattata au bord de la zone d'initiation.
**Forêt de la Route 1, test des 4 changements (Kevin, 2026-10-06)** après « pourquoi les arbres sont moins beaux que l'image Codex ? » (diagnostic : arbres de ville de 4 à 5 cases, herbe visible entre les troncs, 6 images répétées, effet miniature de la vue générale). **A** sous-bois sombre sous les cases de forêt (`sous_bois.gdshader`) ; **B** arbres de forêt ≈ 3 cases, espacés de 1,1 case (planche Codex `WORLD_TREE_FORET_PLANCHE_01`, 8 essences dans le style de la vue générale), grands arbres réservés aux repères ; **C** taille, miroir et teinte tirés au hasard par arbre ; **D** hautes herbes recolorées jaune-vert (`hautes_herbes_jaune.png`). Les bandes trop étroites sont garnies de buissons. La visite montre « Route 1 — NOUVELLE forêt » puis « Route 1 — ancienne forêt » pour comparer sur S24. **B change l'échelle des arbres par rapport aux personnages : décision de Kevin attendue.**
**QA S24 de la forêt serrée (2026-10-06, agent qa-mobile, rapport `build/qa_route1_foret.md`)** : 59,9 fps en moyenne (min 59), ≈ 36,5 Mo de textures, aucune erreur. v1 : arbres tranchés par des arêtes verticales (la planche 4 × 2 de Codex faisait déborder les arbres sur la case voisine, la découpe en grille les coupait) et ombres de contact rectangulaires → planches 2 × 2 espacées (`WORLD_TREE_FORET_PLANCHE_A`, `_B`), découpe à la rangée la plus vide, ombre de contact à l'échelle et au sens de l'arbre. v2 : défauts corrigés. Restent (rendu, reportés) : ombre en aplat sous le groupe de la clairière de l'arbre d'automne, petits traits sombres décollés au pied de quelques troncs, masse de droite très dense où les troncs se lisent peu.

**Forêt serrée retenue par Kevin (2026-10-06)** (échelle des arbres de forêt ≈ 3 cases, environ 2 fois le héros ; les grands arbres restent des repères) et **appliquée à Bourg Palette** : code commun `foret_serree.gd` (sous-bois + plantation) utilisé par `proto_route1.gd` et `proto_bourg.gd` ; à Bourg Palette, cases de forêt = herbe à plus d'une case des chemins, hors zones dégagées, au-dessus de la côte.

**Validation S24 (Kevin, 2026-10-06)** : Route 1 peinte (série 08, forêt serrée) **validée**.

## Série 06 — héros peint, compléments pour le J7 (2026-10-04, Q-1 (b))

Générés par Codex du premier coup, ancre = `PERSO_P2_PEINT_r1` : `HEROS_LANCER` : **le héros doit être droitier** (Kevin) et entrer en bas à gauche. Le générateur dessine obstinément un gaucher vu de dos (Ball à l'opposé de la cible, 7 essais). Solution : image retournée en miroir (Ball dans la main droite), puis retouche par Codex de la tête et des bras → **`HEROS_APRES_r5_1`** (= `VALIDE_HEROS_LANCER.png`) : bras droit tendu vers la cible en haut à droite, main vide, tête tournée vers elle. L'élan avec la Ball en main n'a pas pu être obtenu droitier ; **une seule pose suffit** : `BattleStage` affiche une image fixe (aujourd'hui `trainer_back.png`, 64 px ×6) et la Ball part de la main en arc par Tween. et `HEROS_PORTRAIT_NE_r1` (portrait en pied pour l'écran Dresseur et la carte ; remplace `assets/ui/map/player_portrait.png`). **Sauts de rebord : aucun asset** : `Player` dessine déjà l'arc (le sprite s'élève, l'ombre reste au sol) avec les images de marche.

## Pipeline (production, J7 T3a, 2026-10-05)

`tools/art/preparer.py` (successeur de `preparer_proto.py`) lit `tools/art/manifeste.json` et les images validées de `build/art/` (Mac de Kevin, non versionné) et écrit dans `assets/` ; les PNG et leurs `.import` sont versionnés, le cloud n'a jamais besoin des sources. Relance : `python3 tools/art/preparer.py --source /Users/kevinyankam/dev/kanto-2026/build/art`, puis `godot --headless --path . --import` ; relancer le script une seconde fois active les mipmaps des sols (réglage des `.import`). Les identifiants sont ceux de la fiche en `snake_case` (`bldg_centre_01`, `prop_banc_01`).
- **Lumière** : on ne reprend que les variantes **NE** (méthode C) ; seuls le massif, le banc et le lampadaire n'existent qu'en GH (petits objets, effet négligeable).
- **Dossiers** : `assets/world/{buildings, props (arbres compris), relief, interiors, ground (+ decals), backdrops}`, `assets/sprites/characters/painted/<id>_sheet.png` (héros, héros en course, 9 PNJ, lancer et portrait du héros), `assets/sprites/pokemon/painted/<id>_sheet.png`. Planches 4 × 4 (bas, gauche, droite, haut), découpées par `decouper_perso.py`.
- **Ombres** (reprises du prototype, calculées une fois) : `<id>_shadow.png` = silhouette floutée (σ 7 px), retournée, écrasée à 0,26, inclinée à 45° vers le bas à droite, fondue vers l'extrémité ; `<id>_contact.png` = base de l'objet étirée de 22 px vers le bas et floutée. **Alpha seul** (RVB blanc), **demi-résolution** (à afficher à l'échelle 2, LINEAR). Couleur et opacité viennent du jeu (prototype : ombre `(0,10 ; 0,09 ; 0,22)` à 0,34 ; contact `(0,12 ; 0,10 ; 0,20)` à 0,62). `assets/world/catalogue.json` donne, pour chaque objet, taille, décalage du coin haut gauche **par rapport au pied** (milieu du bas de l'image) et échelle. Pas d'ombre pour les personnages (ellipse du jeu), le relief, les intérieurs (contact seul) ni le massif (contact seul).
- **Herbes hautes** : `ground_hautes_herbes_01.png` et `…_bas.png` (moitié basse, même pied, à poser devant le personnage).
- **Sols** : 384 × 384 (4 × 4 cases), pavés × 0,7 de contraste, chemin × 0,55 de contraste et de saturation ; mipmaps activés.

## Série 10 — Route 2 (jalon 8, 2026-10-06, lumière NE)

Plan technique : `docs/tech/jalon-08.md` (§1.1 grille, §1.2 assets prévus, §1.3 vue générale) ; conception : `docs/design/dossier-11-route-2.md`. Numéro **10** : la série 09 est déjà prise par les personnages peints de Bourg Palette (DA.4, `tools/art/serie09.py` sur `main`).
- **8.0 — vue générale peinte (en cours)**. Grille fonctionnelle `tools/plans/route_2.txt` (42 × 60, source unique de la géométrie), vérifiée par `tools/art/plan_check.py` ; plan en aplats `build/art/PLAN_ROUTE2_v1.png` tiré de la grille par `tools/art/plan_aplats.py` (couleurs du plan de la Route 1) ; prompt `tools/art/prompts/CONCEPT_ROUTE2_VUE_GENERALE_r1.txt`, ancre de style = `reference/route-1-vue-generale-v1.png` (un autre lieu ; jamais un rendu précédent de la Route 2). Génération au T1 (3 essais au plus), puis validation de Kevin ; un changement de composition passe d'abord par la grille.
- **8.0 validé par Kevin (2026-10-07)** : essai 3. **Fiches des assets** : faites au T2 (ci-dessous, « liste exacte et fiches »).

### Série 10 — liste exacte et fiches (T2, 2026-10-07)

**Consigne de Kevin** : le plus petit kit modulaire qui produit la sensation de la vue validée (`reference/route-2-vue-generale-v1.png`, essai 3 ; le plan v2 fait foi pour la géométrie) sans effet répétitif. Liste complète, variations et abandons : `docs/tech/jalon-08.md` §1.2. **Nouveaux : 2 décors + 1 personnage (4 images Codex)** ; tout le reste est repris ou obtenu par variation (teinte par rangée, échelle, miroir, recadrage d'un asset validé). Planche de contrôle sans Codex : `build/art/R2_KIT_v1.png` (`python3 tools/art/serie10.py --planche`). Prompts composés par `tools/art/serie10.py` (ADN v1 + LUMIÈRE NE + fiche) ; références = recadrages `REF_R2_*` de la vue (`--refs`, boîtes versionnées dans le script, agrandies × 3) ; ancres de style `WORLD_PROP_SOUCHE_01_NE_r1` (série 08) et `WORLD_TREE_A_01_NE_r1`.

#### WORLD_BLDG_POSTE_FORET_01 → `bldg_poste_foret_01`
- **Rôle** : façade du poste sud de la Forêt de Jade, objectif visuel de toute la route (vu depuis C3) ; porte → « FORÊT DE JADE — À venir » au J8 ; **réutilisée au J9** (poste nord, dossier 10).
- **Taille** : 7 cases de large (`axe w`, `cases 7`), ≈ 4,5 cases de haut. **Emprise** 7 × 4 (cases (17..23, 5..8)), ancre (20, 8), porte laissée libre `open [(0, 0)]` = (20, 8).
- **Couche** : entités (tri par les pieds), `fade` vrai. **Ombre** : oui (bâtiment), contact 0,12.
- **Référence** : `REF_R2_POSTE` ; ancre supplémentaire `WORLD_BLDG_MAISON_B_01_NE_r1` (ardoises de Jadielle).
- **Contenu** : toit à deux pans d'ardoises gris-bleu, murs de pierre claire, poteaux et linteau de bois, large entrée sombre et vide au milieu du bas, aucune fenêtre, aucun texte ; un peu de mousse au pied. Sans arbres, chemin ni panneau (posés par la carte). Variantes : aucune.

#### WORLD_PROP_GRANDE_PIERRE_01 → `prop_grande_pierre_01`
- **Rôle** : repère unique de C2 (« arbres → pierre → forêt », dossier 11 §15) ; P2 se tient à côté. `prop_rocher_01` (anguleux, déjà trois fois sur les Routes 1 et 22) ne serait pas un repère.
- **Taille** : 3 cases de large, ≈ 2,2 de haut. **Emprise** 3 × 2 (cases (26..28, 23..24)), ancre (27, 24).
- **Couche** : entités, pas de fondu. **Ombre** : non (règle des petits objets) ; contact préparé (0,1), non utilisé.
- **Référence** : `REF_R2_GRANDE_PIERRE`. **Contenu** : un seul gros bloc arrondi et lisse, gris très clair un peu chaud, lichen pâle ; pas un amas de rochers. Variantes : aucune.

#### PNJ_RANDONNEUSE (+ RANDONNEUSE_ATTENTE) → `randonneuse`, `randonneuse_idle`
- **Rôle** : P1, « Randonneuse », au premier embranchement (boucle de 3 cases, regarde le nord). Le Voyageur (Route 1) et la Dresseuse (Jadielle) existent déjà : les reprendre mettrait le même personnage à deux endroits.
- **Taille** : 128 px ; planche de marche 4 × 4 (modèle `PNJ_MARCHAND_NE_r1`, ancre `PERSO_P2_PEINT_r1`) puis planche d'attente 4 × 1 (`tools/art/attente/prompts/RANDONNEUSE_ATTENTE.txt`, calée sur la marche).
- **Référence** : `REF_R2_RANDONNEUSE` (tenue seulement). **Tenue (défaut, règle 4)** : chapeau de paille à bande bleu marine, cheveux châtains longs, chemise vert sauge, short bleu marine, sac à dos orange-brun, bâton de marche ; pas de veste orange (Dresseuse).

#### Variations préparées sans Codex (`preparer.py`, options `recadrage` / `masque`)
- `prop_cloture_piquets_01_court` : 3 des 4 cases de `WORLD_PROP_CLOTURE_PIQUETS_01_NE_r1` (recadrage [47, 430, 917, 903], coupe au milieu d'un intervalle) ; clôtures basses de C1 ; emprise 3 × 1.
- `poke_ball_ground` (section `images_objets`) : la Poké Ball de `INT_COMMODE_POKEBALL_01_NE_r1` (série 07), recadrage [367, 285, 594, 512] + disque, 40 px de haut ; O1 et O2 (Q-1 : même aspect).

#### Conditionnels (prompts dans `serie10.py`, lancés seulement par leur nom, si la capture du T5 le demande)
- `WORLD_PROP_ARBRE_DENSE_01` (`REF_R2_ARBRE_DENSE`, 1,2 case de large, ≈ 1,6 de haut, emprise 1 case) : si FUTUR A en `tree_foret_08` réduit ne se lit pas comme un obstacle.
- `WORLD_PROP_POKEBALL_SOL_01` (`REF_R2_POKEBALL`, 0,42 case) : si la Ball recadrée déçoit au sol.
- `WORLD_GROUND_SOUS_BOIS_01` (planche 4 × 2 de décalcomanies : fougères, mousse, feuilles mortes, racines…) : si le dernier tiers manque de sous-bois ; mutualisable au J9.
