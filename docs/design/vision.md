# Kanto 2026 — Vision & Constitution

> « Construire le Kanto que notre imagination voyait derrière les pixels de la Game Boy. »

Source : conception menée par Kevin avec ChatGPT (fil « Pokémon en 2D »). Ce document en est la synthèse de référence. **Kevin est le directeur du jeu** : toute décision de design non couverte ici lui revient.

## Cadre

- Remake **personnel** de Pokémon Rouge/Bleu (pas de publication, installation APK directe).
- Plateforme : Android (Galaxy S24, 2340×1080), iOS éventuellement plus tard.
- Moteur : Godot 4.7 + GDScript.

## Principe directeur

> **Philosophie officielle (Kevin, 2026-10-02)** : « Kanto 2026 n'est pas un remake modernisé de Rouge/Bleu. C'est une réinterprétation : conserver l'ADN qui rend l'expérience Pokémon reconnaissable, supprimer les frictions héritées des anciennes contraintes techniques et repenser chaque interaction comme si elle était conçue aujourd'hui pour une expérience mobile moderne, tactile, fluide, accessible et immersive. »

Pour chaque système, la question n'est jamais « comment Pokémon faisait ça ? » mais : **pourquoi Pokémon faisait ça, qu'est-ce qui mérite d'être conservé, et comment le ferait-on mieux aujourd'hui ?** On garde l'ADN (exploration, capture, équipe de 6, quatre capacités, types, évolutions, rival, Pokédex, Arènes, Ligue, découverte de Kanto) ; on ne sacralise pas les anciennes contraintes (menus lourds, navigation répétitive, interfaces pensées pour deux boutons, monde figé).

**Règle de déblocage (Kevin, 2026-10-02)** : une fonctionnalité visible n'existe pas pour le joueur avant son déblocage narratif, mais les données nécessaires peuvent déjà être collectées silencieusement lorsque cela garantit la continuité de son aventure. (Exemple : le Pokédex enregistre depuis le jalon 5 et n'est activé par Chen qu'au jalon 7, `dossier-09-jadielle.md` §6.)

On ne modernise pas Pokémon Rouge/Bleu. **On modernise l'expérience que Rouge/Bleu voulait offrir**, sans les contraintes techniques de la Game Boy.

## Constitution (10 règles)

1. Préserver l'âme de Rouge/Bleu plutôt que ses limitations techniques.
2. Kanto doit être reconnaissable, mais crédible et vivant.
3. Les 151 Pokémon restent au cœur de l'expérience.
4. La 2D est un choix artistique assumé, pas une imitation rétro.
5. L'UI doit sembler conçue pour un smartphone de 2026.
6. Chaque ville a une identité visuelle et sonore reconnaissable sans lire son nom.
7. Les Pokémon existent dans le monde, pas uniquement en combat.
8. La modernisation approfondit l'exploration, elle ne la complique pas.
9. L'histoire originale reste la colonne vertébrale, enrichie par le monde, les PNJ et des intrigues secondaires.
10. Chaque nouveauté répond à : **« Qu'est-ce que cela apporte au plaisir de jouer ? »**

Corollaires : la nostalgie vient du contenu, la modernité vient de sa présentation. Plus grand ne veut pas dire plus intéressant : chaque espace doit avoir une raison d'exister.

## Direction artistique — « 2D HD atmosphérique » (verrouillée)

« Et si Pokémon n'avait jamais abandonné la 2D et avait continué à la perfectionner jusqu'en 2026 ? »

> **Kanto 2026 — 2D HD atmosphérique.** Monde 2D dessiné et extrêmement détaillé, légèrement texturé par le pixel art, proportions stylisées mais crédibles, végétation riche, matériaux identifiables, animations environnementales subtiles et éclairage dynamique moderne.
> **Jamais photoréaliste. Jamais cartoon enfantin. Jamais rétro pour être rétro.**
> **La beauté vient d'abord de l'atmosphère, ensuite du niveau de détail.**

« Réaliste » = **crédible** : un monde stylisé qui n'essaie pas de ressembler à une photo, mais dans lequel on croit. Kanto reste chaleureux et idéalisé, jamais sale.

Trois critères pour toute décision visuelle : **beau immédiatement, crédible quand on l'observe, vivant quand on y reste.**

- **Hybride** : de loin une illustration 2D HD ; de près, la texture et le charme du pixel art. Personnages et Pokémon en pixel art fin (**48–64 px de haut** en natif), environnements 2D haute définition, éclairage et effets modernes par-dessus.
- **Détail** : tuiles de toit, bois, rebords de fenêtres, gouttières, légère usure, plantes. Plusieurs essences d'arbres, pas de répétition visible du même arbre. Toujours **lisible immédiatement** (jeu mobile).
- **La lumière est la signature graphique** (~50 % du résultat). Même lieu, cinq émotions :
  - 07:00 légère brume, lumière froide, rosée
  - 12:30 couleurs franches, ombres courtes, eau brillante
  - 18:45 lumière dorée, ombres longues, ciel orangé
  - 23:30 bleu profond, lune, fenêtres chaudes, lucioles
  - pluie : sol légèrement réfléchissant, gouttes dans les flaques, végétation plus sombre, parapluies
- **Micro-animations partout, mais minuscules** : herbe au vent, feuilles, eau, fumée de cheminée, rideau, Roucool qui tourne la tête, ombres de nuages au sol.
- **Les Pokémon appartiennent au décor** : pattes posées, ombre projetée, couleur qui réagit à la lumière ambiante ; la queue de Salamèche éclaire les éléments proches la nuit.
- **Animations des Pokémon** : idle (respiration, oreilles), marche, course, heureux, blessé, attaque, dégâts, KO, sommeil.
- **Effets modernes** sur la 2D : lumière, brouillard, pluie, particules, reflets, profondeur, léger flou, effets d'attaque.
- **Cohérence avant tout** : un **Art Bible** (tuiles, proportions, niveau de pixelisation, perspective, palette, ombres, contours, matériaux, végétation, eau, éclairage, architecture, animations) doit être fixé **avant** la production d'assets, pour ne pas obtenir « une collection de belles images IA ».
- **UI = PAS pixel art** : typographie moderne, panneaux translucides, icônes vectorielles, microanimations.
- **60 fps** partout. Pas de 3D.

Références visuelles :
- [`reference/da-2026-planche-v1.webp`](reference/da-2026-planche-v1.webp) : **UI validée** (voir [ui-reference.md](ui-reference.md)). Son rendu du monde, plus pixelisé, correspond à l'ancienne DA.
- [`reference/bourg-palette-aplus-v1.png`](reference/bourg-palette-aplus-v1.png) : **benchmark graphique du monde**, Bourg Palette A+ en golden hour. Si une zone paraît moins aboutie, elle n'est pas encore au niveau de Kanto 2026.
- [`reference/chambre-joueur-v1.webp`](reference/chambre-joueur-v1.webp) : **référence de la chambre du joueur** (fournie par Kevin, 2026-09-25) : agencement de la pièce et rendu cible des intérieurs (lumière chaude du soir par la fenêtre, parquet, décor riche, murs visibles).
- [`reference/ouverture-storyboard-v1.webp`](reference/ouverture-storyboard-v1.webp), [`reference/maison-rival-v1.webp`](reference/maison-rival-v1.webp), [`reference/labo-chen-v1.png`](reference/labo-chen-v1.png) : **références des intérieurs** et de l'ouverture (Kevin, 2026-09-25/26). L'Évoli de la maison du rival est une erreur, à ignorer.

Historique : d'abord « C : Pokémon 2D 2026 » en pixel art HD, puis évolution validée vers la 2D HD atmosphérique hybride.

## Contrôles mobiles

- **Paysage**.
- Exploration : zone gauche = joystick qui apparaît au toucher et devient transparent au repos ; droite = bouton contextuel (parler / entrer / examiner) qui n'apparaît qu'à proximité d'un élément interactif ; bouton courir.
- Presque aucune UI visible en exploration. Nom de zone affiché à l'arrivée puis disparaît.
- Combat : entièrement tactile, grands boutons. **Le geste** : on choisit l'attaque, on touche l'adversaire → impact (tremblement, flash, particules). Toujours du tour par tour.

## Monde

- **Échelle A+** (règle officielle) : ≈ 3–4× l'original, chaque espace ajouté apporte du gameplay, de l'atmosphère ou de la narration. Dense plutôt que gigantesque.
- On conserve Kanto, les 151, villes, arènes, Team Rocket, Ligue, personnages et trame.
- Villes plus vivantes, routes = lieux (pas des couloirs), en gardant leur géographie et leur fonction.
- **Rencontres aléatoires conservées** (ADN Gen 1) + Pokémon visibles dans le décor (Roucool sur une clôture qui s'envole, Magicarpe qui saute) — ambiance, pas forcément combattables.
- PNJ avec **routines** selon l'heure ; dialogues qui évoluent avec la progression.
- Narration par le monde (Team Rocket de plus en plus présente, Mewtwo semé discrètement).
- L'équipe existe hors combat : humeur, historique ; le Pokémon de tête suit le joueur.

Identités de villes : Bourg Palette (calme, nature, enfance, lumière chaude) · Jadielle (première vraie ville, commerces, voyageurs) · Argenta (pierre, musée, montagne) · Azuria (eau, canaux, fraîcheur) · Carmin-sur-Mer (port, bateaux) · Lavanville (silence, brume, ancien) · Céladopole (métropole, néons, foule) · Safrania (centre économique et technologique).

## Plan de développement (13 phases)

| # | Phase | Résultat |
|---|---|---|
| 0 | Vision | Bible du jeu (ce dossier) |
| 1 | Prototype visuel | Bourg Palette, personnage, UI exploration, jour/nuit |
| 2 | Moteur d'exploration | Déplacement, collisions, portes, zones, caméra |
| 3 | Interactions | PNJ, dialogues, panneaux, objets, événements |
| 4 | Pokémon | Données, types, stats, niveaux, capacités, évolutions |
| 5 | Combat | Sauvage, dresseurs, dégâts, statuts, XP, animations |
| 6 | Capture | Poké Balls, probabilités, stockage, équipe de 6 |
| 7 | Menus 2026 | Équipe, Pokédex, Sac, Carte, profil, options |
| 8 | Progression | Badges, arènes, objets clés, capacités terrain |
| 9 | Monde | Routes, villes, grottes, Ligue |
| 10 | Ambiance | Jour/nuit, météo, éclairage, eau, particules, audio |
| 11 | Mobile | Gestes, vibrations, optimisation, sauvegarde |
| 12 | Polish | Transitions, équilibrage, performances |
| 13 | Build | APK final |

**Vertical slice (premier objectif)** : maison → Bourg Palette → Prof. Chen → choix du starter → Route 1 → herbes → rencontre sauvage → combat → capture → retour → sauvegarde. Elle doit viser la qualité finale.

**Règle d'or** : une fonctionnalité → test sur le téléphone → validation par Kevin → suivante. Jamais trois systèmes en parallèle.
