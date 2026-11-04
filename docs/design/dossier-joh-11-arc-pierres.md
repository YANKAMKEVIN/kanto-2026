# Dossier JOH-11 — L'arc des Pierres : Ruines d'Alpha, Irisia, Ébènelle, Antre du Dragon (jalons JOHP0 à JOHP3, v0.1)

> Nouvel arc du Chapitre Johto, entre la Tour Radio (JOH5) et l'acte 2 (JOH6), décidé par Kevin le
> 2026-11-04 pour résoudre l'écart entre l'équipe de Kanto (55–65) et celle de Johto (≈ 30), sans
> toucher aux niveaux de JOH6 à JOH9 (cadre [`dossier-joh-00-cadre.md`](dossier-joh-00-cadre.md),
> [`dossier-joh-06-tour-radio.md`](dossier-joh-06-tour-radio.md),
> [`dossier-joh-07-acajou.md`](dossier-joh-07-acajou.md)). Écrit par Claude le 2026-11-04.
>
> **Statut : arbitrages JH-61 à JH-79 validés par Kevin le 2026-11-04** (recommandations retenues, §18).
> **Reste à valider : les textes du §17, en un seul lot.** Valeurs **[D]** = défauts. Grilles et vues
> peintes après la validation des textes ; aucun
> code avant. Rien n'est repris tel quel d'Or/Argent : l'intrigue, les énigmes, les personnages et
> les plans de l'arc sont neufs ; seuls les noms de lieux viennent de la région.

## 0. Décisions de Kevin (2026-11-04)

| Sujet | Décision |
|---|---|
| Place | Un arc entre la Tour Radio (JOH5) et l'acte 2 (JOH6) |
| Équipe de Kanto | Son retour passe à la **fin de l'arc** (au lieu du bureau de la Tour Radio) |
| Pierres | **Trois pierres**, une légende : réunies, elles déclenchent un pouvoir mystérieux |
| Pouvoir | Monte les Pokémon de Johto à peu près au niveau de ceux de Kanto, **peu importe leur niveau avant** |
| Enchaînement | **Ruines d'Alpha, puis Irisia, puis Ébènelle** ; Ébènelle et l'Antre du Dragon portent la dernière pierre et le climax |
| Accès | Irisia en **bateau depuis Oliville** ; Ébènelle par un **vol scénarisé sur le Dracolosse d'un messager du clan**, aller et retour |
| Taille | Chaque lieu reste **petit** : une zone et un donjon court, à peu près comme le JOH4 |
| Pistes approuvées | Le pouvoir n'agit que sur les Pokémon nés à Johto ; la Team Rocket veut aussi les pierres (course contre un admin) ; le doyen ou Orme raconte la légende à la fin de la Tour Radio |
| Écartés | Rattrapage d'Exp ; équipe rendue en fin d'acte 2 ; toute baisse des niveaux de JOH6 à JOH9 |
| Exp pendant l'arc | **Pas de ×4**, pour que le joueur ressente la puissance libérée par les pierres. **Le ×1,5 de l'acte 1 reste** pendant l'arc et s'arrête au retour de l'équipe de Kanto |
| Courbe | L'arc va d'≈ 30 à ≈ 40, boss d'Ébènelle vers 42–45 ; le saut du Réveil est **le moment fort du chapitre** |

## 1. Passe d'alignement : ce que le relevé a montré

Relevé fait sur `main` (e363db8f), la branche du JOH5 et les dossiers JOH-00 à JOH-10.

| N° | Constat | Conséquence |
|---|---|---|
| A-1 | Le retour d'équipe est **une seule opération** (`TeamConfiscation.restore`) qui baisse `johto_act1` et `storage_offline` et lève `johto_team_returned`. Tout ce qui en dépend (grotte marine, Vol entre régions, Exp ×1,5, Stockage) suit donc **sans code** si l'étape de scène est déplacée | Le déplacement ne coûte que des données de scène (§5) |
| A-2 | Le verrou de la Route 42 et la suite de l'acte 2 lisent `johto_act2`, posé au hall de la Tour par T-34 | `johto_act2` passe à la fin de l'arc ; il faut un drapeau neuf pour la quête (§7) |
| A-3 | **JH-42 (validé)** dit que Cenere abandonne l'équipe dans le bureau. Si l'équipe ne revient pas, cet arbitrage tombe, et T-21, T-23, T-24, T-26 changent | À rouvrir : JH-61 |
| A-4 | Le Stockage est une **liste unique** sans boîtes, et il contient les Pokémon de Kanto. Le rouvrir pendant l'arc rendrait au joueur ses Pokémon de niveau 50+ avant l'heure | Le Stockage reste fermé pendant l'arc (JH-71) |
| A-5 | Tant que le Stockage est fermé, **tous** les Pokémon de Johto du joueur sont dans l'équipe : au moment du pouvoir, « nés à Johto » = « l'équipe du moment ». Pas besoin de champ neuf | Simplifie JH-67 ; `met_map` existe de toute façon sur chaque Pokémon |
| A-6 | Aucune CS ne peut être exigée : les CS sont gardées, mais rien ne garantit qu'un Pokémon de Johto les apprenne | Aucune Surf, Force ou Coupe obligatoire dans l'arc (d'où le bateau et le vol) |
| A-7 | Trois petits lieux ne donnent pas plus d'≈ 40 sans bonus fort : calcul sur les 26 Dresseurs du §10 et 90 combats sauvages, Multi Exp active, courbe d'Exp moyenne (§9) | Courbe calée sur ≈ 30 à ≈ 40 ; c'est le Réveil qui fait le saut (§13) |
| A-8 | Les Sbires de Rosalia veulent **réveiller** les trois chiens (R-12, R-17) et le doyen refuse d'ouvrir. Brace dit plus tard « Je savais que tu les réveillerais pour moi » (C-7) | Tient parfaitement : Dante cherche les pierres pour réveiller les chiens sans le doyen, échoue, et se rabat sur le joueur. **Aucun texte du JOH6 ne change** (JH-63) |
| A-9 | M-14 (Îles Tourbillon, JOH7 déjà dans `main`) compte « Deux erreurs de calcul » pour Cenere | Si elle est battue pendant l'arc, un mot à changer (§5.3) |
| A-10 | Oliville n'a aujourd'hui « pas de bateau » (JOH-02 §1, §3) mais déjà deux pontons, et O-20 parle de **bateaux sans pavillon**, M-1 d'un **bateau noir** | Le bateau de Cenere à Irisia vient naturellement ; le passeur s'amarre au ponton sans repeindre la ville |
| A-11 | Niveaux réels de l'acte 2 (JOH7 relevé dans les données : 49–64, moyenne 55,5) conformes au cadre §7, écrits pour une équipe de 58–64 | Le pouvoir vise cette plage (JH-66) |
| A-12 | Le JOH5 n'est pas encore dans `main`, ni les JOH6, JOH8 et JOH9. Le JOH5 fusionne tel quel (`etat-projet.md`) | L'arc modifie le JOH5 **après** sa fusion, dans sa propre branche |
| A-13 | **Trou existant** : rien ne ferme la mer au sud d'Oliville. Avec le Surf d'un Pokémon de Johto (JH-36), le joueur peut déjà aller aux Îles Tourbillon pendant l'acte 1, et l'arc allonge cette période de 3 à 4 h. Il y trouverait Cenere (62–64), Suicune et Lugia avant l'heure | Fermer ce bord tant que `johto_act2` manque : marin ou courant **[D]**, avec JOHP2 (JH-72) |

## 2. Hors périmètre

- Les Arènes d'Irisia et d'Ébènelle, leurs champions, leurs badges (cadre §1). Pas de Peter.
- La Route 44, la Route de Glace, le Phare d'Oliville (intérieur), les Routes 32, Bourg Geon, Mauville.
- Les énigmes à glissière et les chambres de Zarbi d'Or/Argent ; le quiz du doyen de l'Antre.
- La liaison à pied entre Ébènelle et Acajou : aucune (§4.1).
- Toute espèce neuve (JH-77) : Zarbi reste en décor.
- Toute baisse ou hausse des niveaux de JOH6 à JOH9 (JH-78).

## 3. L'histoire en bref

**Fin de la Tour Radio.** Dante prend l'antenne, comme prévu. Différence : il dit à Cenere de **tout
emporter**. Le joueur trouve le bureau vide, et un papier oublié : trois lieux et les mots « trois
pierres ». Le directeur offre quand même la Multi Exp. Au hall, Orme reconnaît une légende de Johto
et comprend : Dante veut les pierres pour réveiller les trois Pokémon de Rosalia sans passer par le
doyen. Il envoie le joueur chez une amie archéologue, aux Ruines d'Alpha.

**Ruines d'Alpha (JOHP1).** Une équipe de Sbires fouille les ruines, menée par le **faux employé** de
la Tour Radio, déguisé cette fois en archéologue. Le joueur déchiffre la galerie et prend la **Pierre
Mémoire** devant lui.

**Irisia (JOHP2).** Le passeur Goulven emmène le joueur sur l'île. Le bateau noir est déjà là : les
Sbires vident la Grotte de la Marée avec des pompes. Le joueur arrive au fond **trop tard** : Cenere
vient de prendre la **Pierre Marée** et repart en mer (milieu de l'arc, la course est perdue, JH-62).

**Ébènelle (JOHP3).** Corentin, messager du clan des dragons, vient chercher le joueur à Rosalia sur
son Dracolosse : l'Aïeule du clan a senti une pierre s'éveiller. Le joueur passe l'**épreuve** de
l'Antre (trois Gardiens, puis **Ysolde**, maîtresse du clan) et reçoit la **Pierre Souffle**. À l'autel,
Cenere surgit, la Pierre Marée et la mallette de Balls à la main : « Tes Pokémon contre tes deux
pierres. » Mais trois pierres dans la même salle ne restent pas sages : celle de Cenere lui échappe,
les trois se réunissent, et seul celui qui a passé l'épreuve peut les recevoir. **L'équipe de Johto se
réveille.** Le joueur écrase alors Cenere avec elle, récupère la mallette : **retour de l'équipe de
Kanto**, Stockage rétabli. Les pierres sont éteintes. Corentin ramène le joueur à Rosalia, où les
sages l'attendent : **début de l'acte 2**, sans rien changer à la suite.

## 4. Géographie **[D]**

### 4.1 Place sur la carte

```
                         Mont Argenté ── Route 28
                              │
             Lac Colère ── Route 43
                              │
  Rosalia ── Route 42 ──── Acajou          ·····  Ébènelle, Antre du Dragon
     │                                            (derrière les montagnes,
  Route 37 ─ 36 ─ 35 ── Doublonville               par les airs seulement)
     │        │
     │    Ruines d'Alpha
     │
  Route 38 ── Route 39 ── Oliville ── Routes 40-41 ── Îles Tourbillon
                             ·
                             ·····  Irisia (bateau depuis le ponton est)
```

- **Ruines d'Alpha** : au sud de la Route 36, par une ouverture neuve à l'est de l'embranchement
  (≈ (39..41, 19)) ; une barrière de chantier la ferme jusqu'à `johto_stones_quest`.
- **Irisia** : île à l'ouest des Routes 40-41. Atteinte **seulement** en bateau pendant l'arc ; le Surf
  ne s'y rend pas (dossier JOH-08 §1 inchangé).
- **Ébènelle** : à l'est d'Acajou, derrière la montagne, **sans lien à pied** avec Acajou ni la Route 42.

### 4.2 Cartes

| Jalon | Carte | Taille indicative | Contenu |
|---|---|---|---|
| JOHP1 | **Ruines d'Alpha, extérieur** | ≈ 36 × 30 | Plateau herbeux, murets, 2 poches d'herbes hautes ; tente d'Héloïse ; entrée de la Galerie |
| JOHP1 | Tente d'Héloïse | ≈ 8 × 7 | Intérieur, carnets, moulages |
| JOHP1 | **Galerie des Glyphes** | ≈ 24 × 18 | Couloirs, 3 murs d'inscriptions, dalles à glyphes ; Sbires |
| JOHP1 | **Chambre de la Mémoire** | ≈ 14 × 12 | Salle ronde, socle, Pierre Mémoire |
| JOHP2 | **Le Goéland** (pont) | ≈ 16 × 8 | Bateau de Goulven, une seule scène et un Dresseur ; traversée en fondu |
| JOHP2 | **Irisia** | ≈ 32 × 28 | Village de pêcheurs ; Centre, maison de Goulven, 1 maison, plage ; le bateau noir au large ; entrée de la Grotte |
| JOHP2 | **Grotte de la Marée 1F** | ≈ 26 × 20 | Cave à demi vidée, pompes Rocket |
| JOHP2 | **Grotte de la Marée B1F** | ≈ 20 × 16 | Deux vannes, le bassin, le socle vide |
| JOHP3 | **Ébènelle** | ≈ 32 × 30 | Village de montagne ; Centre, maison de l'Aïeule, 1 maison, aire d'atterrissage ; entrée de l'Antre |
| JOHP3 | **Antre du Dragon 1F** | ≈ 28 × 24 | Trois salles des Gardiens, une sur chaque côté ; sol praticable partout (pas de Surf) |
| JOHP3 | **Sanctuaire de l'Antre** | ≈ 22 × 18 | Ysolde, l'autel, le grand bassin en décor |

Total : **11 cartes neuves** plus 2 ou 3 intérieurs sur modèles de Johto (Centre d'Irisia, Centre
d'Ébènelle, maisons). Retouches : Route 36 (ouverture sud), Oliville (bateau posé en objet sur le
ponton (40..41, 34..37), sans repeindre), Rosalia (aire d'atterrissage sur une place déjà libre).

## 5. Ce qui change dans les jalons existants

### 5.1 JOH5, Tour Radio (dossier JOH-06, branche `claude/joh5-tour-radio-dfd1ba`)

| Élément | Changement |
|---|---|
| T-21 (ordre de Dante) | Réécrit : « Prends tout » (§17) |
| T-23 (Cenere part) | Réécrit : elle emporte la mallette |
| T-24 (bureau) | Réécrit : bureau vide, papier oublié |
| T-25 | Inchangé |
| T-26 (directeur) | Réécrit : il a tout vu, le relais du réseau est parti aussi |
| T-27 à T-30 | **Déplacés** à la fin de l'arc, mêmes mots (P-34 à P-37) |
| T-31 | Dernière bulle réécrite (plus d'« anciens » à côté de qui apprendre) |
| T-32 | Une bulle ajoutée : le réseau de Kanto reste coupé |
| T-33 | Inchangé (l'Agente garde les preuves) |
| T-34 | Fin réécrite ; suivi de la légende (P-1) ; la phrase sur les sages part à la fin de l'arc |
| T-35 à T-37 | Inchangés |
| T-38 | Inchangé (il joue simplement plus tard, à `johto_team_returned`) |
| §4 étapes 7 à 9 | La scène `goldenrod_radio_office` perd l'étape de retour d'équipe et sa sauvegarde dédiée ; la scène du hall pose `johto_stones_quest` au lieu de `johto_act2` |
| §7 | Déplacé ici (§14) ; écran des 6, fusion des sacs, Stockage : mêmes systèmes |
| Conditions | Les PNJ des 1F et 5F et les objectifs (`data/npcs/goldenrod_radio_tower_*.json`, `objectives.json`) lisent `johto_team_returned` ou `johto_act2` : ils passent sur `johto_radio_office_done` et `johto_stones_quest` |
| Multi Exp | **Reste à la Tour** (JH-14 tenu) : elle sert toute l'équipe de Johto pendant l'arc |
| Tests | Tests du JOH5, objectif `free_radio_tower` et plan `jalon-joh5.md` à réaligner ; test du retour déplacé |

### 5.2 JOH6 (dossier JOH-07)

- **Aucun texte ne change.** C-1, C-2 et C-7 tiennent (A-8). Le doyen ouvre la Tour Cendrée au retour
  de l'Antre (`johto_act2` posé en fin d'arc).
- §2 (équipe attendue) à réécrire : équipe de Ligue 55–65 **et** équipe de Johto 55–62.
- Aucun niveau ne change.

### 5.3 JOH7 (dossier JOH-08)

- **M-14** : « Deux erreurs de calcul » devient « Trois erreurs de calcul » (JH-74).
- Rien d'autre ; §1 garde « Irisia hors de ce jalon ».

### 5.4 Cadre et systèmes

- Cadre §1 (retirer Irisia, Ébènelle, Antre du Dragon), §3 (carte, liste), §4.2 et §4.3 (scénario),
  §5.3, §7 (courbe), §8 (Cenere, nouveaux personnages), §9 (art), §10 (jalons).
- JOH-01 §6.4 et §10 : le retour se joue à l'Antre ; `johto_act1` dure jusqu'à la fin de l'arc.
- Roadmap : à mettre à jour **seulement** sur accord de Kevin.

## 6. Ordre de jeu

| Étape | Lieu | Ce qui se passe | Drapeau |
|---|---|---|---|
| 1 | Tour Radio 5F | T-19 à T-22 ; Cenere part avec la mallette (T-23') | `johto_dante_revealed` |
| 2 | Bureau | Bureau vide, directeur, papier, Multi Exp | `johto_radio_office_done`, `radio_exp_share_given` |
| 3 | Hall | L'Agente garde les preuves ; Orme et la légende (T-34', P-1) | `johto_stones_quest` |
| 4 | Route 36 | La barrière de chantier s'ouvre (P-2) | — |
| 5 | Ruines, tente | Héloïse raconte, donne les indices (P-3, P-4) | `johto_alph_met` |
| 6 | Galerie | 3 Sbires, 3 murs d'inscriptions, dalles (§8.1) | `johto_alph_tiles_done` |
| 7 | Chambre | **Faux archéologue** (obligatoire) ; Pierre Mémoire | `johto_stone_memory` |
| 8 | Ruines, tente | Héloïse envoie le joueur à Oliville (P-10) | — |
| 9 | Oliville, ponton | Goulven appareille (P-11, P-12) ; le joueur peut refuser et revenir | `johto_ferry_open` |
| 10 | Irisia | Le bateau noir, les habitants ; 3 Dresseurs libres | `johto_cianwood_arrived` |
| 11 | Grotte 1F, B1F | Sbires, Scientifique, vannes (§8.2) | `johto_tide_valves_done` |
| 12 | Grotte B1F | **Chef de cale** (obligatoire) ; socle vide ; Cenere part (P-17 à P-19) | `johto_stone_tide_lost` |
| 13 | Irisia, Oliville | Retour avec Goulven, qui envoie le joueur à Rosalia (P-19b) ; va-et-vient libre ensuite | — |
| 14 | Rosalia | Corentin et son Dracolosse (P-20, P-21) ; le vol | `johto_clan_called` |
| 15 | Ébènelle | L'Aïeule explique l'épreuve (P-22, P-23) | `johto_blackthorn_arrived` |
| 16 | Antre 1F | Trois Gardiens, dans n'importe quel ordre | `johto_clan_guardians_done` |
| 17 | Sanctuaire | **Ysolde** (obligatoire) ; Pierre Souffle (P-26, P-27) | `johto_clan_trial_done`, `johto_stone_breath` |
| 18 | Sanctuaire | Cenere, l'autel, le réveil (§13) | `johto_stones_awakened` |
| 19 | Sanctuaire | **Cenere** (obligatoire) ; la mallette | `johto_cenere_defeated_arc` |
| 20 | Sanctuaire | **Retour de l'équipe** (§14) | `johto_team_returned` ; retire `johto_act1`, `storage_offline` |
| 21 | Rosalia | Corentin ramène le joueur (P-38) ; le sage attend (C-1) | `johto_act2` |

Le joueur peut revenir en arrière à pied entre les étapes (Doublonville, Écorcia, Oliville…). Ordre
imposé par les drapeaux : voir JH-72.

## 7. Drapeaux **[D]**

Neufs : `johto_stones_quest`, `johto_radio_office_done`, `johto_alph_met`, `johto_alph_tiles_done`,
`johto_stone_memory`, `johto_ferry_open`, `johto_cianwood_arrived`, `johto_tide_valves_done`,
`johto_stone_tide_lost`, `johto_clan_called`, `johto_blackthorn_arrived`,
`johto_clan_guardians_done`, `johto_clan_trial_done`, `johto_stone_breath`, `johto_stones_awakened`,
`johto_cenere_defeated_arc`. Plus les gains de Dresseurs et objets habituels.

Déplacés (mêmes noms) : `johto_team_returned`, `johto_act2`.

## 8. Les trois lieux

### 8.1 Ruines d'Alpha (JOHP1)

- **Héloïse** : archéologue, amie d'Orme, sèche, passionnée. Modèle `chercheuse` existant.
- **Énigme** : trois murs portent chacun un mot de la légende (« se souvient », « revient »,
  « respire »). La salle du fond a douze dalles à glyphes : marcher dans le bon ordre ouvre la porte ;
  une erreur renvoie à l'entrée de la salle. Pas de système neuf : déclencheurs et drapeaux.
- **Faux archéologue** : le faux employé de la Tour Radio (T-2 à T-4), toujours aussi fier de ses
  déguisements. Comique, obligatoire, il repart sans rien.

### 8.2 Irisia (JOHP2)

- **Goulven** : vieux passeur, bourru. Modèle `marin` existant ; le Goéland est un objet peint.
- **Énigme** : les Sbires ont vidé le 1F avec des pompes. Au B1F, deux vannes changent le niveau de
  l'eau (porte d'un `FlagGate`, comme les courants du JOH7), ce qui ouvre l'un ou l'autre chemin vers
  le bassin. **Pas de Surf.**
- **Revers** (JH-62) : le socle est vide, Cenere s'enfuit. Le joueur gagne quand même un Super Bonbon
  et les objets de la Grotte, et le chef de cale reste un vrai combat.

### 8.3 Ébènelle et l'Antre (JOHP3)

- **Le clan des dragons** (JH-65) : personnages neufs. **L'Aïeule**, doyenne aveugle qui « entend » les
  pierres ; **Ysolde**, maîtresse du clan, exigeante et droite ; **Corentin**, messager, jeune et
  bavard ; trois **Gardiens** ; deux apprentis.
- **L'épreuve** : le clan ne pose pas de question. « Le dragon ne juge pas la force, il juge ce qui
  reste quand on n'en a plus. » Trois Gardiens à battre, puis Ysolde. L'Aïeule soigne l'équipe une
  seule fois, avant Ysolde.
- **Pourquoi l'épreuve compte** : seule une personne qui l'a passée peut recevoir le pouvoir. C'est
  l'erreur de calcul de Cenere.

## 9. Courbe de niveau

**Exp calculée** : 26 Dresseurs du §10 (Exp de base réelles des espèces), 30 combats sauvages par lieu,
Multi Exp active (le total est partagé, il ne grandit pas), ×1,5 de l'acte 1 gardé (décision de Kevin,
JH-70), départ au niveau 30. Le ×1,5 dure tant que `johto_act1` est levé, donc jusqu'au retour de
l'équipe : **rien à coder**.

| Fin de… | Équipe de 6 | Équipe de 4 | Équipe de 3 |
|---|---|---|---|
| JOHP1 Ruines | 32,4 | 33,5 | 34,5 |
| JOHP2 Irisia | 35,1 | 37,2 | 39,1 |
| **JOHP3 Antre** | **38,5** | **41,6** | **44,3** |

Autrement dit, ≈ 40 pour une équipe jouée normalement, ≈ 44 pour un joueur qui ne fait monter que
trois Pokémon. Les adversaires sont réglés sur ces valeurs, avec l'avance habituelle de 2 à 3 niveaux.

| Moment | Équipe attendue | Sauvages | Dresseurs | Boss |
|---|---|---|---|---|
| Sortie de Tour Radio | 28–32 | — | — | — |
| JOHP1 Ruines | 30–34 | 27–31 | 30–33 | Faux archéologue 34–35 |
| JOHP2 Irisia | 33–37 | 30–34 | 33–36 | Chef de cale 37–38 |
| JOHP3 Ébènelle, Antre | 36–40 | 33–37 | 36–40 | Ysolde 42–45 |
| **Le Réveil** | **≈ 40 → 55–62 (§13)** | | | Cenere 54–56 |
| **Retour de l'équipe** | Johto 55–62 + Kanto 55–65 | | | |
| JOH6 (inchangé) | 58–64 | 40–50 | 46–60 | Brace 60–62 |

## 10. Dresseurs **[D]**

| Où | Dresseur | Équipe | Évitable |
|---|---|---|---|
| Ruines, ext. | Chercheuse Agnès | Kadabra 31, Nosferalto 30 | oui |
| Ruines, ext. | Intello Rémi | Magnéton 31, Porygon 30 | oui |
| Ruines, ext. | Médium Solange | Spectrum 31, Kadabra 31 | oui |
| Galerie | Sbire (V) | Smogo 31, Rattatac 31 | oui |
| Galerie | Sbire (W) | Arbok 32 | oui |
| Galerie | Sbire (X) | Malosse 32, Cornèbre 32 | **non** (couloir) |
| Galerie | Scientifique Rocket | Magnéton 33, Électrode 33 | oui |
| Chambre | **Faux archéologue** | Arbok 34, Rattatac 34, Démolosse 35 | **non** |
| Le Goéland | Marin Yvon | Machopeur 33, Tentacruel 33 | oui |
| Irisia, plage | Pêcheur Ronan | Hypocéan 34, Tentacruel 34 | oui |
| Irisia | Karatéka Tanguy | Machopeur 34, Kicklee 34 | oui |
| Irisia | Topdresseuse Maëlle | Staross 35, Poissirène 34 | oui |
| Grotte 1F | Sbire (Y) | Nosferalto 34, Smogogo 34 | oui |
| Grotte 1F | Sbire (Z) | Rattatac 35, Arbok 35 | **non** (passage) |
| Grotte B1F | Sbire (AA) | Démolosse 36, Cornèbre 36 | oui |
| Grotte B1F | Scientifique Rocket | Électrode 36, Magnéton 36, Porygon 35 | oui |
| Grotte B1F | **Chef de cale** | Grotadmorv 37, Noarfang 37, Démolosse 38 | **non** |
| Ébènelle | Apprentie Nolwenn | Draco 36, Hypocéan 36 | oui |
| Ébènelle | Apprenti Malo | Draco 37, Léviator 36 | oui |
| Ébènelle | Montagnard Hervé | Gravalanch 37, Onix 37 | oui |
| Antre 1F | Sbire (AB) | Démolosse 37, Smogogo 37 | oui |
| Antre 1F | Sbire (AC) | Rattatac 38, Noarfang 38 | oui |
| Antre 1F | Gardienne de l'Eau | Hypocéan 38, Lamantine 38, Draco 39 | **non** |
| Antre 1F | Gardien de la Pierre | Grolem 39, Onix 39, Draco 39 | **non** |
| Antre 1F | Gardien du Ciel | Rapasdepic 40, Noarfang 40, Draco 40 | **non** |
| Sanctuaire | **Ysolde** | Léviator 42, Draco 42, Draco 43, Hyporoi 43, Dracolosse 45 | **non** |
| Sanctuaire | **Cenere** (après le réveil) | Smogogo 54, Qulbutoké 54, Noarfang 55, Farfuret 56 | **non** |

- **Ysolde** est un grand combat (35–60 % du premier coup, mémoire « Difficulté des combats ») ; c'est
  le mur de l'arc. Dracolosse niveau 45 : exception d'histoire **[D]**, comme le Pokémon d'un maître.
- **Cenere** après le réveil doit faire **sentir la puissance** : recherche ≈ 70–80 % du premier coup,
  sans dépasser les 80 % de la règle (JH-74).
- 27 lignes : les 26 comptées au §9, plus Cenere. Le JOH4 compte 9 Dresseurs pour une taille comparable à **un** de ces lieux.

## 11. Rencontres **[D]**

Aucune espèce neuve : tout est dans les 151 de Kanto ou les 51 de Johto (les espèces de Johto sont en
gras ; toutes déjà codées).

| Carte | Moment | Espèces (poids) | Niveaux |
|---|---|---|---|
| Ruines, ext. | matin, jour | Abra 25, Kadabra 15, Psykokwak 20, Racaillou 20, **Fouinar** 20 | 27–31 |
| Ruines, ext. | nuit | **Hoothoot** 30, **Noarfang** 15, Fantominus 25, Nosferapti 30 | 27–31 |
| Galerie | toute la journée | Nosferapti 35, Nosferalto 15, Racaillou 25, Onix 10, Fantominus 15 | 28–32 |
| Irisia, herbes | matin, jour | Roucoups 30, Rattatac 25, Ramoloss 25, Machoc 20 | 30–34 |
| Irisia, herbes | nuit | **Noarfang** 35, Rattatac 30, Ramoloss 35 | 30–34 |
| Irisia, pêche | toute la journée | Canne : Magicarpe ; Super Canne : Krabby, Hypotrempe, Poissirène | comme Kanto |
| Grotte 1F | toute la journée | Krabby 30, Kokiyas 25, Stari 20, Tentacool 25 | 31–34 |
| Grotte B1F | toute la journée | Krabboss 25, Tentacruel 25, Lamantine 25, Stari 25 | 32–35 |
| Ébènelle, herbes | matin, jour | Machopeur 25, Gravalanch 25, Rapasdepic 25, **Marill** 25 | 33–37 |
| Ébènelle, herbes | nuit | **Noarfang** 35, Gravalanch 30, Nosferalto 35 | 33–37 |
| Antre 1F | toute la journée | **Minidraco 45, Draco 10**, Magicarpe 25, Hypotrempe 20 | 34–38 |

- Minidraco, Draco et Dracolosse : déjà dans les données de Kanto, avec leur art. Aucun art Pokémon à produire.
- Pas de rencontre au Sanctuaire ni dans la Chambre **[D]**.
- Une capture à 6 Pokémon : voir JH-71.

## 12. Objets **[D]**

| Où | Objet |
|---|---|
| Ruines, ext. | Super Potion ×2 ; Rappel (caché) |
| Galerie | Hyper Potion |
| Irisia | Ultra Ball ×3 (Goulven, à la première traversée) |
| Grotte 1F | Hyper Potion |
| Grotte B1F | Super Bonbon (au pied du socle, après le revers) |
| Ébènelle | Rappel Max (maison) |
| Antre 1F | Super Bonbon (caché) ; CT13 Laser Glace (le seul appui contre les dragons sans Farfuret) |

**Trois objets clés neufs** : Pierre Mémoire, Pierre Marée, Pierre Souffle (icônes neuves, ils quittent
le Sac au réveil). La Pierre Marée n'entre jamais dans le Sac du joueur (JH-62).

## 13. Le réveil (le pouvoir des pierres)

### 13.1 Règle (JH-66 à JH-69)

- **Cible** : moyenne des **trois plus hauts niveaux** de l'équipe de Kanto confisquée, arrondie à
  l'entier, **bornée à 55–62**. Une équipe de Kanto avec deux Pokémon faibles (porteurs de CS) ne fait
  pas baisser la cible ; une équipe très forte ne fait pas sortir l'arc de la plage du JOH6.
- **Qui** : tous les Pokémon rencontrés à Johto, sous la cible. Pas de baisse pour ceux qui sont déjà au-dessus.
- **Une seule fois**, à cette scène. Les pierres s'éteignent. Les captures d'après ne sont pas
  concernées (les sauvages de l'acte 2 sont déjà à 40–50).
- **Effet** : niveau = cible, XP au minimum de ce niveau, statistiques recalculées, PV et PP pleins,
  statut retiré. Le lien (`bond`) ne bouge pas (règle « pas de raccourci », JOH-01 §8.1).

### 13.2 Déroulé à l'écran : le moment fort du chapitre

Toute la fin de l'arc prépare un seul effet : le joueur doit **sentir** ≈ 18 niveaux d'un coup. Trois
temps : la faiblesse, le Réveil, la preuve.

**Avant, la faiblesse.** Ysolde vient de pousser l'équipe à bout. Cenere pose la mallette et, pour
prouver son calcul, fait frapper son Farfuret (niveau 56) : scène sans combat, le Pokémon de tête du
joueur est projeté d'un seul coup (P-28b). Le joueur voit de quoi l'équipe de Johto est capable sans
les pierres : de rien.

**Le Réveil** (≈ 60 à 90 s, non passable la première fois **[D]**) :

1. **Silence.** La musique s'arrête net. Les pierres tremblent, la Pierre Marée quitte la main de
   Cenere, les trois se rejoignent sur l'autel (P-29). Seul un battement sourd, de plus en plus fort.
2. **La lumière.** Elle sort de l'autel en trois couleurs (gris de la terre, bleu de la mer, blanc du
   ciel), emplit le Sanctuaire ; l'eau du grand bassin se soulève ; Ysolde et Cenere reculent, le
   Dracolosse d'Ysolde baisse la tête. Le thème du Réveil commence, à voix basse.
3. **L'équipe, un par un.** Les Balls s'ouvrent seules. Chaque Pokémon, à commencer par celui qui a
   été frappé, se relève dans la lumière, en grand, sur un plan à lui : son cri, et un **compteur de
   niveau qui défile** (« 40… 47… 53… 58 »), sans texte. Si le Pokémon évolue, le compteur s'arrête au
   palier, la silhouette change d'un coup, et il repart. Une chaîne entière se joue ainsi d'une traite
   (un Chenipan de niveau 6 passe directement à Papilusion). ≈ 6 à 8 s par Pokémon, sans question ni
   annulation ; espèces par lien (Togetic, Nostenfer) : selon la règle habituelle, si le seuil est atteint.
4. **La ligne.** Le thème éclate ; les six sont debout, côte à côte devant l'autel, plan large.
   **Une seule ligne** de système (P-31). Pas de texte par Pokémon.
5. **L'écran du Réveil** (un seul) : une ligne par Pokémon, « Niv. 40 → 58 », l'évolution, le nombre
   d'attaques nouvelles. Toucher un Pokémon ouvre le panneau d'attaques existant (`MoveForgetPanel`).
   Attaques proposées : celles de l'apprentissage entre l'ancien et le nouveau niveau, **les trois
   plus récentes** **[D]**. Bouton « Continuer » à tout moment : rien n'est imposé.
6. Une sauvegarde **en une seule écriture**, avec `johto_stones_awakened`. Les pierres s'éteignent.

**La preuve.** Sans fondu vers une autre scène, sur le même thème : Cenere envoie Farfuret, le même
(JH-74). Celui qui a été frappé peut lui rendre le coup. C'est le combat où le joueur essaie ses
nouvelles forces, et le choix des 6 qui suit montre les deux équipes au même niveau, côte à côte.

Le joueur qui recharge ou repasse la scène après une défaite contre Cenere ne revoit pas le Réveil :
il reprend à Cenere (§15).

### 13.3 Œuf et cas particuliers

- Œuf non éclos (quasi impossible à ce stade) : ignoré par le réveil **[D]**.
- Compagnon : garde son sprite d'évolution, comme d'habitude ; rafraîchi à la fin.
- Pokédex : chaque évolution note l'espèce « capturée », comme d'habitude (à tester sur le chemin
  groupé, qui n'est pas celui du combat).
- Stockage (JH-71) : les captures en trop reçoivent niveau et évolution sans écran, avec
  les 4 dernières attaques de l'apprentissage ; le Réveil l'annonce en une ligne.

## 14. Le retour de l'équipe

Mêmes systèmes que le JOH5 (dossier JOH-06 §7) :

1. Cenere battue : la mallette tombe (P-33).
2. Retrouvailles (T-27 → P-34), compagnon d'avant le vol qui bondit.
3. Choix des 6 (JH-24, T-28 → P-35) : **la force du Réveil se voit ici** : les deux équipes sont au même
   niveau sur le même écran.
4. Stockage rétabli (T-29 → P-36) : le relais était dans la mallette. Sacs fusionnés (T-30 → P-37).
5. Une seule écriture ; `johto_act1` et `storage_offline` baissés ; grotte marine et Vol entre
   régions ouverts, comme prévu.

## 15. Cas limites (à tester)

- Application tuée pendant le réveil : avant l'écriture, rien n'a changé et la scène reprend à l'autel ;
  après, `johto_stones_awakened` est posé et la scène reprend à Cenere.
- Application tuée pendant l'écran du Réveil (après l'écriture) : les attaques non choisies sont perdues **[D]**.
- Défaite contre Ysolde : retour au Centre d'Ébènelle, Gardiens toujours battus.
- Défaite contre Cenere : retour au Centre d'Ébènelle, réveil acquis, Cenere à l'autel, mallette non rendue.
- Défaite ailleurs pendant l'arc : au dernier Centre, comme à Kanto.
- Équipe sans aucun Pokémon sous la cible (impossible sans triche) : le réveil se joue sans écran.
- Le joueur a Vol avec un Pokémon de Johto : il vole dans Johto, jamais vers Kanto (JH-18 inchangé).
- Surf au sud d'Oliville avant `johto_act2` : refusé une fois A-13 corrigé (à tester).
- **Sauvegardes déjà passées par le bureau** (`johto_team_returned` posé avant l'arc) : l'arc reste fermé, pas de migration (JH-75).

## 16. Ampleur

| Poste | Estimation |
|---|---|
| Cartes | 11 neuves + 2 ou 3 intérieurs ; 3 retouches (≈ + 35 % sur les 35 cartes du chapitre) |
| Dresseurs | 26 + Cenere, dont 3 boss et 3 Gardiens ; le JOH4 : 9 |
| Vues peintes | 10 vues générales (grilles d'abord), Route 36 retouchée |
| Personnages neufs | Ysolde, Corentin, l'Aïeule, tenue du clan (Gardiens et apprentis, 2 modèles), Goulven si `marin` ne suffit pas |
| Objets et décors | 3 icônes de pierres, Le Goéland, le bateau noir, l'autel, pompes |
| Scènes | Dracolosse en vol (2 sens) ; **le Réveil**, à soigner comme une scène de fin de chapitre : effet de lumière en trois couleurs, plans par Pokémon avec compteur de niveau, plan large final, écran du Réveil |
| Espèces, art Pokémon | **Aucune** (JH-77) |
| Son | Pistes de HeartGold / SoulSilver pour les trois lieux ; **un thème pour le Réveil**, à choisir avec Kevin (silence, montée, éclat, puis combat) |
| Système neuf | Le Réveil seul : calcul de cible, évolutions groupées, écran. Le reste est du déjà vu |
| Durée de jeu | ≈ 3 h à 4 h (1 h, 1 h, 1 h 30 à 2 h) ; l'acte 1 en fait ≈ 4 h |
| Découpage | **JOHP0** (Réveil, seul, avec tests de sauvegarde **[D]**), puis JOHP1, JOHP2, JOHP3 ; déplacement du retour d'équipe avec JOHP3, validation seule (règle 1) |

## 17. Textes (à valider en un lot)

Format : bulles séparées par « / ». `{joueur}`, `{pokemon}` = noms ; *italique* = voix, légende.

| N° | Où | Texte |
|---|---|---|
| T-21' | **Dante**, l'ordre de retraite | *Cenere. Prends tout. On part.* |
| T-23' | Cenere, départ | Tu as entendu. / Tes Pokémon étaient dans ce bureau. Étaient. / Un Maître sans son équipe, c'est une variable de moins dans mes calculs. · *(système)* Cenere s'en va par l'escalier de secours, une mallette à la main… |
| T-24' | Système, le bureau | La porte du bureau est ouverte. / Sur la table, rien. / Juste un papier tombé par terre. |
| T-26' | Directeur, libéré | Merci ! Ils m'ont enfermé dans mon propre bureau. / Tes Poké Balls ? Elle les a mises dans une mallette, avec ton sac. / Et le relais du réseau de Kanto, aussi. / Elle a laissé tomber ce papier. · *(système)* « Ruines d'Alpha. Irisia. Ébènelle. Réunir les trois pierres. » |
| T-31' | Directeur, la Multi Exp (dernière bulle) | Avec, toute ton équipe apprendra à chaque combat. |
| T-32' | Directeur, après | L'ascenseur remarche. Les émissions reprendront dès ce soir. / Le réseau de Kanto, lui, restera coupé tant que le relais ne sera pas revenu. / Reviens nous voir quand tu veux. |
| T-34' | Orme, 1F | {joueur} ! J'ai tout entendu à la radio. / Dante… Chen m'a parlé de lui, un jour. Il le croyait disparu depuis des années. / « Quand tout sera cendres »… Ça ne me plaît pas. / Et ils ont emporté ton équipe ? Fais voir ce papier. / … Trois pierres. Je connais cette histoire. |
| P-1 | Orme, la légende | *Trois pierres dorment aux trois bouts de Johto.* / *La première se souvient. La deuxième revient. La troisième respire.* / *Réunies, elles réveillent ce qui est né sur cette terre.* / Les sages de Rosalia ne lui ouvriront jamais leur tour. / Mais avec ces pierres, il n'aurait pas besoin d'eux pour réveiller ce qui dort dessous. / Une amie fouille les Ruines d'Alpha, au sud de la Route 36. Elle s'appelle Héloïse. Va la voir, et vite. |
| P-2 | Ouvrier, Route 36 | Le chantier des ruines ? Le Professeur Orme a appelé. / Passe, c'est ouvert. |
| P-3 | Héloïse, accueil | Orme m'a prévenue. Ne touche à rien. / Des gens en noir fouillent ma galerie depuis trois jours. Ils disent qu'ils sont archéologues. / Ils tiennent leurs pelles à l'envers. |
| P-4 | Héloïse, les murs | La Pierre Mémoire est au fond. Personne n'y est jamais entré. / Lis les murs. Ils disent dans quel ordre marcher. / Les anciens n'écrivaient pas pour décorer. |
| P-5 | Examen, mur 1 · 2 · 3 | Des signes gravés. Héloïse a noté en dessous : « celle qui se souvient ». · « celle qui revient ». · « celle qui respire ». |
| P-6 | Faux archéologue, avant | Halte ! Je suis un éminent savant ! / … Toi ? Le gamin de la Tour Radio ? / Mon déguisement était parfait, pourtant ! |
| P-7 | Faux archéologue, défaite · après | défaite : La science a parlé. Elle a dit non. · après : Je vais en entendre parler, moi… Cenere va me faire recalculer. *(système)* Le faux archéologue arrache sa fausse barbe et s'enfuit ! |
| P-8 | Système, la pierre | Au centre de la salle, une pierre grise, tiède sous la main. / {joueur} obtient la Pierre Mémoire ! |
| P-9 | Description, Pierre Mémoire · Marée · Souffle | Une pierre grise, tiède, couverte de signes. · Une pierre bleue, toujours humide. · Une pierre blanche qui semble se soulever, très lentement. |
| P-10 | Héloïse, après | Elle est tiède. C'est tout ce que je peux en dire. / La deuxième est à Irisia, dans une grotte qui se noie à chaque marée. / Il n'y a pas de route. Va voir le vieux Goulven, au port d'Oliville. Dis que c'est moi. |
| P-11 | Goulven, ponton (avant la Pierre Mémoire) | Le Goéland reste à quai. / Je ne fais pas la traversée pour un inconnu. |
| P-12 | Goulven, départ | Héloïse t'envoie ? Elle me doit encore deux filets. / Irisia, c'est ça ? Tiens, pour la route. / Monte. La mer est bonne, aujourd'hui. |
| P-13 | Goulven, en mer | Tu vois ce bateau, là-bas ? Noir, sans pavillon. / Il fait route vers mon île depuis l'aube. / Je n'aime pas ça. |
| P-14 | Habitante, Irisia | Depuis hier, la grotte fait un bruit de machine. / Et la mer n'y remonte plus. |
| P-15 | Examen, pompe | Une pompe énorme aspire l'eau de la grotte. / Une étiquette dit : « Team Rocket, propriété de Dante ». |
| P-16 | Chef de cale, avant · défaite | avant : Tu arrives trop tard, le gamin. / Mais je vais quand même te faire regretter le voyage. · défaite : Vas-y, regarde. Tu verras bien. |
| P-17 | Système, le socle | L'eau a baissé. Au fond du bassin, un socle de pierre. / Il est vide. |
| P-18 | Cenere, à l'ouverture du B1F sur la mer | Quatorze minutes de retard. / Tu t'améliores. / La Pierre Marée est à moi. Tes Pokémon aussi. / Il m'en reste une à prendre, et celle que tu as dans ta poche. |
| P-19 | Cenere, départ · système | Je ne me fatigue pas à te combattre. Tu viendras à moi. · *(système)* Cenere remonte sur le bateau noir. Le bateau s'éloigne… |
| P-19b | Goulven, retour à Oliville | Tu as la tête de quelqu'un qui a perdu. / Tiens, un drôle de gars t'a cherché ce matin. Il est descendu du ciel sur un Dracolosse. / Il a dit qu'il t'attendrait à Rosalia. |
| P-20 | Corentin, Rosalia | Enfin ! Toi, c'est {joueur} ? Je te cherche depuis Oliville ! / Corentin, messager du clan des dragons, d'Ébènelle. / L'Aïeule a entendu une pierre se réveiller. Elle a dit : « amène-moi celui qui la porte. » / Tu as déjà volé sur un Dracolosse ? Non ? C'est très facile. Tiens-toi bien. |
| P-21 | Système, le vol | Le Dracolosse de Corentin déploie ses ailes ! / {joueur} s'accroche ! |
| P-22 | L'Aïeule | Approche. Non, ne dis rien. Je t'ai entendu monter. / La pierre grise est avec toi. La bleue est partie sur l'eau. La blanche dort ici, chez nous. / Mes yeux ne voient plus, mais les pierres parlent fort. |
| P-23 | L'Aïeule, l'épreuve | La blanche ne se donne pas. / Le dragon ne juge pas la force. Il juge ce qui reste quand on n'en a plus. / Va dans l'Antre. Trois Gardiens, puis ma petite-fille. / Si tu tiens debout à la fin, la pierre est à toi. |
| P-24 | Gardiens, avant · défaite (générique) | Eau — avant : L'eau use la pierre, et elle a tout le temps. · défaite : Tu ne t'es pas laissé user. — Pierre — avant : Tu trembles ? La pierre, non. · défaite : Tu ne trembles pas non plus. — Ciel — avant : Regarde en haut. C'est là que tout tombe. · défaite : Tu es resté debout. |
| P-25 | L'Aïeule, avant Ysolde | Viens, je soigne ton équipe. Une fois. Pas deux. · *(système)* L'équipe de {joueur} est soignée. |
| P-26 | Ysolde, avant | Je suis Ysolde. / Tu n'as que de jeunes Pokémon, et une mission qui n'est pas la tienne. / Moi, je n'ai rien contre toi. Mes dragons non plus. C'est pour ça qu'ils ne te feront aucun cadeau. |
| P-27 | Ysolde, défaite · la pierre | défaite : … Tu tiens debout. · la pierre : Le clan garde cette pierre depuis sept cents ans. / Elle est à toi. Porte-la à l'autel. · *(système)* {joueur} obtient la Pierre Souffle ! |
| P-28 | Cenere, à l'autel | Merci d'avoir fait le voyage. / J'ai ma pierre. Tu as les deux autres. / Et moi, j'ai ceci. · *(système)* Cenere pose une mallette à ses pieds. / Tes six Pokémon contre tes pierres. Le calcul est simple. |
| P-28b | Cenere, la démonstration | Tu hésites ? Regarde ce que valent tes Pokémon. · *(système)* Le Farfuret de Cenere bondit ! {pokemon} est projeté contre l'autel ! · Cenere : Voilà ce que tu as. Voilà ce que j'ai. Les pierres, maintenant. |
| P-29 | Système, la réunion | Les pierres se mettent à trembler. / La Pierre Marée s'échappe de la main de Cenere ! / Les trois pierres se rejoignent sur l'autel ! |
| P-30 | Ysolde, Cenere | Ysolde : Elles ne se donnent qu'à qui a passé l'épreuve. / Cenere : … Ce n'était pas dans les données. |
| P-31 | Système, le réveil | Une lumière monte de la terre, de la mer et du ciel. / Les Pokémon nés à Johto se réveillent ! |
| P-32 | Cenere, avant · défaite | avant : … C'est impossible. Recommence, Farfuret. · défaite : … Ils changent tout. Deuxième erreur. |
| P-33 | Cenere, après | La mallette n'est plus utile. Garde-la. / Le maître n'a plus besoin des pierres. Il a mieux : toi. / Tu verras. · *(système)* Cenere s'en va… |
| P-34 | Système, retrouvailles (T-27) | {pokemon} sort de sa Poké Ball et bondit vers {joueur} ! / {joueur} retrouve son équipe et son sac ! |
| P-35 | Écran de sélection (T-28) | Choisis les six Pokémon qui t'accompagnent. / Les autres iront au Stockage. |
| P-36 | Système, Stockage (T-29) | Connexion au réseau de Kanto… / … / Connexion rétablie ! Les autres Pokémon sont au Stockage. |
| P-37 | Système, sac (T-30) | Les objets de ton ancien sac ont rejoint les nouveaux. |
| P-38 | Corentin, retour | Les pierres sont éteintes, l'Aïeule dit qu'elles ont fini leur travail. / Et les sages de Rosalia ont appelé le clan. Ils te cherchent. / Allez, je te dépose devant leur porte ! |
| P-39 | L'Aïeule, après | Ce qui dort sous Rosalia ne dormira plus longtemps. / Les pierres n'y sont plus pour rien. Les hommes, si. |
| P-40 | Descriptions de zone | Ruines d'Alpha : Des ruines plus vieilles que Johto, et qui se souviennent. · Irisia : Une île de pêcheurs, au bout de la mer. · Grotte de la Marée : Une grotte que la mer visite deux fois par jour. · Ébènelle : Un village perché, au pays des dragons. · Antre du Dragon : Là où le clan des dragons met ses enfants à l'épreuve. |
| P-41 | Panneaux | **RUINES D'ALPHA** / Fouilles en cours. Ne rien emporter. · **IRISIA** / L'île au bout de la mer · **GROTTE DE LA MARÉE** / Entrée interdite à marée haute · **ÉBÈNELLE** / Le village du clan des dragons · **ANTRE DU DRAGON** / Réservé au clan |
| P-42 | Ouvrier, Route 36 (avant la Tour) | Chantier de fouilles. / Entrée réservée au personnel. |
| P-43 | Agnès · Rémi · Solange (Ruines) | Agnès — avant : Une chercheuse doit tester ses hypothèses. Toi, par exemple. · défaite : Hypothèse rejetée. · après : Ces signes changent quand on ne les regarde pas. Je te jure. — Rémi — avant : J'ai calculé l'âge de ces murs. Veux-tu calculer ta défaite ? · défaite : J'ai oublié une retenue. · après : Personne n'a jamais compté toutes les dalles. — Solange — avant : Les ruines murmurent. Écoute-les avec moi. · défaite : Elles murmuraient ton nom. · après : La nuit, les signes bougent sur les murs. |
| P-44 | Sbires V · W · X, Scientifique (Galerie) | V — avant : On creuse ! Dégage ! · défaite : Ma pelle… · après : On cherche un caillou. Trois jours pour un caillou. — W — avant : Pas de visite aujourd'hui ! · défaite : La visite est terminée. · après : Le patron des fouilles porte une fausse barbe. Ne lui dis pas que ça se voit. — X — avant : Tu ne passeras pas ce couloir ! · défaite : Bon, si. · après : Personne ne comprend ces dalles. Elles nous renvoient toujours au début. — Scientifique — avant : Ces signes sont du bruit. Mes machines le prouveront. · défaite : Du bruit. Rien que du bruit. · après : Comment peut-on lire ça ? |
| P-45 | Examen, dalles | bonne dalle : Le signe s'éclaire. · mauvaise dalle : Le sol gronde. {joueur} est ramené à l'entrée de la salle. · fin : La porte du fond s'ouvre. |
| P-46 | Yvon · Ronan · Tanguy · Maëlle (bateau, Irisia) | Yvon — avant : À bord, on se bat pour passer le temps ! · défaite : Le temps a passé vite. · après : Goulven n'a jamais raté une traversée. — Ronan — avant : Sur cette île, le poisson décide. · défaite : Il a décidé. · après : La grotte ne se remplit plus. Les poissons ont fui. — Tanguy — avant : Je m'entraîne contre les vagues. Tu seras plus facile. · défaite : Les vagues frappent moins fort. · après : Ces hommes en noir n'ont pas salué l'île. Ça ne se fait pas. — Maëlle — avant : On vient à Irisia pour une seule raison : la mer. Et toi ? · défaite : Tu as une bonne raison. · après : Le bateau noir est là depuis hier. |
| P-47 | Sbires Y · Z · AA, Scientifique (Grotte) | Y — avant : Les pompes tournent, personne n'entre ! · défaite : Ça tourne sans moi. · après : Une grotte qu'on vide, c'est long. — Z — avant : Encore toi ? On t'a vu aux ruines ! · défaite : Et on te reverra, c'est ça le problème. · après : Cenere a dit qu'on aurait fini à l'heure. Elle a toujours raison. — AA — avant : Cenere est déjà descendue. Tu perds ton temps ! · défaite : C'est moi qui perds. · après : Vas-y, cours. Elle a calculé ça aussi. — Scientifique — avant : Niveau de l'eau, débit, durée : tout est prévu. Sauf toi. · défaite : Sauf toi. · après : Tourne les vannes si tu veux. Il est trop tard. |
| P-48 | Examen, vanne · bateau noir | vanne : {joueur} tourne la vanne. / On entend l'eau bouger, plus bas. · bateau : Un bateau noir, sans pavillon, à l'ancre devant l'île. |
| P-49 | Nolwenn · Malo · Hervé (Ébènelle) | Nolwenn — avant : Je suis apprentie, mais mon Draco, lui, ne l'est pas ! · défaite : Il a encore à apprendre. Moi aussi. · après : L'Aïeule entend tout. Ne dis pas de mal d'elle, même ici. — Malo — avant : Tu es venu sur le Dracolosse de Corentin ? Il t'a parlé tout le long ? · défaite : Il parle mieux qu'il ne se bat. Moi aussi. · après : Il n'y a qu'un moyen de quitter le village : par les airs. — Hervé — avant : Je suis monté à pied. Trois semaines. Montre-moi que ça en valait la peine. · défaite : Ça en valait la peine. · après : Acajou est juste derrière ces montagnes. Il n'y a pas de chemin. |
| P-50 | Sbires AB · AC (Antre) | AB — avant : Le clan ne nous a pas vus entrer. Toi non plus, tu ne nous as pas vus ! · défaite : Tu nous as vus. · après : On prépare le chemin de Cenere. — AC — avant : Ces dragons me font peur. Pas toi. · défaite : Si, un peu toi aussi. · après : Elle arrive, tu sais. Elle arrive toujours. |
| P-51 | Gardiens, après | Eau : L'Aïeule te soignera quand tu auras les trois. · Pierre : Il reste deux portes. Ou une. Je ne compte pas pour toi. · Ciel : Ysolde t'attend au Sanctuaire. |
| P-52 | Ysolde, Corentin, après le Réveil | Ysolde : Cette femme a porté sa pierre jusqu'à toi. Elle n'aurait pas dû. / Le clan te doit la fin de sa garde. · Corentin : J'ai tout raté ! J'étais dehors avec le Dracolosse ! |
| P-53 | Examen, autel (après) | Trois pierres ternes, posées sur l'autel. / Elles sont froides, maintenant. |
| P-54 | Doyen, Rosalia (pendant l'arc) | Les pierres ? Une vieille histoire. / Ces hommes frappent à ma porte, et je ne l'ouvre pas. Alors ils en cherchent une autre. |
| P-55 | Goulven, après l'arc | Irisia ? Toujours. / La mer ne change pas d'avis, et moi non plus. |
| P-56 | Corentin, Rosalia, après l'arc | Ébènelle ? Monte ! / Il paraît que je parle trop. Tu trouves que je parle trop ? |
| P-57 | Héloïse, après l'arc | Elles sont éteintes, donc. / Je vais écrire trois cents pages là-dessus, et personne ne les lira. |
| P-58 | Système, capture à 6 pendant l'arc | Ton équipe est pleine. {pokemon} part au laboratoire d'Orme, qui s'en occupe en attendant. |
| P-59 | Marin, plage d'Oliville (avant `johto_act2`) | La mer est mauvaise au sud, en ce moment. / Le bateau noir rôde. Fais demi-tour. |

M-14' (JOH7) : Tu es là avant moi. Encore. / **Trois** erreurs de calcul. Ça commence à faire beaucoup.

## 18. Arbitrages pour Kevin

| N° | Question | Recommandation de Claude |
|---|---|---|
| JH-61 | ✅ **Rouvre JH-42** : Dante dit « Prends tout », Cenere emporte équipe, sac et relais du réseau (T-21', T-23') (Kevin, 2026-11-04) | — |
| JH-62 | ✅ **Cenere prend la Pierre Marée** à Irisia : revers au milieu de l'arc ; elle l'apporte elle-même à l'autel (Kevin, 2026-11-04) | — |
| JH-63 | ✅ Dante veut les pierres pour **réveiller les trois chiens** sans le doyen ; il s'en passe ensuite (C-7 tient, aucun texte du JOH6 ne change) (Kevin, 2026-11-04) | — |
| JH-64 | ✅ **Pierre Mémoire, Pierre Marée, Pierre Souffle** ; le pouvoir s'appelle **le Réveil** ; jalons **JOHP0 à JOHP3** (Kevin, 2026-11-04) | — |
| JH-65 | ✅ Clan des dragons en **personnages neufs** (Ysolde, l'Aïeule, Corentin), sans Arène ni badge (Kevin, 2026-11-04) | — |
| JH-66 | ✅ Cible du Réveil : **moyenne des 3 plus hauts niveaux de l'équipe de Kanto, bornée à 55–62** (Kevin, 2026-11-04) | — |
| JH-67 | ✅ Concernés : **l'équipe et les captures de l'arc parties au Stockage** ; pas les captures d'après ; jamais de baisse (Kevin, 2026-11-04) | — |
| JH-68 | ✅ **Usage unique** : une scène, pierres éteintes (Kevin, 2026-11-04) | — |
| JH-69 | ✅ Évolutions d'un coup, **sans annulation ni refus**, chaîne comprise ; **un seul écran du Réveil**, 3 attaques les plus récentes au choix (Kevin, 2026-11-04) | — |
| JH-70 | ✅ **Pas de ×4 ; le ×1,5 de l'acte 1 reste pendant l'arc** et s'arrête au retour de l'équipe de Kanto. Courbe ≈ 30 à ≈ 40, boss d'Ébènelle 42–45 (Kevin, 2026-11-04) | — |
| JH-71 | ✅ Stockage **fermé** pendant l'arc, mais à partir de la Tour la **capture en trop y part sans retrait possible** jusqu'à la fin de l'arc (`CaptureGate`, P-58) (Kevin, 2026-11-04) | — |
| JH-72 | ✅ **Ordre imposé** par les drapeaux (bateau après la Pierre Mémoire, Corentin après la Grotte) ; mer au sud d'Oliville fermée tant que `johto_act2` manque (A-13, P-59) (Kevin, 2026-11-04) | — |
| JH-73 | ✅ Réveil en **scène complète** (§13.2, ≈ 60 à 90 s), **non passable** la première fois, écran du Réveil ; **pas** de marque permanente (Kevin, 2026-11-04) | — |
| JH-74 | ✅ **Cenere frappe avant le Réveil, se bat après**, niveaux 54–56, ≈ 70–80 % de victoire ; retour d'équipe ensuite ; les Îles Tourbillon deviennent son troisième combat (M-14 change d'un mot) (Kevin, 2026-11-04) | — |
| JH-75 | ✅ Sauvegarde **v10 inchangée** (drapeaux seulement). Parties déjà passées par le bureau : **pas de migration**, l'arc reste fermé pour elles (Kevin, 2026-11-04) | — |
| JH-76 | ✅ Carte de Johto : **3 repères neufs**. Vol : **Irisia et Ébènelle**, ouverts une fois visités, pas de point aux Ruines. Pokédex : 202 espèces, inchangé (Kevin, 2026-11-04) | — |
| JH-77 | ✅ **Zarbi en décor seul** : signes animés et sons dans la Galerie, aucune donnée (Kevin, 2026-11-04) | — |
| JH-78 | ✅ Dresseurs de l'acte 2 : **niveaux inchangés** ; simulation de Brace, Cenere (Tourbillon) et Dante 1 avec une équipe mixte ; au-delà de 80 %, corriger par l'IA et les attaques (Kevin, 2026-11-04) | — |
| JH-79 | ✅ Après l'arc, **tout reste ouvert** : Goulven traverse toujours, Corentin garde son vol depuis Rosalia, Ruines ouvertes ; pas de revanches (Kevin, 2026-11-04) | — |

## 19. Prochaines étapes

1. ~~Kevin répond aux arbitrages~~ (fait le 2026-11-04) ; ~~propagation au cadre et aux dossiers~~ (faite,
   sauf les textes T- et M- déjà validés, réécrits seulement après le lot du §17, et la roadmap).
2. Kevin relit les textes du §17 **en un seul lot**.
3. Grilles dans `tools/plans/`, puis vues générales peintes, validées avant tout code.
4. Plan technique `docs/tech/jalon-johp.md`, puis code, après la fusion du JOH5 : JOHP0 (le Réveil),
   JOHP1, JOHP2, JOHP3.
