# Dossier JOH-02 — Le passage et Oliville : grotte marine, vol, Professeur Orme (jalon JOH1, v0.1)

> Premier jalon de contenu du Chapitre Johto (cadre [`dossier-joh-00-cadre.md`](dossier-joh-00-cadre.md)
> §4.1–4.2 ; systèmes [`dossier-joh-01-systemes-joh0.md`](dossier-joh-01-systemes-joh0.md) §6).
> Écrit par Claude le 2026-11-02 ; **textes (§14) et JH-25 à JH-27 validés par Kevin le jour même** ;
> le reste du dossier est à valider.
> Valeurs **[D]** = défauts. Grilles et vues générales peintes après validation du dossier, comme
> à Kanto. **Grilles validées par Kevin le 2026-11-02** : `tools/plans/grotte_marine_1.txt`,
> `grotte_marine_2.txt`, `oliville.txt` (contrôle `tools/art/plan_check_joh1.py`, aperçu
> `reference/joh1-grilles-apercu-v1.png`) ; vues peintes après les grilles de tout l'acte 1. **Pas de code avant la fin de Kanto et du JOH0.**

## 1. Hors périmètre

- Les Routes 39 et suivantes (JOH2).
- L'intérieur du Phare d'Oliville (façade seule), le port et le bateau (pas de S.S. Aqua).
- La Peau Métal (placée au JOH6 **[D]**, pour ne pas ouvrir Steelix et Cizayox dès l'acte 1).
- Le Diplôme de Johto (remis plus tard, cadre §5.6).

## 2. Hypothèses d'entrée

- JOH0 fait : heure, lumières de Johto, équipe confisquée, Stockage hors ligne, régions, Pokédex 201,
  données des 51 espèces.
- Sauvegarde d'après la Ligue (`league_champion_defeated`), Surf obtenu.

## 3. Géographie

### 3.1 Retouche de Bourg Palette

- Une **bouche de grotte** dans les rochers de la rive sud, **à l'est du ponton**, accessible en
  Surf depuis l'eau de Bourg Palette (rangées 32–33, déjà de l'eau ; position exacte à caler sur
  `tools/build_pallet_town.gd` et la grille de la Route 21) **[D]**.
- **Avant** la lettre de Chen : rochers fermés, rien à voir. **Après** : la marée a baissé, la
  bouche est visible (un seul décor qui change selon le drapeau `johto_letter_read`) **[D]**.
- Rien d'autre ne change à Bourg Palette (JH-8).

### 3.2 Grotte marine (2 salles, ≈ 30 × 40 cases chacune) **[D]**

- **Salle 1** : eau surfable, quelques îlots de roche, un courant qui pousse vers l'est (système de
  glissade forcée existant, réglé sur l'eau) ; une seule voie.
- **Salle 2** : plus grande, plafond haut, eau profonde au centre. **L'ombre de Lugia** passe sous
  l'eau quand le joueur atteint le milieu (cinématique de 4 s, sans combat, une seule fois).
- **Sortie** : une plage de galets qui s'ouvre sur la côte sud-ouest d'Oliville.
- Profil de lumière : `cave_1f` éclairci de bleu, lumière qui tombe de fissures **[D]**.
- **Retour** : pendant l'acte 1, le courant de la salle 2 empêche de repartir vers Kanto (JH-18) ;
  à partir de l'acte 2, il s'inverse et la grotte se traverse dans les deux sens.

### 3.3 Oliville (≈ 50 × 40 cases) **[D]**

Ville portuaire sur une falaise basse, vue en golden hour sur les références de Johto à venir.

| Lieu | Rôle au JOH1 |
|---|---|
| **Centre Pokémon** (intérieur) | Repos, vol, choix du Pokémon de départ ; une salle de repos à l'étage (lit) |
| **Boutique** (intérieur) | Achats de base (Poké Balls, Potions, Antidotes, Rappels) |
| **Phare** (façade) | Décor ; allumé la nuit ; fermé (« en travaux ») |
| **Port** (quai) | Décor, PNJ ; pas de bateau |
| **Plage de galets** | Sortie de la grotte marine |
| 2 maisons (intérieurs) | PNJ |
| Sortie est | Route 39 (JOH2) ; fermée au JOH1 par un PNJ jusqu'au choix du Pokémon de départ |

Point de Vol : Oliville (cadre §3.2), ajouté à l'arrivée mais utilisable seulement à l'acte 2.

## 4. Ordre de jeu

| Étape | Lieu | Ce qui se passe | Drapeau posé |
|---|---|---|---|
| 1 | Bourg Palette, chez le joueur | Au premier réveil après le générique de la Ligue, la mère dit que Chen veut le voir **[D]** | — |
| 2 | Labo de Chen | Chen lit la lettre d'Orme, montre la vieille carte | `johto_letter_read` |
| 3 | Rive sud | La bouche de grotte est visible ; Surf | — |
| 4 | Grotte marine | Courant, ombre de Lugia | `johto_lugia_shadow` |
| 5 | Plage d'Oliville | Arrivée **de nuit** (moment imposé) ; titre de zone « Oliville » | `johto_arrived` |
| 6 | Centre | L'infirmière soigne l'équipe et propose de dormir ; le joueur accepte (scène forcée) | — |
| 7 | Centre, nuit | Vol (scène : silhouettes de Sbires dans la pénombre, sons) ; équipe et sac confisqués (JOH0 §6.2) | `johto_team_stolen`, `johto_act1`, `storage_offline` |
| 8 | Centre, matin | Réveil, l'infirmière découvre le vol, le PC ne répond pas | — |
| 9 | Centre | Orme arrive, se présente, propose les trois Pokémon | — |
| 10 | Centre | Choix du Pokémon de départ, 5 Poké Balls, 1 Potion | `johto_starter_chosen` |
| 11 | Oliville | Retour à l'heure réelle ; la sortie est s'ouvre | — |

**Scènes forcées et heure** : de l'étape 5 à l'étape 8, l'heure est imposée (nuit, puis matin) ; à
l'étape 11, on revient à l'heure du téléphone (JOH0 §2).

**Sauvegarde** : point de reprise au Centre d'Oliville après l'étape 10 ; le vol (étape 7) est une
seule écriture (JOH0 §6.2).

## 5. Rencontres

| Lieu | Espèces | Niveaux | Moment |
|---|---|---|---|
| Grotte marine, eau | Tentacool 60 %, Kokiyas 30 %, Stari 10 % | 40–45 | toute la journée |

Les rencontres de la grotte sont de **niveau Ligue** (le joueur a encore son équipe). Aucune
rencontre à Oliville. **[D]**

## 6. Objets

| Lieu | Objet | Note |
|---|---|---|
| Grotte marine, salle 1, îlot | Perle | Vente |
| Grotte marine, salle 2, îlot | Rappel Max | Volé avec le sac la nuit même (petite ironie, assumée) **[D]** |
| Orme | 5 Poké Balls, 1 Potion | Au choix du Pokémon de départ |

## 7. Personnages

| Personnage | Où | Rôle |
|---|---|---|
| Prof. Chen | Labo | Lit la lettre |
| Prof. Orme | Centre d'Oliville | Donne le Pokémon de départ ; repart à Doublonville (on le revoit au JOH3) |
| Infirmière d'Oliville | Centre | Soigne, propose le lit, découvre le vol |
| Sbires | Centre, nuit | Silhouettes dans la pénombre (JH-27), sans combat |
| 1 marin, 1 vieille dame, 1 enfant | Port, maisons | Ambiance, rumeurs sur la Team Rocket |
| Garde de la sortie est | Oliville | Bloque la Route 39 jusqu'au choix du Pokémon de départ |

## 8. Le choix du Pokémon de départ

- Même mise en scène que le choix de Kanto (trois Poké Balls sur une table, ici dans la salle de
  repos du Centre), avec la liste `starters_johto` (Germignon, Héricendre, Kaiminus), niveau 5.
- **Pas de Pokémon pour le rival** (cadre §5.7).
- Le Pokémon choisi devient **compagnon** et prend le lien de départ 50 (JOH0 §8).

## 9. Drapeaux **[D]**

`johto_letter_read`, `johto_lugia_shadow`, `johto_arrived`, `johto_team_stolen`, `johto_act1`,
`storage_offline`, `johto_starter_chosen`.

## 10. Défaites

Avant le vol : comme à Kanto (dernier Centre visité). Après le vol, l'équipe ne peut pas perdre
avant le choix du Pokémon de départ (aucun combat). Après le choix : retour au Centre d'Oliville.

## 11. Cas limites (à tester)

- Application tuée pendant la scène du vol (avant / après l'écriture).
- Application tuée entre le vol et le choix du Pokémon de départ : on reprend au Centre, le matin,
  avec Orme qui arrive (aucun moyen de sortir sans Pokémon).
- Le joueur va à la grotte sans Surf (impossible : Surf est requis pour la Ligue) ; avec un
  Pokémon surfeur K.O. : message habituel.
- Le joueur revient vers Kanto par la grotte pendant l'acte 1 : courant, message (JH-18).
- L'heure réelle est la nuit pendant les étapes 9 à 11 : on reste en matin imposé jusqu'à l'étape 11.
- Un œuf ou un Pokémon évolué dans l'équipe au moment du vol : tout part dans `confiscated`.

## 12. Validation (sous-jalon JOH1)

- Tests : drapeaux, confiscation sur ce parcours, choix du Pokémon de départ, courant bloquant.
- Captures : bouche de grotte avant / après, ombre de Lugia, Oliville de nuit et de jour, Centre.
- QA téléphone bornée (mémoire « QA bornée ») : départ de débogage après la Ligue.

## 13. Art

- Grotte marine (2 vues générales), Oliville (vue générale + plan), intérieurs du Centre (avec
  salle de repos) et de la Boutique de Johto, 2 maisons.
- Bouche de grotte de Bourg Palette (retouche d'un décor existant).
- Personnages : **Prof. Orme** (neuf), infirmière (existante), silhouettes de Sbires (existantes,
  assombries, en mouvement dans la pénombre : JH-27), marin, vieille dame, enfant (existants si possible).
- Ombre de Lugia : silhouette sombre sous l'eau (pas besoin du sprite de combat).

## 14. Textes (lot validé par Kevin le 2026-11-02)

Format : bulles séparées par « / ». `{joueur}`, `{rival}`, `{pokemon}` = noms.

| N° | Où | Texte |
|---|---|---|
| O-1 | Mère, au réveil après la Ligue | Bonjour, Maître de la Ligue ! / Le Professeur Chen est passé ce matin. / Il voudrait te voir au labo, ça avait l'air important. |
| O-2 | Chen, la lettre | Ah, {joueur} ! Te voilà. / J'ai reçu une lettre du Professeur Orme, un vieil ami. / Il travaille à Johto, la région à l'ouest de Kanto. / Il écrit que des Pokémon fuient les côtes… / et que des hommes en noir rôdent près des villes. / La Team Rocket, à Johto ? Je n'aime pas ça. |
| O-3 | Chen, la carte | Regarde cette vieille carte. / Une grotte marine relie la rive sud de Bourg Palette à la côte de Johto. / Elle n'apparaît qu'aux grandes marées basses… / Et la marée de cette semaine est la plus basse depuis des années. / Orme a entendu parler du nouveau Maître de Kanto. / Il serait heureux de te rencontrer. Va le trouver à Oliville ! |
| O-4 | Chen, après | La grotte est sur la rive sud, à l'est du ponton. / Prends garde aux courants. |
| O-5 | Examen, bouche de grotte | Une grotte s'ouvre dans les rochers. / L'eau s'y engouffre doucement. |
| O-6 | Grotte, ombre de Lugia (système) | … ! / Une ombre immense passe sous l'eau. / Elle disparaît dans les profondeurs. |
| O-7 | Courant, retour pendant l'acte 1 | Le courant est trop fort. / Impossible de repartir par là. |
| O-8 | Infirmière d'Oliville, arrivée | Bonsoir, et bienvenue à Oliville. / Vous venez de Kanto par la mer ? Quelle aventure ! / Je soigne vos Pokémon. / Vous avez l'air épuisé… / Nous avons une chambre à l'étage. Reposez-vous, je veille sur eux. |
| O-9 | Nuit (système, pendant que les silhouettes passent) | … / *Un bruit de verre.* / *Des pas pressés.* / *Une porte qui claque.* |
| O-10 | Infirmière, matin | {joueur} ! Réveillez-vous ! / Des voleurs sont entrés cette nuit… / Vos Pokémon… et vos affaires… / Ils ont tout pris. Je suis désolée… |
| O-11 | PC du Centre, après le vol | Connexion au réseau de Kanto… / … / Le réseau ne répond pas. |
| O-12 | Orme, arrivée | Bonjour ! C'est toi, {joueur} ? / Je suis le Professeur Orme. Chen m'a prévenu de ta venue. / J'arrive trop tard… L'infirmière m'a tout raconté. / Des hommes en noir, un « R » sur la poitrine. / C'est bien la Team Rocket. |
| O-13 | Orme, proposition | Écoute. Tu ne peux pas rester sans Pokémon. / J'ai apporté trois Pokémon que j'étudie. / Ils sont jeunes, mais ils ont du cœur. / Choisis celui qui t'accompagnera. |
| O-14 | Examen, Germignon | Germignon, le Pokémon Feuille. Type Plante. / Tu le choisis ? |
| O-15 | Examen, Héricendre | Héricendre, le Pokémon Souris Feu. Type Feu. / Tu le choisis ? |
| O-16 | Examen, Kaiminus | Kaiminus, le Pokémon Mâchoire. Type Eau. / Tu le choisis ? |
| O-17 | Orme, après le choix | {pokemon} a l'air de bien t'aimer ! / Prends aussi ces Poké Balls et cette Potion. / Tu as été Maître à Kanto ; ici, tu repars de zéro. / Mais je suis sûr que tu retrouveras tes Pokémon. |
| O-18 | Orme, départ | Je retourne à Doublonville, à l'est. / La Team Rocket y est très active, paraît-il. / Si tu passes par là, viens me voir au Centre. / Bonne chance, {joueur} ! |
| O-19 | Garde, sortie est, avant le choix | La Route 39 est par là. / Mais sans Pokémon, n'y pense même pas. |
| O-20 | Marin, port | Depuis quelques semaines, des bateaux sans pavillon passent la nuit. / Ils déchargent des caisses et repartent avant l'aube. |
| O-21 | Vieille dame, maison | Le Phare d'Oliville veille sur la côte depuis des siècles. / Ces temps-ci, il est en travaux. On se sent moins tranquille. |
| O-22 | Enfant, maison | Mon papa dit que les hommes en noir cherchent les Pokémon les plus forts du monde. / C'est quoi, le Pokémon le plus fort du monde ? |
| O-23 | Description de zone, Oliville | Une ville portuaire au pied de son vieux phare. |
| O-24 | Description de zone, Grotte marine | Un passage sous la mer, entre Kanto et Johto. |
| O-25 | Panneau, Oliville | **OLIVILLE** / La ville où souffle le vent du large |

## 15. Arbitrages pour Kevin

| N° | Question | Recommandation de Claude |
|---|---|---|
| JH-25 | ✅ Le Rappel Max de la grotte est gardé ; il revient avec le sac (Kevin, 2026-11-02) | — |
| JH-26 | ✅ Pas de Carte Dresseur de Johto (Kevin) | — |
| JH-27 | ✅ Le joueur voit les **silhouettes des Sbires** filer dans la pénombre du Centre (Kevin) | — |
