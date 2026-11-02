# Dossier JOH-03 — Premiers pas à Johto : Routes 39 et 38, Rosalia (jalon JOH2, v0.1)

> Deuxième jalon de contenu du Chapitre Johto (cadre [`dossier-joh-00-cadre.md`](dossier-joh-00-cadre.md)
> §4.2). Écrit par Claude le 2026-11-02 ; **textes (§13) et JH-28 à JH-30 validés par Kevin le jour
> même** ; le reste est à valider. Valeurs **[D]** = défauts. Grilles et vues peintes après validation.

## 1. Hors périmètre

- L'intérieur des tours de Rosalia (Tour Cendrée au JOH6, Tour Carillon au JOH8).
- La Route 37 et au-delà (JOH3).
- Les Kimonos, le Théâtre de danse, la maison du Pokémon Légendaire (Or/Argent) : absents.

## 2. Hypothèses d'entrée

- JOH1 fait : le joueur a un Pokémon de départ de Johto, niv. 5, 5 Poké Balls, `johto_act1`.
- L'heure du téléphone joue (JOH0) : les tables de rencontres changent avec le moment.

## 3. Géographie **[D]**

| Carte | Taille indicative | Contenu |
|---|---|---|
| **Route 39** | ≈ 24 × 50 | Du nord d'Oliville vers le nord ; la **Ferme Meumeu** en façade (enclos, Écrémeuh, Tauros et Ponyta) ; herbes hautes en deux poches |
| **Route 38** | ≈ 60 × 20 | Vers l'est ; un sentier entre des prés et une petite falaise ; 3 poches d'herbes hautes ; une barrière d'arbres (pas de Coupe nécessaire) |
| **Rosalia** | ≈ 56 × 48 | Ville ancienne, toits de tuiles, érables ; **Tour Cendrée** (ruine noircie, nord-ouest) et **Tour Carillon** (au nord-est, derrière un bois) en façade ; Centre, Boutique, 2 maisons, maison des sages |

Points de Vol : Rosalia (utilisable à l'acte 2).

## 4. Ordre de jeu

| Étape | Lieu | Ce qui se passe | Drapeau |
|---|---|---|---|
| 1 | Route 39 | Premières captures ; 2 Dresseurs | — |
| 2 | Route 38 | 3 Dresseurs ; un PNJ parle des tours de Rosalia | — |
| 3 | Rosalia, entrée | Titre de zone ; le joueur voit deux Sbires devant la Tour Cendrée | — |
| 4 | Rosalia, Tour Cendrée | Les Sbires interrogent un sage ; ils voient le joueur et s'enfuient vers l'est (sans combat) | `johto_rosalia_rockets_seen` |
| 5 | Rosalia, maison des sages | Le doyen raconte la Tour Cendrée et les trois Pokémon nés des cendres | `johto_tower_legend_heard` |
| 6 | Rosalia | Centre (soin, PC hors ligne), Boutique ; sortie est vers la Route 37 | — |

Pas de combat obligatoire au JOH2 hors Dresseurs inévitables (un sur la Route 38 **[D]**).

## 5. Rencontres **[D]**

| Carte | Moment | Espèces (poids) | Niveaux |
|---|---|---|---|
| Route 39 | matin, jour | Fouinette 30, Wattouat 30, Rattata 18, Roucool 18, Écrémeuh 4 | 4–7 |
| Route 39 | nuit | Hoothoot 40, Rattata 30, Mystherbe 30 | 4–7 |
| Route 38 | matin, jour | Fouinette 30, Wattouat 25, Roucool 20, Rattata 12, Miaouss 9, Écrémeuh 4 | 7–11 |
| Route 38 | nuit | Hoothoot 40, Rattata 30, Miaouss 20, Mystherbe 10 | 7–11 |
| Rosalia, herbe des tours | nuit | Cornèbre 50, Hoothoot 50 | 10–12 (rare, 10 % du taux habituel) |

## 6. Dresseurs **[D]**

| Où | Dresseur | Équipe | Évitable |
|---|---|---|---|
| Route 39 | Gamin Hugo | Rattata 6, Fouinette 7 | oui |
| Route 39 | Écolière Lina | Wattouat 8 | oui |
| Route 38 | Ornithologue Paul | Roucool 9, Hoothoot 10 | oui |
| Route 38 | Dresseuse Inès | Miaouss 10, Mystherbe 10, Wattouat 11 | **non** (sentier) |
| Route 38 | Pique-niqueur Théo | Fouinette 11, Rattata 11 | oui |

Gains d'XP ×1,5 (acte 1, JOH0 §10) en plus du ×1,5 des Dresseurs : objectif équipe niv. 12–14 à
Rosalia.

## 7. Objets **[D]**

| Où | Objet |
|---|---|
| Route 39, derrière la ferme | Potion |
| Route 38, au bout d'une impasse | Poké Ball ×2 |
| Route 38, caché (examen d'un tronc) | Super Potion |
| Rosalia, maison | Antidote ×2 (PNJ) |

## 8. PNJ de la semaine (JOH0, cadre §5.2)

Les deux premiers des sept **[D]** :

| Jour | Où | Personnage | Don (une fois) |
|---|---|---|---|
| Lundi | Oliville, port | **Lucien**, marin du lundi | Super Potion ×3 |
| Mardi | Rosalia, près du Centre | **Margot**, conteuse du mardi | Rappel ×2 |

Les autres jours viendront avec leurs villes (JOH3 à JOH6). Hors de son jour, le PNJ est absent.

## 9. Drapeaux **[D]**

`johto_rosalia_rockets_seen`, `johto_tower_legend_heard`, `week_monday_gift`, `week_tuesday_gift`.

## 10. Cas limites (à tester)

- Les tables changent si le moment change pendant que le joueur est sur la route (la prochaine
  rencontre suit le nouveau moment).
- Capture refusée à 6 Pokémon (JH-23), avec 5 Poké Balls seulement : la Boutique de Rosalia en
  vend.
- PC de Rosalia hors ligne (texte O-11).
- PNJ de la semaine : jour qui change à minuit pendant la partie.

## 11. Validation (sous-jalon JOH2)

- Tests : tables par moment, Dresseurs, drapeaux, PNJ de la semaine par jour (horloge injectée).
- Captures : Route 39 de jour et de nuit, Rosalia de jour et de nuit, la scène des Sbires.

## 12. Art

Route 39 (avec la Ferme Meumeu et ses Écrémeuh), Route 38, Rosalia (vue générale + plan, deux tours en façade,
Tour Cendrée noircie), intérieurs : Centre et Boutique (modèles de Johto du JOH1), maison des
sages, 2 maisons. Personnages : doyen et sages (neufs), Lucien, Margot (neufs), 5 Dresseurs
(modèles existants).

## 13. Textes (lot validé par Kevin le 2026-11-02)

| N° | Où | Texte |
|---|---|---|
| R-1 | Panneau, Route 39 | **ROUTE 39** / Oliville — Rosalia |
| R-2 | Panneau, Ferme Meumeu | **FERME MEUMEU** / Lait frais tous les matins |
| R-3 | Fermière, Route 39 | Les Tauros sont nerveux depuis quelques nuits. / Des gens passent sur la route sans lumière. / Je n'aime pas ça. |
| R-4 | Gamin Hugo | avant : Toi aussi tu viens d'avoir ton premier Pokémon ? · défaite : D'accord, tu as plus d'expérience que moi ! · après : J'ai l'impression que tu as déjà fait ça… |
| R-5 | Écolière Lina | avant : Mon Wattouat a une laine toute douce ! · défaite : Il est tout électrique maintenant… · après : On va réviser nos leçons. |
| R-6 | Panneau, Route 38 | **ROUTE 38** / Rosalia — Route 39 |
| R-7 | Ornithologue Paul | avant : La nuit, les Hoothoot comptent le temps. Et toi ? · défaite : Ton heure était venue… la mienne aussi. · après : Reviens la nuit, tu en verras plein. |
| R-8 | Dresseuse Inès | avant : Personne ne passe sans un petit combat ! · défaite : Bon, tu peux passer. · après : Rosalia est juste à l'est. Ses tours valent le détour. |
| R-9 | Pique-niqueur Théo | avant : Tu interromps mon pique-nique ! · défaite : Mon sandwich est tombé… · après : Il en reste un peu, tu veux ? |
| R-10 | Promeneur, Route 38 | À Rosalia, il y a deux tours. / L'une a brûlé il y a longtemps. / L'autre, personne n'a le droit d'y monter. |
| R-11 | Panneau, Rosalia | **ROSALIA** / Ville historique, où le passé reste vivant |
| R-12 | Sbire 1, devant la Tour Cendrée | Alors, vieux ? Où sont-ils, ces trois Pokémon ? / On sait qu'ils dorment sous la tour. |
| R-13 | Sage, devant la Tour Cendrée | Vous n'obtiendrez rien de moi. / La tour est fermée, et le restera. |
| R-14 | Sbire 2, voyant le joueur | Hé ! On nous regarde. / On s'en va. Le chef n'aime pas qu'on se fasse remarquer. |
| R-15 | Sage, après | Merci, jeune Dresseur. Ces hommes reviennent chaque nuit. / Va voir notre doyen, dans la maison au toit rouge. |
| R-16 | Doyen, la légende | Il y a cent cinquante ans, la Tour Cendrée a brûlé. / Trois Pokémon ont péri dans les flammes. / Alors un Pokémon arc-en-ciel est descendu du ciel… / et les a fait renaître de leurs cendres. / On dit qu'ils dorment encore sous la tour. |
| R-17 | Doyen, suite | Ces hommes en noir veulent les réveiller. / Pour quoi faire ? Je n'ose y penser. / Tant que je vivrai, la tour restera fermée. |
| R-18 | Doyen, après | Le Pokémon arc-en-ciel s'appelle Ho-Oh. / Il ne se montre qu'aux Dresseurs au cœur pur. |
| R-19 | Examen, porte de la Tour Cendrée | La porte est fermée. / Une odeur de vieux bois brûlé flotte encore. |
| R-20 | Garde, chemin de la Tour Carillon | La Tour Carillon est sacrée. / Seuls ceux que les sages autorisent peuvent y entrer. |
| R-21 | Lucien, marin du lundi (Oliville) | Le lundi, je reviens toujours au port. / Tiens, ça porte chance pour la semaine ! · *(système)* {joueur} reçoit 3 Super Potions ! · après : À lundi prochain, peut-être ! · autre jour : *(absent)* |
| R-22 | Margot, conteuse du mardi (Rosalia) | Le mardi, je raconte les vieilles histoires de Rosalia. / Tu as écouté jusqu'au bout ? Tiens, pour la route. · *(système)* {joueur} reçoit 2 Rappels ! · après : Reviens un mardi, j'en connais d'autres. |
| R-23 | Description de zone, Route 39 | Une route de campagne, entre la mer et les prés de la ferme. |
| R-24 | Description de zone, Route 38 | Un chemin entre les prés, vers la vieille ville de Rosalia. |
| R-25 | Description de zone, Rosalia | Une ville ancienne, gardée par deux tours. |

## 14. Arbitrages pour Kevin

| N° | Question | Recommandation de Claude |
|---|---|---|
| JH-28 | ✅ **Écrémeuh ajoutée** (51e espèce) : à la Ferme Meumeu et, rare, sur les Routes 38 et 39 (Kevin, 2026-11-02) | — |
| JH-29 | ✅ Les PNJ de la semaine donnent des consommables (Kevin) | — |
| JH-30 | ✅ Le doyen nomme Ho-Oh dès le JOH2 (Kevin) | — |
