# Prompt ChatGPT — dossier 24 : le retour à la Tour Pokémon (jalon 21)

> Préparé par Claude le 2026-10-14, à coller dans ChatGPT pour concevoir le **jalon 21** : retour à
> la Tour Pokémon avec le Scope Sylphe, Ossatueur, le 7e étage et la Team Rocket, le sauvetage de
> M. Fuji, la Poké Flûte et Lavanville apaisée. Numéro **24** : 22 = J19, 23 = J20 (passe J20, H-1).
> Joindre à ChatGPT, **pour l'ambiance et la DA seulement** : `docs/design/reference/tour-pokemon-vue-generale-v1.png`
> et `tour-pokemon-plan-v1.png` (branche `docs/dossier-j19`), `combat-v1.webp`. Coller aussi, si
> possible, la V2 du J19 et celle du J20 (`docs/design/passes/j19-v2-chatgpt.md`,
> `j20-v2-chatgpt.md`). Le texte entre les deux lignes est le prompt.

---

Tu m'aides à concevoir le **jalon 21** de *Kanto 2026*, mon remake personnel de Pokémon Rouge/Bleu en 2D HD peinte, sur smartphone (Android, paysage, déplacement case par case). Je suis le directeur du jeu ; un autre assistant (Claude) implémente à partir de ton dossier, après une passe d'alignement avec le code réel. Il a besoin d'un dossier **complet, précis et sans ambiguïté** : tout ce que tu ne tranches pas, il devra me le redemander.

Le J21 **résout l'intrigue de la Tour Pokémon** ouverte au J19 : le joueur revient à Lavanville avec le Scope Sylphe obtenu au J20, voit enfin les spectres pour ce qu'ils sont, apaise l'âme de la mère d'Osselait, chasse la Team Rocket du sommet de la Tour, libère M. Fuji et reçoit la Poké Flûte. C'est un jalon **court en surface, fort en émotion** : pas de nouvelle ville, pas d'Arène.

## Ce qui est déjà décidé (à respecter, ne pas remettre en cause)

**Esprit et règles générales**
- « Comme si Pokémon n'avait jamais quitté la 2D » : on reconnaît Rouge/Bleu, enrichi, jamais remplacé. Chaque nouveauté répond à « qu'est-ce que cela apporte au plaisir de jouer ? ».
- **Aucune mécanique nouvelle sans la signaler** (je dois pouvoir dire oui ou non). **Aucun objet pour une mécanique qui n'existe pas encore.** Pas de tutoriel quand un système se découvre ; pas de fenêtre « OBJECTIF MIS À JOUR » ; textes courts (bulles de 2 lignes d'environ 40 caractères).
- Monde : grille (1 case ≈ 1 m), déplacement à angles droits, marche et course, portes et changements de carte avec fondu, intérieurs, PNJ avec petites routines, cinématiques (le jeu peut déplacer le joueur), sauvegarde automatique. Défaite → retour au dernier Centre utilisé, sans perte d'argent ni de progression.
- Art : décors peints ; personnages et Pokémon **peints simplifiés**. Chaque pose ou animation par espèce coûte une image peinte : rester sobre.

**Systèmes qui existent déjà dans le jeu**
- Combat complet (J11) : statuts majeurs dont le **sommeil** (1 à 3 tours), confusion, effets de capacités, changement de Pokémon, IA de Dresseurs, CT. Capture, Pokédex vu / capturé, Sac avec catégorie **objets clés**.
- Team Rocket déjà combattue (Mont Sélénite au J12, puis Repaire de Céladopole au J20) ; Dresseurs avec ligne de vue, combats inévitables, récompenses en argent.
- **Compagnon Pokémon** (J11) : un Pokémon choisi suit le joueur dehors. Règles du projet : il est **caché pendant les combats** et **rentre dans sa Ball à toute cinématique**, il ne déclenche pas de rencontre et n'occupe pas la grille.

**Ce que les jalons précédents posent (conçus, pas tous codés : ce sont tes hypothèses d'entrée)**
- **J18** : Lavanville, ville mélancolique, mystérieuse et respectueuse ; Centre, Boutique, **maison de M. Fuji avec Fuji absent** (« il passe ses journées à la Tour »), maison d'Osselait ; extérieur et rez-de-chaussée de la Tour.
- **J19** : étages 1F à 6F de la Tour. Sans le Scope, **toute rencontre sauvage aux étages 3 à 6 s'affiche « SPECTRE »** : impossible à identifier, à capturer ou à toucher, la fuite réussit toujours. Le **rival n° 5** au 2F. Exorcistes (Médiums) combattus. Au **6F**, devant l'escalier du 7F, un « SPECTRE » bloque : message « Va-t'en… Intrus… », combat où l'on ne peut que fuir, puis le joueur est **repoussé d'une case**. Le **7F n'est pas construit** au J19. Un PNJ de Lavanville dit que Fuji est monté à la Tour et **n'en est pas revenu**, sans nommer la Team Rocket.
- **J19 → J20** : le mode spectre **lit la présence du Scope Sylphe dans le Sac**. Dès qu'on l'a, les rencontres de la Tour deviennent normales (Fantominus, Spectrum, Osselait…) sans autre changement.
- **J20** : Céladopole, Erika (Badge Prisme), Repaire Rocket complet, **Giovanni** battu, **Scope Sylphe** obtenu. Le J20 ne touche à aucune carte de Lavanville et ne pose aucun drapeau Fuji, Ossatueur ou Flûte. La Poké Flûte n'est **pas** obtenue au J20. Postes de garde de Safrania **fermés**.
- **Ronflex** endormi qui bloque le passage : à l'extrémité est de la Route 11 (J17) ; un second est envisagé à l'ouest de Céladopole, vers la Route 16 (passe J20, à confirmer). **Aucun des deux ne se réveille avant la Poké Flûte.**
- Drapeaux déjà **nommés** pour que les jalons parlent la même langue : `ghost_marowak_calmed`, `fuji_rescued`, `got_poke_flute`.
- Équipe du joueur en arrivant : environ niveau 28 à 32, probablement 4 badges.

**Ce que fait Rouge/Bleu (vérifié dans le désassemblage du jeu) — base, pas obligation**
- **6F, avec le Scope** : le spectre se révèle : c'est l'âme de la mère d'Osselait, un **Ossatueur N30** (Massd'Os, Rugissement, Groz'Yeux, Puissance). Il **ne peut pas être capturé** (la Ball est déviée). Victoire → « L'âme de la mère s'est apaisée. Elle est partie pour l'au-delà. » Fuir ou perdre laisse le blocage en place.
- **7F** : trois Sbires Rocket inévitables — Nosferapti, Nosferapti, Nosferalto N25 ; Smogo, Soporifik N26 ; Nosferapti, Rattata, Rattatac, Nosferapti N23. Répliques : « Ce vieux est venu se plaindre qu'on maltraite des Pokémon inutiles », « Les Pokémon ne servent qu'à faire de l'argent ! ».
- **M. Fuji** : « Tu es venu me sauver ? Merci. Mais je suis venu ici de mon plein gré, pour apaiser l'âme de la mère d'Osselait. » Il invite le joueur chez lui, au pied de la Tour ; le joueur est **téléporté directement** dans la maison de Fuji.
- **Maison de Fuji** : Fuji remet la **Poké Flûte** (« Ta quête du Pokédex échouera sans amour pour tes Pokémon ») ; Psykokwak et Nidorino recueillis ; une fillette explique qu'il recueille les Pokémon abandonnés et orphelins. Ensuite : « Ma Flûte t'a-t-elle aidé ? ».
- **Poké Flûte** : objet clé. En combat, elle **réveille tous les Pokémon endormis** (des deux côtés). Dans le monde, elle réveille Ronflex (N30, combat sauvage, une seule chance de le capturer).
- **Après le sauvetage** : la fille de la maison d'Osselait dit que le spectre de la Tour est parti, que quelqu'un a apaisé son âme ; un client de la Boutique change de réplique ; Rouge/Bleu modifie aussi en silence quelques PNJ de Safrania.

## Ce que j'attends : la V2 du « dossier 24 — Le retour à la Tour Pokémon »

Rédige-le en français, en sections numérotées, avec les **textes définitifs**. Pour chaque point, tranche ; si tu hésites, propose une valeur par défaut et signale-la. Pour chaque règle, indique si elle suit **Rouge/Bleu (RB)**, **Rouge Feu / Vert Feuille (RFVF)** ou une **invention de Kanto 2026 (K26)**, et pourquoi.

1. **Intention** : ce que le joueur doit ressentir, en deux ou trois phrases (deuil, apaisement, colère contre la Team Rocket, gratitude de Fuji). Comment le jalon s'en distingue du J19, sur les mêmes cartes.
2. **Périmètre et découpage** : ce qui est dedans, ce qui est **explicitement reporté**, puis 2 ou 3 sous-jalons jouables (chacun validé sur téléphone), du moins risqué au plus risqué.
3. **Le retour à Lavanville** : le joueur sait-il qu'il doit revenir (indice après Giovanni, rien du tout, une ligne d'un PNJ) ? Lavanville change-t-elle **avant** le sauvetage (ambiance, PNJ) ? Sans quête ni marqueur.
4. **La Tour avec le Scope** : ce qui change aux étages 1F à 6F (rencontres identifiées, Pokédex, Exorcistes déjà battus, objets). Présentation du **Scope au premier spectre identifié** (mise en scène courte ou rien ?). Faut-il « utiliser » le Scope, ou sa simple possession suffit-elle (hypothèse du J19 : la possession suffit) ?
5. **Ossatueur** — le cœur émotionnel : déclenchement (même case qu'au J19), révélation (le spectre se dissipe : comment, en combien de temps, avec quelle image), règles exactes du combat (capture impossible : quel message ? fuite possible ? défaite ?), ce qui se passe à la victoire (texte, lumière, départ de l'âme), et ce qui se passe si le joueur fuit ou perd. Pokédex : Ossatueur vu ? Ton : jamais macabre, jamais comique.
6. **Le 7F** : agencement général (sans level design détaillé), les trois Rocket (équipes, niveaux, ordre, inévitables ou non), répliques de combat et d'après-combat, argent. Y a-t-il un « chef » ? Le lien avec Giovanni, battu au J20, est-il évoqué ?
7. **M. Fuji** : sa scène au 7F (texte complet), **téléportation comme RB ou retour à pied** ? Son portrait : qui il est pour Kanto 2026 (sans spoiler le post-game ni Mewtwo). Ce qu'il dit du joueur et de ses Pokémon.
8. **La maison de Fuji après le sauvetage** : remise de la Poké Flûte (texte, toast), Pokémon recueillis (lesquels, interactions), répliques de Fuji ensuite, ce que disent les autres habitants. Osselait : le revoit-on, avec qui, et que devient-il (**pas** de don au joueur sans le signaler comme mécanique nouvelle) ?
9. **La Poké Flûte** : usage dans le monde (Ronflex seulement, ou aussi « jouer » ailleurs pour rien ?), usage en combat (règle RB : réveille tout le monde, adversaires compris ; à garder ?), présentation dans le Sac, animation et son. Le **compagnon** réagit-il à la Flûte ?
10. **Ronflex** : le réveil fait-il partie du J21 ? Les routes derrière les deux Ronflex (Routes 12 et 16) n'existent pas encore. Propose : (a) le J21 s'arrête à la Flûte, le réveil arrive avec le jalon de chaque route, ou (b) le J21 conçoit déjà la règle générale du réveil (texte, combat N30, capture en une chance ou nouvelle chance plus tard, que devient la case libérée). Tranche avec une recommandation.
11. **Lavanville et la Tour après le jalon** : PNJ qui changent (liste et textes), ambiance de la ville (lumière, musique, Pokémon d'ambiance) ; la Tour reste-t-elle visitable et que deviennent ses rencontres ; la Médium du rez-de-chaussée ; une récompense discrète pour qui revient ?
12. **Team Rocket et suite de l'aventure** : ce que le J21 dit (ou ne dit pas) de la Sylphe SARL et de Safrania, sans spoiler ; les postes de garde restent-ils fermés (le Thé et l'accès à Safrania appartiennent à un autre jalon) ?
13. **Rival** : RB n'en a pas dans ce passage. Confirme qu'il n'apparaît pas, ou justifie une apparition sans combat.
14. **Compagnon** : comportement dans la Tour (intérieur : sort-il ?), aux cinématiques (règle : il rentre), avec un Osselait ou un Pokémon Spectre en compagnon.
15. **Pokédex, Équipe, Dresseur** : ce qui s'enregistre (Ossatueur vu, espèces des Rocket), ce qui s'affiche de nouveau (Flûte dans les objets clés, profil dresseur).
16. **Données, drapeaux, sauvegarde** : liste des drapeaux (en reprenant `ghost_marowak_calmed`, `fuji_rescued`, `got_poke_flute`), ordre dans lequel ils se posent, cas d'une sauvegarde faite au milieu (après Ossatueur, avant le 7F ; après le 7F, avant la maison). Objectif : **aucun changement de version de sauvegarde** si possible. Rien ne doit être perdu ni bloqué.
17. **Espèces et art nécessaires** : nouvelles espèces dans les données (Ossatueur, Nosferalto, Smogo, Soporifik, Rattatac, Ronflex, Psykokwak…), images peintes nécessaires (portrait et sprite de Fuji, Ossatueur révélé, Sbires, intérieur du 7F, maison de Fuji « habitée »), en restant sobre.
18. **Textes à valider** : tous les textes regroupés et numérotés.
19. **Questions ouvertes** : numérotées, avec ta recommandation pour chacune.
20. **Tableau final « Décisions verrouillées »** (élément | décision), au format de tes V2 précédentes.

**Contraintes de forme** : pas de zone nouvelle hors du 7F (et de la maison de Fuji, déjà construite) ; pas de mécanique nouvelle sans la signaler ; ne rien spoiler (Mewtwo, Fuji et le Manoir Pokémon, post-game) ; textes courts ; garde en tête le coût d'art et la lisibilité sur un écran de téléphone.

---

## Après ChatGPT

Colle sa réponse à Claude : passe d'alignement habituelle (`docs/design/passes/j21-v2-chatgpt.md`
et `j21-v2-alignement.md`) contre `vision.md`, la roadmap, les dossiers et passes des J17 à J20, le
code réel et Rouge/Bleu, avec des arbitrages numérotés à trancher ; puis
`docs/design/dossier-24-tour-pokemon.md`. Le plan technique `docs/tech/jalon-21.md` vient ensuite.

### Points que Claude vérifiera de toute façon (inventaire du 2026-10-14)

- **Combat sauvage lancé par une scène** : l'étape `battle` du `CutsceneDirector` n'accepte que des
  Dresseurs (`cutscene_director.gd`) ; le J19 prévoit de l'étendre pour le SPECTRE. Le J21 en dépend
  (Ossatueur, Ronflex).
- **Capture impossible** et **fuite** pour un sauvage précis : à vérifier dans le moteur (aucun cas
  aujourd'hui hors combats de Dresseurs).
- **Poké Flûte** : le sommeil existe (`StatusRules`, J11), mais **un objet clé n'est jamais
  « utilisé »** aujourd'hui, ni en combat ni dans le monde (`game/items/item_data.gd`) : la Flûte
  sera le premier objet clé utilisable.
- **Téléportation de fin de scène** vers une autre carte : à vérifier (changement de carte par
  cinématique).
- **Espèces** : Ossatueur, Osselait, Fantominus, Spectrum, Smogo, Soporifik, Rattatac, Ronflex,
  Psykokwak absents de `data/pokemon/species/` sur `main` au 2026-10-14 (le J19 en ajoute une
  partie).
- **Sauvegarde** : v6 sur `main`, v7 sur `jalon-15` ; le J21 ne devrait ajouter que des drapeaux.
- **Faits RB** : relevés dans `pret/pokered` (`af51989`) : `parties.asm` (Rocket du 7F),
  `scripts/PokemonTower6F.asm`, `PokemonTower7F.asm`, `MrFujisHouse.asm`, `LavenderCuboneHouse.asm`,
  `LavenderMart.asm`, `engine/items/item_effects.asm` (Ossatueur non capturable).
