# Prompt ChatGPT — Safrania et la Sylphe SARL (REPORTÉ, initialement jalon 22)

> **Reporté le 2026-10-16** : Kevin a fixé le J22 sur « Les deux chemins vers Parmanie » (Routes 12 à 18
> et Parmanie, `docs/design/passes/j22-v2-chatgpt.md`) et le J23 sur le Parc Safari, les CS et Koga.
> Ce prompt reste valable pour le jalon de Safrania ; ses faits RB et son inventaire du code restent justes.

> Préparé par Claude le 2026-10-15, à coller dans ChatGPT pour concevoir le **jalon 22** : ouverture
> de Safrania, libération de la Sylphe SARL (rival n° 6, Giovanni n° 2), Dojo et Arène de Morgane.
> Périmètre choisi par Kevin le 2026-10-15 : **Safrania** (colonne du dossier 06 : Céladopole →
> Safrania → Parmanie), plutôt que les Routes 12–15. Numéro **25** : 22 = J19, 23 = J20, 24 = J21.
> Joindre à ChatGPT, **pour l'ambiance et la DA seulement** : `docs/design/reference/combat-v1.webp`,
> `centre-pokemon-v1.webp`, et une vue générale récente (par exemple Céladopole du J20, branche
> `docs/dossier-23-j20`). Coller aussi, si possible, les V2 du J20 et du J21
> (`docs/design/passes/j20-v2-chatgpt.md`, `j21-v2-chatgpt.md` quand elle existera). Le texte entre
> les deux lignes est le prompt.

---

Tu m'aides à concevoir le **jalon 22** de *Kanto 2026*, mon remake personnel de Pokémon Rouge/Bleu en 2D HD peinte, sur smartphone (Android, paysage, déplacement case par case). Je suis le directeur du jeu ; un autre assistant (Claude) implémente à partir de ton dossier, après une passe d'alignement avec le code réel. Il a besoin d'un dossier **complet, précis et sans ambiguïté** : tout ce que tu ne tranches pas, il devra me le redemander.

Le J22 **ouvre Safrania**, la ville fermée depuis le J20, au centre de Kanto. La Team Rocket l'occupe et a pris le siège de la **Sylphe SARL**. Le joueur traverse l'immeuble, retrouve son rival (combat n° 6), affronte **Giovanni une deuxième fois** et libère l'entreprise. La ville contient aussi le **Dojo** et l'**Arène de Morgane** (Psy). C'est le **plus gros jalon depuis Céladopole** : la découpe en sous-jalons compte autant que le contenu.

## Ce qui est déjà décidé (à respecter, ne pas remettre en cause)

**Esprit et règles générales**
- « Comme si Pokémon n'avait jamais quitté la 2D » : on reconnaît Rouge/Bleu, enrichi, jamais remplacé. Chaque nouveauté répond à « qu'est-ce que cela apporte au plaisir de jouer ? ».
- **Aucune mécanique nouvelle sans la signaler** (je dois pouvoir dire oui ou non). **Aucun objet pour une mécanique qui n'existe pas encore.** Pas de tutoriel quand un système se découvre ; pas de fenêtre « OBJECTIF MIS À JOUR » ; textes courts (bulles de 2 lignes d'environ 40 caractères).
- Monde : grille (1 case ≈ 1 m), déplacement à angles droits, marche et course, portes et changements de carte avec fondu, intérieurs, PNJ avec petites routines, cinématiques (le jeu peut déplacer le joueur), sauvegarde automatique. Défaite → retour au dernier Centre utilisé, sans perte d'argent ni de progression.
- Les **badges n'ont aucun effet caché** (dossier 12) ; les capacités d'exploration suivent les règles déjà décidées par les jalons précédents.
- Art : décors peints ; personnages et Pokémon **peints simplifiés**. Chaque pose, intérieur ou animation coûte une image peinte : rester sobre. **Un immeuble de 11 étages ne doit pas coûter 11 décors uniques.**

**Progression et caractères (dossier 06)**
- Colonne vertébrale : … Lavanville → Céladopole → **Safrania** → Parmanie → Cramois'Île → Jadielle → Plateau Indigo.
- **Morgane — puissance** : « une vraie claque après l'arc Rocket de Safrania : IA forte, Pokémon rapides, Psy spectaculaire ».
- Team Rocket : présence progressive, puis arc de Safrania comme sommet de l'intrigue Rocket avant Jadielle.
- **Rival** : 8 combats majeurs ; le n° 6 est à la **Sylphe SARL**. Le tournant du rival a eu lieu à Lavanville (dossier 06 §6, J19). Chaque combat du rival est un **Grand moment**, victoire comme défaite ; états gagné / perdu / pas affronté = mémoire du monde, jamais des branches.

**Systèmes qui existent déjà**
- Combat complet (J11) : statuts, confusion, effets, changements, IA de Dresseurs, CT, évolutions. Capture, Pokédex vu / capturé, Sac avec objets clés, Centre, Boutique, argent, Grands moments.
- Dresseurs avec ligne de vue, combats inévitables ; Team Rocket combattue au Mont Sélénite (J12), à Azuria (J13–J14), au Repaire de Céladopole (J20, Giovanni n° 1 battu, Scope Sylphe).
- **Compagnon Pokémon** (J11) : il suit le joueur dehors, il est caché en combat, rentre dans sa Ball à toute cinématique, ne déclenche pas de rencontre et n'occupe pas la grille.

**Ce que les jalons précédents posent (tes hypothèses d'entrée)**
- **J20** : Route 7 et Route 8 avec un **poste de garde de Safrania sur chaque route, fermé**. Le garde dit : « Désolé, Safrania est fermée pour le moment. » ; **il ne parle pas de soif**. Le J20 a laissé au jalon de Safrania le choix de l'ouverture (boissons comme RB, Thé comme RFVF, ou autre). Le Casino de Céladopole est narratif (pas de jetons) et **Porygon a été confié au dossier de Safrania**. Un employé de Céladopole dit seulement : « Sylphe ? Une grande entreprise de Safrania. »
- **J20** : Giovanni battu dans le Repaire (Onix, Rhinocorne, Kangourex), Scope Sylphe obtenu.
- **J21** (dossier 24, arbitrages validés) : Tour Pokémon résolue, M. Fuji sauvé, **Poké Flûte** (objet clé utilisable hors combat et en combat), deux Ronflex N30 (Route 11 et Route 16 est) capturables ou vaincus, début de la Route 12. Le J21 **laisse explicitement à plus tard** : l'accès à Safrania (Thé, PNJ que RB change), Osselait offert, Ronflex compagnon. Drapeaux nommés `ghost_marowak_calmed`, `fuji_rescued`, `got_poke_flute`.
- Les Routes 5 et 6 (nord et sud de Safrania) existent (J15) ; vérifie avec moi si leurs postes de garde sont aussi fermés.
- Équipe du joueur en arrivant : environ niveau 32 à 38, probablement 4 badges (Pierre, Ondine, Major Bob, Erika).

**Ce que fait Rouge/Bleu (vérifié dans le désassemblage du jeu) — base, pas obligation**
- **Accès** : quatre postes de garde (Routes 5, 6, 7, 8). Le garde a soif ; une boisson (Eau Fraîche, Soda Cool ou Limonade, achetées au distributeur du toit du grand magasin de Céladopole) ouvre **les quatre** postes. RFVF remplace les boissons par le **Thé** offert par une vieille dame de Céladopole.
- **Dans la ville** : 7 Sbires Rocket en extérieur qui ne combattent pas (« Le BOSS dit qu'il va prendre cette ville ! »). Devant la porte de la Sylphe, un garde Rocket bloque l'entrée **jusqu'au sauvetage de M. Fuji** (Tour, 7F), puis il est remplacé par un Sbire endormi. Bâtiments : Centre, Boutique, Sylphe SARL, Arène, Dojo, maison de la Copieuse (2 étages : elle donne la CT31 Copie contre la Poupée), maison de M. Psy (CT29 Psyko), maison du Roucarnage (courrier).
- **Sylphe SARL** : **11 étages + ascenseur**. **30 Dresseurs** (Sbires et Scientifiques, environ N25 à N39 ; un Jongleur au 5F) répartis du 2F au 11F. **Dalles de téléportation** entre les pièces. **Portes verrouillées** ouvertes par la **Carte Magnétique** trouvée au 5F. Une infirmière soigne l'équipe au **9F**. Objets : CT Bélier, CT Danse-Lames, CT Séisme, Super Bonbon, vitamines, Rappel Max, Hyper Potion, Corde Sortie…
- **Rival n° 6 au 7F** : Roucarnage 37, Arcanin / Léviator / Noeunoeuf 35–38, Alakazam 35, starter final 40 (équipe selon le starter).
- **Lokhlass N15 offert au 7F** par un employé, en remerciement.
- **11F** : deux Sbires, puis **Giovanni** : Nidorino 37, Kangourex 35, Rhinocorne 37, Nidoqueen 41. Après sa défaite, il part ; le **Président** remercie et donne la **Master Ball** (une seule dans le jeu). Toute la Team Rocket quitte Safrania.
- **Dojo** : 5 Karatékas, maître Kicklee + Tygnon N37 ; récompense : **choisir Kicklee ou Tygnon N30** (un seul).
- **Arène de Morgane** : salles reliées par des **dalles de téléportation** (puzzle), 8 Dresseurs (Médiums et Psy) ; Morgane : Kadabra 38, M. Mime 37, Aéromite 38, Alakazam 43 ; **Badge Marais**, **CT46 Vague Psy**.
- Dans RB, l'Arène est accessible **avant** la Sylphe ; la plupart des joueurs font la Sylphe d'abord.

## Ce que j'attends : la V2 du « dossier 25 — Safrania et la Sylphe SARL »

Rédige-le en français, en sections numérotées, avec les **textes définitifs**. Pour chaque point, tranche ; si tu hésites, propose une valeur par défaut et signale-la. Pour chaque règle, indique si elle suit **Rouge/Bleu (RB)**, **Rouge Feu / Vert Feuille (RFVF)** ou une **invention de Kanto 2026 (K26)**, et pourquoi.

1. **Intention** : ce que le joueur doit ressentir (ville occupée, tension, libération, puis la « claque » de Morgane), en deux ou trois phrases.
2. **Périmètre et découpage** : ce qui est dedans, ce qui est **explicitement reporté**, puis **3 ou 4 sous-jalons jouables** (chacun validé sur téléphone), du moins risqué au plus risqué. Propose aussi, en option, un découpage en **deux jalons** (J22 Sylphe, J23 Morgane et Dojo) avec ta recommandation.
3. **Ouverture de Safrania** : boissons (RB), Thé (RFVF) ou autre ; qui donne quoi, où, quand ; un objet ouvre-t-il les quatre postes ; textes des gardes avant / après. Lien avec le J21 : faut-il avoir sauvé Fuji pour **entrer dans la ville**, ou seulement pour **entrer dans la Sylphe** (comme RB) ?
4. **Safrania occupée** : plan général de la ville (sans level design détaillé), bâtiments ouverts, PNJ et Sbires (combattent-ils ?), ambiance (lumière, musique), ce qui est fermé tant que la Sylphe n'est pas libérée.
5. **Sylphe SARL — structure** : nombre d'étages **réellement construits** (11 comme RB, ou moins, avec quelle justification), ascenseur (quels étages, quand), escaliers, **dalles de téléportation** (garder, simplifier, supprimer ?), **portes verrouillées et Carte Magnétique** (garder, simplifier ?). Pense à la lisibilité sur téléphone, au coût d'art (**étages types réutilisables**) et à ne pas perdre le joueur. Mécanique nouvelle → signale-la.
6. **Sylphe — contenu** : nombre de Dresseurs (30 dans RB : en garder combien ?), répartition par étage, équipes de référence, objets, infirmière ou point de soin, employés et leurs répliques. Garde une **courbe de difficulté** jouable d'une traite ou en plusieurs visites ; où la sauvegarde automatique se fait-elle ?
7. **Rival n° 6** : où, comment il arrive, équipe et niveaux (référence RB), textes avant / après en tenant compte de son tournant à Lavanville ; obligatoire ou facultatif ; rejouable après défaite ?
8. **Lokhlass** : don au 7F comme RB ? Si oui, c'est un **don de Pokémon hors starter** (mécanique à signaler si elle n'existe pas) : équipe pleine, surnom, Pokédex.
9. **Giovanni n° 2** : mise en scène au 11F, équipe et niveaux, textes, ce qu'il dit du Repaire et de la suite (sans spoiler Jadielle), son départ. Le **Président** et la **Master Ball** (garder l'objet ? une seule ?). Porygon (confié par le J20) : où, comment, ou reporté ?
10. **Safrania libérée** : départ de la Team Rocket (en une fois, en cinématique ?), PNJ qui changent (liste et textes), Sylphe après le jalon (étages visitables ?), récompense discrète.
11. **Dojo** : 5 Karatékas et le maître (équipes, ordre, inévitables ?), textes, choix **Kicklee ou Tygnon** (un seul, définitif), statut du Dojo après la création de l'Arène officielle.
12. **Arène de Morgane** : principe du puzzle (dalles comme RB ou autre idée **lisible sur téléphone**), Dresseurs (nombre, équipes), guide de l'Arène, **Morgane** (équipe, niveaux, IA, textes d'avant et d'après), Badge Marais, CT46 Vague Psy (ou autre CT), Grand moment. Comment rendre la « claque » sans frustration ?
13. **Maisons et annexes** : Copieuse (Poupée → CT31 Copie, ou reporté ?), M. Psy (CT29 Psyko), maison du Roucarnage, Centre, Boutique (stock).
14. **Postes de garde et Routes 5 à 8** : ce qui change une fois Safrania ouverte (raccourcis, PNJ).
15. **Compagnon** : comportement dans la Sylphe (intérieur : sort-il ?), sur les dalles de téléportation, dans l'ascenseur, dans l'Arène.
16. **Pokédex, Équipe, Dresseur** : ce qui s'enregistre (espèces vues, Lokhlass, Kicklee / Tygnon), ce qui s'affiche de nouveau (Carte Magnétique, Master Ball, Badge Marais au profil).
17. **Données, drapeaux, sauvegarde** : liste des drapeaux (noms en anglais, `snake_case`), ordre dans lequel ils se posent, cas d'une sauvegarde faite au milieu de la Sylphe (porte ouverte, étage à moitié vidé, Giovanni battu mais Président pas encore vu). Objectif : **aucun changement de version de sauvegarde** si possible. Rien ne doit être perdu ni bloqué.
18. **Espèces et art nécessaires** : nouvelles espèces dans les données (Kadabra / Alakazam, M. Mime, Aéromite, Kicklee, Tygnon, Lokhlass, Roucarnage, Arcanin, Léviator, Noeunoeuf, Nidoqueen, Kangourex, Rhinocorne… à recouper avec ce qui existe), images peintes nécessaires (ville, étages types de la Sylphe, ascenseur, Dojo, Arène, Morgane, Giovanni, Président, employés), en restant sobre.
19. **Équilibrage** : niveaux de référence RB, mais **niveaux finaux fixés par simulation** (règle du projet depuis Pierre). Donne des fourchettes.
20. **Textes à valider** : tous les textes regroupés et numérotés.
21. **Questions ouvertes** : numérotées, avec ta recommandation pour chacune.
22. **Tableau final « Décisions verrouillées »** (élément | décision), au format de tes V2 précédentes.

**Contraintes de forme** : pas de zone hors de Safrania et de ses bâtiments (les postes de garde existent déjà) ; pas de mécanique nouvelle sans la signaler ; ne rien spoiler (Giovanni Champion de Jadielle, Mewtwo, post-game) ; textes courts ; garde en tête le coût d'art et la lisibilité sur un écran de téléphone.

---

## Après ChatGPT

Colle sa réponse à Claude : passe d'alignement habituelle (`docs/design/passes/j22-v2-chatgpt.md`
et `j22-v2-alignement.md`) contre `vision.md`, la roadmap, le dossier 06, les dossiers et passes des
J15 à J21, le code réel et Rouge/Bleu, avec des arbitrages numérotés à trancher ; puis
`docs/design/dossier-25-safrania.md`. Le plan technique `docs/tech/jalon-22.md` vient ensuite.

### Faits RB vérifiés (`pret/pokered` `af51989`, 2026-10-15)

- `data/trainers/parties.asm` : `Rival2Data` (Sylphe 7F : Roucarnage 37, Arcanin / Léviator /
  Noeunoeuf 35–38, Alakazam 35, starter final 40) ; `GiovanniData` (Sylphe 11F : Nidorino 37,
  Kangourex 35, Rhinocorne 37, Nidoqueen 41) ; `SabrinaData` (Kadabra 38, M. Mime 37, Aéromite 38,
  Alakazam 43) ; `BlackbeltData` (Dojo : maître Kicklee + Tygnon 37, 4 Karatékas 31–36) ;
  `PsychicData` et `ChannelerData` (Arène : 4 Psy 31–38, 3 Médiums 33–38).
- `data/maps/objects/SilphCo*.asm` : 30 Dresseurs du 2F au 11F (Rocket et Scientifiques, un Jongleur
  au 5F), Carte Magnétique au 5F, infirmière au 9F, Rival au 7F, Président au 11F ; objets listés
  au prompt.
- `scripts/SilphCo7F.asm` : Lokhlass N15 (`GivePokemon`) ; `scripts/SilphCo11F.asm` : Master Ball,
  puis la liste des Sbires de Safrania retirés de la ville.
- `scripts/PokemonTower7F.asm` (l. 234–237) : le sauvetage de Fuji **retire le garde Rocket de la
  porte de la Sylphe** et fait apparaître le Sbire endormi.
- `scripts/FightingDojo.asm` : Kicklee ou Tygnon N30 ; `scripts/SaffronGym.asm` : CT46 Vague Psy ;
  `scripts/MrPsychicsHouse.asm` : CT29 Psyko ; `scripts/CopycatsHouse2F.asm` : CT31 Copie.
- `text/SaffronGates.asm` : garde assoiffé ; une boisson ouvre les quatre postes.

### Points que Claude vérifiera de toute façon (inventaire du code, 2026-10-15)

- **Cohérence avec le dossier 24** : sa table de périmètre (l. 64) range « Route 12 sud, Routes 13 à
  15, Parmanie » sous le **J22**. Kevin a choisi Safrania pour le J22 le 2026-10-15 : la mention du
  dossier 24 est à corriger (Routes 12–15 et Parmanie → jalon suivant) avec la session du J21.
- **Ascenseur** : aucun code ; conçu au dossier 23 §13.4 (J20, grand magasin et Repaire, clé
  `lift_key`). La Sylphe le réutilisera.
- **Dalles de téléportation** : aucun code. Il n'existe que des warps ordinaires (`game/world/warp.gd`,
  `warp_table.gd`, sans condition de drapeau) et l'étape `change_map` des cinématiques. Les dalles
  tournantes du Repaire (dossier 23 §13.3) sont un autre mécanisme.
- **Portes verrouillées / Carte Magnétique** : aucun code. `FlagGate` (`game/world/flag_gate.gd`) est
  visuel et ne bloque pas la grille ; les PNJ apparaissent selon `if` / `unless` sur des drapeaux.
- **Don de Pokémon hors starter** (Lokhlass, Kicklee / Tygnon, Porygon) : aucun code. Le seul choix
  est `StarterOffer` (`game/pokemon/starter_offer.gd`) ; l'ajout passe par `Party.add` ou le Stockage
  (`storage_rules.gd`). L'étape `give` des cinématiques ne donne que des objets.
- **Postes de garde** : `route_5_gate_rule` et `route_6_gate_rule` (J15) repoussent le joueur, sans
  drapeau de déblocage ; aucune condition « objet dans le Sac ». Aucun Thé ni boisson dans les données.
- **Master Ball** : absente des données.
- **Espèces** : `main` en a 62, `jalon-19` 71. Présents : Abra, Kadabra, Staross, Férosinge,
  Colossinge, Machoc (+ Noeunoeuf, Caninos, Léviator… selon les branches ; Soporifik / Hypnomade
  sur `jalon-17`). Absents partout : Alakazam, M. Mime, Kicklee, Tygnon, Lokhlass, Machopeur,
  Mackogneur, Porygon, Nidoqueen. **Amnésie** est absente (le J21 la crée pour Ronflex).
- **Sauvegarde** : v6 sur `main`, v7 sur `jalon-15` à `jalon-19` ; le J22 ne devrait ajouter que
  des drapeaux.
