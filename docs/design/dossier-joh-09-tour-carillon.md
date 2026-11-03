# Dossier JOH-09 — La flamme : Tour Carillon, Dante, Entei, Ho-Oh (jalon JOH8, v0.1)

> Dernier jalon de l'acte 2 du Chapitre Johto (cadre [`dossier-joh-00-cadre.md`](dossier-joh-00-cadre.md)
> §4.3). Suite du JOH7 ([`dossier-joh-08-iles-tourbillon.md`](dossier-joh-08-iles-tourbillon.md) : Orme
> annonce que Dante a forcé la porte de la Tour Carillon avec Entei en cage, M-31, M-32). Écrit par
> Claude le 2026-11-02 ; **textes H-1 à H-38 et arbitrages JH-52 à JH-55 validés par Kevin le jour même**
> (recommandations retenues) ; le reste est à valider. Valeurs **[D]** = défauts. Grilles et vues peintes après validation.

## 1. Hors périmètre

- Le Mont Argenté, le relais du rival, Brace et Cenere, Giovanni (JOH9). Brace et Cenere **ne sont
  pas** à la Tour Carillon : Dante monte seul avec une petite escorte de Sbires **[D]**.
- Les étages 3F à 8F de la Tour Carillon d'Or/Argent : ici la tour a **trois cartes jouables**
  (cadre §3.1), le reste de la montée est un long escalier en fondu **[D]**.
- Aucun objet d'accès (ni Cloche Cristal, ni Plume Arc-en-ciel) : les sages ouvrent la porte **[D]**,
  comme le Lugia sans Argent Aile (JH-49).

## 2. Hypothèses d'entrée

- JOH7 fait : `johto_lugia_done`, `johto_bell_tower_clue` ; équipe 62–68 attendue (cadre §7).
- Raikou et Suicune ont été libérés par le joueur (capturés ou non, JOH6 et JOH7). Dante n'a qu'**un**
  chien : Entei (§8, JH-52).

## 3. Géographie **[D]**

| Carte | Taille indicative | Contenu |
|---|---|---|
| **Rosalia** (retour) | déjà faite (JOH2) | Le chemin de la Tour Carillon, gardé depuis le JOH2 (R-20), s'ouvre ; un sage blessé devant la porte forcée |
| **Bois de la Tour** | ≈ 24 × 20 | Petit bois d'érables entre Rosalia et la tour ; lanternes ; 1 Sbire de guet |
| **Tour Carillon 1F** | ≈ 24 × 24 | Grand hall de bois, colonnes rouges, autel ; deux sages assommés ; escalier vers 2F |
| **Tour Carillon 2F** | ≈ 24 × 24 | Plancher ancien, **planches qui cèdent** (trous → retour au 1F) ; 2 Sbires ; le sage **Hiroshi**, qui soigne l'équipe (§6) ; long escalier vers le sommet (fondu « La montée est longue… », H-12) |
| **Tour Carillon, sommet** | ≈ 20 × 20 | Toit-terrasse sous la **grande cloche** ; ciel ouvert ; Dante, Entei en cage de feu ; plus tard Ho-Oh |

Points de Vol : aucun neuf (Rosalia existe).

**Grilles validées par Kevin le 2026-11-03** (validation d'avance) : `tools/plans/bell_tower_woods.txt`, `bell_tower_1f.txt`,
`bell_tower_2f.txt`, `bell_tower_roof.txt` (la grille fait foi pour la géométrie ; défauts [D] dans
leurs en-têtes) ; retouche de `rosalia.txt` (sage blessé, raccord nord) ; contrôle
`tools/art/plan_check_joh8.py` ; aperçu `reference/joh8-grilles-apercu-v1.png`. **Vues générales peintes le
2026-11-03** (`reference/bois-de-la-tour-vue-generale-v1.png`, `tour-carillon-1f-…`, `tour-carillon-2f-…`,
`tour-carillon-sommet-vue-generale-v1.png`, plans annotés `reference/plans-johto/`, planche `reference/joh8-vues-v1.png`,
écarts et défauts dans `fiches-assets/serie-johto-vues-acte1.md`), **validées par Kevin le 2026-11-03** (« Oui, fusionne »).

## 4. Ordre de jeu

| Étape | Lieu | Ce qui se passe | Drapeau |
|---|---|---|---|
| 1 | Rosalia, maison des sages | Le doyen raconte la nuit : Dante a forcé la porte ; il remet au joueur le droit d'entrer (H-2, H-3) | `johto_bell_tower_open` |
| 2 | Bois de la Tour | Sbire de guet (évitable) | — |
| 3 | Tour 1F | Deux sages assommés (H-6) ; Sbire V (obligatoire, devant l'escalier) | — |
| 4 | Tour 2F | Planches qui cèdent ; Sbire W ; le sage Hiroshi soigne l'équipe (H-10) | — |
| 5 | Sommet | Arrivée à l'**aube** (JH-55) ; Dante devant la cage d'Entei (H-13 à H-16) | `johto_dante_met` |
| 6 | Sommet | **Premier combat contre Dante** (obligatoire, grand combat) | `johto_dante_defeated_1` |
| 7 | Sommet | Dante sonne la grande cloche ; **Ho-Oh descend**, regarde Dante et **le refuse** (H-19 à H-22) | `johto_ho_oh_seen` |
| 8 | Sommet | Dante ouvre la cage d'Entei pour couvrir sa fuite et part (JH-53, H-23 à H-26) | `johto_dante_fled_1` |
| 9 | Sommet | **Entei** se retourne vers le joueur : combat et capture | `johto_entei_done` |
| 10 | Sommet | **Ho-Oh** se pose sur le toit : combat et capture | `johto_ho_oh_done` |
| 11 | Rosalia | Le doyen et Orme : le Mont Argenté (accroche du JOH9, H-34 à H-36) | `johto_act3` |

## 5. Rencontres

**Aucune rencontre sauvage** dans la Tour Carillon et le Bois de la Tour : lieu sacré, cadre §7
(« — ») **[D]**.

## 6. Dresseurs **[D]**

| Où | Dresseur | Équipe | Évitable |
|---|---|---|---|
| Bois de la Tour | Sbire (guet) | Smogogo 60, Arbok 60 | oui |
| Tour 1F | Sbire V | Démolosse 61, Nosferalto 61 | **non** (devant l'escalier) |
| Tour 2F | Sbire W | Grotadmorv 61, Noarfang 61, Malosse 60 | oui |
| Tour 2F | **Sage Hiroshi** | — (soigne l'équipe une fois par passage, comme la mère de Bourg Palette) | — |
| Sommet | **Dante** (1) | Démolosse 64, Magmar 65, Cizayox 66, Farfuret 66, **Arcanin 68** | **non** |
| Sommet | **Entei** | niv. 60, sauvage, capturable | — |
| Sommet | **Ho-Oh** | niv. 65, sauvage, capturable | — |

- **Dante (1)** : 5 Pokémon, sans **Tyranocif**, gardé pour le sommet du Mont Argenté (cadre §8 :
  « équipe forte, mais pas complète ») **[D]**. Grand combat : victoire du premier coup **35–60 %**
  (mémoire « Difficulté des combats »). Thème feu et ténèbres ; Cizayox contre les Psy et les Plante,
  Farfuret contre les Dragon et Vol. Il n'utilise pas Entei (en cage).
- **Défaite contre Dante** : retour au Centre de Rosalia ; Dante reste au sommet (« Tu reviens
  déjà ? », H-17) ; la scène reprend à l'étape 5.
- **Entei et Ho-Oh** : K.O. ou fuite → ils disparaissent et reviennent après le chapitre (cadre
  §4.5) : Entei à la Tour Cendrée, Ho-Oh au sommet de la Tour Carillon **[D]**. Jamais perdus.

## 7. Objets **[D]**

| Où | Objet |
|---|---|
| Bois de la Tour | Hyper Potion ×2 |
| Tour 1F | Rappel Max |
| Tour 2F, au bord d'un trou | PP Plus |
| Sommet, après Ho-Oh (capturé, K.O. ou fuite) | **Plume Arc-en-ciel** (souvenir, objet clé sans effet ; elle tombe de Ho-Oh, H-32, H-33) |

## 8. Comment Ho-Oh est appelé (JH-52)

- La légende du doyen (C-10) dit : « si un homme les tient tous les trois ». Le joueur en a libéré
  deux. Dante n'en a qu'un.
- **Recommandation** : Dante a compris que **la douleur d'un seul suffit** : Entei, dans sa cage de
  feu, souffre ; Dante sonne la grande cloche à l'aube, et Ho-Oh descend pour le sauver (H-15).
  Ho-Oh vient donc, mais pas pour Dante : il le **refuse** (cœur pur, R-18) et sa flamme brise la
  cage (H-21). Le plan de Dante échoue sur le fond, pas sur la forme.
- Variante écartée (JH-52) : « les trois réunis » — les deux chiens du joueur (dans
  l'équipe) répondent à la cloche et complètent l'appel malgré lui. Joli, mais fragile si le joueur
  a mis K.O. Raikou ou Suicune.

## 9. Dante au sommet

- **Portrait** (cadre §8) : âgé, élégant, long manteau sombre, **cicatrice de brûlure** sur la moitié
  du visage et la main gauche ; voix calme, phrases courtes ; jamais de cri.
- Premier face-à-face : le joueur l'a seulement entendu (T-19, T-20) et vu jeune dans le souvenir
  (C-35). Dante sait que le joueur a vu le souvenir (le déserteur, H-14).
- **Fuite (JH-53)** : Dante ouvre la cage d'Entei, qui s'interpose ; Dante saute sur le dos de son
  **Arcanin** et descend la tour par les toits **[D]** recommandé, plutôt qu'un hélicoptère.
- **Sa promesse** (brief de Kevin) : « finir là où tout a commencé, au sommet du monde » (H-25) :
  le Mont Argenté, où il a fondé la première Team Rocket (le doyen le comprend, H-34) **[D]**.

## 10. L'aube (JH-55)

- La scène du sommet (étapes 5 à 10) est **forcée à l'aube** (lumière `johto_morning`, quelle que
  soit l'heure réelle), comme l'arrivée forcée de nuit à Oliville (cadre §4.1) ; à la sortie du
  sommet, l'heure réelle reprend **[D]**.
- Les cloches sonnent au moment où Ho-Oh descend (son, cadre §5.2).

## 11. Drapeaux **[D]**

`johto_bell_tower_open`, `johto_dante_met`, `johto_dante_defeated_1`, `johto_ho_oh_seen`,
`johto_dante_fled_1`, `johto_entei_done`, `johto_ho_oh_done`, `johto_act3`.

## 12. Cas limites (à tester)

- Défaite contre Dante : retour au Centre de Rosalia, reprise au sommet (étape 5, texte H-17).
- Entei ou Ho-Oh K.O., fuite, Master Ball ; capture avec équipe pleine (Stockage).
- Le joueur quitte l'application entre Dante et Entei : à la reprise, il est au sommet, Entei libre
  devant lui (la scène ne se rejoue pas).
- Corde Sortie dans la tour : ramène devant la porte ; interdite au sommet tant qu'Entei et Ho-Oh
  n'ont pas été affrontés **[D]**.
- Planches qui cèdent : ne font jamais tomber au sommet ou hors de la carte (test de la grille).
- `johto_act3` posé même si Entei et Ho-Oh ont été mis K.O.

## 13. Validation (sous-jalon JOH8)

- Tests : ordre doyen → tour → Dante → cloche → Entei → Ho-Oh → doyen ; aube forcée puis heure
  réelle ; défaite et reprise ; K.O. des légendaires et retour après le chapitre.
- Captures : sommet à l'aube (Dante, la cage d'Entei), descente de Ho-Oh, 2F (planches).

## 14. Art

Bois de la Tour, Tour Carillon (1F, 2F, sommet ; vue générale de la tour depuis Rosalia), grande
cloche. Personnages : **Dante âgé** (neuf : manteau, cicatrice ; DA à valider), le sage Hiroshi
(modèle des sages), Sbires (existent). Pokémon : **Entei** (existe depuis le JOH6), **Ho-Oh** (dos,
face), cage de feu (objet de décor), plume arc-en-ciel. Effet : descente de Ho-Oh (lumière
arc-en-ciel, plumes). Musique : Tour Carillon et Ho-Oh (HeartGold / SoulSilver, JH-12) ; thème de
Dante (à choisir avec le lot musique).

## 15. Textes (lot validé par Kevin le 2026-11-02)

Format : bulles séparées par « / ». `{joueur}` = nom ; *italique* = voix intérieure ou système.

| N° | Où | Texte |
|---|---|---|
| H-1 | Sage blessé, devant la porte de la tour | Il est venu cette nuit, avec des hommes en noir. / Un Pokémon rouge hurlait dans une cage de feu. / Va voir le doyen. Vite. |
| H-2 | Doyen, maison des sages | Te voilà enfin. / L'homme de la radio est monté dans la Tour Carillon. Avec le troisième. / Mes sages ont voulu l'arrêter. Il a suffi d'un regard de son Pokémon. |
| H-3 | Doyen, l'ouverture | La tour attend un cœur pur depuis trois cents ans. / Ce n'est pas lui. / C'est peut-être toi. Monte, {joueur}. Avant l'aube. |
| H-4 | Panneau, Bois de la Tour | **TOUR CARILLON** / Ses cloches appellent le gardien du ciel. |
| H-5 | Sbire de guet | avant : Personne ne monte ! Ordre du patron ! · défaite : Le patron va me brûler vif… · après : Il est en haut. Il attend l'aube. |
| H-6 | Sages assommés, 1F | Sage 1 : … Il nous a dit de dormir. Et nous avons dormi. · Sage 2 : Ses yeux… Je n'avais jamais vu une telle haine. |
| H-7 | Sbire V, 1F | avant : L'escalier est à nous ! · défaite : Bon… monte, si tu veux mourir. · après : Toi, tu n'as jamais vu le patron en colère. |
| H-8 | Sbire W, 2F | avant : À l'aube, tout le ciel sera à nous ! · défaite : Le ciel attendra. · après : Le patron dit qu'un seul suffit. Je n'ai pas compris quoi. |
| H-9 | Examen, planche fragile | Le bois craque sous les pieds. |
| H-10 | Sage Hiroshi, 2F | Tu es le Dresseur de Kanto ? / Repose tes Pokémon. Ce qui t'attend là-haut n'a pas de pitié. · *(système)* L'équipe de {joueur} est soignée. |
| H-11 | Description de zone | Tour Carillon : Une tour sacrée, où sonnent les cloches de l'aube. · Bois de la Tour : Un bois d'érables, au pied de la Tour Carillon. |
| H-12 | Système, escalier vers le sommet | La montée est longue… / Le ciel pâlit. |
| H-13 | Système, arrivée au sommet | Un homme se tient sous la grande cloche. / À ses pieds, une cage de flammes. Un Pokémon rouge s'y débat. |
| H-14 | **Dante**, l'accueil | Te voilà. / Le déserteur t'a raconté mon histoire, je suppose. La porte, le feu. / Il t'a dit que j'avais survécu. Il ne t'a pas dit ce qu'il en reste. |
| H-15 | Dante, le plan | Les sages croient qu'il faut les trois. / Ils se trompent. Il suffit qu'un seul souffre assez. / Ho-Oh viendra pour lui. Et ce jour-là, sa flamme sera à moi. |
| H-16 | Dante, avant le combat | Tu as libéré les deux autres. Courageux. Inutile. / Je ne te déteste pas, {joueur}. Tu es seulement sur mon chemin. / Comme moi, autrefois, j'étais sur celui de Giovanni. |
| H-17 | Dante, après une défaite du joueur (retour) | Tu reviens déjà ? / Le soleil, lui, n'attend pas. |
| H-18 | Dante, défaite | … / Bien. Très bien. / Tu te bats comme moi, quand j'avais encore quelque chose à protéger. |
| H-19 | Dante, la cloche | Mais tu arrives trop tard. Regarde. · *(système)* Dante frappe la grande cloche. / Le son roule jusqu'à l'horizon. |
| H-20 | Système, la descente | Le soleil se lève. / Un cri traverse le ciel. / Un Pokémon aux mille couleurs descend des nuages ! |
| H-21 | Système, le refus | Ho-Oh se pose devant Dante. / Il le regarde longtemps. / … / Ses ailes s'embrasent ! La cage de feu vole en éclats ! / Ho-Oh s'envole et tourne au-dessus de la tour. |
| H-22 | Dante, refusé | Non… / Même lui. Même lui me tourne le dos. |
| H-23 | Dante, la fuite | Pas ici. Pas comme ça. / Entei ! Tu es libre. Montre-leur ta colère. · *(système)* Entei pousse un rugissement ! |
| H-24 | Système, Arcanin | Dante saute sur le dos de son Arcanin ! / Ils bondissent de toit en toit… |
| H-25 | Dante, en partant | Je finirai là où tout a commencé. / Au sommet du monde. / Viens, si tu l'oses. |
| H-26 | Système, Entei | Entei se tourne vers {joueur}. / La colère brûle encore dans ses yeux ! |
| H-27 | Système, Entei après (K.O. ou fuite) | Entei bondit par-dessus la rambarde et disparaît. |
| H-28 | Système, Entei capturé | Entei s'est calmé. |
| H-29 | Système, Ho-Oh se pose | Ho-Oh redescend. / Il se pose sous la grande cloche, face à {joueur}. / Il attend. |
| H-30 | Système, Ho-Oh (combat) | Ho-Oh veut éprouver le cœur de {joueur} ! |
| H-31 | Système, Ho-Oh après (K.O. ou fuite) | Ho-Oh s'élève dans la lumière du matin et disparaît. |
| H-32 | Système, la plume | Une plume aux mille couleurs tombe doucement sur le toit. |
| H-33 | Système, Plume Arc-en-ciel | {joueur} ramasse la Plume Arc-en-ciel ! / Elle brille de toutes les couleurs. |
| H-34 | Doyen, après (Rosalia) | Les cloches ont sonné. Toute la ville a vu le ciel s'ouvrir. / Ho-Oh a choisi, {joueur}. Et ce n'est pas cet homme. / « Le sommet du monde »… Il n'y a qu'un lieu qu'on appelle ainsi : le Mont Argenté. / Les anciens disent que la Team Rocket y est née, il y a bien longtemps. |
| H-35 | Orme (Rosalia, Centre) | {joueur} ! J'ai vu la lumière depuis Doublonville ! / Le Mont Argenté… C'est la montagne la plus dangereuse entre Johto et Kanto. / Le chemin part d'Acajou, vers le nord. Prépare-toi bien. |
| H-36 | Orme, après | Raikou, Suicune, Entei libres. Lugia et Ho-Oh sont apparus. / Il ne reste plus que Dante. / Je préviens Chen. Lui saura peut-être qui t'attend là-haut. |
| H-37 | Habitante de Rosalia (après) | Ce matin, le ciel était plein de couleurs. / Ma grand-mère pleurait. Elle disait qu'elle l'attendait depuis toujours. |
| H-38 | Diane (dimanche, après, en plus de C-46) | Ce matin, les cloches ont sonné toutes seules. / Je n'y ai même pas touché. |

## 16. Arbitrages pour Kevin

| N° | Question | Recommandation de Claude |
|---|---|---|
| JH-52 | ✅ **La douleur d'un seul suffit** : Entei souffre dans la cage, Dante sonne la cloche, Ho-Oh vient pour le sauver et refuse Dante (Kevin, 2026-11-02) | — |
| JH-53 | ✅ Dante **ouvre la cage d'Entei** pour couvrir sa fuite et descend par les toits sur son **Arcanin** (Kevin) | — |
| JH-54 | ✅ Dante (1) : **5 Pokémon (64–68), sans Tyranocif**, gardé pour le Mont Argenté (Kevin) | — |
| JH-55 | ✅ Scène du sommet à l'**aube forcée**, puis l'heure réelle reprend (Kevin) | — |
