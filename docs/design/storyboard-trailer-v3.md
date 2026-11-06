# Bande-annonce de Pokemake — storyboard v3 (à valider par Kevin)

> 2026-11-06. Suite de [`analyse-teasers-pokemon.md`](analyse-teasers-pokemon.md), dont Kevin a retenu
> toutes les recommandations (TR-1 à TR-7, « Oui, toutes »). TR-3 n'avait pas de valeur par défaut :
> le choix des costumes ci-dessous est un **[D]**, à confirmer.
>
> **La v2.1 reste intacte pour comparer** (demande de Kevin, 2026-11-06) :
> [`storyboard-trailer-v1.md`](storyboard-trailer-v1.md), `tools/trailer/cuts.json` et
> `assets/ui/opening/trailer.ogv` ne sont ni modifiés ni supprimés. Le jeu garde la v2.1 tant que
> Kevin n'a pas choisi après avoir vu les deux.

## 1. Décisions

| # | Décision |
|---|---|
| TR-1 | Deux montages. **A (Kanto)** pour la RC des proches, avec l'ombre de Lugia, sans nommer Johto. **B (Kanto + Johto)** quand Johto sera diffusé |
| TR-2 | 4 costumes montrés, le reste en silhouettes |
| TR-3 | **[D]** Luffy, Naruto, Son Goku, Iron Man ; la joueuse en Nami. À confirmer |
| TR-4 | Le joueur porte la vidéo, la joueuse apparaît dans « Toi » |
| TR-5 | Épique, avec un moment drôle : Iron Man qui surfe |
| TR-6 | Boîte de dialogue du jeu sur l'image ; plus aucun carton sur noir |
| TR-7 | Ouverture sur le duo |

Inchangé : scènes jouées dans le vrai jeu, thème du titre sous toute la vidéo, HUD caché, première
lecture seulement (sans sauvegarde), un toucher passe la vidéo, carton des studios avant, lettres
après.

## 2. Montage A (Kanto), plan par plan

Durées en secondes. « Texte » = boîte de dialogue du jeu, sur l'image.

| # | Début | Durée | Moment | Lieu | Action | Cadre | Texte |
|---|---|---|---|---|---|---|---|
| 1 | 0,0 | 4,5 | Le duo | Bourg Palette | Le héros et Salamèche, côte à côte, se mettent en marche ; Salamèche lève la tête vers lui | **serré** sur le duo | « Salamèche te regarde, l'air heureux. » |
| 2 | 4,5 | 3,5 | L'aventure | Route 1 | Ils courent vers les hautes herbes, éclair de rencontre | suit, moyen | — |
| 3 | 8,0 | 3,0 | | Combat sauvage | Poké Ball, trois secousses, clic, « Roucool capturé » | combat | — |
| 4 | 11,0 | 2,0 | | Route 22 | Le rival surgit, « ! » | moyen | « Ça tombe bien. » |
| 5 | 13,0 | 2,0 | | Entrée du combat | Banderoles, VS qui claque | — | — |
| 6 | 15,0 | 3,0 | | Combat du rival | 2 PV restants, riposte, K.O. | combat | — |
| 7 | 18,0 | 2,5 | | Évolution | Silhouette blanche, Reptincel | plein écran | — |
| 8 | 20,5 | 3,2 | **Toi** | Céladopole | **Une seule marche**, même cadre : tenue d'origine, Luffy, Naruto, Son Goku, un changement toutes les 0,8 s, coupé sur le temps | serré, fixe | — |
| 9 | 23,7 | 1,5 | | Piste Cyclable | La joueuse en Nami à vélo | suit | — |
| 10 | 25,2 | 3,0 | | Menu Dresseur | Rangée de silhouettes noires ; l'une s'allume : Iron Man | plein écran | « Nouveau costume : Iron Man » |
| 11 | 28,2 | 2,5 | | Route 19 | **Iron Man surfe**, sérieux, sur le dos de son Pokémon | serré | — |
| 12 | 30,7 | 1,2 | Le monde | Pont Pépite | Traversée | serré | — |
| 13 | 31,9 | 1,2 | | Mont Sélénite | Dans le noir, entre les lampes | serré | — |
| 14 | 33,1 | 1,4 | | Tour Pokémon | Le SPECTRE | combat | — |
| 15 | 34,5 | 2,0 | | Grotte Azurée | Entrée de Mewtwo | combat | — |
| 16 | 36,5 | 1,4 | | Plateau Indigo | Montée vers la Ligue | suit | — |
| 17 | 37,9 | 2,0 | | Salle du Maître | Banderole de la Championne, VS | — | — |
| 18 | 39,9 | 0,5 | | Noir | Musique coupée | — | — |
| 19 | 40,4 | 2,0 | **L'ombre** | Grotte marine | Eau calme, une ombre immense passe dessous | fixe | — |
| 20 | 42,4 | 0,5 | | Noir | Un temps | — | — |

Durée : **42,9 s**, puis les lettres (3,5 s) ; ≈ 49 s avec le carton des studios (v2.1 : 46 s de vidéo).

Valeurs [D] :
- Les textes reprennent des lignes du jeu : compagnon, rival (`route_22.json`), notification de costume (un toast, pas une boîte). Aucune
  phrase n'est inventée pour le montage A.
- L'ombre passe **avant** les lettres, et non après comme dans la trame : la fin de l'ident fond déjà
  vers l'écran titre, on n'y touche pas.
- Musique coupée au plan 18, reprise sur les lettres.

## 3. Montage B (Kanto + Johto), pour plus tard

Plans 1 à 18 identiques. Puis :

| # | Durée | Lieu | Action | Texte |
|---|---|---|---|---|
| 19 | 2,0 | Noir, puis Rosalia de nuit | Première nuit de la vidéo : le duo marche sous les lanternes ; passage à une musique de Johto [D] | « Ce n'est que le début. » [D] |
| 20 | 1,5 | Tour Carillon | Montée dans la tour | — |
| 21 | 2,0 | Sommet | Entrée de Ho-Oh | — |
| 22 | 2,0 | Grotte marine | L'ombre de Lugia | — |
| 23 | 0,5 | Noir | Un temps | — |

**Jamais montrés**, dans aucun montage : le vol de l'équipe, la révélation de Dante (Dante retiré de
la trame [D], même en contre-jour), le Réveil de l'arc des Pierres.

## 4. Faisabilité (vérifiée dans le code, pas encore à l'image)

| Besoin | État |
|---|---|
| Plans serrés | `cuts.json` sait zoomer (`zoom`, `focus`). À vérifier : netteté au-delà de ≈ ×1,5 |
| Compagnon | Clé `companion` des départs de débogage ; Salamèche et Reptincel éligibles (`data/pokemon/companions.json`), donc Reptincel peut suivre le joueur après le plan 7 |
| Costumes, joueuse | **Pas de clé dans les départs de débogage** : à poser dans `capture_trailer_scene.gd`. Art présent, vélo et surf compris |
| Marche à costumes | Une prise par tenue, même chemin, montées en coupes ; le risque est le raccord des pas |
| Silhouette (plan 10) | Écran réel du menu Dresseur, à piloter ; l'allumage de la silhouette peut demander un effet de montage. **Plan le plus risqué** ; repli : la notification après un badge |
| Nuit | Clé `period`, Johto seulement |
| Ombre de Lugia | Scène du jeu `sea_cave_lugia_shadow`. **Son image est encore un provisoire** (`assets/world/props/placeholder/lugia_shadow.png`) : à relire à l'image |
| Deux vidéos | `assemble.py` lit un `cuts.json` fixe et écrit sur `trailer.ogv` : à paramétrer avant tout rendu, sinon il écraserait la v2.1. Fichiers prévus : `cuts_v3_kanto.json`, `build/trailer/pokemake-trailer-v3.mp4` |

## 5. Réalisation (2026-11-06, montage A rendu)

- **Rendu :** `TRAILER_RAW=raw_v3 tools/trailer/render.sh <scènes>` puis
  `python3 tools/trailer/assemble.py --cuts tools/trailer/cuts_v3_kanto.json --tag v3` →
  `build/trailer/pokemake-trailer-v3.mp4` et `-720p.mp4`. Avec `--tag`, l'outil n'écrit jamais la
  vidéo du jeu ni `data/opening/trailer.json`. Scènes neuves dans `capture_trailer_scene.gd`, départs
  `tools/debug_start/trailer_v3_*.json`.
- **Écarts avec le §2 :**
  - Plan 4 : « Tu hésites trop. » (ligne de Régis) remplace « Ça tombe bien. », qui ne ressort pas
    lisiblement dans ce rendu.
  - Plan 1 : le duo marche d'abord de côté, pour que Salamèche soit à côté du héros et pas derrière.
  - Plan 8 : 0,65 s par tenue au lieu de 0,8 s.
  - Plan 19 : ombre agrandie ×2,5 et assombrie par rapport au jeu ; elle reste une image provisoire,
    sur un bassin aux carrés sombres.
- **Pas fait :** montage B (Johto) ; intégration dans le jeu, qui garde la v2.1.

## 6. Suite

Kevin compare la v2.1 et la v3. Seulement alors, si la v3 gagne, la vidéo du jeu change. Sur
`release/0.34`, ce serait une nouvelle RC (≥ 0.34.2) : à décider à ce moment.

## 7. Version 4 (2026-11-06, retours de Kevin sur la v3)

Remplace le §2 et le §3 pour le montage courant : `tools/trailer/cuts_v4.json`, ≈ 51 s, rendu par
`python3 tools/trailer/assemble.py --cuts tools/trailer/cuts_v4.json --tag v4 --raw raw_v3`.

**Décisions de Kevin (2026-11-06) :**
- **Johto dans la vidéo** et « plus de 200 Pokémon » : le jeu ne se résume pas à Kanto. **Annule la
  TR-1** (deux montages) : un seul montage.
- Textes qui accompagnent toute la vidéo, posés sur l'image (**annule la TR-6**).
- Villes à vélo avec leur nom ; Pokédex qui défile ; trois évolutions côte à côte.
- Retrait du combat contre le SPECTRE.

**Valeurs [D] :**
- Ombre de Lugia retirée ; Lugia et Ho-Oh en combat à la place.
- Surf retiré, en attendant la réponse de Kevin sur ce qui ne va pas.
- Costumes en grand : Iron Man et Son Goku à l'entrée du combat de Régis, avec leur nom.
- Textes : « Pars à l'aventure. », « Capture-les tous. », « Plus de 200 Pokémon à découvrir. »,
  « Fais-les évoluer. », « Des rivaux à battre. », « Parcours les villes. », Argenta, Azuria,
  Céladopole, Carmin-sur-Mer, « Deviens qui tu veux. », « Un costume à chaque badge. », « Affronte
  les légendes. », « Jusqu'au sommet. », « Et ce n'est que la moitié du voyage. », « Johto », « La
  nuit tombe sur Rosalia. », « Deux régions. Un seul voyage. »
- Ho-Oh est lancé par une rencontre directe : pas son entrée légendaire du jeu.
