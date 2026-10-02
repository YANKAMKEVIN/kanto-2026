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
