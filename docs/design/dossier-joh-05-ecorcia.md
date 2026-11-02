# Dossier JOH-05 — Le détour du sud : Route 34, Bois aux Chênes, Écorcia, Puits Ramoloss (jalon JOH4, v0.1)

> Quatrième jalon de contenu du Chapitre Johto (cadre [`dossier-joh-00-cadre.md`](dossier-joh-00-cadre.md)
> §4.2). Écrit par Claude le 2026-11-02 ; **textes E-1 à E-36 et arbitrages JH-37 à JH-39 en attente
> de Kevin**. Valeurs **[D]** = défauts. Grilles et vues peintes après validation.

## 1. Hors périmètre

- L'Arène d'Écorcia et son Champion, la fabrique de Noigrumes, la Pension de la Route 34 (pas de
  reproduction, cadre §1), l'énigme du Canarticho de la charbonnerie (Canarticho en décor **[D]**).
- La Tour Radio (JOH5) ; Celebi et l'usage de l'autel (post-game, JH-16).

## 2. Hypothèses d'entrée

- JOH3 fait : `johto_azalea_clue` posé, sortie sud de Doublonville ouverte, œuf reçu (il éclot en
  général pendant ce jalon), équipe niv. 17–20.

## 3. Géographie **[D]**

| Carte | Taille indicative | Contenu |
|---|---|---|
| **Route 34** | ≈ 24 × 48 | Du sud de Doublonville vers le sud ; une maison de bord de route (sans Pension), un étang côtier, 3 poches d'herbes hautes |
| **Bois aux Chênes** | ≈ 48 × 48 | Forêt serrée (mêmes règles que la Forêt de Jade : « nature dense ») ; un sentier en lacets ; **l'autel** dans une clairière (fermé, JH-39) ; la **charbonnerie** en lisière sud (façade, Canarticho) |
| **Écorcia** | ≈ 44 × 36 | Petite ville sous les arbres, toits de chaume ; Centre, Boutique, maison de **Fargas** (JH-37), charbonnerie, **Puits Ramoloss** (entrée au nord-est) ; des Ramoloss somnolent dans les rues… sauf qu'il n'y en a plus |
| **Puits Ramoloss** | 2 niveaux, ≈ 30 × 24 chacun | B1F : Sbires, eau peu profonde, rochers ; B2F : grande salle humide, Ramoloss sans queue, **Brace** |

Points de Vol : Écorcia (utilisable à l'acte 2). Retour à Doublonville à pied par le Bois (JOH5).

## 4. Ordre de jeu

| Étape | Lieu | Ce qui se passe | Drapeau |
|---|---|---|---|
| 1 | Route 34 | 3 Dresseurs ; un PNJ parle des Ramoloss disparus | — |
| 2 | Bois aux Chênes | Sentier, autel (examen), 2 Dresseurs | `johto_shrine_seen` |
| 3 | Écorcia, entrée | Titre de zone ; plus un Ramoloss dans les rues | — |
| 4 | Écorcia, maison de Fargas | Fargas raconte : la Team Rocket coupe les queues des Ramoloss pour les vendre ; il descend au puits | `johto_kurt_told` |
| 5 | Puits, entrée | Un Sbire garde l'entrée ; il fuit dans le puits à l'arrivée de Fargas | — |
| 6 | Puits B1F | Fargas tombe et se fait mal au dos ; il laisse le joueur continuer (E-15) ; 3 Sbires | — |
| 7 | Puits B2F | **Brace** (combat obligatoire) ; il s'enfuit en laissant l'**ordre de mission** signé « D. » et la **Carte d'accès** de la Tour Radio | `johto_brace_defeated`, `johto_radio_pass` |
| 8 | Puits | Les Ramoloss retournent vers la ville ; Fargas, remis, donne la **Roche Royale** | `johto_slowpoke_well_cleared` |
| 9 | Écorcia | Les Ramoloss sont de retour dans les rues ; Vincent le vendredi | `week_friday_gift` |

## 5. Rencontres **[D]**

| Carte | Moment | Espèces (poids) | Niveaux |
|---|---|---|---|
| Route 34 | matin, jour | Fouinette 25, Abra 20, Nidoran♀ 15, Nidoran♂ 15, Rattatac 15, Métamorph 10 | 16–19 |
| Route 34 | nuit | Hoothoot 35, Rattatac 25, Métamorph 15, Nidoran♀ 12, Nidoran♂ 13 | 16–19 |
| Bois aux Chênes | matin | Teddiursa 25, Paras 25, Chenipan 15, Aspicot 15, Scarhino 5, Mystherbe 15 | 17–20 |
| Bois aux Chênes | jour | Paras 30, Chenipan 20, Aspicot 20, Mystherbe 20, Fouinette 10 | 17–20 |
| Bois aux Chênes | nuit | Cornèbre 30, Noarfang 15, Hoothoot 25, Mystherbe 20, Paras 10 | 17–20 |
| Puits Ramoloss | toute la journée | Ramoloss 45, Nosferapti 45, Racaillou 10 | 18–22 |
| Puits, eau (Surf, JH-36) | toute la journée | Ramoloss 70, Ptitard 30 | 18–22 |

Ramoloss reste capturable au puits (JH-38).

## 6. Dresseurs **[D]**

| Où | Dresseur | Équipe | Évitable |
|---|---|---|---|
| Route 34 | Pique-niqueuse Sophie | Marill 18, Nidoran♀ 18 | oui |
| Route 34 | Pokémaniac Bruno | Métamorph 19, Ramoloss 19 | oui |
| Route 34 | Jongleur Félix | Abra 18, Kadabra 20 | **non** (sentier) |
| Bois aux Chênes | Scout Tom | Paras 19, Chenipan 18, Chrysacier 19 | oui |
| Bois aux Chênes | Dresseuse Céline | Hoothoot 20, Teddiursa 20 | oui |
| Puits B1F | Sbire (E) | Rattatac 20, Abo 20 | **non** |
| Puits B1F | Sbire (F) | Smogo 21, Nosferapti 20 | oui |
| Puits B1F | Sbire (G) | Malosse 21, Cornèbre 21 | oui |
| Puits B2F | **Brace**, admin | Cornèbre 24, Smogo 24, **Démolosse 26** | **non** |

Brace est un **grand combat** (mémoire « Difficulté des combats » : victoire du premier coup
35–60 % avec une équipe de 20–24). Objectif : équipe niv. 22–26 en sortant du puits.

## 7. Objets **[D]**

| Où | Objet |
|---|---|
| Route 34, au bord de l'étang | Super Potion |
| Bois aux Chênes, souche (caché) | Super Bonbon |
| Bois aux Chênes, impasse | Repousse ×2 |
| Puits B1F | Super Ball ×2 |
| Puits B2F | Corde Sortie |
| Fargas | **Roche Royale** (objet d'évolution, JOH0 §9) |
| Brace (en fuite) | **Ordre de mission** (objet clé, lisible) ; **Carte d'accès** de la Tour Radio (objet clé, utilisée au JOH5) |

## 8. L'ordre de mission

Objet clé lisible depuis le Sac (E-22). Il ne dit pas le nom de Dante : seulement l'initiale
« D. ». Il disparaît du Sac au JOH5, quand Dante se révèle **[D]**.

## 9. PNJ de la semaine

| Jour | Où | Personnage | Don (une fois) |
|---|---|---|---|
| Vendredi | Écorcia, devant la charbonnerie | **Vincent**, charbonnier du vendredi | Super Repousse ×2 |

Samedi et dimanche viendront au JOH6 (Acajou, Rosalia rouverte) **[D]**.

## 10. Drapeaux **[D]**

`johto_shrine_seen`, `johto_kurt_told`, `johto_brace_defeated`, `johto_radio_pass`,
`johto_slowpoke_well_cleared`, `week_friday_gift`.

## 11. Cas limites (à tester)

- Défaite contre Brace : retour au Centre d'Écorcia ; Fargas reste au B1F, Brace au B2F.
- Le joueur ressort du puits avant Brace : les Ramoloss restent absents d'Écorcia.
- Roigada ou Tarpaud dès l'acte 1 avec la Roche Royale au terminal d'échange local (JH-38).
- Œuf qui éclot dans le puits (hors combat, hors cinématique : JOH0 §7).
- Corde Sortie dans le puits : ramène à l'entrée du puits, comme à Kanto.

## 12. Validation (sous-jalon JOH4)

- Tests : tables par moment (matin du Bois), ordre Fargas → Brace → Roche Royale, objets clés
  remis, retour des Ramoloss, PNJ du vendredi.
- Captures : Bois aux Chênes de matin et de nuit, autel, Écorcia avant / après, Puits B2F et Brace.

## 13. Art

Route 34, Bois aux Chênes (vue générale + plan, forêt serrée), Écorcia (vue générale + plan,
avec et sans Ramoloss), Puits Ramoloss (2 vues), intérieurs : maison de Fargas, Centre et Boutique
(modèles du JOH1), maison de la Route 34. Personnages neufs : **Fargas**, **Brace** (impétueux,
tenue d'admin), **Vincent**. Ramoloss sans queue (variante de décor du sprite peint).

## 14. Textes (lot à valider par Kevin)

Format : bulles séparées par « / ». `{joueur}` = nom.

| N° | Où | Texte |
|---|---|---|
| E-1 | Panneau, Route 34 | **ROUTE 34** / Doublonville — Bois aux Chênes |
| E-2 | Pêcheur, Route 34 | Avant, les Ramoloss d'Écorcia venaient pêcher ici. / Ça fait des semaines qu'on n'en voit plus un seul. |
| E-3 | Sophie · Bruno · Félix | Sophie — avant : Tu tombes bien, je m'ennuyais ! · défaite : Bon, je retourne à mon panier. · après : Le Bois aux Chênes est sombre, ne te perds pas. — Bruno — avant : Mes Pokémon sont rares, tu vas voir ! · défaite : Rares… mais pas assez forts. · après : Mon Métamorph imite tout, sauf la victoire. — Félix — avant : Hop, hop ! Regarde bien mes balles ! · défaite : J'en ai fait tomber une. · après : Au sud, c'est le Bois aux Chênes. Suis le sentier. |
| E-4 | Panneau, Bois aux Chênes | **BOIS AUX CHÊNES** / Forêt protégée. Respectez le gardien du bois. |
| E-5 | Examen, autel | Un petit autel de bois, couvert de mousse. / Quelqu'un y a déposé des fleurs fraîches. / On dirait qu'il attend quelque chose. |
| E-6 | Vieille femme, près de l'autel | On dit que le gardien de la forêt voyage dans le temps. / Il ne se montre qu'à ceux qui respectent le bois. / Moi, je ne l'ai jamais vu. Mais je lui apporte des fleurs. |
| E-7 | Scout Tom · Dresseuse Céline | Tom — avant : Je connais ce bois par cœur ! · défaite : Je me suis perdu dans le combat. · après : La sortie est au sud. — Céline — avant : La nuit tombe vite, sous les arbres. · défaite : Tu as de bons yeux. · après : Le matin, de drôles de Pokémon sortent des troncs. |
| E-8 | Charbonnier, lisière du bois | Mon Canarticho m'aide à couper le bois. / Sans lui, pas de charbon pour Écorcia. |
| E-9 | Panneau, Écorcia | **ÉCORCIA** / La ville où l'on vit au rythme des Ramoloss |
| E-10 | Habitante, Écorcia | Tu vois des Ramoloss, toi ? / Avant, ils dormaient partout dans les rues. / Depuis que les hommes en noir sont là, plus un seul. |
| E-11 | Fargas, accueil | Hein ? Qui es-tu ? / … Le Maître de Kanto ? Ici ? / Alors écoute bien, petit. |
| E-12 | Fargas, le récit | Des hommes en noir se sont installés dans le Puits Ramoloss. / Ils coupent la queue des Ramoloss, pour la vendre. / Une queue de Ramoloss, ça vaut une fortune chez certains. / Les pauvres bêtes ne sentent rien… mais c'est une honte ! |
| E-13 | Fargas, départ | Ça suffit. J'y vais, moi ! / Suis-moi si tu as du cran. |
| E-14 | Sbire, entrée du puits | Hé, le vieux ! On ne passe pas ! / … / Il a l'air furieux. Je préviens les autres ! |
| E-15 | Fargas, au B1F (il tombe) | Aïe ! Mon dos… / Je suis tombé dans le noir, comme un débutant. / Vas-y sans moi, {joueur}. Sauve les Ramoloss ! |
| E-16 | Sbire E · F · G (B1F) | E — avant : Tu ne passeras pas, gamin ! · défaite : Si, tu passes… · après : Le chef est en bas. Il va te réduire en miettes. — F — avant : On fait du commerce, rien de plus ! · défaite : Le commerce est fermé. · après : Des queues de Ramoloss, ça pousse, tu sais. Enfin, je crois. — G — avant : Brace va te faire regretter d'être venu ! · défaite : Brace va me faire regretter d'être venu… · après : Va-t'en tant qu'il est encore temps. |
| E-17 | Brace, avant | Alors c'est toi, le gamin de Kanto. / On m'avait dit de me méfier de toi. / Moi, je ne me méfie de personne. Je fonce ! |
| E-18 | Brace, défaite | Quoi ? Battu par un gamin avec des Pokémon de rien du tout ? |
| E-19 | Brace, après | Tu crois avoir gagné ? On a déjà ce qu'on voulait. / Le vrai travail commence ailleurs. / Profite bien de ta petite victoire ! |
| E-20 | Système, Brace s'enfuit | Brace s'enfuit… / Il a laissé tomber des papiers ! |
| E-21 | Système, objets clés | {joueur} ramasse un Ordre de mission. / {joueur} ramasse une Carte d'accès. Il y est écrit : « Tour Radio de Doublonville ». |
| E-22 | Ordre de mission (lecture dans le Sac) | Opération Écorcia : récolte terminée avant la fin du mois. / Fonds pour la phase suivante. / Préparer l'antenne de Doublonville. / Personne ne doit savoir qui donne les ordres. — D. |
| E-23 | Fargas, au B2F après | Tu les as chassés ! / Regarde, les Ramoloss rentrent à la maison. / Leurs queues repousseront, ne t'en fais pas. |
| E-24 | Fargas, la Roche Royale | Tiens, je l'ai trouvée au fond du puits il y a bien longtemps. / Une Roche Royale. / On dit qu'un Ramoloss qui la porte, quand on l'échange, devient un roi. · *(système)* {joueur} reçoit une Roche Royale ! |
| E-25 | Fargas, après (chez lui) | Ces voleurs parlaient de Doublonville. De leur « antenne ». / La Tour Radio, sans doute. / Fais attention à toi, petit. |
| E-26 | Habitante, après | Les Ramoloss sont revenus ! / Tu les entends bâiller ? C'est le plus beau bruit du monde. |
| E-27 | Ramoloss, examen (ville, après) | Ramoloss bâille. / … Il a déjà oublié pourquoi. |
| E-28 | Vincent, charbonnier du vendredi | Le vendredi, je livre le charbon à toute la ville. / Tu sens la fumée ? Ça éloigne les petites bêtes. Prends ça. · *(système)* {joueur} reçoit 2 Super Repousses ! · après : À vendredi ! |
| E-29 | Garçon, Centre d'Écorcia | Il paraît que le Champion d'Écorcia est parti voyager. / Dommage, j'aurais voulu le défier. |
| E-30 | Homme, maison de la Route 34 | Ma femme gardait des Pokémon pour les Dresseurs, avant. / Elle a pris sa retraite. La maison est bien calme. |
| E-31 | Examen, entrée du puits (après) | Le Puits Ramoloss. / Un Ramoloss somnole sur la margelle. |
| E-32 | Description de zone, Route 34 | Une route le long de la côte, au sud de Doublonville. |
| E-33 | Description de zone, Bois aux Chênes | Une forêt ancienne, où le temps semble suspendu. |
| E-34 | Description de zone, Écorcia | Une petite ville paisible, au rythme des Ramoloss. |
| E-35 | Description de zone, Puits Ramoloss | Un vieux puits humide, sous la ville. |
| E-36 | Panneau, Puits Ramoloss | **PUITS RAMOLOSS** / Lieu de repos des Ramoloss. Ne pas déranger. |

## 15. Arbitrages pour Kevin

| N° | Question | Recommandation de Claude |
|---|---|---|
| JH-37 | Le gardien du puits : **Fargas** (personnage d'Or/Argent, sans sa fabrique de Noigrumes) ou un personnage neuf ? | **Fargas** |
| JH-38 | Ramoloss capturable au puits, et Roigada / Tarpaud possibles **dès l'acte 1** avec la Roche Royale au terminal d'échange | **Oui** : récompense du jalon, sans casser la courbe (Roigada niv. ≈ 20) |
| JH-39 | L'autel du Bois aux Chênes : visible et examinable dès maintenant, ou caché jusqu'au post-game ? | **Visible dès le JOH4**, avec un texte qui annonce le gardien (E-5, E-6) |
