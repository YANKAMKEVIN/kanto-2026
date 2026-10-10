# Textes en brouillon — jalon 10, lot système (2026-10-08)

> **VALIDÉ PAR KEVIN LE 2026-10-08** : les 48 textes tels que proposés, et pour chaque **Note** la proposition (pas la variante) ; Route 2 sur la Carte : rien ne change ; Racaillou du tailleur : pas d'observation. La tâche T8 recopie ce lot mot pour mot dans `data/`.
>
> **48 textes numérotés, à relire par Kevin en une passe** (Q-5 du plan `docs/tech/jalon-10.md`, décision du 2026-10-08 ; tâche T7). Comme aux J6, J7 et J9 : commente ligne par ligne (numéro + correction) ; **tout ce que tu ne commentes pas est validé tel quel**. Rien de ce lot n'est encore dans `data/` (le test `test_no_draft_in_data` refuse les brouillons) : la tâche T8 (données, après la fusion du J9) le recopiera mot pour mot après ta relecture.
>
> Ce lot ne couvre que ce que le dossier 12 ne fixe pas. Toutes les répliques des habitants, du Musée, du garde, de l'Arène, de Liam et de Pierre, la carte du Champion, les objectifs, la description d'Argenta sur la Carte et les textes du Grand moment « badge » sont **déjà verrouillés** (dossier 12, « Textes verrouillés », 2026-10-07) et ne sont pas repris ici.
>
> Conventions suivies (celles des textes validés) : espace simple avant `! ? : ;` (comme dans tout `data/`) ; bulles de 2 lignes de ~40 signes au plus ; panneaux en capitales sur la première ligne, comme « ROUTE 2 » / « BOURG PALETTE » ; noms officiels français (Rouge/Bleu). Longueurs : descriptions de capacités 32 à 92 signes aujourd'hui, Pokédex 66 à 126 ; le lot reste dans ces bornes. Aucune mention du Mont Sélénite (hors texte verrouillé de la Pierre Lune), de la Team Rocket ni de Giovanni.
>
> Les points marqués **Note** sont ceux où j'hésite : ils appellent un mot de ta part, sinon la proposition s'applique.

## A. Capacités (`data/pokemon/moves/moves.json`)

Capacités des apprentissages de Rouge/Bleu des six espèces du J10 qui n'existent ni sur `main` ni dans le J9 (Armure, Météores, Frénésie, Grincement, Dard-Venin, Combo-Griffe, Tranche, Jet de Sable, Griffe, Charge existent déjà). Apprentissages vérifiés (Rouge/Bleu) :
- **Racaillou** : Charge ; 11 Boul'Armure ; 16 Jet-Pierres ; 21 Destruction ; 26 Armure ; 31 Séisme ; 36 Explosion. **Gravalanch / Grolem** : Charge, Boul'Armure ; 11 Boul'Armure ; 16 Jet-Pierres ; 21 Destruction ; 29 Armure ; 36 Séisme ; 43 Explosion.
- **Onix** : Charge, Grincement ; 15 Étreinte ; 19 Jet-Pierres ; 25 Frénésie ; 33 Souplesse ; 43 Armure.
- **Sabelette** : Griffe ; 10 Jet de Sable ; 17 Tranche ; 24 Dard-Venin ; 31 Météores ; 38 Combo-Griffe. **Sablaireau** : Griffe, Jet de Sable ; 10 Jet de Sable ; 17 Tranche ; 27 Dard-Venin ; 36 Météores ; 47 Combo-Griffe.

Mention « … dans le moteur actuel. » selon la règle validée au J9 : seulement quand la capacité entière est sans effet ou n'a qu'un coup ; un effet secondaire encore absent est décrit sans mention (comme Danse Flamme, dont l'emprisonnement n'est pas joué).

| # | Clé cible | Contexte (valeurs actuelles prévues au T8) | Texte proposé |
|---:|---|---|---|
| 1 | `rock_throw` · `name` | Roche, physique, 50, précision 90, PP 15 ; seule attaque Roche de Pierre (Onix) | « Jet-Pierres » |
| 2 | `rock_throw` · `description` | | « Le lanceur soulève de petits rochers et les jette sur la cible. » |
| 3 | `defense_curl` · `name` | Normal, statut, Défense +1 sur soi, PP 40 (Racaillou de Pierre) | « Boul'Armure » |
| 4 | `defense_curl` · `description` | même registre que Repli (« Le lanceur se cache dans sa carapace. Augmente sa Défense. ») | « Le lanceur se roule en boule pour se protéger. Augmente sa Défense. » |
| 5 | `self_destruct` · `name` | Normal, physique, 200, PP 5 ; le lanceur tombe K.O. (`pending_effects` au T8) | « Destruction » |
| 6 | `self_destruct` · `description` | voir la **Note A2** | « Le lanceur explose et blesse gravement la cible. Il tombe K.O. ensuite. » |
| 7 | `earthquake` · `name` | Sol, physique, 100, PP 10 | « Séisme » |
| 8 | `earthquake` · `description` | | « Un violent tremblement de terre secoue le sol et frappe la cible. » |
| 9 | `explosion` · `name` | Normal, physique, 250, PP 5 ; le lanceur tombe K.O. (`pending_effects`) | « Explosion » |
| 10 | `explosion` · `description` | voir la **Note A2** | « Le lanceur explose dans un souffle terrible. Il tombe K.O. ensuite. » |
| 11 | `bind` · `name` | Normal, physique, 15, précision 85, PP 20 ; emprisonnement (`trap`, en attente, comme Danse Flamme) | « Étreinte » |
| 12 | `bind` · `description` | | « Ligote la cible de son long corps et la serre pendant quelques tours. » |
| 13 | `slam` · `name` | Normal, physique, 80, précision 75, PP 20 | « Souplesse » |
| 14 | `slam` · `description` | | « Le lanceur frappe la cible de sa longue queue ou de ses lianes. » |

**Note A1 — noms dans le plan.** Le plan (§2.3) cite « Autodestruction », « Ligotage » et « Patience ». Corrigé ici d'après les noms officiels français : *Self-Destruct* = **Destruction** ; *Bind* (Onix) = **Étreinte** (« Ligotage » est *Wrap*, que ces espèces n'apprennent pas) ; *Patience* (*Bide*) n'est dans aucun apprentissage de Rouge/Bleu des six espèces : **non ajoutée**.

**Note A2 — Destruction et Explosion sans le K.O. du lanceur.** Si le moteur ne joue pas encore le K.O. du lanceur, ces deux capacités frappent très fort **sans contrepartie** (l'inverse des cas « Un seul coup dans le moteur actuel. », où la capacité est plus faible que décrite). Proposé : la description vraie (6, 10), sans mention, parce qu'aucun Pokémon qui les connaît ne peut être rencontré avant longtemps (Racaillou les apprend aux Nv. 21 et 36 ; il n'est pas capturable au J10, et Pierre a ses capacités choisies à la main). Variante si tu préfères la mention : « … Il ne tombe pas K.O. dans le moteur actuel. » À traiter côté moteur avant la première rencontre possible (au plus tôt au J12).

## B. Pokédex (`data/pokedex/kanto.json`)

Descriptions originales (observation de terrain, jamais les textes officiels). Comme pour les espèces existantes et celles du J9, **les formes de base ont une note** débloquée à la première rencontre (`"unlock": { "seen": 1 }`), les évolutions n'en ont pas : notes 16, 20 et 22 (à retirer d'un mot si tu n'en veux pas). Taille et poids : valeurs officielles.

| # | Clé cible | Contexte | Texte proposé |
|---:|---|---|---|
| 15 | `species/geodude` · `description` | Racaillou, n° 074 — 0,4 m, 20,0 kg | « On le prend souvent pour une simple pierre au bord des sentiers. Ses bras robustes soulèvent des rochers plus lourds que lui. » |
| 16 | `species/geodude/notes/0` · `text` (`geodude_sun`) | note de terrain | « Au soleil, il s'enfonce à moitié dans la terre et ne bouge plus. Seuls ses bras trahissent sa présence. » |
| 17 | `species/graveler` · `description` | Gravalanch, n° 075 — 1,0 m, 105,0 kg | « Trop lourd pour grimper vite, il descend les pentes en roulant. Sur son passage, la roche garde de longues traces. » |
| 18 | `species/golem` · `description` | Grolem, n° 076 — 1,4 m, 300,0 kg (évolution par échange : « ??? » dans le Pokédex, rien à dire de plus) | « Sa carapace de pierre ne craint presque rien. Une fois l'an, dit-on, il s'en défait et laisse une coque vide derrière lui. » |
| 19 | `species/onix` · `description` | Onix, n° 095 — 8,8 m, 210,0 kg | « Il creuse la terre en se tordant à grande vitesse. Les tunnels qu'il laisse servent ensuite de terrier à d'autres Pokémon. » |
| 20 | `species/onix/notes/0` · `text` (`onix_rumble`) | note de terrain | « Un grondement sourd sous les pieds, puis plus rien : un Onix vient de passer, quelque part sous la roche. » |
| 21 | `species/sandshrew` · `description` | Sabelette, n° 027 — 0,6 m, 12,0 kg | « Il aime les terres sèches et sablonneuses. Menacé, il se roule en boule et sa peau dure encaisse les coups. » |
| 22 | `species/sandshrew/notes/0` · `text` (`sandshrew_burrow`) | note de terrain | « Il passe les heures chaudes au fond de son terrier et n'en sort que le soir, quand le sable fraîchit. » |
| 23 | `species/sandslash` · `description` | Sablaireau, n° 028 — 1,0 m, 29,5 kg | « Les piquants de son dos sont faits de peau durcie. Il les hérisse dès qu'on l'approche, puis se roule en boule pour charger. » |

Noms d'espèces (rappel, officiels) : Racaillou, Gravalanch, Grolem, Onix, Sabelette, Sablaireau.

**Note B1 — 16 et le Racaillou du tailleur.** Le seul Racaillou du monde au J10 est celui du tailleur (Pokémon d'ambiance, non capturable) ; la description 15 (« soulèvent des rochers ») fait écho à son animation « soulève une pierre », la note 16 parle d'un Racaillou sauvage. Si ta règle est « la note décrit ce qu'on a vu », la note 16 ne colle à rien au J10 (on voit Racaillou d'abord en combat, chez Liam ou Pierre) : à garder quand même ou à remplacer par « Les tailleurs de pierre l'apprécient : il porte sans se plaindre des blocs plus lourds que lui. » ?

**Note B2 — Onix.** « tunnels » reste général : pas de lieu nommé (ni Mont Sélénite, ni Grotte, ni Tunnel Roche).

## C. Grand moment « Arrivée à Argenta » (`data/trainer/moments.json`, `zone_arrivals`)

| # | Clé cible | Contexte | Texte proposé |
|---:|---|---|---|
| 24 | `zone_arrivals/pewter_city` · `title` | frise de l'écran Dresseur ; modèle de Jadielle « Arrivée à Jadielle » | « Arrivée à Argenta » |
| 25 | `zone_arrivals/pewter_city` · `detail` | Jadielle : « Une nouvelle ville. » ; Route 1 : « Premiers pas sur la Route 1. » | « Une ville de pierre, au pied des montagnes. » |

**Note C1.** Le plan proposait le défaut « Une nouvelle ville. » (identique à Jadielle). Je propose un détail propre à Argenta, sur le modèle de la Route 1, qui reprend les repères du dossier (pierre, montagne) sans répéter la description de la Carte. Si tu préfères la sobriété de Jadielle : « Une nouvelle ville. »

## D. Noms affichés (`speaker` des dialogues)

| # | Personnage (dossier 12) | Où | Texte proposé |
|---:|---|---|---|
| 26 | Pierre | Arène (dialogues et scène ; aussi `name` du Dresseur `pewter_gym_brock` : « Tu as battu Pierre ! ») | « Pierre » |
| 27 | Campeur Liam | Arène (aussi `name` du Dresseur : « Campeur Liam veut se battre ! », comme « Scout Théo ») | « Campeur Liam » |
| 28 | Guide d'Arène | Arène, près de l'entrée | « Guide » |
| 29 | Montagnard | Route 2 nord | « Montagnard » |
| 30 | Tailleur de pierre | Argenta, chantier | « Tailleur de pierre » |
| 31 | Enfant | Argenta, gros rocher de la place | « Enfant » |
| 32 | Visiteuse du Musée | Argenta, place ↔ Musée | « Visiteuse » |
| 33 | Vieil habitant | Argenta, point de vue | « Vieil homme » |
| 34 | Jeune Dresseuse (PNJ sans combat) | Argenta, près du Centre | « Dresseuse » |
| 35 | Employé du Musée | Argenta, devant l'entrée | « Employé du Musée » |
| 36 | Chercheur (salle science) | Musée | « Chercheur » |
| 37 | Chercheuse (salle science) | Musée | « Chercheuse » |
| 38 | Garde de la Route 3 | Argenta, sortie est | « Garde » |
| 39 | Compagne du tailleur | Maison du tailleur | « Habitante » |
| 40 | Enfant du tailleur | Maison du tailleur | « Enfant » |
| 41 | Habitante de la maison de la chercheuse | Maison de la chercheuse | « Chercheuse » |

Déjà validés, réutilisés : « Infirmière » (Centre), « Marchand » (Boutique).

**Note D1 — 30.** « Tailleur » seul se lit d'abord comme un tailleur de vêtements ; « Tailleur de pierre » (18 signes) est sans ambiguïté et tient dans l'étiquette de la bulle. Variante courte : « Tailleur ».

**Note D2 — 33 et 34.** Le dossier dit « vieil habitant » et « jeune Dresseuse » ; je reprends les étiquettes déjà validées à Jadielle (« Vieil homme », « Dresseuse ») par cohérence. Variantes : « Vieil habitant », « Jeune Dresseuse ».

**Note D3 — 28.** « Guide » seul, court ; variante « Guide de l'Arène » si l'étiquette seule te semble trop vague.

**Note D4 — 41.** La maison est celle « de la chercheuse » et sa sœur travaille au Musée : « Chercheuse » comme la chercheuse du Musée (37), sur une autre carte. Si tu veux éviter deux « Chercheuse » : « Habitante ».

**Note D5 — répartition des trois répliques des chercheurs** (verrouillées, deux chercheurs). Proposé : le **Chercheur** dit les deux premières en deux pages (« Les fossiles sont comme des pages / arrachées au passé. » puis « Certains Pokémon ont changé au fil du temps. / D'autres semblent presque inchangés. ») ; la **Chercheuse** dit la phrase sur les collectionneurs, seule. Aucune n'est changée.

## E. Écran Dresseur — bulle de détail d'un badge obtenu

| # | Clé cible | Contexte | Texte proposé |
|---:|---|---|---|
| 42 | bulle · ligne 1 (`BadgeSlotView.name`) | toucher un badge obtenu ; nom tiré de `badges.json` | « {badge} » → « Badge Roche » |
| 43 | bulle · ligne 2 (`BadgeSlotView.detail`, `BadgeLibrary.DETAIL_FORMAT`) | ville et Champion tirés de `badges.json` ; format générique pour les 8 badges | « {ville} — {champion} » → « Argenta — Pierre » |

**Note E1.** Variante plus parlante pour la ligne 2, alignée sur le Grand moment : « Obtenu à Argenta contre Pierre. » ; proposé : la forme courte, pour ne pas répéter mot pour mot la frise des Grands moments affichée sur le même écran.

## F. Panneaux et points d'examen non couverts par le dossier

La grille d'Argenta (`tools/plans/argenta.txt`) et celle de la Route 2 nord placent quatre panneaux, et le plan (§2.2) un panneau d'exposition dans la salle science ; le dossier n'en donne pas le texte.

| # | Clé cible (prévue au T8) | Contexte | Texte proposé |
|---:|---|---|---|
| 44 | `route_2_north_sign` · `pages` | panneau (13, 19) en sortant du poste nord ; modèle « ROUTE 2 / Jadielle — Forêt de Jade » ; sous-titre = celui du titre d'arrivée (dossier §20) | « ROUTE 2\nForêt de Jade — Argenta » |
| 45 | `pewter_city_sign` · `pages` | panneau (16, 42) à l'entrée de la ville ; modèle « BOURG PALETTE » (nom seul) | « ARGENTA » |
| 46 | `pewter_museum_sign` · `pages` | panneau (15, 38) devant le Musée ; le Musée est gratuit (arbitrage 16) | « MUSÉE D'ARGENTA\nEntrée libre. » |
| 47 | `pewter_gym_sign` · `pages` | panneau (39, 12) devant l'Arène ; aucun conseil de types | « ARÈNE D'ARGENTA\nChampion : Pierre » |
| 48 | `pewter_museum_science_panel` · `pages` (`narration`) | panneau d'exposition de la salle science (« l'évolution et les traces laissées par les Pokémon anciens », dossier §7) | « LES POKÉMON ANCIENS\nCe qu'il reste d'eux dort dans la roche. » |

**Note F1 — 45.** « ARGENTA » seul, comme « BOURG PALETTE » et comme le titre d'arrivée. Variante avec sous-titre (comme les routes) : « ARGENTA\nEntre pierre et montagne ».

**Note F2 — 47.** Le panneau nomme Pierre avant qu'on le rencontre (le garde le fait aussi : « Pierre dirige l'Arène d'Argenta. »). Rouge/Bleu ajoutait une devise au Champion ; non proposée (rien dans le dossier). Si tu préfères un panneau sans nom : « ARÈNE D'ARGENTA » seul.

**Note F3 — 48.** « dort dans la roche » ne promet aucune résurrection de fossile (rien n'est donné ni annoncé au J10 ; le laboratoire reste fermé). Variante plus neutre : « LES POKÉMON ANCIENS\nIls ont laissé leurs traces dans la roche. »

## Hors numérotation : rien de nouveau

Repris tels quels, aucun texte à écrire : messages de combat (« {trainer} veut se battre ! », « Tu as battu {trainer} ! », gain d'argent), toast « Point de repos enregistré — Argenta », ramassage de la Potion (format du J8), dialogues de l'infirmière et du marchand (définitions de Jadielle), Antidote (J9), réveil au Centre (`nurse_wakeup`), écran « ROUTE 3 — À venir » de la sortie est (étiquette `coming_soon` = « Route 3 », le nom de zone existant dans `zones.json`), titre « ARGENTA » (nom de zone existant).

## Questions liées au lot (pas des textes)

- **Route 2 sur la Carte** (conséquence de Q-3 : la Route 2 nord est la 2e carte de la zone `route_2`). La zone garde aujourd'hui le sous-titre « Jadielle — Forêt de Jade » et la description « Un chemin bordé de prairies qui s'enfonce peu à peu sous les arbres. », écrits pour la seule moitié sud. *Proposé : ne rien changer* (le plan disait « aucun texte nouveau », et la description reste juste) ; si tu veux que la Carte couvre les deux moitiés : sous-titre « Jadielle — Argenta », description inchangée. Le panneau du sud (« ROUTE 2 / Jadielle — Forêt de Jade ») ne change pas.
- **Racaillou du tailleur, observation.** Le plan (§2.12) le veut sans dialogue. Les Pokémon d'ambiance de Bourg Palette ont une observation (« Il picore les graines, l'œil attentif. ») : en veux-tu une pour lui ? *Proposition si oui* : « Il soulève une pierre, puis la repose avec soin. » (non numérotée tant que tu ne la demandes pas).
