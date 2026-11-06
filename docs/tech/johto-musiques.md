# Johto — table des musiques (HeartGold / SoulSilver)

> Claude, 2026-11-06. **Document de validation pour Kevin. Aucun fichier téléchargé, aucun audio ajouté, ni `game/` ni `data/` modifiés.**
> Modèle : `docs/tech/jalon-son.md` §2 (carte → piste). Décision de Kevin du 2026-10-24 : Kanto = Let's Go ; Johto = HeartGold / SoulSilver (JOH9, JH-12). Jeu privé, cercle restreint.
> **Titres de pistes** : écrits de mémoire d'après la bande-son HGSS ; ils sont **à confirmer à l'écoute** (comme la tâche T1 du jalon Son) avant tout téléchargement. Le choix de la source et des droits viendra après la validation de cette liste.

## 1. Ce qui joue aujourd'hui à Johto

Le moteur (`MusicSelector`) choisit : surcharge de carte → Surf / Vélo → drapeau → **carte** (`music_zones.json` « maps ») → **zone** → silence. Les combats passent par `battle_music.json` (catégories : sauvage, légendaire, Dresseur, Champion, rival final).

Tout Johto joue des **pistes de Kanto (Let's Go) en substitution** (`[D]`, « lot Son ») :

- **Cartes** : seules 11 cartes de Johto ont leur propre entrée (Doublonville : Centre et grand magasin → Centre ; Tour Radio → Silph Co.). **Tout le reste passe par la zone.**
- **Centres et Boutiques de Johto** (Rosalia, Écorcia, Oliville, Acajou, Irisia, Ébènelle, Mont Argenté) : **absents** de la table des cartes → ils jouent le thème de leur *ville*, pas celui du Centre (écart avec Kanto, où Centres et Boutiques ont leur piste). À corriger au branchement.
- **Combats** : les Dresseurs de Johto (Sbires, Brace, Cenere, Chef de cale / de bande, Dante 1) jouent « Battle! Trainer » ; seuls **Dante 2** (Gym Leader) et **le rival final** (« Final Battle Rival ») ont une piste à part. Johto n'a **pas d'Arène**.
- **Légendaires** : la liste `legendary_species` contient Suicune et Lugia, **mais pas Ho-Oh, Entei, Raikou ni Celebi** (ils jouent donc la musique d'un sauvage ordinaire). Toutes les catégories jouent la même « Battle! Wild » que Kanto.
- **Scènes** : « Réveil des pierres » → `final_road` ; `rival` → `blue_theme` ; les Sbires → « Trainer appears (bad guy) » ; tous les autres Dresseurs, Dante et Cenere compris → « Trainer appears (boy) ».
- **Surf / Vélo** : `the_sea` / `pokemon_road` partout, Johto compris.
- **Jingles** (soin, objet, badge…) : ceux de Let's Go, communs au jeu entier.

## 2. Table carte → piste

Code : **HG-xx** = piste HGSS à obtenir (numérotation de la §4). Les noms de zones sont ceux du jeu.

### 2.1 Villes, routes, lieux de plein air

| Lieu (zone) | Musique actuelle | Piste proposée | Remarque |
|---|---|---|---|
| Oliville | Cinnabar Island (LG) | **HG-01 Olivine City** | |
| Rosalia | Pewter City (LG) | **HG-02 Ecruteak City** | |
| Doublonville | Celadon City (LG) | **HG-03 Goldenrod City** | |
| Écorcia | Pewter City (LG) | **HG-04 Azalea Town** | |
| Irisia | Pewter City (LG) | **HG-05 Cianwood City** | |
| Acajou | Pewter City (LG) | **HG-06 Mahogany Town** | |
| Ébènelle | Lavender Town (LG) | **HG-07 Blackthorn City** | |
| Centres et Boutiques de Johto (7 Centres, 3 Boutiques, grand magasin) | thème de la ville (Doublonville : Pokémon Center LG) | **HG-08 Pokémon Center** (HGSS) | règle de Kanto : Boutique = Centre. Dépend de JM-1 |
| Routes 34, 35, 36, 37 | Road to Cerulean / Viridian (LG) | **HG-09 Route 29** | thème de départ de HGSS, le plus « route de campagne » |
| Routes 38, 39, 43 | Road to Cerulean / Viridian (LG) | **HG-10 Route 38** | |
| Route 42, Sentier du Mont Argenté | Road to Cerulean / Lavender (LG) | **HG-11 Route 42** | montagne |
| Route 28 | Pokémon Road (LG) | **HG-12 Route 28** | titre exact à vérifier (thème des Routes 26 / 27 / 28 de HGSS) |
| Routes 40, 41 (mer) | Road to Cerulean (LG) ; Surf = The Sea | **HG-13 Surf** (Surf) + HG-09 à pied | en mer on surfe presque toujours |
| Surf partout à Johto | The Sea (LG) | **HG-13 Surf** | demande une règle « par région » (voir §5) |
| Vélo à Johto | Pokémon Road (LG) | **HG-14 Bicycle** | idem ; voir JM-2 |
| Lac Colère | Road to Cerulean (LG) | **HG-22 Lake of Rage** | |
| Bois aux Chênes | Viridian Forest (LG) | **HG-15 Ilex Forest** | |
| Bois de la Tour | Viridian Forest (LG) | **HG-15 Ilex Forest** | lieu inventé (sans équivalent HGSS) |
| Le Goéland (pont) | Road to Cerulean (LG) | **HG-26 S.S. Aqua** | lieu inventé, arc des Pierres ; proche : le ferry de HGSS |

### 2.2 Grottes, ruines, tours, repaires

| Lieu (zone) | Musique actuelle | Piste proposée | Remarque |
|---|---|---|---|
| Puits Ramoloss | Mt. Moon (LG) | **HG-16 Union Cave** | |
| Souterrain de Doublonville | Road to Viridian (LG) | **HG-16 Union Cave** | HGSS n'a pas de piste dédiée sûre ; grotte la plus proche |
| Grotte marine | Mt. Moon (LG) | **HG-16 Union Cave** | |
| Grotte de la Marée (Irisia) | Mt. Moon (LG) | **HG-16 Union Cave** | arc des Pierres, lieu inventé |
| Îles Tourbillon | Viridian Forest (LG) | **HG-24 Whirl Islands** | |
| Ruines d'Alpha (extérieur, tente, galerie, chambre) | Road to Cerulean / Mt. Moon (LG) | **HG-17 Ruins of Alph** | arc des Pierres : pas de piste différente pour la chambre des dalles (JM-8) |
| Tour Cendrée | Pokémon Tower (LG) | **HG-18 Burned Tower** | |
| Tour Carillon (1F, 2F, toit) | Pokémon Tower (LG) | **HG-19 Bell Tower** | le toit a peut-être sa propre piste (JM-8) |
| Tour Radio (1F à 5F, ascenseur) | Silph Co. (LG) | **HG-20 Radio Tower** | |
| Repaire Rocket d'Acajou (B1F à B3F) | Rocket Hideout (LG) | **HG-21 Team Rocket HQ** | |
| Souvenir de Dante (QG, flashback) | Rocket Hideout (LG) | **HG-21 Team Rocket HQ** | lieu inventé |
| Antre du Dragon (étage et Sanctuaire) | Mt. Moon (LG) | **HG-23 Dragon's Den** | |
| Mont Argenté (Centre, extérieur, 1F à 3F) | Mt. Moon (LG) | **HG-25 Mt. Silver** | le Centre dépend de JM-1 |
| Sommet du Mont Argenté | The Final Road (LG) | **HG-25 Mt. Silver** | |

### 2.3 Combats

| Combat | Musique actuelle | Piste proposée | Remarque |
|---|---|---|---|
| Sauvage (toute la région) | Battle! Wild (LG) | **HG-27 Battle! Wild (Johto)** | règle « par région » |
| Dresseur ordinaire | Battle! Trainer (LG) | **HG-28 Battle! Trainer (Johto)** | |
| Sbire, Scientifique, Chef de cale / de bande | Battle! Trainer (LG) | **HG-28** ou **HG-29 Battle! Team Rocket** | JM-4 |
| Brace (Puits, Repaire), Cenere (Tour Radio, Îles, Antre), Dante 1 (Tour Carillon) | Battle! Trainer (LG) | **HG-29 Battle! Team Rocket** (admin) | pas de catégorie « Rocket » aujourd'hui |
| Dante 2 (Mont Argenté) | Gym Leader (LG) | **HG-30 Battle! Gym Leader (Johto)** | |
| Rival (Mont Argenté, final) | Final Battle Rival (LG) | **HG-31 Battle! Champion** | combat final de Johto ; ou **HG-32 Battle! Rival** (JM-6) |
| Suicune, Entei, Raikou | Wild (Suicune seul « légendaire », même piste) | **HG-33 Battle! Legendary Beasts** | à ajouter à la liste des légendaires |
| Lugia, Ho-Oh | Wild (Lugia « légendaire », même piste) | **HG-34 Battle! Lugia / Ho-Oh** | idem pour Ho-Oh |
| Celebi | Wild | **HG-27 Battle! Wild (Johto)** | pas de piste propre sûre |
| Victoire (Dresseur / sauvage / Champion) | Victory! (LG) | **HG-35 / HG-36 / HG-37 Victory!** | JM-7 : garder les victoires de Let's Go ? |
| « ! » du Dresseur (garçon, fille, Rocket, rival) | Trainer Appears (LG) | thèmes LG actuels | aujourd'hui Dante, Cenere et Brace jouent « garçon » ; JM-7 |

### 2.4 Scènes et événements

| Scène | Musique actuelle | Piste proposée | Remarque |
|---|---|---|---|
| Réveil des pierres (arc des Pierres) | The Final Road (LG) | **HG-23 Dragon's Den** | écran du Réveil et scène de l'autel |
| Rival (scènes) | Blue's Theme (LG) | **HG-32 Rival** (thème d'apparition) ou LG | JM-6 |
| Générique de Johto | (rien de propre) | **HG-38 Ending / Credits** | JM-9 |
| Jingles : soin, objet, badge, capture, évolution | Let's Go | inchangés | |

## 3. Lieux sans équivalent dans HeartGold / SoulSilver

| Lieu | Pourquoi | Piste proche proposée |
|---|---|---|
| Le Goéland (arc des Pierres) | pont de navire inventé | HG-26 S.S. Aqua |
| Grotte de la Marée | inventée (Irisia, arc des Pierres) | HG-16 Union Cave |
| Bois de la Tour | inventé | HG-15 Ilex Forest |
| Souterrain de Doublonville | HGSS : Souterrain sans piste identifiée | HG-16 Union Cave |
| Chambre / Galerie des Ruines d'Alpha (dalles, Pierre Mémoire) | scène d'énigme inventée | HG-17 Ruins of Alph |
| Sanctuaire et épreuve de l'Antre du Dragon | inventés (arc des Pierres) | HG-23 Dragon's Den |
| Souvenir de Dante (flashback) | inventé | HG-21 Team Rocket HQ |
| Mont Argenté (Centre, sentier) | Centre d'altitude inventé | HG-08 Pokémon Center / HG-11 Route 42 |
| Combats Brace / Cenere / Dante / Chef | personnages inventés | HG-29 Battle! Team Rocket |
| Îles Tourbillon, Tour Radio, etc. | existent bien dans HGSS | piste d'origine |

## 4. Pistes à obtenir

**38 pistes HGSS au total**, regroupées ainsi (les numéros HG-xx renvoient à la §2) :

| Groupe | Pistes | Nombre |
|---|---|---|
| Villes | 01 à 07 | 7 |
| Centre | 08 | 1 |
| Routes et déplacement | 09 à 14 (R29, R38, R42, R28, Surf, Vélo) | 6 |
| Lieux : forêt, grottes, ruines, tours, repaires | 15 à 26 | 12 |
| Combats | 27 à 34 | 8 |
| Victoires | 35 à 37 | 3 |
| Générique | 38 | 1 |
| **Total** | | **38** |

**Noyau minimal (29 pistes)** : villes, Centre, 4 routes, 11 lieux, 6 combats (sauvage, Dresseur, Rocket, Gym, Champion, une piste de légendaires), sans Surf, Vélo, S.S. Aqua, victoires ni générique ; les manques retombent sur Let's Go (déjà dans le jeu). Les jingles, les « ! » des Dresseurs et les bruitages restent ceux de Let's Go.

## 5. Ce que le code devra faire (pour mémoire, pas fait ici)

Rien n'est touché dans ce document. Au branchement : (1) une règle **par région** pour le sauvage, le Dresseur, le Surf et le Vélo (aujourd'hui une seule piste pour tout le jeu) ; (2) une catégorie de combat « Rocket » ; (3) les Centres et Boutiques de Johto dans `music_zones.json` ; (4) Ho-Oh, Entei, Raikou à `legendary_species` ; (5) un thème d'apparition propre à Dante, Cenere, Brace. Le point de départ est `data/audio/*.json` et `tracks.json` (`expected: false` tant qu'un fichier manque).

## 6. Décisions (Kevin m'a laissé choisir, 2026-11-06 : mes recommandations s'appliquent)

| N° | Décision |
|---|---|
| JM-1 | Centres et Boutiques de Johto : HG-08 Pokémon Center HGSS (et l'écart actuel est corrigé au branchement). |
| JM-2 | Surf : HG-13 à Johto. Vélo : HG-14 gardé (la piste est courte, 1 piste de plus). |
| JM-3 | Routes : 4 thèmes regroupés (HG-09 à HG-12), pas une piste par route. |
| JM-4 | Sbires et Scientifiques gardent « Battle! Trainer » ; Brace, Cenere, Dante 1 et les Chefs prennent HG-29 Team Rocket. |
| JM-5 | Trois pistes de légendaires (HG-33 Bêtes, HG-34 Lugia / Ho-Oh, Celebi en sauvage) ; Ho-Oh, Entei, Raikou ajoutés à la liste. |
| JM-6 | Dante 2 = HG-30 Gym Leader ; rival final = HG-31 Champion ; HG-32 Rival sert aux scènes d'apparition du rival. |
| JM-7 | Jingles, « ! » des Dresseurs : Let's Go. Victoires : Let's Go aussi (HG-35 à HG-37 retirées du lot ; total ramené à **35 pistes**). Dante, Cenere et Brace prennent le « ! » Rocket. |
| JM-8 | Une piste par lieu comme en §2 ; le toit de la Tour Carillon et la chambre des dalles gardent celle de leur lieu. |
| JM-9 | Générique de Johto : HG-38 (fin HGSS). |
| JM-10 | Sommet du Mont Argenté : même piste que la montagne (HG-25). |
| JM-11 | Les titres exacts se fixent à l'écoute avant tout téléchargement ; la liste peut perdre ou gagner une ou deux pistes. |

**Liste finale à obtenir : 35 pistes** (38 moins les 3 victoires). Aucun téléchargement tant que Kevin n'a pas relu cette liste et choisi la source (droits). Les lieux inventés de la §3 prennent la piste proche proposée.

## 7. Source : choix A (Kevin, 2026-11-06)

Comme pour Kanto : **Kevin télécharge lui-même** l'album HeartGold / SoulSilver sur KHInsider (FLAC, sinon le meilleur MP3), noms d'origine, dans `~/Music/johto-hgss/`. Claude ne télécharge rien ; il découpe les boucles et intègre ensuite. Jeu privé, aucune diffusion.

**Les 35 pistes à garder** (titres à confirmer sur la liste de l'album) :

| Groupe | Pistes |
|---|---|
| Villes (7) | 01 Olivine City · 02 Ecruteak City · 03 Goldenrod City · 04 Azalea Town · 05 Cianwood City · 06 Mahogany Town · 07 Blackthorn City |
| Centre (1) | 08 Pokémon Center |
| Routes (6) | 09 Route 29 · 10 Route 38 · 11 Route 42 · 12 Route 28 · 13 Surf · 14 Bicycle |
| Lieux (12) | 15 Ilex Forest · 16 Union Cave · 17 Ruins of Alph · 18 Burned Tower · 19 Bell Tower · 20 Radio Tower · 21 Team Rocket HQ · 22 Lake of Rage · 23 Dragon's Den · 24 Whirl Islands · 25 Mt. Silver · 26 S.S. Aqua |
| Combats (8) | 27 Wild · 28 Trainer · 29 Team Rocket · 30 Gym Leader · 31 Champion · 32 Rival · 33 Legendary Beasts · 34 Lugia / Ho-Oh |
| Générique (1) | 38 Ending / Credits |

Si un titre manque ou diffère dans l'album, Kevin garde le plus proche et le signale ; on ajuste la table.

## 8. Album choisi : « Super Music Collection (Looped) » (relevé le 2026-11-06)

Page lue sans rien télécharger : 6 disques, 281 fichiers, 648 Mo en MP3 ou 2,4 Go en FLAC ; chaque piste joue deux fois avant le fondu (boucle déjà faite). **Les disques 1 à 4 sont la version DS** (à utiliser) ; **les disques 5 et 6 sont la version Game Boy** (sons de Gold / Silver, à ignorer).

**Présentes dans l'album (27 de nos 35)** : Azalea Town, Ecruteak City, Goldenrod City, Cianwood City, Pokémon Center, Route 29, Route 38, Route 42, Surf, Bicycle, Union Cave, Ruins of Alph, Burned Tower, Bell Tower, Radio Tower Occupied!, Team Rocket HQ, Dragon's Den, S.S. Aqua, Battle! Wild (Johto), Trainer (Johto), Team Rocket, Gym Leader (Johto), Champion, Rival, Raikou / Entei / Suicune, Lugia, Ho-Oh, Ending.

**Absentes (8) — repli proposé (règle 4)** :

| Piste voulue | Repli dans l'album |
|---|---|
| HG-01 Olivine City | Olivine Lighthouse |
| HG-06 Mahogany Town | Route 42 |
| HG-07 Blackthorn City | Ice Path |
| HG-12 Route 28 | Route 26 |
| HG-15 Ilex Forest | Viridian Forest (version HGSS de l'album) |
| HG-22 Lake of Rage | Route 38 |
| HG-24 Whirl Islands | Union Cave |
| HG-25 Mt. Silver | Ice Path |

Si Kevin veut les vrais thèmes manquants, ils sont peut-être dans le gamerip « Pokémon HeartGold and SoulSilver » de KHInsider (à vérifier plus tard).
