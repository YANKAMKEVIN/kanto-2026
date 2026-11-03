# Dossier JOH-10 — Le sommet du monde : Mont Argenté, Dante, Giovanni, le rival, épilogue (jalon JOH9, v0.1)

> Jalon unique de l'acte 3 et fin du Chapitre Johto (cadre [`dossier-joh-00-cadre.md`](dossier-joh-00-cadre.md)
> §4.4, §4.5). Suite du JOH8 ([`dossier-joh-09-tour-carillon.md`](dossier-joh-09-tour-carillon.md) :
> Dante fuit vers « le sommet du monde », le doyen et Orme désignent le Mont Argenté, H-34 à H-36).
> Écrit par Claude le 2026-11-02 ; **textes A-1 à A-54 et arbitrages JH-56 à JH-60 validés par
> Kevin le jour même** (recommandations retenues) ; le reste est à valider. Valeurs **[D]** = défauts. Grilles et vues peintes après validation.

## 1. Hors périmètre

- Les combats en duo (chantier à part, cadre §1) ; Red au sommet (n'existe pas : le joueur est le
  héros de Kanto).
- Les revanches de Dante, des admins ou du rival après le chapitre **[D]**.
- Le reste du post-game de Johto, sauf **Celebi** (§11) et le retour des légendaires non capturés
  (cadre §4.5).

## 2. Hypothèses d'entrée

- JOH8 fait : `johto_act3`, `johto_dante_fled_1` ; équipe 68–75 attendue (cadre §7).
- Le joueur a Surf, Force et Flash (Kanto) ; le voile d'obscurité du J17 existe.
- Le rival est de retour de la Ligue (Champion battu par le joueur) ; son apparence et son prénom
  `{rival}` viennent de l'ouverture (dossier 13, `dossier-joueuse-rivale.md` : garçon ou fille).
  **Les textes sont neutres** sur son genre.

## 3. Géographie **[D]**

| Carte | Taille indicative | Contenu |
|---|---|---|
| **Lac Colère** (retouche) | déjà fait (JOH6) | Au nord-est, un **sentier** gardé par un garde forestier depuis le JOH6 (« La montagne est fermée », A-1) ; ouvert avec `johto_act3` |
| **Sentier du Mont Argenté** | ≈ 24 × 44 | Montée boisée, la neige commence ; 3 Dresseurs ; en haut, le **Centre Pokémon du Mont Argenté** (Centre complet, Boutique) |
| **Mont Argenté, extérieur** | ≈ 40 × 40 | Pente enneigée, rochers, herbes hautes sous la neige ; l'entrée de la grotte ; **le relais** (§7) |
| **Grotte 1F** | ≈ 32 × 28 | Rochers à pousser (**Force**) ; lac intérieur en **Surf** |
| **Grotte 2F** | ≈ 32 × 28 | **Obscurité** (voile du J17, Flash automatique) ; le rival rejoint le joueur (§7) |
| **Grotte 3F** | ≈ 28 × 24 | Corniches et vent ; l'escalier vers le sommet |
| **Sommet** | ≈ 20 × 18 | Plateau de neige au-dessus des nuages ; ruines d'un ancien camp (le premier QG de Dante, §8) |
| **Route 28** | ≈ 44 × 20 | Versant ouest ; de la sortie ouest de la grotte 1F jusqu'au **poste de la Route 28** ; une maison (le gardien) |
| **Route 22** (Kanto, retouche) | existe | À l'ouest, une **porte neuve** vers le poste de la Route 28 (seule retouche de Kanto, JH-8) |

Points de Vol : **Centre du Mont Argenté**.

**Grilles validées par Kevin le 2026-11-03** (validation d'avance) : `tools/plans/silver_trail.txt`,
`mt_silver_outside.txt`, `mt_silver_1f.txt`, `mt_silver_2f.txt`, `mt_silver_3f.txt`,
`mt_silver_summit.txt`, `route_28.txt`, `route_28_gate.txt` (la grille fait foi pour la géométrie ;
défauts [D] dans leurs en-têtes) ; retouches de `lake_of_rage.txt` (raccord du sentier) et de
`route_22_ouest.txt` (poste de la Route 28 et porte neuve, JH-8) ; contrôle
`tools/art/plan_check_joh9.py` ; aperçu `reference/joh9-grilles-apercu-v1.png`.

## 4. Ordre de jeu

| Étape | Lieu | Ce qui se passe | Drapeau |
|---|---|---|---|
| 1 | Lac Colère | Le garde forestier laisse passer (A-2) | — |
| 2 | Sentier | 3 Dresseurs ; Centre du Mont Argenté | — |
| 3 | Extérieur | **Brace, Cenere** et 4 Sbires barrent l'entrée (A-8, A-9) ; **le rival arrive** et les retient (A-10 à A-13) : le joueur entre seul | `johto_rival_relay` |
| 4 | Grotte 1F | Force, Surf ; 2 Sbires passés entre les mailles | — |
| 5 | Grotte 2F | Obscurité ; le **rival** rejoint le joueur, essoufflé, et soigne son équipe (A-19 à A-21) | `johto_rival_healed` |
| 6 | Grotte 3F | Montée ; un Montagnard | — |
| 7 | Sommet | **Dante** (A-26 à A-30) : **combat final contre Dante** (obligatoire, grand combat) | `johto_dante_defeated_2` |
| 8 | Sommet | **Giovanni** apparaît, sans combat (A-31 à A-37) ; Cenere arrive et reste auprès de Dante (JH-56, JH-58) | `johto_giovanni_seen` |
| 9 | Sommet | Le **rival** arrive : **dernier combat de rivaux** (obligatoire, JH-19) | `johto_rival_final_done` |
| 10 | Route 28 → Route 22 | Descente libre par le versant ouest ; la porte de la Route 22 s'ouvre de l'intérieur | `johto_route28_open` |
| 11 | Bourg Palette, labo | **Épilogue** : Chen et Orme (JH-60) ; Orme donne la **Balle Verte** ; petit générique | `johto_chapter_done` |
| — | Bois aux Chênes | **Celebi** (post-game, §11) | `johto_celebi_done` |

## 5. Rencontres **[D]**

| Carte | Moment | Espèces (poids) | Niveaux |
|---|---|---|---|
| Sentier | matin, jour | Teddiursa 25, Phanpy 20, Airmure 15, Grolem 20, Machopeur 20 | 52–56 |
| Sentier | nuit | Démolosse 25, Farfuret 20, Noarfang 25, Grolem 15, Machopeur 15 | 52–56 |
| Extérieur | toute la journée | Ursaring 25, Donphan 25, Airmure 20, Farfuret 15 (nuit 30), Démolosse 15 (nuit seulement) | 56–60 |
| Grotte 1F | toute la journée | Ursaring 25, Donphan 20, Onix 20, Nosferalto 25, Machopeur 10 | 58–62 |
| Grotte 1F (Surf) | toute la journée | Tentacruel 30, Léviator 20, Lamantine 30, Otaria 20 | 58–62 |
| Grotte 2F | toute la journée | Nosferalto 30, Ursaring 25, Donphan 20, Onix 20, **Embrylex 5** | 60–64 |
| Grotte 3F | toute la journée | Ursaring 30, Donphan 25, Nosferalto 25, Mackogneur 15, **Ymphect 5** | 62–65 |
| Route 28 | jour | Phanpy 30, Donphan 20, Airmure 20, Ponyta 15, Galopa 15 | 55–60 |

## 6. Dresseurs **[D]**

| Où | Dresseur | Équipe | Évitable |
|---|---|---|---|
| Sentier | Montagnard Baptiste | Grolem 64, Donphan 64 | oui |
| Sentier | Topdresseuse Inès | Airmure 64, Pharamp 64, Mentali 65 | oui |
| Sentier | Karatéka Hugo | Mackogneur 65, Ursaring 65 | **non** (passage) |
| Grotte 1F | Sbire (X) | Démolosse 66, Grotadmorv 66 | oui |
| Grotte 1F | Sbire (Y) | Farfuret 66, Smogogo 66, Arbok 66 | **non** |
| Grotte 3F | Montagnard Lucas | Steelix 67, Ursaring 67 | oui |
| Route 28 | Topdresseur Jules | Tyranocif 68, Airmure 66, Arcanin 66 | oui |
| Sommet | **Dante** (2) | Démolosse 72, Farfuret 73, Magmar 74, Cizayox 74, Arcanin 76, **Tyranocif 78** | **non** |
| Sommet | **{rival}** (final) | §9 | **non** |

- **Dante (2)** : équipe complète, grand combat, victoire du premier coup **35–60 %** (mémoire
  « Difficulté des combats ») ; Tyranocif en dernier.
- **Défaite contre Dante** : retour au Centre du Mont Argenté ; Dante attend au sommet (A-25).
- **Défaite contre le rival** : retour au Centre du Mont Argenté ; le rival attend au sommet (A-45) ;
  Dante, Giovanni et Cenere ne rejouent pas leur scène.
- Les Sbires X et Y ne sont plus là si le joueur revient après le chapitre.

## 7. Le relais du rival (JH-9)

- **Arrivée** : Orme a prévenu Chen (H-36), Chen a prévenu le rival. Il arrive de Kanto par la Route
  28 et l'extérieur, au moment où les admins barrent l'entrée **[D]**.
- **Entrée** : Brace, Cenere et 4 Sbires. Le rival envoie son Pokémon de départ, le joueur entre ; on
  ne voit pas le combat (bruits, lueurs à la sortie de la grotte) **[D]**.
- **Grotte 2F** : le rival rattrape le joueur dans le noir, soigne son équipe (Hyper Potions, comme
  un sage), dit ce qu'il a fait des admins (A-20, JH-56), et repart vers la sortie « surveiller le
  bas » **[D]**.
- **Sort des admins (JH-56)** : **Brace** est retenu et livré à l'**Agente** (celle de la Tour Radio,
  T-33), qui arrive avec le rival au sommet plus tard (A-44) ; **Cenere** s'échappe et rejoint Dante
  au sommet après sa défaite, fidèle jusqu'au bout (JH-51).

## 8. Dante, Giovanni (JH-7, JH-57, JH-58)

- **Lieu** : les ruines au sommet sont celles du **premier camp de la Team Rocket**, fondée par Dante
  « ici, au-dessus des nuages » (A-26) **[D]**. Elles font écho à « finir là où tout a commencé » (H-25).
- **Giovanni** : à Jadielle, il a dit « La Team Rocket, c'est terminé. Je pars m'entraîner seul »
  (`viridian_gym_giovanni_departure`). Il s'entraîne **sur le Mont Argenté** depuis : c'est pour ça
  qu'il est là **[D]**.
- **Ce qu'il dit (JH-57)** : la Team Rocket est **finie**, celle d'hier comme celle de Dante ; il
  n'emmène personne, ne reprend rien, ne demande pas pardon. Il reconnaît pourtant ce qu'il doit à
  Dante (A-34) et s'adresse au joueur avant de partir (A-36).
- **Sort de Dante (JH-58)** : il reste au sommet, à genoux dans la neige, **Cenere** à ses côtés. Il
  ne dit plus rien au joueur. Quand le joueur revient au sommet après le chapitre, il n'y a plus
  personne : une écharpe brûlée sur une pierre (A-52) **[D]**.

## 9. Le rival, dernier combat (JH-19, JH-59)

- **Obligatoire**, niveaux 75–80, grand combat (35–60 %).
- **Équipe** : son équipe de Ligue (`rival_champion`, données de la Ligue) **+ 14 niveaux**, avec **un
  Pokémon de Johto** à la place de Rhinoféros (JH-59) : **Steelix** **[D]** :

| Rang | Pokémon | Niveau |
|---|---|---|
| 1 | Roucarnage | 75 |
| 2 | Alakazam | 76 |
| 3 | **Steelix** (à la place de Rhinoféros) | 76 |
| 4–5 | Les deux Pokémon de Ligue qui dépendent du starter (`team_by_starter`) | 77 |
| 6 | Son Pokémon de départ | 80 |

- Tenue d'hiver (cadre §8). Le rival ne dit pas d'où vient son Steelix ; un Pokémon de Johto montre
  seulement qu'il a progressé lui aussi (A-41) : son Onix a évolué grâce à une Peau Métal trouvée à Johto **[D]**.

## 10. Épilogue (JH-60)

- Après le rival, le joueur **descend librement** par la grotte 1F (sortie ouest) et la Route 28 ;
  la porte de la Route 22 s'ouvre (A-47). Les deux régions sont reliées à pied (cadre §3.2).
- **Déclenchement** : en entrant au **labo de Chen** à Bourg Palette, avec `johto_giovanni_seen` et
  `johto_rival_final_done` (JH-60). Chen et Orme (venu en visite) ; Orme donne la **Balle Verte**
  (JH-16) ; le rival passe la tête à la porte (A-51).
- **Petit générique** de chapitre **[D]** : 60 à 90 s, images des lieux de Johto et des légendaires
  capturés (ou vus), musique de HeartGold / SoulSilver ; puis le jeu reprend au labo, sauvegarde
  proposée.

## 11. Celebi (post-game, JH-16)

- Avec la **Balle Verte**, le joueur l'examine à l'autel du Bois aux Chênes (JOH4) : elle se pose,
  la forêt se tait, **Celebi** apparaît (A-53, A-54).
- Celebi niv. **60** **[D]**, sauvage, capturable ; K.O. ou fuite → il revient à l'autel au prochain
  passage (la Balle Verte reste sur l'autel) **[D]**. Seul Pokémon hors du Diplôme de Johto (JH-28).

## 12. Drapeaux **[D]**

`johto_rival_relay`, `johto_rival_healed`, `johto_dante_defeated_2`, `johto_giovanni_seen`,
`johto_rival_final_done`, `johto_route28_open`, `johto_chapter_done`, `johto_celebi_done`.

## 13. Cas limites (à tester)

- Défaite contre Dante ou contre le rival : retour au Centre du Mont Argenté, reprise au bon moment
  (aucune scène rejouée en double).
- Le joueur quitte l'application entre Giovanni et le rival : à la reprise, il est au sommet, le
  rival devant lui.
- Vol ou Corde Sortie pendant la montée : possible avant le sommet ; interdits au sommet entre
  Dante et le rival **[D]**.
- Le joueur revient au Mont Argenté après le chapitre : plus de Sbires ni d'admins ; sommet vide
  (A-52) ; les rencontres restent.
- Porte de la Route 22 : fermée de l'est tant que `johto_route28_open` n'est pas posé (A-48).
- Épilogue : ne se déclenche qu'une fois ; le Pokédex et le Diplôme de Johto restent accessibles.
- Celebi : Balle Verte posée, Celebi K.O., retour ; capture avec équipe pleine (Stockage).

## 14. Validation (sous-jalon JOH9)

- Tests : ordre relais → 2F → Dante → Giovanni → rival → Route 28 → labo ; équipe du rival par
  starter ; défaites et reprises ; porte de la Route 22 ; Celebi.
- Captures : relais devant la grotte, sommet (Dante, Giovanni, Cenere), rival en tenue d'hiver,
  Route 28 et sa porte, labo de l'épilogue, autel et Celebi.

## 15. Art

Sentier, Centre du Mont Argenté (intérieur : modèle des Centres), extérieur enneigé, grotte (1F, 2F,
3F), sommet (ruines du premier camp, mer de nuages), Route 28, poste de la Route 28, porte neuve de
la Route 22. Personnages : **Dante âgé** (JOH8), **Giovanni** (modèle de Kanto, tenue de montagne
**[D]**), Brace, Cenere, l'Agente (existent), **le rival en tenue d'hiver** (garçon et fille),
Montagnards, Topdresseurs, Karatéka (modèles de Kanto). Pokémon : Celebi (dos, face), Embrylex,
Ymphect, Tyranocif, Steelix. Générique de chapitre. Musique : Mont Argenté, Dante (combat final),
rival (HeartGold / SoulSilver, JH-12).

## 16. Textes (lot validé par Kevin le 2026-11-02)

Format : bulles séparées par « / ». `{joueur}`, `{rival}`, `{pokemon}` = noms ; *italique* = système.

| N° | Où | Texte |
|---|---|---|
| A-1 | Garde forestier, Lac Colère (avant l'acte 3) | La montagne est fermée. / Là-haut, la neige ne pardonne pas. |
| A-2 | Garde forestier (acte 3) | Le Mont Argenté ? Des hommes en noir y sont montés cette nuit. / Je n'ai pas pu les arrêter. Toi, peut-être. Passe. |
| A-3 | Panneau, sentier | **MONT ARGENTÉ** / Réservé aux Dresseurs confirmés. |
| A-4 | Montagnard Baptiste | avant : Personne ne monte ici sans se mesurer à moi ! · défaite : Tu as le pied montagnard. · après : Au-dessus du Centre, la neige commence. |
| A-5 | Topdresseuse Inès | avant : Le Maître de Kanto ? J'attendais ce combat. · défaite : On m'avait prévenue… · après : Il paraît qu'un homme s'entraîne seul, tout en haut, depuis des mois. |
| A-6 | Karatéka Hugo | avant : Mes poings ont brisé la glace du sentier ! · défaite : Et toi, tu m'as brisé. · après : Des hommes en noir m'ont bousculé, cette nuit. Ils allaient vers la grotte. |
| A-7 | Descriptions de zone | Sentier : Un sentier de montagne, au-dessus du Lac Colère. · Mont Argenté : La plus haute montagne entre Johto et Kanto. · Sommet : Le sommet du monde, au-dessus des nuages. · Route 28 : Un col de montagne, vers Kanto. |
| A-8 | **Brace**, à l'entrée | Le revoilà, le gamin ! / Cette fois, tu ne passes pas. Le patron finit son œuvre là-haut. |
| A-9 | **Cenere**, à l'entrée | Six contre un. J'ai refait le calcul trois fois. / Tu ne passeras pas. |
| A-10 | **{rival}**, arrivée | Six contre un ? Refais ton calcul. · *(système)* {rival} arrive en courant ! |
| A-11 | {rival}, au joueur | Chen m'a tout raconté. La radio, le vol, la tour. / Ne me regarde pas comme ça. Je ne fais pas ça pour toi. / Je fais ça parce que personne ne vole l'équipe du Maître de Kanto. Personne, à part moi, un jour. |
| A-12 | {rival}, aux admins | Allez, {pokemon} ! On s'occupe d'eux. / {joueur}, monte. Va finir ça. |
| A-13 | Système, l'entrée | {joueur} entre dans la grotte. / Derrière, on entend les cris des Pokémon… |
| A-14 | Sbire X · Sbire Y (1F) | X — avant : Quelqu'un est passé ? Impossible ! · défaite : Bon, si, c'est possible. · après : Ton copain, en bas, il est fou. — Y — avant : Je me suis glissé derrière toi. Le patron saura que je suis fidèle ! · défaite : Le patron ne saura rien… · après : Va. Il t'attend, de toute façon. |
| A-15 | Examen, rocher (1F) | Un gros rocher. On pourrait le pousser. |
| A-16 | Système, obscurité (2F) | Il fait noir comme dans un four. |
| A-17 | Système, Flash (2F) | {pokemon} éclaire la grotte avec Flash ! |
| A-18 | Montagnard Lucas (3F) | avant : Un rival de montagne ! Enfin ! · défaite : Je redescends m'entraîner. · après : Au sommet, il y a déjà deux hommes. Je n'ose pas monter. |
| A-19 | Système, le rival (2F) | Quelqu'un court dans le noir… / {rival} rattrape {joueur} ! |
| A-20 | {rival}, 2F | Pff… Pff… Tu marches vite. / L'impétueux, je l'ai coincé. L'Agente arrive pour lui. / La froide a filé. Elle monte, elle aussi. Fais attention. |
| A-21 | {rival}, les soins | Tes Pokémon sont dans un état… Tiens. / Je ne veux pas que tu perdes avant notre combat. · *(système)* L'équipe de {joueur} est soignée. · {rival} : Je redescends surveiller l'entrée. Ne t'avise pas de tomber. |
| A-22 | Système, 3F, vent | Un vent glacé souffle dans la grotte. / La lumière vient d'en haut. |
| A-23 | Système, arrivée au sommet | Le ciel est immense. / Les nuages s'étendent sous les pieds de {joueur}. / Un homme attend au milieu des ruines. |
| A-24 | Examen, ruines | De vieilles pierres noircies, à moitié enterrées sous la neige. / Un « R » est gravé sur l'une d'elles. |
| A-25 | Dante, après une défaite du joueur (retour) | Encore toi. / Ici, on ne redescend qu'une fois. |
| A-26 | **Dante**, l'accueil | Ici, il y a quarante ans, j'ai planté la première tente de la Team Rocket. / Trois hommes, une idée, et la neige. / C'est ici que tout a commencé. C'est ici que tout finira. |
| A-27 | Dante, le refus de Ho-Oh | Ho-Oh m'a regardé, et il t'a choisi. / J'ai compris ce matin-là. Je n'ai plus de flamme à prendre. / Il ne me reste que la mienne. |
| A-28 | Dante, avant le combat | Tu as tout ce que j'ai perdu, {joueur}. Des Pokémon qui te suivent. Un nom. Un avenir. / Alors montre-moi. / Montre-moi ce que vaut un cœur que personne n'a trahi. |
| A-29 | Dante, défaite | … / Je vois. / Il n'y avait pas de feu assez grand pour toi. |
| A-30 | Dante, après | Vingt ans à attendre ce jour. Vingt ans à brûler de l'intérieur. / Et c'est un enfant qui éteint tout. / … C'est peut-être mieux ainsi. |
| A-31 | Système, Giovanni | Des pas crissent dans la neige. / Un homme apparaît derrière les ruines. |
| A-32 | **Giovanni** | Dante. / Je savais que tu reviendrais ici. Tout le monde finit par revenir ici. |
| A-33 | Dante, à Giovanni | … Giovanni. / Tu viens voir ton œuvre ? Regarde-moi bien. Tu as fait ça. |
| A-34 | Giovanni | Oui. / Tu m'as appris que rien ne doit se mettre en travers. Pas même un maître. / J'ai bien appris. Je l'ai payé, moi aussi. |
| A-35 | Giovanni (JH-57) | La Team Rocket est morte, Dante. Celle d'hier, et celle que tu as voulu ranimer. / Un enfant l'a battue deux fois. Il n'y en aura pas de troisième. / Je ne suis pas venu la reprendre. Ni te demander pardon. |
| A-36 | Giovanni, au joueur | Toi. / À Jadielle, je t'ai dit que nos chemins se croiseraient peut-être. / Je m'entraîne ici depuis. Seul. Un jour, je serai de nouveau digne d'un combat contre toi. Pas aujourd'hui. |
| A-37 | Système, Giovanni part | Giovanni s'éloigne dans la neige, sans se retourner. |
| A-38 | **Cenere**, au sommet (JH-56, JH-58) | *(système)* Cenere arrive en courant. / Cenere : Maître… / … Je reste. Les calculs, c'est fini. Je reste. |
| A-39 | Système, Dante et Cenere | Dante ne répond pas. Il regarde les nuages. / Cenere s'agenouille à côté de lui. |
| A-40 | **{rival}**, arrivée au sommet | Ouf. J'ai cru que je n'arriverais jamais. / Alors ? C'est fini ? / … Bien. |
| A-41 | {rival}, avant | Tu sais pourquoi je suis monté jusqu'ici ? / Pas pour lui. Pour toi. / Depuis la Ligue, je m'entraîne. Et j'ai trouvé de quoi faire évoluer mon Onix, à Johto. / Toi et moi, ce n'est pas fini. |
| A-42 | {rival}, défaite | … Encore. / Bon. Je crois que je commence à m'y faire. |
| A-43 | {rival}, après | Tu sais, à la Ligue, je t'en ai voulu. / Mais là, en bas, quand je retenais ces deux-là… / J'étais content que ce soit toi, là-haut. Ne le répète à personne. |
| A-44 | {rival}, Agente | L'Agente a embarqué l'impétueux, en bas. / Pour ces deux-là… Laissons-les. Ils n'iront plus nulle part. |
| A-45 | {rival}, après une défaite du joueur (retour) | Te revoilà. / On reprend. Et cette fois, pas d'excuse. |
| A-46 | {rival}, départ | On rentre ? Par l'ouest, la Route 28 mène tout droit chez nous. / Dernier arrivé à Bourg Palette paie le dîner ! · *(système)* {rival} s'en va en courant. |
| A-47 | Système, porte de la Route 22 | La porte s'ouvre. / Devant {joueur}, la Route 22. Kanto ! |
| A-48 | Garde, poste de la Route 28 (côté Kanto, avant) | Le col vers le Mont Argenté est fermé. / Trop dangereux. |
| A-49 | **Chen**, épilogue | {joueur} ! Te voilà rentré ! / Orme m'a tout raconté. Johto te doit beaucoup. / Moi, je savais que tu reviendrais. Tu reviens toujours. |
| A-50 | **Orme**, épilogue | Le Maître de Kanto a sauvé Johto. Je l'écrirai dans mon prochain livre ! / J'ai quelque chose pour toi. Je l'ai trouvé chez un antiquaire d'Écorcia. / Une Balle Verte. Très ancienne. Les gens de là-bas disent qu'elle appartient au Bois aux Chênes. · *(système)* {joueur} reçoit la Balle Verte ! · Orme : Pose-la sur l'autel du bois. Qui sait ce qui viendra ? |
| A-51 | {rival}, à la porte du labo (petit-enfant de Chen, JR-3) | Grand-père, il reste à manger ? / … Ah, {joueur} est arrivé avant moi. Je paie le dîner, alors. |
| A-52 | Examen, sommet (après le chapitre) | Il n'y a plus personne. / Sur une pierre, une écharpe à moitié brûlée. |
| A-53 | Système, autel (Balle Verte) | {joueur} pose la Balle Verte sur l'autel. / … / La forêt se tait. Les feuilles tremblent. |
| A-54 | Système, Celebi | Un petit Pokémon vert apparaît au-dessus de l'autel ! / Celebi veut jouer avec {joueur} ! |

## 17. Arbitrages pour Kevin

| N° | Question | Recommandation de Claude |
|---|---|---|
| JH-56 | ✅ **Brace livré à l'Agente** par le rival ; **Cenere s'échappe** et rejoint Dante au sommet, fidèle (Kevin, 2026-11-02) | — |
| JH-57 | ✅ Giovanni **s'entraîne au Mont Argenté** depuis Jadielle ; la Team Rocket est **finie**, il ne reprend rien et part seul (Kevin) | — |
| JH-58 | ✅ Dante **reste au sommet**, brisé, avec Cenere ; après le chapitre, le sommet est vide (Kevin) | — |
| JH-59 | ✅ Le rival ajoute **Steelix** à la place de Rhinoféros (Kevin) | — |
| JH-60 | ✅ Épilogue **en entrant au labo de Chen**, après une descente libre par la Route 28 (Kevin) | — |
