# Dossier JOH-04 — La grande ville : Routes 37, 36, 35, Doublonville (jalon JOH3, v0.1)

> Troisième jalon de contenu du Chapitre Johto (cadre [`dossier-joh-00-cadre.md`](dossier-joh-00-cadre.md)
> §4.2 ; systèmes [`dossier-joh-01-systemes-joh0.md`](dossier-joh-01-systemes-joh0.md) §7–8).
> Écrit par Claude le 2026-11-02 ; **textes D-1 à D-38 et arbitrages JH-31 à JH-36 en attente de
> Kevin**. Valeurs **[D]** = défauts. Grilles et vues peintes après validation.

## 1. Hors périmètre

- L'intérieur de la Tour Radio (JOH5) ; la Route 34 et au-delà (JOH4).
- L'Arène de Blanche, le Parc National, le Casino, la Gare Magnétique, le salon de coiffure, le
  Simularbre (absent des 51 espèces), l'est de la Route 36 (Mauville).
- Le Grand Magasin d'Or/Argent en entier (6 étages) : ici **réduit** (§3.2).

## 2. Hypothèses d'entrée

- JOH2 fait : le joueur sort de Rosalia par le sud, équipe niv. 12–14, `johto_act1` posé.
- JOH0 fait : heure, lien `bond`, œuf (`egg_steps`), Améliorator dans les données.
- Le joueur a gardé ses **objets clés et ses badges** (JH-3) : Bicyclette, Cannes, CS et le droit
  de les utiliser (voir JH-36 pour le Surf).

## 3. Géographie **[D]**

### 3.1 Routes

| Carte | Taille indicative | Contenu |
|---|---|---|
| **Route 37** | ≈ 20 × 40 | Du sud de Rosalia vers le sud ; trois arbres fruitiers en décor, un bosquet sombre ; c'est là que rôdent les Sbires **la nuit** |
| **Route 36** | ≈ 56 × 20 | Carrefour d'ouest en est : à l'ouest, la Route 37 ; au centre, l'embranchement sud vers la Route 35 ; à l'est, un **pont en travaux** ferme la route de Mauville (JH-35) ; la grille du Parc National reste fermée (« fermé pour entretien ») |
| **Route 35** | ≈ 24 × 44 | Vers le sud ; un **étang** (pêche, Surf selon JH-36), herbes hautes en trois poches ; poste de garde au sud, porte nord de Doublonville |

### 3.2 Doublonville (≈ 72 × 60, la plus grande ville de Johto)

| Lieu | Rôle au JOH3 |
|---|---|
| **Centre Pokémon** | Orme y attend le joueur et remet l'**œuf de Togepi** (JH-32) ; PC hors ligne |
| **Grand Magasin** | RDC (accueil, **promotion du jour**), 1er (soins, Balls), 2e (Repousses, objets de combat), **toit** (distributeurs, **Améliorator**) — 3 niveaux + toit au lieu de 6 **[D]** |
| **Tour Radio** (façade, hall) | Fermée ; un « employé » garde l'ascenseur (JH-34) ; des **messages brouillés** passent dans les haut-parleurs de la ville |
| **Souterrain** (≈ 40 × 14) | Passage sous la place, boutiques fermées ; trois Sbires, le dernier **obligatoire** (JH-31) et porteur de l'indice vers Écorcia |
| **Maison du lien** | **Mme Clémence** évalue le lien du Pokémon de tête (dossier JOH-01 §8.3) |
| 2 maisons, la gare (façade fermée) | PNJ |
| Sortie sud | Route 34 (JOH4) ; un agent la ferme jusqu'à l'indice du Souterrain |

Points de Vol : Doublonville (utilisable à l'acte 2).

## 4. Ordre de jeu

| Étape | Lieu | Ce qui se passe | Drapeau |
|---|---|---|---|
| 1 | Route 37 | Le jour : 1 Dresseur. La nuit : 2 Sbires de route en plus (facultatifs) | — |
| 2 | Route 36 | 2 Dresseurs ; pont fermé à l'est ; Mercédès le mercredi | — |
| 3 | Route 35 | 3 Dresseurs ; étang | — |
| 4 | Doublonville, entrée | Titre de zone ; un haut-parleur grésille (D-10) | `johto_goldenrod_arrived` |
| 5 | Centre | Orme raconte : la Tour Radio, les Sbires du Souterrain ; il remet l'œuf | `johto_egg_received` |
| 6 | Tour Radio, hall | L'« employé » refuse l'accès | `johto_radio_tower_closed_seen` |
| 7 | Souterrain | 2 Sbires évitables, puis le chef de bande (obligatoire) : indice vers Écorcia | `johto_azalea_clue` |
| 8 | Sortie sud | L'agent laisse passer vers la Route 34 | — |
| — | Grand Magasin, maison du lien, PNJ du jeudi | Libres, à tout moment | `goldenrod_upgrade_taken`, `week_wednesday_gift`, `week_thursday_gift` |

Le premier combat contre la Team Rocket est garanti au Souterrain, quelle que soit l'heure
(JH-31) ; ceux de la Route 37 sont un bonus de nuit (cadre §5.2).

## 5. Rencontres **[D]**

| Carte | Moment | Espèces (poids) | Niveaux |
|---|---|---|---|
| Route 37 | matin, jour | Fouinar 25, Caninos 25, Roucool 20, Ponyta 15, Rattata 15 | 13–16 |
| Route 37 | nuit | Hoothoot 35, Malosse 30, Mystherbe 20, Rattatac 15 | 13–16 |
| Route 36 | matin, jour | Fouinette 30, Caninos 20, Nidoran♀ 15, Nidoran♂ 15, Roucool 10, Chenipan 10 (matin seulement, reporté sur Fouinette le jour) | 12–15 |
| Route 36 | nuit | Hoothoot 40, Nidoran♀ 15, Nidoran♂ 15, Mystherbe 20, Rattata 10 | 12–15 |
| Route 35 | matin, jour | Nidoran♀ 15, Nidoran♂ 15, Roucool 20, Marill 20, Abra 15, Fouinette 15 | 13–16 |
| Route 35 | nuit | Hoothoot 30, Nidoran♀ 15, Nidoran♂ 15, Mystherbe 20, Marill 20 | 13–16 |
| Route 35, étang (Surf) | toute la journée | Ptitard 60, Marill 40 | 13–17 |
| Route 35, étang (pêche) | toute la journée | Canne : Magicarpe ; Super Canne : Ptitard, Poissirène | comme Kanto |

## 6. Dresseurs **[D]**

| Où | Dresseur | Équipe | Évitable |
|---|---|---|---|
| Route 37 | Ornithologue Lise | Roucool 14, Hoothoot 15 | oui |
| Route 37, nuit | Sbire (A) | Malosse 15, Rattata 14 | oui |
| Route 37, nuit | Sbire (B) | Cornèbre 15, Abo 15 | oui |
| Route 36 | Scout Max | Caninos 15, Nidoran♂ 14 | oui |
| Route 36 | Médium Ernest | Abra 16 | oui |
| Route 35 | Pêcheur Gaston | Magicarpe 13, Magicarpe 13, Ptitard 15 | oui |
| Route 35 | Campeuse Anna | Nidoran♀ 15, Ponyta 16 | **non** (poste de garde) |
| Route 35 | Gentleman Armand | Caninos 17 | oui |
| Souterrain | Sbire (C) | Rattata 15, Abo 16 | oui |
| Souterrain | Sbire (D) | Cornèbre 16, Malosse 16 | oui |
| Souterrain | Chef de bande | Malosse 17, Cornèbre 17, Smogo 18 | **non** (JH-31) |

Objectif : équipe niv. 17–20 en sortant de Doublonville (Exp ×1,5 de l'acte 1).

## 7. L'œuf de Togepi (JH-32)

- Remis par **Orme en personne** au Centre (il l'avait annoncé à Oliville, O-18).
- Équipe pleine (6) : Orme garde l'œuf et attend qu'une place se libère (Stockage hors ligne,
  JOH0 §7) ; il le redonne dès qu'on lui reparle avec une place **[D]**.
- Éclosion après **2 000 pas** (JOH0 §7) : en pratique entre la Route 34 et le Puits Ramoloss.
- Lien de départ du Togepi éclos : 50 (JOH0 §8).

## 8. Grand Magasin

### 8.1 Rayons **[D]**

| Étage | Vente |
|---|---|
| RDC | Accueil, panneau de la promotion du jour |
| 1er | Poké Ball, Super Ball, Potion, Super Potion, Antidote, Anti-Para, Réveil, Total Soin |
| 2e | Repousse, Super Repousse, Corde Sortie, Attaque +, Défense +, Vitesse +, Spécial + |
| Toit | Distributeurs : Eau Fraîche, Soda Cool, Limonade |

### 8.2 Promotion du jour (JH-33) **[D]**

Un article à **moitié prix**, au jour du téléphone. Le panneau du RDC l'annonce (D-21).

| Jour | Article en promotion |
|---|---|
| Lundi | Poké Ball |
| Mardi | Potion et Super Potion |
| Mercredi | Super Ball |
| Jeudi | Repousse et Super Repousse |
| Vendredi | Rappel *(vendu ce jour seulement, au 1er)* |
| Samedi | Total Soin |
| Dimanche | Boissons du toit |

### 8.3 Améliorator

Une **Poké Ball posée sur le toit**, ramassée une fois (`goldenrod_upgrade_taken`) **[D]**. Elle ne
sert qu'à l'acte 2 (Porygon, obtenu à Kanto au J32, est au Stockage hors ligne pendant l'acte 1).

## 9. La maison du lien

Mme Clémence regarde le Pokémon de tête (le compagnon s'il y en a un, sinon le premier non-œuf
**[D]**) et dit l'un des quatre paliers (JOH0 §8.3). Œuf en tête : texte à part (D-27).

## 10. PNJ de la semaine

| Jour | Où | Personnage | Don (une fois) |
|---|---|---|---|
| Mercredi | Route 36, près de l'embranchement | **Mercédès**, jardinière du mercredi | Super Ball ×3 |
| Jeudi | Doublonville, devant le Grand Magasin | **Jérôme**, livreur du jeudi | Eau Fraîche ×3 |

## 11. Objets **[D]**

| Où | Objet |
|---|---|
| Route 37, derrière un arbre | Super Potion |
| Route 36, au bout du pont fermé | Rappel |
| Route 35, caché (rocher au bord de l'étang) | Super Ball ×2 |
| Souterrain | Repousse ×2 ; Perle (cachée) |
| Grand Magasin, toit | Améliorator |

## 12. Drapeaux **[D]**

`johto_goldenrod_arrived`, `johto_egg_received`, `johto_radio_tower_closed_seen`,
`johto_azalea_clue`, `goldenrod_upgrade_taken`, `week_wednesday_gift`, `week_thursday_gift`.

## 13. Cas limites (à tester)

- Équipe pleine quand Orme donne l'œuf (§7) ; œuf en tête chez Mme Clémence.
- Arrivée de jour : aucun Sbire sur la Route 37, le Souterrain suffit (JH-31).
- Le chef du Souterrain gagne : retour au Centre, chef toujours là, sortie sud fermée.
- Promotion qui change à minuit pendant que le menu de la Boutique est ouvert : le prix change à la
  réouverture **[D]**.
- Surf sur l'étang de la Route 35 avec un Pokémon de Johto (JH-36) ; Surf de Bourg Palette
  toujours bloqué par le courant (O-7).

## 14. Validation (sous-jalon JOH3)

- Tests : tables par moment, Sbires de nuit, ordre Souterrain → sortie sud, œuf (équipe pleine),
  promotions par jour (horloge injectée), paliers de Mme Clémence, PNJ du mercredi et du jeudi.
- Captures : Routes 37 et 35 de nuit, Doublonville de jour et de nuit, Souterrain, toit.

## 15. Art

Routes 37, 36, 35 ; Doublonville (vue générale + plan, la Tour Radio en point haut) ; intérieurs :
Centre (modèle du JOH1), Grand Magasin (RDC, 2 étages, toit), hall de la Tour Radio, Souterrain,
maison du lien, 2 maisons. Personnages neufs : Mme Clémence, Mercédès, Jérôme, l'« employé » de la
Tour Radio (tenue qu'on reverra au JOH5). Œuf de Togepi (icône d'équipe, déjà prévue au JOH0).

## 16. Textes (lot à valider par Kevin)

Format : bulles séparées par « / ». `{joueur}`, `{pokemon}` = noms.

| N° | Où | Texte |
|---|---|---|
| D-1 | Panneau, Route 37 | **ROUTE 37** / Rosalia — Route 36 |
| D-2 | Ornithologue Lise | avant : Chut ! Tu vas faire fuir les oiseaux. · défaite : Bon, ils sont partis de toute façon. · après : La nuit, il y a des gens bizarres sur cette route. |
| D-3 | Sbire A (nuit, Route 37) | avant : Un gamin seul, la nuit ? Donne-moi tes Pokémon ! · défaite : Tu n'es pas un gamin ordinaire… · après : On a l'ordre de ne pas traîner. Je file. |
| D-4 | Sbire B (nuit, Route 37) | avant : On t'a vu à Rosalia, toi. · défaite : Le chef ne va pas aimer ça. · après : Doublonville, c'est chez nous, maintenant. |
| D-5 | Panneau, Route 36 | **ROUTE 36** / Route 37 — Route 35 |
| D-6 | Panneau, pont de la Route 36 | Pont en travaux. / Passage interdit jusqu'à nouvel ordre. |
| D-7 | Scout Max · Médium Ernest | Max — avant : Un scout est toujours prêt ! · défaite : Pas assez prêt, apparemment. · après : Doublonville est au sud, par la Route 35. — Ernest — avant : Mon Abra a vu ta victoire… ou ta défaite ? · défaite : Il avait mal vu. · après : Il a dormi pendant tout le combat. |
| D-8 | Panneau, Route 35 | **ROUTE 35** / Doublonville — Route 36 |
| D-9 | Pêcheur Gaston · Campeuse Anna · Gentleman Armand | Gaston — avant : Ça mord ! Ah non, c'est toi. · défaite : Raté. · après : Les Ptitard aiment l'étang. — Anna — avant : Tu veux passer ? Il faut me battre ! · défaite : D'accord, la ville est à toi. · après : Doublonville est immense, tu vas t'y perdre ! — Armand — avant : Un combat, entre gens bien élevés ? · défaite : Quelle élégance. · après : Ma radio ne capte plus que des grésillements. |
| D-10 | Haut-parleur de la ville | *Ici Radio Doublonville… bonne jour… * / *…crrr… R… reviens… crrr…* / *…nous nous excusons pour cette interruption.* |
| D-11 | Panneau, Doublonville | **DOUBLONVILLE** / La ville scintillante, au carrefour de Johto |
| D-12 | Orme, Centre | {joueur} ! Tu es venu jusqu'ici, bravo. / Et ton {pokemon} a bien grandi. / Ici aussi, la Team Rocket s'agite. / La Tour Radio diffuse des messages brouillés depuis une semaine. / Et des hommes en noir traînent dans le Souterrain. |
| D-13 | Orme, l'œuf | J'ai quelque chose pour toi. / Un ami de Doublonville m'a confié cet œuf. / Je ne sais pas encore ce qui en sortira. / Garde-le dans ton équipe : les Pokémon nés d'un œuf s'attachent vite à qui les a portés. · *(système)* {joueur} reçoit un Œuf ! |
| D-14 | Orme, équipe pleine | Ton équipe est pleine… / Et le réseau de stockage est toujours coupé. / Reviens me voir quand tu auras une place. |
| D-15 | Orme, après | Fais attention à toi, {joueur}. / Ceux qui ont volé tes Pokémon ne sont pas loin. |
| D-16 | Œuf, éclosion (système) | Hein ? / … / L'Œuf éclot ! / {joueur} obtient un Togepi ! |
| D-17 | Écran Équipe, phrases de l'œuf | > 1 000 pas : Ce qui est dedans dort encore. · 300–1 000 : Il bouge un peu. · < 300 : On l'entend remuer ! Il va bientôt éclore. |
| D-18 | « Employé » de la Tour Radio | Désolé, la Tour est fermée au public. / Travaux techniques. / Revenez… plus tard. Beaucoup plus tard. |
| D-19 | Examen, ascenseur de la Tour Radio | Un écriteau : « Étages fermés ». / Des voix étouffées descendent de là-haut. |
| D-20 | Hôtesse du Grand Magasin | Bienvenue au Grand Magasin de Doublonville ! / Les soins au 1er, les accessoires au 2e, / et une vue magnifique sur le toit. |
| D-21 | Panneau de la promotion | **PROMOTION DU JOUR** / Aujourd'hui, {article} à moitié prix ! |
| D-22 | Examen, Améliorator (système) | {joueur} trouve un Améliorator ! / Une étrange boîte de la Sylphe SARL. |
| D-23 | Vieil homme, toit | D'ici, on voit toute la ville. / Et la Tour Radio. / Depuis une semaine, sa lumière clignote toute la nuit. |
| D-24 | Mme Clémence, accueil | Bonjour, mon petit. Je suis Clémence. / Je sais lire dans le cœur des Pokémon. / Montre-moi celui qui marche devant toi. |
| D-25 | Mme Clémence, paliers | < 30 : Hum… Il ne te connaît pas encore très bien. Laisse-lui du temps. · 30–69 : Il commence à t'apprécier. Continuez ensemble. · 70–89 : Il t'aime beaucoup. Ça se voit dans ses yeux. · ≥ 90 : Je n'ai jamais vu un lien pareil. Il te suivrait n'importe où. |
| D-26 | Mme Clémence, après | Un Pokémon qui t'aime peut changer, parfois. / Prends soin de lui. |
| D-27 | Mme Clémence, œuf en tête | Un œuf ! Je ne peux pas encore lire son cœur. / Mais il entend déjà ta voix, tu sais. |
| D-28 | Panneau, Souterrain | **SOUTERRAIN DE DOUBLONVILLE** / Boutiques ouvertes de 10 h à 20 h *(un papier collé : « Fermé jusqu'à nouvel ordre »)* |
| D-29 | Sbire C · Sbire D (Souterrain) | C — avant : Le Souterrain est à nous, dégage ! · défaite : Ouille. · après : Va voir le chef, au fond. Il va t'apprendre la politesse. — D — avant : Encore toi ? On t'avait dit de disparaître ! · défaite : Tu es tenace. · après : Le chef ne recule jamais. |
| D-30 | Chef de bande, avant | Alors c'est toi, le gamin qui fouine partout. / Ici, c'est notre territoire. Personne ne passe. |
| D-31 | Chef de bande, défaite | Grr… Comment un gamin peut-il être aussi fort ? |
| D-32 | Chef de bande, l'indice | Tu crois qu'on est seulement ici ? / Les copains font de bonnes affaires à Écorcia, au sud. / Les queues de Ramoloss, ça se vend très cher. / Et les ordres viennent d'en haut. De très haut. |
| D-33 | Agent, sortie sud, avant l'indice | La Route 34 ? Pas aujourd'hui. / Avec ce qui se passe dans le Souterrain, on ne laisse sortir personne. |
| D-34 | Agent, après l'indice | C'est toi qui as chassé les hommes du Souterrain ? / Merci. La route du sud est ouverte. |
| D-35 | Mercédès, jardinière du mercredi (Route 36) | Le mercredi, j'arrose les fleurs de la route. / Tu as l'air pressé… Tiens, ça pourra servir. · *(système)* {joueur} reçoit 3 Super Balls ! · après : Reviens un mercredi, les fleurs seront plus belles. |
| D-36 | Jérôme, livreur du jeudi (Doublonville) | Le jeudi, je livre le Grand Magasin. / Oups, il me reste des bouteilles en trop. Prends ! · *(système)* {joueur} reçoit 3 Eaux Fraîches ! · après : À jeudi prochain ! |
| D-37 | Femme, maison de Doublonville | Mon mari travaille à la Tour Radio. / Il n'est pas rentré depuis trois jours. / Ils disent qu'il fait des heures en plus… |
| D-38 | Descriptions de zone | Route 37 : Un chemin bordé d'arbres, entre Rosalia et la plaine. · Route 36 : Un carrefour de campagne, au cœur de Johto. · Route 35 : Une route verte, avec un étang, aux portes de Doublonville. · Doublonville : La grande ville de Johto, dominée par sa Tour Radio. · Souterrain : Un passage sous la ville, presque désert. |

## 17. Arbitrages pour Kevin

| N° | Question | Recommandation de Claude |
|---|---|---|
| JH-31 | Premier combat contre la Team Rocket : garanti au Souterrain, quelle que soit l'heure, ou seulement la nuit sur la Route 37 ? | **Garanti au Souterrain** (chef obligatoire) ; les Sbires de nuit de la Route 37 restent un bonus |
| JH-32 | Qui remet l'œuf de Togepi ? | **Orme en personne**, au Centre (cohérent avec O-18) |
| JH-33 | Forme des promotions du Grand Magasin | **Un article à moitié prix par jour** (§8.2) |
| JH-34 | Qui garde la Tour Radio ? | **Un faux employé** (Sbire déguisé, démasqué au JOH5) |
| JH-35 | Ce qui ferme l'est de la Route 36 (Mauville, hors périmètre) | **Un pont en travaux** |
| JH-36 | Surf pendant l'acte 1 avec un Pokémon de Johto (CS et badges gardés) | **Autorisé** (étang de la Route 35) ; le courant de la grotte marine bloque toujours Kanto |
