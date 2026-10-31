# Chantier JR : relevé des accords joueur / rival (féminin)

Relevé exhaustif, pour validation par Kevin en un seul lot, des textes de `data/` qui doivent recevoir un accord.
Rédigé le 2026-10-31, lecture seule (aucun fichier de `data/` ni de `game/` modifié).

Conventions :

- `{g:masculin|féminin}` s'accorde avec le **joueur** ; `{gr:masculin|féminin}` avec le **rival**.
- Le masculin proposé est identique au texte actuel. Les propositions utilisent des **mots entiers** dans les accolades (`{g:prêt|prête}`), pas des suffixes vides, pour ne pas dépendre de la gestion d'une alternative vide.
- Numéro de ligne = ligne du fichier JSON où commence la chaîne (la première, quand une page en regroupe plusieurs sur la même ligne). `[clé]` = identifiant du dialogue.
- Les noms affichés `"speaker": "{rival}"` ne sont pas relevés.
- Participe passé avec COD placé avant l'auxiliaire (« t'a vu passer », « t'a emporté », « t'avais prévenu ») : il s'accorde, donc il figure dans le relevé.

## 0. Introduction de Chen (déjà intégrée sur la branche `claude/jr-integration`, à valider)

Ces textes sont dans `data/opening/oak_intro.json`. Les formes féminines n'apparaissent que si la rivale est choisie.

| # | Texte | Nature |
|---|---|---|
| I1 | « Mais parlons un peu de toi. » | réplique existante, conservée telle quelle comme question du **choix de l'apparence du joueur** (deux cartes, sans mot « garçon » ni « fille », bouton VALIDER) |
| I2 | « Et puis, il y a quelqu'un d'autre… » | **nouveau texte**, question du choix de l'apparence du rival (dite avant toute réplique accordée) |
| I3 | « Et {gr:lui\|elle}, tu {gr:le\|la} connais depuis toujours. C'est {gr:mon petit-fils\|ma petite-fille}. » | accord de la réplique existante (JR-3 : petite-fille de Chen) |
| I4 | « {gr:Il\|Elle} s'appelle… euh… » | accord |
| I5 | « Comment s'appelle-t-{gr:il\|elle}, déjà ? » | accord |

Prénoms proposés selon l'apparence (JR-4, déjà validés) : joueuse Leaf · Céleste · Kelly, rivale Régine · Green · Iris ; prénom par défaut, si aucune saisie, = le premier proposé [D].

## 1. Joueur (`g`)

### 1.1 Participes passés et adjectifs accordés au sujet ou au COD « tu / te »

| # | Fichier : ligne [clé] | Texte actuel | Proposition |
|---|---|---|---|
| J1 | `dialogues/player_house.json:10` [mom] | Bonjour ! Tu es enfin réveillé ? | Bonjour ! Tu es enfin {g:réveillé\|réveillée} ? |
| J2 | `dialogues/rival_house.json:9` [rival] | Ah. Enfin réveillé. | Ah. Enfin {g:réveillé\|réveillée}. |
| J3 | `dialogues/pallet_town.json:44` [oak_route1_warning] | Tu allais vraiment entrer là-dedans tout seul ? | Tu allais vraiment entrer là-dedans tout {g:seul\|seule} ? |
| J4 | `dialogues/oak_lab.json:176` [rival_parcel_greet] | Tiens. T'es déjà revenu, toi aussi ? | Tiens. T'es déjà {g:revenu\|revenue}, toi aussi ? |
| J5 | `dialogues/oak_lab.json:127` [oak_lab_waiting] | C'était mon dernier Pokémon.\nIl t'a attendu. Prends-en soin. | C'était mon dernier Pokémon.\nIl t'a {g:attendu\|attendue}. Prends-en soin. |
| J6 | `dialogues/oak_lab.json:91` [rival_lab_lost] | Mais je t'avais prévenu : j'étais prêt. (voir aussi R1 pour « prêt » du rival) | Mais je t'avais {g:prévenu\|prévenue} : j'étais {gr:prêt\|prête}. |
| J7 | `dialogues/route_22.json:25` [route22_rival_greet] | Toi aussi, tu es venu voir jusqu'où cette route mène ? | Toi aussi, tu es {g:venu\|venue} voir jusqu'où cette route mène ? |
| J8 | `dialogues/route_22.json:42` [route22_rival_lost] | Tu t'es amélioré. | Tu t'es {g:amélioré\|améliorée}. |
| J9 | `dialogues/j21_tower.json:65` | Oh… Tu es venu me chercher ?\nMerci, mon enfant. | Oh… Tu es {g:venu\|venue} me chercher ?\nMerci, mon enfant. |
| J10 | `dialogues/mt_moon.json:89` | Tu es revenu ?\nTu ne les auras pas ! | Tu es {g:revenu\|revenue} ?\nTu ne les auras pas ! |
| J11 | `dialogues/vermilion_city.json:69` | Tu es venu écouter l'histoire\nde mon Ponyta ? | Tu es {g:venu\|venue} écouter l'histoire\nde mon Ponyta ? |
| J12 | `dialogues/pokemon_tower_floors.json:240` [rival_tower_intro] | {player}. …Tu es venu pour quoi ? | {player}. …Tu es {g:venu\|venue} pour quoi ? |
| J13 | `dialogues/pewter_gym.json:20` | D'accord… Tu es prêt. | D'accord… Tu es {g:prêt\|prête}. |
| J14 | `dialogues/pewter_gym.json:55` | Prêt à essayer autrement ? | {g:Prêt\|Prête} à essayer autrement ? |
| J15 | `dialogues/celadon_gym.json:139` | Reviens quand tu seras prêt. | Reviens quand tu seras {g:prêt\|prête}. |
| J16 | `dialogues/cerulean_city.json:215` | L'eau t'a emporté, cette fois. / Reviens quand tu seras prêt. (deux pages sur la même ligne) | L'eau t'a {g:emporté\|emportée}, cette fois. / Reviens quand tu seras {g:prêt\|prête}. |
| J17 | `dialogues/cerulean_city.json:217` | Prêt à replonger ? | {g:Prêt\|Prête} à replonger ? |
| J18 | `dialogues/cerulean_city.json:201` | Le pont t'a déjà vu passer ? | Le pont t'a déjà {g:vu\|vue} passer ? |
| J19 | `dialogues/celadon_gym.json:92` | Erika t'attend. Elle ne t'a\nsans doute pas entendu arriver. | Erika t'attend. Elle ne t'a\nsans doute pas {g:entendu\|entendue} arriver. |
| J20 | `dialogues/celadon_gym.json:11` | Au moins, tu as été silencieux. | Au moins, tu as été {g:silencieux\|silencieuse}. |
| J21 | `dialogues/j23_fuchsia_gym.json:182` | Reviens quand tu seras prêt. | Reviens quand tu seras {g:prêt\|prête}. |
| J22 | `dialogues/j29.json:21` [rival_route22_final_lost] | Tu n'es pas prêt pour la Ligue. | Tu n'es pas {g:prêt\|prête} pour la Ligue. |
| J23 | `dialogues/league.json:5` [league_guard_door] | Au-delà de cette porte, pas de retour avant la fin. Tu es prêt ? | Au-delà de cette porte, pas de retour avant la fin. Tu es {g:prêt\|prête} ? |
| J24 | `dialogues/silph_co_story.json:20` [rival_silph_lost] | Reviens quand tu seras prêt. | Reviens quand tu seras {g:prêt\|prête}. |
| J25 | `dialogues/saffron_gym.json:126` | Tu t'es perdu ?\nLes esprits, eux, savent où tu es. | Tu t'es {g:perdu\|perdue} ?\nLes esprits, eux, savent où tu es. |
| J26 | `dialogues/rocket_hideout.json:40` | Tu t'es perdu ? | Tu t'es {g:perdu\|perdue} ? |
| J27 | `dialogues/rocket_hideout.json:24` | Je ne t'ai pas vu. | Je ne t'ai pas {g:vu\|vue}. |
| J28 | `dialogues/silph_co.json:304` [silph_co_9f_3_before] | Mon Hypno t'a vu\ngrimper les étages. | Mon Hypno t'a {g:vu\|vue}\ngrimper les étages. |
| J29 | `dialogues/silph_co.json:172` [silph_co_6f_2_before] | Tu es tombé au mauvais\nétage, petit visiteur. | Tu es {g:tombé\|tombée} au mauvais\nétage, {g:petit visiteur\|petite visiteuse}. |
| J30 | `dialogues/silph_co_life.json:226` [silph_co_9f_nurse] | Tu as l'air fatigué !\nRepose-toi un instant. | Tu as l'air {g:fatigué\|fatiguée} !\nRepose-toi un instant. |
| J31 | `dialogues/route_12.json:65` | Tu as l'air pressé. Tiens, ça devrait te plaire. | Tu as l'air {g:pressé\|pressée}. Tiens, ça devrait te plaire. |
| J32 | `dialogues/route_9.json:11` | Bon. Tu es échauffé. | Bon. Tu es {g:échauffé\|échauffée}. |
| J33 | `dialogues/route_6_trainers.json:20` | D'accord, d'accord. Tu es fort. | D'accord, d'accord. Tu es {g:fort\|forte}. |
| J34 | `dialogues/victory_road.json:137` | Incroyable… Tu es vraiment fort. | Incroyable… Tu es vraiment {g:fort\|forte}. |
| J35 | `dialogues/fighting_dojo.json:151` | Hu ! Reviens quand tu seras\nplus fort ! | Hu ! Reviens quand tu seras\nplus {g:fort\|forte} ! |
| J36 | `dialogues/j22_route_13.json:101` | Ouais, bon… T'es pas mauvais. | Ouais, bon… T'es pas {g:mauvais\|mauvaise}. |
| J37 | `dialogues/ss_anne_life.json:17` [ss_anne_armand_after] | Reviens après t'être entraîné. | Reviens après t'être {g:entraîné\|entraînée}. |
| J38 | `dialogues/j32_ct.json:8` | Toi, tu as l'air de ceux qui encaissent les coups.\nTiens, prends ça ! | Toi, tu as l'air de {g:ceux\|celles} qui encaissent les coups.\nTiens, prends ça ! |

### 1.2 Termes d'adresse (« petit », « gamin », « Champion », « Dresseur » adressé…)

| # | Fichier : ligne [clé] | Texte actuel | Proposition |
|---|---|---|---|
| J39 | `dialogues/ss_anne_life.json:11` [ss_anne_armand_defeated] | Tu as du talent, jeune ami. | Tu as du talent, {g:jeune ami\|jeune amie}. |
| J40 | `dialogues/j32_ct.json:29` | Je sentais ta venue, jeune Dresseur. | Je sentais ta venue, {g:jeune Dresseur\|jeune Dresseuse}. |
| J41 | `dialogues/j32_ct.json:7` | J'avais un cadeau pour un Dresseur doué. | J'avais un cadeau pour {g:un Dresseur doué\|une Dresseuse douée}. (la phrase suivante est « Toi, tu… », donc adressée au joueur) |
| J42 | `dialogues/league.json:52` [league_agatha_defeated] | Hé hé… Tu iras loin, petit. Va voir Peter. | Hé hé… Tu iras loin, {g:petit\|petite}. Va voir Peter. |
| J43 | `dialogues/league.json:90` [league_oak_congrats] | {player} ! Félicitations. Tu es le nouveau Champion de la Ligue Pokémon. | {player} ! Félicitations. Tu es {g:le nouveau Champion\|la nouvelle Championne} de la Ligue Pokémon. |
| J44 | `data/trainer/moments.json:36` [moments.champion.title] | Champion de la Ligue Pokémon | {g:Champion\|Championne} de la Ligue Pokémon |
| J45 | `dialogues/vermilion_gym.json:87` | Hé, petit ! Tu as réussi à ouvrir ma barrière ? | Hé, {g:petit\|petite} ! Tu as réussi à ouvrir ma barrière ? |
| J46 | `dialogues/vermilion_gym.json:94` | Trop lent, petit ! | Trop {g:lent\|lente}, {g:petit\|petite} ! |
| J47 | `dialogues/vermilion_gym.json:101` | Ouch ! Tu m'as bien secoué. / Du cran, petit. Tu as gagné. | Ouch ! Tu m'as bien secoué. / Du cran, {g:petit\|petite}. Tu as gagné. |
| J48 | `dialogues/cinnabar_gym.json:22` | Salut, futur Champion ! Auguste est\nun expert du Feu. Mise sur l'Eau ! | Salut, {g:futur Champion\|future Championne} ! Auguste est\nun expert du Feu. Mise sur l'Eau ! |
| J49 | `dialogues/saffron_gym.json:82` | Salut, futur Champion ! | Salut, {g:futur Champion\|future Championne} ! |
| J50 | `dialogues/fighting_dojo.json:86` et `:100` | Champion de la Ligue… Mes poings\nt'attendaient. | {g:Champion\|Championne} de la Ligue… Mes poings\nt'attendaient. (deux occurrences identiques) |
| J51 | `dialogues/fighting_dojo.json:23` | Un disciple de plus ?\nPrépare-toi ! | {g:Un\|Une} disciple de plus ?\nPrépare-toi ! (épicène) |
| J52 | `dialogues/fighting_dojo.json:137` | Ha ! Un challenger ! | Ha ! {g:Un challenger\|Une challengeuse} ! |
| J53 | `dialogues/cerulean_rocket.json:14` [cerulean_rocket_spotted] | Hein ?! Un gamin ? Pas question que tu me suives ! | Hein ?! {g:Un gamin\|Une gamine} ? Pas question que tu me suives ! |
| J54 | `dialogues/cerulean_rocket.json:18` [cerulean_rocket_before] | Bon. Tu l'auras voulu. Je ne vais pas me laisser coincer par un môme ! | Bon. Tu l'auras voulu. Je ne vais pas me laisser coincer par {g:un môme\|une môme} ! |
| J55 | `dialogues/mt_moon.json:49` [mt_moon_rocket_2_before] | Encore un curieux ? J'ai du travail. | Encore {g:un curieux\|une curieuse} ? J'ai du travail. |
| J56 | `dialogues/mt_moon.json:64` [mt_moon_rocket_3_before] | Et surtout pas un gamin curieux. | Et surtout pas {g:un gamin curieux\|une gamine curieuse}. |
| J57 | `dialogues/silph_co.json:16` [silph_co_2f_2_before] | Un visiteur non autorisé ? | {g:Un visiteur non autorisé\|Une visiteuse non autorisée} ? |
| J58 | `dialogues/silph_co.json:40` [silph_co_2f_4_before] | Encore un curieux. / Fais demi-tour, gamin. | Encore {g:un curieux\|une curieuse}. / Fais demi-tour, {g:gamin\|gamine}. |
| J59 | `dialogues/silph_co.json:328` [silph_co_10f_2_before] | Presque arrivé ? Pas pour\nlongtemps, gamin. | Presque {g:arrivé\|arrivée} ? Pas pour\nlongtemps, {g:gamin\|gamine}. |
| J60 | `dialogues/saffron_life.json:5` [saffron_rocket] | Safrania est à nous. Circule, gamin. | Safrania est à nous. Circule, {g:gamin\|gamine}. |
| J61 | `dialogues/j21_tower.json:40` | Le boss est parti, mais nous, on reste.\nTu ne sauveras personne, gamin ! | Le boss est parti, mais nous, on reste.\nTu ne sauveras personne, {g:gamin\|gamine} ! |
| J62 | `dialogues/rocket_hideout.json:4` | Un intrus ? Personne n'entre ici\nsans badge d'accès. | {g:Un intrus\|Une intruse} ? Personne n'entre ici\nsans badge d'accès. |
| J63 | `dialogues/rocket_hideout.json:52` | Encore un étage, encore un intrus. | Encore un étage, encore {g:un intrus\|une intruse}. |
| J64 | `dialogues/route_24.json:120` [nugget_rocket_beaten] | Hm. Tu ferais un excellent… / Non. Un ennemi. Tu ferais un excellent ennemi. | Hm. Tu ferais {g:un excellent\|une excellente}… / Non. {g:Un ennemi\|Une ennemie}. Tu ferais {g:un excellent ennemi\|une excellente ennemie}. |
| J65 | `dialogues/j23_fuchsia_gym.json:164` | Fwahahaha ! Un enfant ose me défier ? | Fwahahaha ! {g:Un\|Une} enfant ose me défier ? (épicène) |
| J66 | `dialogues/route_12.json:34` | Le roi du ponton contre le petit dresseur ! | Le roi du ponton contre {g:le petit dresseur\|la petite dresseuse} ! |
| J67 | `dialogues/route_21_trainers.json:76` | Encore un dresseur à la nage ? | Encore {g:un dresseur\|une dresseuse} à la nage ? |

## 2. Rival (`gr`)

| # | Fichier : ligne [clé] | Texte actuel | Proposition |
|---|---|---|---|
| R1 | `dialogues/oak_lab.json:91` [rival_lab_lost] | Mais je t'avais prévenu : j'étais prêt. | Mais je t'avais {g:prévenu\|prévenue} : j'étais {gr:prêt\|prête}. (même ligne que J6) |
| R2 | `dialogues/oak_lab.json:205` [rival_lab_waiting] | Tu vois ? Je t'avais dit que j'étais prêt. | Tu vois ? Je t'avais dit que j'étais {gr:prêt\|prête}. |
| R3 | `dialogues/oak_lab.json:172` [rival_parcel_return] | Professeur ! Je suis revenu. | Professeur ! Je suis {gr:revenu\|revenue}. |
| R4 | `dialogues/rival_house.json:11` [rival] | Moi, je suis prêt. | Moi, je suis {gr:prêt\|prête}. |
| R5 | `dialogues/league.json:71` [rival_champion_before] | {player} ! Je suis arrivé ici avant toi. Je suis le Champion maintenant. | {player} ! Je suis {gr:arrivé\|arrivée} ici avant toi. Je suis {gr:le Champion\|la Championne} maintenant. |
| R6 | `dialogues/league.json:72` [rival_champion_before] | Tu sais ce que ça veut dire ? Que je suis le meilleur Dresseur du monde ! | Tu sais ce que ça veut dire ? Que je suis {gr:le meilleur Dresseur\|la meilleure Dresseuse} du monde ! |
| R7 | `dialogues/silph_co.json:204` [silph_co_7f_1_after] | Le rival est derrière.\nIl te cherche. | {gr:Le rival\|La rivale} est derrière.\n{gr:Il\|Elle} te cherche. |
| R8 | `dialogues/silph_co_story.json:29` [silph_co_7f_lapras_giver] | Tu as battu ce garçon ? | Tu as battu {gr:ce garçon\|cette fille} ? |
| R9 | `dialogues/silph_co_story.json:41` [silph_co_7f_lapras_giver] | Ce garçon bloque le passage depuis tout à l'heure. / On dirait qu'il attend quelqu'un. | {gr:Ce garçon\|Cette fille} bloque le passage depuis tout à l'heure. / On dirait qu'{gr:il\|elle} attend quelqu'un. |
| R10 | `dialogues/pewter_gym.json:37` | Un autre Dresseur de Bourg Palette\nest passé récemment. | {gr:Un autre Dresseur\|Une autre Dresseuse} de Bourg Palette\nest {gr:passé\|passée} récemment. (variante `badge_boulder` : Pierre parle du rival) |
| R11 | `data/trainer/moments.json:8` [moments.rival_battle.title] | Combat contre le rival | Combat contre {gr:le rival\|la rivale} |

Déjà accordé dans `data/opening/oak_intro.json` (lignes 27, 29, 32) : rien à faire. Aucune occurrence de « mon petit-fils » / « fils » ailleurs dans `data/` (la mère ne parle pas ainsi) ; aucun « ton rival », « ton ami », « ton copain » trouvé.

## 3. À trancher

| # | Fichier : ligne [clé] | Texte actuel | Problème | Recommandation |
|---|---|---|---|---|
| T1 | `dialogues/oak_lab.json:98` [oak_after_battle] | Pour un premier combat, vous vous êtes bien débrouillés. | Pluriel qui réunit joueur et rival : « débrouillés » (au moins un garçon) ou « débrouillées » (deux filles). Aucune des deux syntaxes ne couvre le cas. | Reformuler sans accord : « Pour un premier combat, c'était honorable. » (ou « Pour un premier combat, vous avez bien tenu. »). |
| T2 | `dialogues/oak_lab.json:50` [oak_starter_offer] | Mais découvrir ce monde seul serait une mauvaise idée. | « seul » générique après « Vous voulez tous les deux… ». Masculin neutre acceptable, mais lu comme adressé à une joueuse il sonne faux. | Reformuler : « Mais découvrir ce monde sans aide serait une mauvaise idée. » |
| T3 | `dialogues/route_3.json:33` [route_3_lea_after] | On s'est bien amusés quand même. | Fillette Léa dit « on » ; l'accord dépend de qui est « on » (Léa seule, ou Léa et le joueur). | Garder tel quel si « on » = Léa et ses Pokémon ; sinon « On s'est bien amusé{g:s\|es} »… à éviter. Recommandation : laisser inchangé (« on » à valeur générale). |
| T4 | `dialogues/route_24.json:34` [misty_bridge_invite] | Joli combat. / Tu ne l'as pas lâché, même quand il a pris l'avantage. | Lecture probable : Ondine parle du rival (« l' » et « il »), mais le texte peut aussi viser le combat. | Si c'est bien le rival : « Tu ne l'as pas {gr:lâché\|lâchée}, même quand {gr:il\|elle} a pris l'avantage. ». Kevin confirme la lecture. |
| T5 | `dialogues/silph_co_life.json:174` et `:179` [silph_co_6f_worker_5] | Un autre Dresseur est passé. Moins aimable que toi. / Un autre Dresseur est passé par ici,\navant toi. Il avait l'air pressé. | « Un autre Dresseur » est très probablement le rival (il passe à la Sylphe avant le joueur), mais rien ne l'écrit. | Traiter comme le rival : « {gr:Un autre Dresseur\|Une autre Dresseuse} est {gr:passé\|passée}. Moins aimable que toi. » et « …avant toi. {gr:Il\|Elle} avait l'air pressé. » |
| T6 | `data/trainer/moments.json:42` [outcomes.loss] | Il l'emporte, cette fois. | Texte d'issue de combat contre n'importe quel adversaire, pas seulement le rival. | Reformuler neutre : « L'adversaire l'emporte, cette fois. » |
| T7 | `dialogues/j29.json:6` [rival_route22_final_greet] | La Ligue n'aura qu'un seul vainqueur,\net ce sera moi. | « vainqueur » est un nom de rôle ; le féminin « vainqueure » est peu naturel. | Laisser inchangé (masculin générique) ou, si le style le demande, « {gr:un seul vainqueur\|une seule gagnante} ». Recommandation : inchangé. |
| T8 | `dialogues/oak_lab.json:99`, `:159` ; `dialogues/victory_road.json:23`, `:89` ; `dialogues/j29.json:27…111` ; `dialogues/viridian_city.json:38` | « ce qu'un Dresseur doit apprendre », « un Dresseur découvre sur le terrain », « les bons Dresseurs », « Seuls les Dresseurs qui ont le Badge… », « les jeunes Dresseurs » | Emplois génériques (pas adressés au joueur). | Laisser au masculin générique. Seuls les cas adressés (J39 à J67) sont accordés. |
| T9 | `dialogues/route_12.json:14` [route_12_fisher_1_defeated] | Bah ! Un petit poisson. | Jeu de mots de pêcheur sur sa propre prise, pas sur le joueur. | Laisser inchangé. |
| T10 | `dialogues/j21_tower.json:65`, `dialogues/rocket_hideout.json:166` | « mon enfant », « l'enfant qui dérange mes affaires » | Nom épicène, déterminant « mon / l' » sans marque de genre. | Laisser inchangé. |
| T11 | J51 et J65 (épicènes) | « Un disciple », « Un enfant » | « Une disciple » / « Une enfant » sont corrects mais d'un effet inhabituel. | Garder la proposition `{g:Un\|Une}` (mêmes règles que « Un gamin » → « Une gamine »), sauf refus de Kevin. |

## 4. Décompte

| Cible | Occurrences |
|---|---|
| Joueur (`g`) | **67** entrées J1 à J67 (une entrée regroupe parfois deux chaînes sur la même ligne ; J50 vaut deux lignes) |
| Rival (`gr`) | **11** entrées R1 à R11 (R5 et R6 sont deux chaînes d'un même dialogue ; J6 / R1 est une même ligne à double accord, comptée dans les deux cibles) |
| À trancher | **11** entrées T1 à T11 (dont 5 vraies décisions : T1, T2, T4, T5, T6 ; les autres recommandent de ne rien changer) |

### Fichiers lus en entier (toutes les chaînes, avec orateurs)

22 fichiers : `dialogues/rival_house.json`, `oak_lab.json`, `pallet_town.json`, `player_house.json`, `route_22.json`, `route_24.json`, `ss_anne_captain_corridor.json`, `ss_anne_captain_room.json`, `ss_anne_departure.json`, `ss_anne_life.json`, `silph_co.json`, `silph_co_life.json`, `silph_co_story.json`, `league.json`, `j29.json`, `pokemon_tower.json`, `pokemon_tower_floors.json`, `cerulean_rocket.json`, `viridian_city.json`, `route_1.json`, `bill_house.json`, et `opening/oak_intro.json`.

### Couverture du reste

Les 633 fichiers JSON de `data/` ont été balayés par extraction de toutes les chaînes à espace (4 801 chaînes ; 4 351 hors `audio/`, `pokedex/`, `pokemon/`), puis filtrées par motifs : 597 chaînes à la 2e personne relues une par une, plus recherche des participes et adjectifs, des termes d'adresse (petit, gamin, Champion, jeune, intrus, curieux, visiteur…), de « rival / garçon / autre Dresseur / Bourg Palette » et des jetons `{player}` / `{rival}`. Les autres fichiers de dialogue (dont `cerulean_city.json`, `celadon_*`, `vermilion_gym.json`, `route_*` hors liste ci-dessus) n'ont donc pas été relus en entier, mais toute chaîne contenant un motif a été examinée.

### Limites

- **Code GDScript** (`game/`) non couvert : textes en dur éventuels (carte de Dresseur, menus, titres de classe « Dresseur », écran de fin, `battle_text.gd`, `dialogue_tokens.gd`) à relever séparément.
- `data/npcs/` ne contient pas de texte à relever (aucune chaîne à espace) ; `data/cutscenes/` n'a que 9 chaînes, sans accord. Les noms de classes d'adversaires (« Jeune Dresseur Nathan », « Gamin Lucas »…) désignent des PNJ, non le joueur : non relevés.
- Les chaînes d'une seule ligne contenant un guillemet échappé ou sans espace n'étaient pas extraites ; les numéros de ligne désignent la première chaîne d'une page quand plusieurs partagent la ligne.
- Rival : le relevé repose sur la déduction « ce garçon » / « un autre Dresseur de Bourg Palette » = le rival (R8 à R10, T4, T5) ; à confirmer par Kevin.
- Les accords de pluriels mixtes (joueur + rival, joueur + PNJ) ne sont pas couverts par `g` / `gr` (T1, T3).
