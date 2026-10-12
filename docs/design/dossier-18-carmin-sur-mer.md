# Dossier 18 — Route 5, passage souterrain, Route 6 et Carmin-sur-Mer (jalon 15)

> **VERROUILLÉ — validé par Kevin le 2026-10-12** (« on va avec tes reco ») : lot de textes §15, défaut d'évolution à la Pension (§4.2), grilles v1 (§13.1, Route 5 à retravailler). Consolidé par Claude le 2026-10-11. Sources : V2 de Kevin avec ChatGPT
> (`passes/j15-v2-chatgpt.md`, 6 décisions verrouillées), passe d'alignement de Claude
> (`passes/j15-v2-alignement.md`, V-1 à V-4 et F-1 à F-16), et réponses de Kevin du 2026-10-11 :
> **toutes les recommandations sont retenues** (F-2 « rendu quand même », F-3 « évolution proposée
> au retrait », F-7 « ordre officiel neutre » confirmés un par un).
>
> **Numérotation** : 16 = J13 et 17 = J14 (réservés) → **18**.
>
> Légende : **[V]** décision de Kevin · **[D]** valeur par défaut technique (règle 4 de
> `CLAUDE.md`, modifiable sans rouvrir la conception). Origine des règles : **RB** Rouge/Bleu ·
> **G+** génération plus récente · **K26** invention de Kanto 2026.

## Arbitrages de Kevin (2026-10-11)

| N° | Décision | Statut |
|---|---|---|
| — | Périmètre : Route 5, passage souterrain, Route 6, Carmin-sur-Mer | [V] |
| — | Pension Pokémon fonctionnelle dès le J15 | [V] |
| — | Souterrain enrichi, découverte facultative | [V] |
| — | Carmin-sur-Mer complète ; S.S. Anne visible, non explorable | [V] |
| — | Arène de Major Bob présente, défi reporté | [V] |
| — | Postes de garde vers Safrania fermés, justification narrative | [V] |
| V-1 | Pension : un Pokémon à la fois, sans reproduction | [V] |
| V-2 | Capacités dues proposées au retrait, dans l'ordre, sans oubli automatique | [V] |
| V-3 | Souterrain sans rencontres, une découverte cachée | [V] |
| V-4 | Maison du Pêcheur présente, pêche reportée ; la Canne sera donnée à la visite suivante | [V] |
| F-1 | 1 XP par pas, XP en attente appliquée au retrait | [V] |
| F-2 | 100 ₽ + 100 ₽ par niveau ; si l'argent manque, Pokémon rendu et tout l'argent pris | [V] |
| F-3 | Évolution proposée au retrait (annulable) | [V] |
| F-4 | Niveaux gagnés et prix annoncés ; aucun Pokémon visible au jardin | [V] |
| F-5 | S.S. Anne : réplique provisoire au J15 ; règle permanente au J16 = Passe Bateau | [V] |
| F-6 | Arène bloquée par un arbre (RB), qui tombe avec Coupe | [V] |
| F-7 | Safrania : fermeture officielle sans motif, le garde indique le souterrain | [V] |
| F-8 | Fan Club présent, Bon pour Vélo reporté au système du vélo | [V] |
| F-9 | Souterrain ≤ 50 cases, 2 coudes, 3 alcôves, Guérison cachée, un passant | [V] |
| F-10 | Espèces nouvelles : Miaouss et Persan (+ Mystherbe, Chétiflor, Ortide, Boustiflor s'ils ne viennent pas du J13) | [V] |
| F-11 | Les 6 Dresseurs de la Route 6 (RB), 1 inévitable au plus | [V] |
| F-12 | Carmin ≤ 64 × 48, sinon quai en carte séparée | [V] |
| F-13 | Lieux gardés / exclus (§9.2) | [V] |
| F-14 | Boutique : stock d'Azuria + Super Potion | [V] |
| F-15 | Validation 15.0 (Pension seule) → 15A → 15B | [V] |
| F-16 | Roadmap mise à jour (ordre J12 → J17) | [V] |

## 1. Intention

Un jalon de **voyage** : on quitte Azuria par le sud, on découvre une première fonctionnalité de
gestion (la Pension), on traverse un passage calme et ancien, puis la mer apparaît. Carmin-sur-Mer
est la première ville **tournée vers le large** : là où Azuria est traversée par l'eau, Carmin vit
autour de la mer. Le S.S. Anne est une **promesse visible** ; l'Arène de Major Bob, un défi qu'on
voit sans pouvoir le relever encore.

## 2. Périmètre

```
AZURIA (sortie sud, J14) ─▶ ROUTE 5 ─┬─▶ poste nord ─▶ SAFRANIA (fermée)
                                     ├─▶ PENSION
                                     └─▶ entrée du SOUTERRAIN
                                              │ (≤ 50 cases, aucune rencontre)
                                              ▼
                          SAFRANIA (fermée) ◀─ poste ─ ROUTE 6 ─▶ CARMIN-SUR-MER
                                                                    ├─ quai : S.S. Anne (fermé)
                                                                    ├─ Arène (arbre)
                                                                    └─ est : ROUTE 11 (« À venir »)
```

Hors périmètre : intérieur du S.S. Anne, rival n° 4 et Coupe (J16) ; combat de Major Bob et
Badge Foudre (J17) ; Safrania ; Route 11 et Grotte Taupiqueur ; vélo ; pêche ; échanges.

## 3. Route 5

### 3.1 Forme

Enveloppe **≈ 42 × 62 cases** [D, recalée sur la grille], orientée nord → sud. Verdoyante et
dense, pas un couloir : deux bandes d'herbes hautes, un petit bois, une clôture de jardin.

```
AZURIA (from_cerulean, relais du J14)
   │  ① L'ARRIVÉE : chemin large, herbes H1
   ▼
   ② LA PENSION : bâtiment à toit chaud, jardin clos visible depuis le chemin, panneau
   │     (on la reconnaît à son architecture et à son jardin, sans flèche)
   ▼
   ③ LE CARREFOUR : poste de garde nord (vers Safrania, fermé) ; herbes H2 ;
         petit bâtiment d'entrée du souterrain
```

Retour vers Azuria toujours possible. **Aucun Dresseur** (RB). La grille
`tools/plans/route_5.txt` fera foi.

### 3.2 Rencontres sauvages [V F-10 ; niveaux et poids D]

Table RB (identique sur la Route 6) : les deux versions sont réunies, comme au J12.

| Espèce | Niveaux | Poids |
|---|---|---|
| Roucool | 13–16 | 30 |
| Mystherbe | 13–16 | 15 |
| Chétiflor | 13–16 | 15 |
| Férosinge | 10–16 | 20 |
| Miaouss | 10–16 | 20 |

Taux et rampe de la Route 3 [D]. **Miaouss** est la découverte de la route.

### 3.3 Vie, objets

- **PNJ non combattants (2)** [D] : une promeneuse près du jardin de la Pension ; un voyageur au
  carrefour qui revient de Safrania fermée. Répliques §15.
- **Objets** [D] : 1 visible (Super Potion), 1 caché près du petit bois (Antidote).

## 4. La Pension Pokémon

### 4.1 Le lieu

Petit bâtiment au toit chaud, jardin clos fleuri. Intérieur standard 15 × 10 [D], un **gardien**
au comptoir (modèle `old_man`). Le jardin est un décor : **aucun Pokémon visible** au J15 [V F-4].

### 4.2 Règles [V]

| Règle | Comportement |
|---|---|
| Capacité | **Un Pokémon** à la fois ; aucune reproduction, aucun Œuf. |
| Dépôt | Depuis l'équipe, auprès du gardien. Refusé pour le dernier Pokémon apte (règle du Stockage). Un Pokémon K.O. peut être déposé. |
| Progression | **1 XP par pas** du joueur, sur toutes les cartes. Pas scriptés exclus ; la course compte comme la marche ; un pas refusé ne compte pas. Plafond : niveau 100. |
| Pendant le séjour | Rien ne change sur le Pokémon : l'XP est **en attente**. Aucune évolution, aucune capacité. |
| Annonce | Le gardien annonce les niveaux gagnés et le prix avant la confirmation. |
| Prix | **100 ₽ + 100 ₽ par niveau gagné**. |
| Argent insuffisant | **Le Pokémon est rendu et tout l'argent du joueur est pris** (*K26*). Un Pokémon n'est jamais bloqué. |
| Équipe pleine | Retrait refusé jusqu'à ce qu'une place se libère. |
| Retrait | XP appliquée → **chaque capacité due, dans l'ordre**, avec l'écran « veut apprendre… oublier ? » (refuser = non apprise) → **évolution proposée** si le seuil est atteint **et qu'au moins un niveau a été gagné à la Pension** (même règle qu'en fin de combat ; annulable) → **soin complet** (PV, statut, PP). |
| Compagnon | Déposer le compagnon l'efface ; le joueur en choisit un autre (règle du J11). |
| Pokédex, Grands moments | Rien ne change. Aucun Grand moment pour la Pension. |
| Sauvegarde | Pokémon déposé, XP en attente et niveau au dépôt sauvegardés : **nouvelle version** (v7 après la v6 du J11). |

**Écarts RB assumés** : RB remplaçait la plus ancienne capacité sans rien demander, refusait le
retrait sans argent et ne proposait l'évolution qu'au prochain niveau gagné en combat.

## 5. Le passage souterrain [V V-3, F-9]

- **Deux petits bâtiments d'entrée** (Route 5 et Route 6), sur le modèle des postes de la Forêt de
  Jade (10 × 8), avec un escalier qui descend.
- **Galerie ≤ 50 cases**, deux coudes à angle droit, **trois alcôves**. Pierre ancienne, appliques
  murales, traces de passage au sol. Aucune rencontre, aucun Dresseur.
- **Un passant** au milieu (respiration, indice discret). **Un objet caché : Guérison**, dans une
  alcôve, avec le système du J12 (EXAMINER face à une pierre descellée).
- Catégorie [D] : **ni grotte ni intérieur**. La carte ne figure pas dans `caves.json`, donc pas de
  Corde Sortie. Pas de ciel, profil de lumière dédié, compagnon visible comme sur une route.

## 6. Route 6

### 6.1 Forme

Enveloppe ≈ 42 × 56 cases [D], plus ouverte que la Route 5. Du bâtiment de sortie du souterrain
vers le sud : herbes, un étang (obstacle), le poste de garde vers Safrania (fermé) et, au bout,
**la première vue sur le port** (grues, mâts, la cheminée du S.S. Anne au-dessus des toits).

### 6.2 Dresseurs (6, dont 1 inévitable) [V F-11 ; prénoms, emplacements, récompenses D]

Équipes RB, toutes espèces existantes. Récompense = base de la classe × niveau du dernier Pokémon
(Scout 12, Campeur 20, Jeune Dresseuse 20). IA `random`. Capacités apprises au niveau.

| | Dresseur | Où | Évitable | Équipe | ₽ |
|---|---|---|---|---|---|
| D1 | Jeune Dresseuse Chloé | sortie du souterrain | **non** | Roucool Nv. 16 ×3 | 320 |
| D2 | Campeur Lucas | à côté de Chloé | oui | Piafabec Nv. 16, Rattatac Nv. 16 | 320 |
| D3 | Scout Axel | herbes ouest | oui | Aspicot, Chenipan, Aspicot Nv. 16 | 192 |
| D4 | Campeur Mathis | près de l'étang | oui | Carapuce Nv. 20 | 400 |
| D5 | Jeune Dresseuse Manon | à côté de Mathis | oui | Rattata Nv. 16, Pikachu Nv. 16 | 320 |
| D6 | Scout Timéo | détour, vue sur le port | oui | Papilusion Nv. 20 | 240 |

Les paires RB (combat en duo) deviennent deux combats voisins. Papilusion connaît Poudre Toxik,
Para-Spore et Poudre Dodo : la paralysie et le sommeil viennent du J11.

### 6.3 Rencontres, vie, objets

Même table que la Route 5 (§3.2) [D]. Un pêcheur sans canne au bord de l'étang (PNJ, parle de
Carmin). Objets [D] : 1 visible (Poké Ball), 1 caché (Super Potion).

## 7. Postes de garde vers Safrania [V F-7]

- Deux postes (Route 5 nord, Route 6 est), sur le modèle `_forest_gate` (10 × 8). Un garde se
  tient devant la porte côté Safrania. Le joueur qui avance reçoit la réplique, puis recule d'une
  case (modèle du garde d'Argenta).
- Raison : **fermeture officielle, sans motif**. Rien n'annonce la Team Rocket. Le garde de la
  Route 5 indique le souterrain.
- Le déblocage sera décidé avec l'arc Rocket de Safrania (hors J15).

## 8. Carmin-sur-Mer

### 8.1 Forme [V F-12]

Enveloppe **≤ 64 × 48 cases** [D], mesurée à la grille. Si la carte dépasse 3 000 nœuds, le quai
du S.S. Anne devient une carte séparée (`vermilion_dock`, comme dans RB). Trois repères visuels :
**les quais, le S.S. Anne, l'Arène**. Angles droits : quais rectilignes, pontons perpendiculaires
au rivage, coque parallèle au quai.

Palette : façades claires, toitures chaudes, bois des pontons, cordages, métal du port, mer bleu
profond, végétation côtière.

```
            ROUTE 6 (nord)
                 │
   maisons ── CENTRE ── BOUTIQUE
       │          │
   FAN CLUB    place ── ARÈNE (arbre devant l'entrée)
       │          │
 PÊCHEUR ───── quais ─────────── est : ROUTE 11 (« À venir »)
                 │
          passerelle ── S.S. ANNE (amarré, fermé au J15)
```

### 8.2 Lieux [V F-13]

| Lieu | Contenu au J15 |
|---|---|
| Centre Pokémon | Standard (soin, Stockage, point de repos). |
| Boutique | Poké Ball, Potion, **Super Potion** (nouveau), Antidote, remèdes du J11 [V F-14]. |
| Arène | Façade et panneau ; **un arbre devant l'entrée** [V F-6]. |
| Fan Club | Président bavard, quelques membres et leurs Pokémon (PNJ). **Pas de Bon pour Vélo** [V F-8]. |
| Maison du Pêcheur | Le Pêcheur parle de pêche. **Pas de Canne** [V V-4]. |
| Quai | Le S.S. Anne, un marin devant la passerelle, deux dockers [V F-5]. |
| 2 maisons d'habitants | Dialogues (Major Bob, Safrania, le navire). |

Exclus : maison d'échange (Canarticho), échange « SPOT » de la Route 5, maison de la lettre de
Roucool (aucun système d'échange ni de courrier).

### 8.3 Le S.S. Anne [V F-5]

Grand repère visuel dès l'arrivée. Le joueur approche du quai, voit le navire et parle au
personnel. **Au J15, le marin bloque la passerelle avec une réplique provisoire** (l'équipage
prépare la croisière), identique avec ou sans Passe Bateau. Cette réplique disparaît au J16, qui
pose la règle permanente : **le Passe Bateau suffit** (RB). Aucune mention « à venir ».

### 8.4 L'Arène de Major Bob [V F-6]

Un jeune arbre bloque l'entrée (EXAMINER : réplique). Le panneau se lit ; les habitants parlent de
Major Bob. L'arbre tombe avec Coupe (S.S. Anne). Ni garde, ni porte fermée, ni message
d'interface.

### 8.5 Sorties

| Sortie | État au J15 |
|---|---|
| Nord | Route 6, ouverte |
| Est | Route 11 : bord fermé, « ROUTE 11 — À venir » en développement (mécanisme existant) |
| Sud | Quai, S.S. Anne fermé (§8.3) |

## 9. Ambiance

- **Route 5** : fin d'après-midi douce, jardins, odeur de foin.
- **Souterrain** : frais, appliques chaudes espacées, échos de pas, silence entre deux lampes.
- **Route 6** : l'air change, des mouettes, le vent de la mer avant de la voir.
- **Carmin** : lumière dorée sur l'eau, cordages qui grincent, sirène lointaine du navire.

Références d'ambiance de la V2 : non versées au dépôt (droits). Vues générales peintes à produire
(§13).

## 10. Espèces, capacités et assets

### 10.1 Espèces nouvelles [V F-10]

| Espèce | Atteignable au J15 | Remarque |
|---|---|---|
| Miaouss | sauvage | découverte de la Route 5 |
| Persan | niveau 28 | en s'entraînant |
| Mystherbe, Chétiflor, Ortide, Boustiflor | sauvages / niveau 21 | **seulement s'ils ne viennent pas déjà du J13** (D-8) |

Données et face (artwork officiel) ; dos selon l'état de la filière des dos ; planche d'exploration
de Miaouss si le compagnon l'exige (à voir au plan).

### 10.2 Capacités

- Miaouss apprend **Jackpot** (RB, niveau 12 à 17) : **elle n'existe pas** dans `moves.json`.
  Défaut [D] : la créer avec l'effet RB (argent ramassé à la fin d'un combat gagné : 2 × niveau du
  lanceur par utilisation). Petite mécanique de fin de combat.
- Morsure, Grincement, Combo-Griffe, Griffe, Rugissement : existent.

### 10.3 Objets nouveaux

| Objet | Rôle | Prix |
|---|---|---|
| Super Potion | soin 50 PV | 700 ₽ (RB) |
| Guérison | soin total + statut | 3 000 ₽ (RB, non vendue au J15) |

### 10.4 Personnages et décors

- Modèles existants : `old_man` (gardien), `guard`, `scout`, `camper`, `lass`, `nurse`, `clerk`,
  pêcheur (planche `pecheur`), `traveler`.
- Nouveaux [D] : **marin** et **docker** (quai) ; président du Fan Club.
- Décors : Pension (extérieur et intérieur), souterrain (galerie, bâtiments d'entrée), Carmin
  (façades, quais, pontons, grues, eau du port), **S.S. Anne vu de l'extérieur** (grand asset du
  jalon), Arène (façade, arbre), Fan Club, Pêcheur.

## 11. Données et sauvegarde

- **Drapeaux** [D, noms indicatifs] : Dresseurs de la Route 6 (`beaten_<id>`), objets
  (`got_<id>`), `route_5_entered`, `vermilion_reached` (objectifs).
- **Pension** : champ `daycare` (Pokémon, XP en attente, niveau au dépôt) → **sauvegarde v7**, avec
  sa migration et ses tests. C'est le **seul** changement de format du J15.
- **Point de repos** : Centre de Carmin (mécanisme existant).
- **Relais** : reçu du J14 (`route_5`, arrivée `from_cerulean`) ; passé au J16 (quai, passerelle)
  et au J17 (arbre et Arène).

## 12. Objectifs du tableau de bord [D]

- En entrant sur la Route 5 : « Rejoindre Carmin-sur-Mer, au sud. »
- En arrivant à Carmin : « Explorer Carmin-sur-Mer. »

## 13. Découpage et validation S24 [V F-15]

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **15.0** | Pension : logique pure, données, tests ; puis sauvegarde v7 et migration | **seule** (système risqué), Mac puis S24 |
| **15A** | Route 5, Pension sur la carte (dialogues, dépôt, retrait, compteur de pas), poste nord, souterrain, objet caché | S24 |
| **15B** | Route 6, Dresseurs, Carmin (Centre, Boutique, Arène et arbre, Fan Club, Pêcheur, quai et S.S. Anne), poste est, Route 11 fermée, clôture | S24 |

Avant toute carte : **vues générales peintes** et **grilles `tools/plans/`** validées par Kevin
(Route 5, souterrain, Route 6, Carmin). Ce travail, la logique pure de la Pension, les données des
espèces et l'art avancent **en parallèle des autres jalons**. Seule l'intégration attend les
systèmes qu'elle utilise :
- J11 : v6, uid, compagnon, statuts ;
- J12 : objets cachés, évolution hors combat ;
- J14 : raccord sud d'Azuria, Passe Bateau.

### 13.1 Grilles v1 (validées par Kevin le 2026-10-12)

Les grilles font foi pour la géométrie (contrôles verts : `tools/art/plan_check_j15.py`,
`plan_check_carmin.py`) :

| Carte | Grille | Taille | Remarque |
|---|---|---|---|
| Route 5 | `tools/plans/route_5.txt` | 42 × 62 | **v2 faite (2026-10-12), à valider** : le chemin serpente à angles droits (3 décalages), avec un détour vers le petit bois |
| Souterrain | `tools/plans/underground_path.txt` | 26 × 30 | 40 pas, 2 coudes, 3 alcôves, Guérison en A2 |
| Route 6 | `tools/plans/route_6.txt` | 42 × 56 | Chloé inévitable au goulet, 68 pas |
| Carmin | `tools/plans/vermilion_city.txt` | 64 × 43 | quai dans la carte ; le S.S. Anne se découvre en descendant vers le quai (la cheminée au-dessus des toits relève de la peinture) |

## 14. Cas limites (à couvrir au plan)

- Déposer le compagnon.
- Déposer, puis quitter l'application avant l'autosave.
- Retirer avec l'équipe pleine.
- Retirer sans assez d'argent, ou avec 0 ₽.
- Pokémon déposé au niveau 99 ou 100.
- Plusieurs capacités dues, toutes refusées.
- Évolution annulée au retrait.
- Pokémon empoisonné ou K.O. déposé.
- Partie sauvegardée sur le raccord « ROUTE 5 — À venir » du J14.
- Partie v6 chargée par une build v7 (migration) et partie v7 lue par une build v6 (refus).
- Arrivée à Carmin sans Passe Bateau, puis avec.

## 15. Lot de textes — VALIDÉ par Kevin le 2026-10-12

### 15.1 Pension

| # | Moment | Texte |
|---|---|---|
| T-1 | Panneau | « PENSION POKÉMON — Nous gardons votre Pokémon pendant votre voyage. » |
| T-2 | Pension vide | « Bienvenue à la Pension ! Je garde un Pokémon pendant que tu voyages. » / « Il s'entraîne un peu à chaque pas que tu fais. Tu veux m'en confier un ? » [Oui / Non] |
| T-3 | Non | « Reviens quand tu veux. » |
| T-4 | Choix | « Lequel veux-tu me confier ? » |
| T-5 | Dernier Pokémon apte | « Tu ne peux pas partir sans un Pokémon en forme. » |
| T-6 | Dépôt | « Très bien. Je m'occupe de {pokemon}. Reviens le chercher quand tu veux. » |
| T-7 | Visite, aucun niveau | « {pokemon} va très bien. Il n'a pas encore beaucoup changé. » / « Tu veux le reprendre ? Ce sera {price} ₽. » [Oui / Non] |
| T-8 | Visite, niveaux gagnés | « Ah, te voilà ! {pokemon} a gagné {levels} niveau(x). » / « Tu veux le reprendre ? Ce sera {price} ₽. » [Oui / Non] |
| T-9 | Équipe pleine | « Ton équipe est complète. Fais-lui une place d'abord. » |
| T-10 | Retrait | « Merci ! Voici {pokemon}. Il est en pleine forme. » |
| T-11 | Argent insuffisant | « Tu n'as pas tout à fait assez… Ce n'est rien, je prends ce que tu as. » / « Voici {pokemon}. » |
| T-12 | Après le retrait | « Je garde toujours une place. Reviens quand tu veux. » |

### 15.2 Route 5, souterrain, Route 6

| # | Moment | Texte |
|---|---|---|
| T-13 | Panneau Route 5 | « ROUTE 5 — Azuria ↔ Safrania » |
| T-14 | Panneau du souterrain | « PASSAGE SOUTERRAIN — Route 5 ↔ Route 6 » |
| T-15 | Garde, Route 5 | « Halte ! La route de Safrania est fermée. » / « Ordre de la ville. Je n'en sais pas plus, désolé. » |
| T-16 | Garde, Route 5, ensuite | « Toujours fermé. Si tu vas vers Carmin-sur-Mer, prends le passage souterrain. » |
| T-17 | Garde, Route 6 | « Désolé, personne n'entre à Safrania en ce moment. » / « Ordre de la ville. » |
| T-18 | Passant du souterrain | « On dit que ce passage est plus vieux que les routes. » / « Il y a des recoins où personne ne regarde jamais. » |
| T-19 | Indice (EXAMINER) | « Une pierre est descellée dans le mur. Quelque chose est coincé derrière. » → toast « Guérison obtenue » |
| T-20 | Panneau Route 6 | « ROUTE 6 — Safrania ↔ Carmin-sur-Mer » |
| T-21 | Promeneuse, Route 5 | « Le jardin de la Pension est le plus beau de la région. Les Pokémon y sont bien. » |
| T-22 | Voyageur, carrefour | « Je voulais aller à Safrania, mais les gardes ne laissent passer personne. » / « Tant pis, je descends vers la mer. » |
| T-23 | Pêcheur de l'étang | « Pas de canne aujourd'hui. Je regarde l'eau, c'est déjà bien. » / « À Carmin, il y a un vrai pêcheur. Un drôle de type. » |
| T-24 | 6 Dresseurs | Voir §15.5 (écrits dans le ton validé, relisibles au plan). |

### 15.3 Carmin-sur-Mer

| # | Moment | Texte |
|---|---|---|
| T-25 | Panneau d'entrée | « CARMIN-SUR-MER — Le port des grands départs » |
| T-26 | Marin de la passerelle (J15, provisoire) | « Le S.S. Anne est à quai pour quelques jours. » / « L'équipage prépare la croisière. L'embarquement n'a pas encore commencé. » |
| T-27 | Docker 1 | « Ce paquebot fait le tour du monde. Les Dresseurs à bord viennent de partout. » |
| T-28 | Docker 2 | « On charge depuis l'aube. Des caisses, des malles… et des Pokémon de toutes les régions. » |
| T-29 | Arbre de l'Arène (EXAMINER) | « Un jeune arbre pousse devant l'entrée. Impossible de passer. » |
| T-30 | Panneau de l'Arène | « ARÈNE DE CARMIN-SUR-MER — Champion : Major Bob » (sous-titre à proposer) |
| T-31 | Habitant, Major Bob | « Major Bob a servi dans l'armée, autrefois. » / « Ses Pokémon Électrik l'ont sorti de bien des situations. » |
| T-32 | Habitante, l'arbre | « Cet arbre devant l'Arène ? Il a poussé tout seul. » / « Major Bob dit que les vrais challengers trouveront un moyen. » |
| T-33 | Président du Fan Club | « Tu aimes les Pokémon ? Alors écoute-moi parler de mon Ponyta ! » / « Sa crinière, sa démarche… un champion ! » / « Reviens quand tu veux, j'ai toujours une histoire à raconter ! » |
| T-34 | Membre du Fan Club | « Ici, on ne se bat pas. On se raconte nos Pokémon. » |
| T-35 | Pêcheur | « Je suis le meilleur pêcheur de Carmin ! » / « La mer est pleine de Pokémon. Un jour, je t'apprendrai. » |
| T-36 | Habitant, Safrania | « Safrania est fermée depuis quelque temps. Personne ne sait vraiment pourquoi. » |

### 15.4 Objets, Pokédex, objectifs

| # | Élément | Texte |
|---|---|---|
| T-37 | Super Potion | « Rend 50 PV à un Pokémon. » |
| T-38 | Guérison | « Rend tous les PV et soigne le statut d'un Pokémon. » |
| T-39 | Jackpot | « Des pièces s'éparpillent sur l'adversaire. On les ramasse après un combat gagné. » |
| T-40 | Miaouss (Pokédex) | « Il adore ce qui brille. La nuit, il rôde dans les rues à la recherche de pièces. » |
| T-41 | Persan (Pokédex) | « Élégant et rapide. Le joyau de son front s'illumine quand il est sur ses gardes. » |
| T-42 | Objectifs | « Rejoindre Carmin-sur-Mer, au sud. » / « Explorer Carmin-sur-Mer. » |

### 15.5 Dresseurs de la Route 6 (T-24)

| # | Dresseur | Avant | Défaite | Après |
|---|---|---|---|---|
| T-24a | Chloé | « Tu sors du souterrain ? Mes Roucool t'attendaient ! » | « Trois contre un, et j'ai quand même perdu… » | « Carmin est tout au bout. Tu sentiras la mer avant de la voir. » |
| T-24b | Lucas | « Chloé a fini ? À mon tour ! » | « D'accord, d'accord. Tu es fort. » | « On attend le S.S. Anne. Il paraît qu'il y a des Dresseurs du monde entier à bord. » |
| T-24c | Axel | « Les herbes d'ici sont pleines d'insectes. Les miens sont les meilleurs ! » | « Mes Aspicot ont besoin de repos. » | « Un jour, ils évolueront tous. Tu verras. » |
| T-24d | Mathis | « Mon Carapuce s'entraîne au bord de l'eau. Il est prêt ! » | « Il a fait de son mieux. » | « Je l'ai choisi parce qu'il me ressemble : têtu. » |
| T-24e | Manon | « Mathis a perdu ? Alors je vais le venger ! » | « Ah… pas de vengeance aujourd'hui. » | « Mon Pikachu adore l'étang. Il ne se baigne jamais, mais il regarde. » |
| T-24f | Timéo | « D'ici, on voit tout le port. Et toi, tu vas voir mon Papilusion ! » | « Il vole mieux qu'il ne se bat… » | « Regarde ce bateau. Un jour, je partirai avec lui. » |

## 16. Valeurs par défaut (règle 4)

Enveloppes de cartes (Route 5 ≈ 42 × 62, souterrain ≤ 50 cases, Route 6 ≈ 42 × 56,
Carmin ≤ 64 × 48) ; poids et niveaux des rencontres ; prénoms et emplacements des Dresseurs ;
récompense de Jeune Dresseuse 20 ; objets des routes ; catégorie du souterrain ; Jackpot avec
l'effet RB ; marin et docker en nouveaux modèles ; objectifs du tableau de bord.

## Décisions verrouillées

| Élément | Décision |
|---|---|
| Périmètre | Route 5, souterrain, Route 6, Carmin-sur-Mer |
| Pension | 1 Pokémon ; 1 XP par pas en attente ; 100 + 100 ₽ par niveau ; rendu même sans assez d'argent ; capacités puis évolution proposées au retrait ; soin complet ; sauvegarde v7 |
| Souterrain | Sans rencontre ; ≤ 50 cases ; Guérison cachée ; pas de Corde Sortie |
| Route 6 | 6 Dresseurs RB, 1 inévitable |
| Espèces | Miaouss, Persan (+ lignées Mystherbe / Chétiflor si le J13 ne les apporte pas) |
| S.S. Anne | Visible ; marin et réplique provisoire au J15 ; Passe Bateau au J16 |
| Major Bob | Arène bloquée par un arbre, qui tombe avec Coupe |
| Safrania | Fermeture officielle, sans motif ; déblocage avec l'arc Rocket |
| Fan Club, Pêcheur | Présents ; Bon pour Vélo et Canne reportés à leurs systèmes |
| Exclus | Échanges, courrier, Route 11, vélo, pêche |
| Validation | 15.0 (Pension seule) → 15A → 15B |
| Textes | Lot §15 validé (2026-10-12) |
