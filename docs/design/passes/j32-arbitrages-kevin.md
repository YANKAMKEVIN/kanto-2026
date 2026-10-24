# J32 — Un Kanto complet et vivant : arbitrages de collection pour Kevin

> **VALIDÉ PAR KEVIN le 2026-10-24 : N-1 à N-16, toutes les recommandations ; textes du §5 validés.**
>
> Claude, 2026-10-24. **Documentation seule : aucune ligne de code.**
> Prépare le §7 du plan `docs/tech/jalon-32.md` (branche `jalon-31`) et la tâche T3 « Obstacles de
> collection », qui attend ces réponses. Relu contre `vision.md` (constitution, dossier 04 §17
> « Mew »), `roadmap.md` (Phase 9 : « puis le mystère Mew »), la passe `j32-v1-chatgpt.md` (ses
> 7 arbitrages verrouillés ne sont pas rouverts), les dossiers 15, 23 et 28, les passes J20 et J25,
> et les **données réelles** d'`origin/main` (`af0e84ef`) et des branches `jalon-20` à `jalon-31`
> (lecture `git grep`).
>
> **Faits Rouge/Bleu** : désassemblage `pret/pokered` (fichiers cités au cas par cas, relus le
> 2026-10-24). Origine des règles : **RB** Rouge/Bleu · **J** Pokémon Jaune · **K26** adaptation
> Kanto 2026 · **[D]** valeur par défaut (règle 4), modifiable sans débat.
>
> Arbitrages numérotés **N-1 à N-16** (lettre libre sur `main` et `jalon-31`). Réponds par numéro
> (« tout ok », ou « 3 : B, 9 : non ») ; les textes du §5 se valident en un seul lot.

## 0. Ce que l'audit change à la question

Trois découvertes qui déplacent le débat :

1. **Les exclusivités Rouge/Bleu sont déjà résolues dans les données.** Le projet applique la
   convention de l'**union Rouge + Bleu** des tables sauvages (rappelée au J25, X-8) : Abo **et** Sabelette
   (Routes 3, 4, 8 à 11), Goupix **et** Caninos (Route 7, 8, Manoir), Miaouss **et** Chétiflor
   (Routes 5 à 8, 24, 25), Mystherbe, Férosinge, Insécateur **et** Scarabrute (Parc Safari,
   `jalon-23`), Magmar (Manoir). Il ne manque qu'**Élektek**, parce que la **Centrale** n'existe
   pas (point 2).
2. **Le Pokédex a des trous que le plan J32 ne liste pas** (aucune voie sur aucune branche) :
   **Électhor** et **Élektek** (Centrale jamais prévue : la Route 10 la montre « visible,
   inaccessible, sans promesse », J18 I-15) ; **Minidraco, Draco, Dracolosse** (la Super Canne du
   Parc Safari ne les a pas) ; **Porygon** (Casino sans jetons au J20 H-6, reporté au J26 Q26-5,
   toujours sans voie) ; **M. Mime, Lippoutou, Canarticho, Excelangue** (échanges PNJ de RB : seuls
   les trois de Cramois'Île existent) ; **deux évolutions d'Évoli sur trois** (Évoli unique).
   Ce sont des voies RB, pas des inventions : je les ajoute aux arbitrages (N-9 à N-14).
3. **Le fossile se choisit au J12** (Mont Sélénite, dossier 15 V-6 « un seul fossile, choix
   définitif »), pas au J25 (qui ressuscite). Le chercheur dit déjà « Un fossile chacun. Choisis. »
   (`data/dialogues/mt_moon.json`) : **il garde l'autre**, comme dans RB.

## 1. Mew

### 1.1 Faits RB
- Mew est l'espèce n° 151 dans les données, mais **aucune voie en jeu** : il ne s'obtenait que par
  des distributions officielles (événements, au niveau 5) ou des bugs. Aucun script de
  `pret/pokered` ne le donne.
- Le **Diplôme** du concepteur (Céladopole, Résidence 3e étage) compte **150** et non 151 :
  `scripts/CeladonMansion3F.asm` : `cp NUM_POKEMON - 1 ; discount Mew`. RB considère donc le
  Pokédex « complet » sans Mew.
- Le « Mew sous le camion » du quai de Carmin est une **légende de cour d'école** : le camion
  existe dans RB, il n'y a rien dessous.
- Dans le projet : journaux du Manoir (« Mew. », « Mew a donné naissance. », J25), sans effet sur
  le Pokédex (J25 X-11 : le secret reste entier). Le bureau du concepteur est une porte fermée
  « Bureau privé » au J20 (« le Diplôme RB est post-game »). Pas de camion au port de Carmin.
- `vision.md` : « Le plus grand secret de Kanto 2026. Aucune quête affichée ; on peut finir
  l'aventure sans le voir. » ; décision verrouillée « Mew : secret majeur ». Roadmap : « puis le
  mystère Mew ».

### 1.2 Options

| | Option | Conséquences |
|---|---|---|
| **A** | **Rencontre secrète unique** en post-game, sans aucune annonce | Une rencontre de légendaire (même moteur que Mewtwo, J31), un drapeau, une carte touchée. Fidèle à l'esprit (« secret majeur »), pas à la lettre de RB. |
| **B** | **Aucun Mew en solo** (RB strict) : 150 = complet, Diplôme | Rien à coder. Contredit la roadmap (« le mystère Mew ») et rend le « plus grand secret » vide. |
| **C** | **Cadeau de distribution** : code hors ligne que Kevin remet aux proches | Imite les événements de 1999 ; demande un écran de saisie et un format de code ; le secret dépend de Kevin, pas du monde. |

**Recommandation : A.** Le jeu est privé (cercle de proches) : la meilleure distribution, c'est le
monde lui-même.

### 1.3 Si A : condition, lieu, rencontre

- **Condition (N-2)** : **A** les 150 autres espèces capturées (le moment exact du Diplôme RB) ·
  **B** Mewtwo résolu (capturé ou vaincu) · **C** Ligue gagnée. **Reco A** : Mew couronne la
  collection, on peut finir l'aventure sans le voir, et la condition implique déjà Ligue et Mewtwo.
- **Lieu (N-3)** : **A** le **vieux camion du quai de Carmin** (la légende devient vraie ; ajoute un
  décor au port du J15/J16, déjà vide depuis le départ du S.S. Anne) · **B** le **Manoir Pokémon**,
  au journal « Mew a donné naissance » (sobre, dans la ligne des journaux) · **C** la Grotte Azurée
  après Mewtwo. **Reco A** : c'est la rumeur que tous les joueurs de RB ont crue ; elle parle
  exactement au public du jeu. Une seule rumeur de PNJ à Carmin, présente dès le J15, sans aucun
  lien avec le Pokédex (dossier 04 §15 : « indice d'un PNJ »).
- **Rencontre (N-4)** : Mew **N30** [D] (le N5 des distributions serait sans combat), **une seule
  rencontre**, même politique que Mewtwo (J31) pour la fuite et le K.O. ; Mew devient « vu » à la
  rencontre seulement. Aucun texte d'annonce : Mew apparaît (bruit, scintillement [D]), le combat
  commence.
- **Diplôme (N-5)** : la porte « Bureau privé » s'ouvre après la Ligue ; le concepteur encourage,
  puis remet le **Diplôme** à 150 (texte RB, §5). Écran du Diplôme simple + Grand moment [D]. Le
  Diplôme ne dit rien de Mew.

**Données et sauvegarde** : drapeaux d'événement `mew_appeared`, `mew_resolved`, `diploma_received`
[D] ; un décor (camion) et un déclencheur sur `vermilion_city` ; aucune nouvelle structure de
sauvegarde (à confirmer par l'architecte à T3). **Jalons touchés** : carte de Carmin (J15/J16,
fusionnés), Résidence de Céladopole (J20, fusionné), J31 (moteur de légendaire).

## 2. Starters, fossile, Dojo, Évoli : les choix uniques

Règle commune (plan J32 §0) : **la première récompense n'est jamais annulée** ; la seconde arrive
après, par une autre voie. Tous les dons passent par `PokemonGift` (équipe pleine → stockage).

### 2.1 Starters non choisis (N-6)
**Faits** : RB : un seul starter ; le rival prend celui qui bat le vôtre ; la troisième Poké Ball
reste sur la table : « That's PROF.OAK's last POKéMON! » (`text/OaksLab.asm`,
`_OaksLabLastMonText`). Les deux autres ne s'obtiennent que par échange. **Jaune** donne les trois en
cours d'aventure (Azuria, Route 24, Carmin).

| | Option | Conséquences |
|---|---|---|
| **A** | **Chen, après la Ligue**, au laboratoire : il confie son « dernier Pokémon » (la Poké Ball restée sur la table), puis le second (« un autre est arrivé au labo ») [D] | Deux dons, N5 [D], un seul lieu, déjà fusionné ; aucune nouvelle mécanique. |
| **B** | À la Jaune, **pendant l'aventure** (trois PNJ, Azuria, Route 24, Carmin) | Touche trois jalons fermés ; change l'équilibrage du début ; rival moins singulier. |
| **C** | Échange avec un PNJ de Bourg Palette (le [D] du plan) | Il faut donner un Pokémon pour chacun ; moins chaleureux. |
| **D** | Rien (RB strict) | La collection solo est impossible. |

**Recommandation : A.** Le « dernier Pokémon du Prof. Chen » vient de RB : il prend enfin un sens.

### 2.2 Second fossile (N-7)
**Faits** : `scripts/MtMoonB2F.asm` : `CheckEitherEventSet EVENT_GOT_DOME_FOSSIL,
EVENT_GOT_HELIX_FOSSIL`, puis `MtMoonB2FSuperNerdTakesOtherFossilScript` : **le chercheur emporte
l'autre**. Le Vieil Ambre est indépendant (J25 X-3).

| | Option | Conséquences |
|---|---|---|
| **A** | **Le chercheur du Mont Sélénite** revient, au Labo de Cramois'Île, après la Ligue, et confie **son** fossile, une fois | Suite logique de « Un fossile chacun » ; un PNJ, un don d'objet ; le `FossilLab` existant fait le reste. |
| **B** | Machine de Cramois'Île, une seule fois (le [D] du plan) | Invente une machine sans racine RB. |
| **C** | Fouille post-game au Mont Sélénite | Nouvel objet caché ; moins lisible. |

**Recommandation : A.** Le Labo a déjà une salle de réunion où un Intello parle du Mont Sélénite
(dossier 28) : on peut y placer le chercheur.

### 2.3 Kicklee / Tygnon (N-8)
**Faits** : `scripts/FightingDojo.asm` : `CheckEitherEventSet EVENT_GOT_HITMONLEE,
EVENT_GOT_HITMONCHAN` ; l'autre n'est plus jamais donné.
**Options** : **A** après la Ligue, le Maître Karaté offre la Poké Ball restante (pas de revanche :
les Dresseurs ne sont pas rejouables) · **B** rien. **Recommandation : A.**

### 2.4 Évoli (N-9, trou nouveau)
**Faits** : RB donne **un seul** Évoli (Résidence de Céladopole, toit) ; Aquali, Voltali et Pyroli
demandent trois Évoli, donc des échanges. Le projet suit RB (don unique, J20).
**Options** : **A** après la Ligue, **deux** autres Poké Balls dans la même pièce [D] (trois Évoli en
tout, un par évolution) · **B** Évoli sauvage rare (aucune racine RB) · **C** rien (deux espèces
inobtenables). **Recommandation : A.**

## 3. Exclusivités Rouge/Bleu (N-10, N-11)

**Faits** (`pret/pokered`, `data/wild/maps/*.asm`, blocs `IF DEF(_RED)` / `IF DEF(_BLUE)`) :
Rouge seul : Abo, Mystherbe, Férosinge, Caninos, Insécateur, Élektek (Centrale :
`data/wild/maps/PowerPlant.asm`) ; Bleu seul : Sabelette, Goupix, Miaouss, Chétiflor, Scarabrute,
Magmar, et Raichu sauvage à la Centrale. Le Coin à lots diffère aussi
(`data/events/prizes.asm` : Rouge Nidorina, Minidraco, Insécateur ; Bleu Nidorino, Scarabrute,
Minidraco ; Porygon dans les deux).

| | Option | Conséquences |
|---|---|---|
| **A** | **Ratifier l'union Rouge + Bleu** déjà appliquée (§0) | Rien à refaire ; seul Élektek manque, avec la Centrale (N-11). |
| **B** | Répartir (une moitié sauvage, l'autre par PNJ) | Défait des tables validées sur huit jalons. |
| **C** | Échanges PNJ pour les exclusivités | Lourd, sans intérêt de jeu. |

**Recommandation : A.**

**Centrale (N-11)** : RB : Route 10, accès par Surf, rencontres ci-dessus, **Électhor N50**, objets.
**A** la Centrale entre au J32 comme **lot 32G** (grille RB, union Rouge + Bleu : Élektek **et**
Raichu) · **B** un mini-jalon après le J32 · **C** Électhor ailleurs, sans Centrale.
**Recommandation : A** : c'est du contenu RB oublié, pas une « nouvelle région » ; sans elle,
Électhor et Élektek n'ont aucune voie et la collection est impossible. Coût : une carte, une grille
à valider, un fond de combat, un légendaire (moteur du J24 et du J29).

## 4. Autres voies RB manquantes (N-12 à N-14)

- **N-12 Minidraco** : RB : Super Canne du Parc Safari = Minidraco, Krabby, Psykokwak, Ramoloss N15
  (`data/wild/super_rod.asm`, `.Group6`). Le projet n'a pas de groupe Safari. **Reco** : ajouter ce
  groupe RB (données seules ; Draco et Dracolosse par niveau).
- **N-13 Porygon** : J20 H-6 (validé) : « donné plus tard par Sylphe SARL » ; J26 Q26-5 l'a
  reporté. **Reco** : un employé de Sylphe SARL le confie **après Giovanni** [D], une fois. Option B :
  dans le post-game seulement.
- **N-14 Échanges PNJ de RB absents** (`data/events/trades.asm`) : Abra → **M. Mime** (maison
  d'échange de la Route 2), Têtarte → **Lippoutou** (Azuria), Piafabec → **Canarticho** (Carmin),
  Flagadoss → **Excelangue** (poste de la Route 18), Nidoran ♂ → Nidoran ♀ (souterrain Route 5),
  Nidorino → Nidorina (poste de la Route 11). **A** les six, sur le modèle `InGameTrade` des trois
  de Cramois'Île (J25) · **B** seulement les quatre nécessaires au Pokédex. **Reco A** (fidélité ;
  les deux Nidoran coûtent une ligne de données chacun). Surnoms VF de RB à relever (Poképédia) ;
  présence des maisons à vérifier par T1/T6.

## 5. Textes — **VALIDÉS par Kevin le 2026-10-24**

Deux lignes de 40 caractères au plus par page. Tous [D].

**Rumeur de Carmin (N-3, PNJ du port, présent dès le J15)**
1. « Le vieux camion du quai ? Personne ne sait\nqui l'a garé là. »
2. « Mon frère jure qu'un Pokémon rose\ndort dessous. Il dit n'importe quoi. »

**Mew (N-4, au camion, condition remplie)**
3. *(examiner le camion)* « Quelque chose bouge sous le camion… »
→ combat, sans autre texte.

**Concepteur, Résidence 3e (N-5, d'après RB)**
4. « Tu sais quoi ? C'est moi qui ai conçu\nce jeu ! »
5. « Remplir le Pokédex, c'est dur.\nMais n'abandonne pas ! »
6. *(150 capturés)* « Incroyable ! Tu as complété\nton Pokédex ! Félicitations ! »
7. « {player} reçoit le Diplôme ! »

**Chen, après la Ligue (N-6)**
8. « {player} ! Tu te souviens de la Poké Ball\nrestée sur cette table ? »
9. « C'était mon dernier Pokémon.\nIl t'a attendu. Prends-en soin. »
10. *(second don)* « Et ce n'est pas tout : un autre\nest arrivé au labo. Il est pour toi. »

**Chercheur du Mont Sélénite, Labo de Cramois'Île (N-7)**
11. « Toi ! On a partagé les fossiles,\nau Mont Sélénite. »
12. « Je n'ai jamais su le réveiller.\nGarde-le : ici, ils savent faire. »

**Maître du Dojo (N-8)**
13. « Champion de la Ligue… Mes poings\nt'attendaient. »
14. « Prends l'autre Poké Ball. Un Dojo\nn'est rien sans ses deux styles. »

**Évoli (N-9, la pièce du toit)**
15. *(panneau ou note)* « D'autres Évoli sont nés.\nPrends-en un si tu veux. »

**Porygon (N-13, employé de Sylphe SARL)**
16. « Notre prototype, Porygon. Un Pokémon\nfait de données. Il est à toi. »

## 6. Conséquences pour le plan J32

- **T3** reçoit N-1 à N-14 ; **lot 32G** (Centrale, Électhor) si N-11 A ; l'audit T1 vérifie chaque
  voie ajoutée.
- **Sauvegarde** : drapeaux d'événement seulement (un par don ou rencontre) ; pas d'incrément de
  version attendu.
- **Cartes fusionnées touchées** : Bourg Palette (labo), Carmin (camion, PNJ, maison d'échange),
  Céladopole (bureau, toit), Safrania (Dojo, Sylphe), Cramois'Île (Labo), Routes 2, 5, 11, 18,
  Azuria, Parc Safari (Super Canne). À faire **après la fusion** des J23 et J26 à J31 dans `main`.
- Rien ne guide le joueur : aucune liste de manquants, aucun marqueur (plan J32 §1.4).

## 7. Arbitrages

| N° | Sujet | Options | Recommandation |
|---|---|---|---|
| **N-1** | Mew en solo | A rencontre secrète · B absent (RB) · C code de distribution | **A** |
| **N-2** | Condition de Mew | A 150 capturés (Diplôme RB) · B Mewtwo résolu · C Ligue | **A** |
| **N-3** | Lieu de Mew | A camion du quai de Carmin + rumeur · B Manoir · C Grotte Azurée | **A** |
| **N-4** | Rencontre | N30 [D], unique, politique de Mewtwo, « vu » à la rencontre | **oui** |
| **N-5** | Diplôme | Bureau privé ouvert après la Ligue, concepteur RB, Diplôme à 150 | **oui** |
| **N-6** | Starters non choisis | A Chen après la Ligue · B à la Jaune · C échange PNJ · D rien | **A** |
| **N-7** | Second fossile | A le chercheur du Mont Sélénite à Cramois'Île · B machine · C fouille | **A** |
| **N-8** | Kicklee / Tygnon | A le Maître offre l'autre après la Ligue · B rien | **A** |
| **N-9** | Évoli | A deux Évoli de plus après la Ligue · B sauvage rare · C rien | **A** |
| **N-10** | Exclusivités | A union Rouge + Bleu ratifiée · B répartition · C échanges | **A** |
| **N-11** | Centrale et Électhor | A lot 32G · B mini-jalon après le J32 · C Électhor ailleurs | **A** |
| **N-12** | Minidraco | Super Canne RB au Parc Safari (données) | **oui** |
| **N-13** | Porygon | A Sylphe après Giovanni (H-6) · B post-game seulement | **A** |
| **N-14** | Échanges PNJ RB | A les six · B les quatre nécessaires | **A** |
| **N-15** | Terminal d'échange local | Tous les Centres (le [D] du plan §7.6) | **oui** |
| **N-16** | Textes §5 | Lot unique, 16 répliques | **validés** |

## 8. Suite
Après tes réponses : report dans `docs/tech/jalon-32.md` §7 et T3 (par la session du J32, pas sur
`jalon-31` en cours), textes validés au §3 du plan, grille de la Centrale à préparer si N-11 A.
