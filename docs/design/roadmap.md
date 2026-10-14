# Kanto 2026 — Roadmap globale

> Vue macro du projet, du prologue à la Ligue et au post-game. Validée par Kevin le 2026-09-29.
> Objectif : avancer par **grandes phases** et par **systèmes**, pas route par route, pour ne pas
> découvrir au jalon 12 qu'un système fondamental (Pokédex, économie, sauvegarde…) n'a pas été
> prévu. L'état détaillé et la prochaine étape concrète restent dans [`docs/tech/etat-projet.md`](../tech/etat-projet.md).

## Principe directeur

Construire un jeu dont l'**architecture grandit proprement**, pas un prototype qui accumule des
fonctionnalités. On verrouille d'abord Route 1 et la boucle fondamentale ; on ne conçoit pas dix
villes en avance. Une fois les systèmes principaux posés, on **fabrique du contenu avec ces
systèmes** plutôt que de réinventer le moteur à chaque ville.

**Règle « données avant interface »** : un système commence à **enregistrer ses données dès qu'il
est pertinent**, même si son écran arrive plus tard. Exemple appliqué dès le jalon 5 : le Pokédex
enregistre `seen` / `caught` et les persiste dans la sauvegarde ; l'écran Pokédex du jalon 6 n'est
alors qu'une interface sur des données déjà collectées, jamais un système greffé après coup.

## Phases

### Phase 1 — Fondations du jeu (J0 → J4) — ✅ terminé
Déplacement, caméra, collisions, interactions, bâtiments/intérieurs, PNJ, dialogues, cinématiques,
données Pokémon, starter, moteur de combat, première UI de combat. Résultat : prologue jouable
jusqu'au premier combat.

### Phase 2 — Boucle Pokémon fondamentale (J5) — ✅ terminé
- **5A** — la carte de la Route 1
- **5B** — rencontres sauvages (le combat du 4B réutilisé en extérieur, « le monde devient la scène »)
- **5C** — XP / niveaux / apprentissage de capacités
- **5C.5** — **sauvegarde** (avant la capture : fermer/relancer l'app restaure équipe, XP, sac, progression, position)
- **5D** — première capture
- **5E** — défaite sauvage → fondu → réveil à Bourg Palette, Pokémon soignés par Maman
- **5F** — QA complète « joueur » (scénario de bout en bout, 60 fps, sans perte de données)

À la fin : **Explorer → rencontrer → combattre → gagner de l'XP → capturer → sauvegarder → continuer.**
Le cœur de Pokémon fonctionne.

### Phase 3 — Le système joueur (J6) — Menu principal — ✅ terminé
Avant d'étendre Kanto. Chaque entrée du menu devient un vrai système (UI 2026, pas une boîte texte) :
- **6A Équipe** : Pokémon possédés, PV, niveau, XP, types, capacités, stats, ordre de l'équipe, examen.
- **6B Sac** : catégories (objets, soins, Poké Balls, CT, objets clés), quantité, description, UTILISER.
  **Le même Sac en exploration et en combat**, pas deux systèmes.
- **6C Pokédex** : Vu / Capturé (données déjà collectées depuis le J5) ; plus tard habitat, taille,
  description, formes, évolutions découvertes, zones observées.
- **6D Carte** : Bourg Palette, Route 1, Jadielle, puis Kanto se dévoile. Comprendre le monde, pas
  une checklist de `?`.
- **6E Profil dresseur** : nom, avatar, temps de jeu, Pokédex, badges, argent ; plus tard Ligue, stats.
- **6F Paramètres** : audio, musique, vibrations, vitesse du texte, accessibilité, commandes,
  perfs. Accessibilité pensée dès ici, pas à la fin.

### Phase 4 — Premier hub (J7) — Jadielle — ✅ terminé
- **Centre Pokémon** : soin + animation ; **point de retour après défaite** (dernier Centre utilisé,
  plus systématiquement Maman à partir d'ici).
- **Boutique** : premiers achats (Poké Balls, Potions, antidotes…).
- **Économie** : argent, prix, achats, ventes, récompenses des combats de Dresseurs.

### Phase 5 — Route 2 / Forêt de Jade (J8 – J9) — ✅ terminé (J8 le 2026-10-07, J9 le 2026-10-08)
Nouveaux Pokémon, premiers vrais Dresseurs, poison / antidotes, plus d'objets, capture plus
intéressante, équipe qui se construit, premier apprentissage de nouvelles capacités, premières
évolutions selon les niveaux.
- **Poison seul au J9** (décision de Kevin, 2026-10-06, dossier 10) : persistant après le combat,
  **aucun dégât en marchant**, guéri par Antidote ou Centre. Les autres statuts arrivent au J11.
- **Premières évolutions au J9** : séquence simple mais propre et **définitive fonctionnellement**,
  avec annulation ; le J11 n'enrichit que la mise en scène, sans refaire la logique métier.
- **Contraintes de la Route 2 (J8)** : **aucun Dresseur avant la Forêt de Jade** (le Scout Théo
  reste le premier vrai Dresseur) ; la Route 2 est **interrompue par la forêt** et ne permet pas
  de la contourner lors de la première progression.
- **Forêt de Jade : vue générale peinte validée** par Kevin (2026-10-07,
  `reference/foret-jade-vue-generale-v1.png`, dossier 10) ; la grille du jeu fait foi pour la
  géométrie.
- **J9 terminé** (2026-10-08) : forêt agrandie à 70 × 90 (Théo et Milo inévitables), 5 Dresseurs,
  poison, premières évolutions ; la porte nord du poste nord attend la Route 2 nord (J10).

### Phase 6 — Argenta + première Arène (J10) — ✅ terminé (2026-10-10)
Ville d'Argenta (musée, habitants, Centre, Boutique, Arène). **Système de badges** : victoire →
Badge Roche → profil dresseur mis à jour, progression narrative, réactions des PNJ. Première grande
boucle longue : Bourg Palette → routes → captures → ville → préparation → Arène → badge.

### Phase 7 — Systèmes avancés Pokémon (J11) — grande passe avant d'étendre Kanto — ✅ terminé (2026-10-13)
- **Évolutions** : la logique et une séquence propre existent depuis le J9 ; ici, présentation
  enrichie (montée de niveau → « Salamèche évolue ! », animation 2026,
  annulation possible, nouvelles stats, Pokédex).
- **CT** : trouver, Sac → CT, Pokémon compatibles, apprentissage.
- **Statuts complets** : paralysie, sommeil, brûlure, gel, et système général des statuts
  (le poison existe depuis le J9).
- **Changement de Pokémon en combat** (équipe → choisir → transition).
- **Compagnon Pokémon** : sortir de sa Ball et suivre le joueur, proprement (comportements par
  espèce, vitesse, obstacles, intérieurs, réactions, animations, rappel automatique, interactions).
  Pas un sprite collé derrière le joueur.
- **J11 terminé** (2026-10-13) : sauvegarde v6 (identifiant de Pokémon, compagnon), paralysie,
  sommeil, brûlure, gel, confusion et effets simples (multi-coups, apeurement…), remèdes, CT et
  CT34 Patience remise par Pierre, évolution courte (≈ 6 s, accélérable), compagnon qui suit le
  joueur dehors ; **lot d'art partiel** : 3 planches sur 5 (Herbizarre, Carabaffe, Papilusion),
  Reptincel et Pikachu en attente (12 espèces éligibles).

### Phase 8 — Kanto devient un monde (J12+)
- **J12 terminé** (2026-10-14, après validation de Kevin) : Route 3 (six Dresseurs, objet
  caché), Centre du Mont Sélénite, Mont Sélénite sur trois étages (gravats, échelles, lumière
  rare, Corde Sortie), Team Rocket (trois Sbires qui partent après leur défaite), chercheur
  Gaspard et choix définitif d'un fossile (Grand moment), Pierre Lune et évolution par pierre,
  CT01, sas de la Route 4 ; moteur : drain, piège, Entrave, Repos, Destruction ; sauvegarde
  inchangée (v6).
Les systèmes principaux existent : on produit le contenu. Mont Sélénite, Azuria (Léo), Carmin-sur-Mer
(Major Bob), Océane, Lavanville, Céladopole (Erika), Team Rocket, Safrania (Morgane), Parmanie (Koga),
Cramois'Île (Auguste), Jadielle finale (Giovanni), Route Victoire, Ligue.

### Phase 9 — Fin de jeu
Conseil 4, Rival Maître, générique, retour à Bourg Palette, monde post-Ligue (Champions améliorés),
Grotte Azurée / Mewtwo, puis le mystère Mew.

## Jalons narratifs à ne pas oublier

### Team Rocket (décision de Kevin, 2026-10-06)
- La **Team Rocket fait partie de l'aventure** de Kanto 2026 : à prévoir dans la conception de
  chaque jalon concerné, en particulier **Argenta (J10), Route 3 et Mont Sélénite (J12+)**.
- **Rythme de Rouge/Bleu conservé** : Bourg Palette → Route 1 → Jadielle → Route 2 → Forêt de Jade
  → Argenta → Route 3 → **Mont Sélénite = première véritable apparition et premiers combats** contre
  la Team Rocket.
- **Avant le Mont Sélénite : aucune confrontation directe** avec la Team Rocket (ni à Bourg Palette,
  ni à Jadielle, ni en chemin).
- **Non décidé, à ne pas inventer ni verrouiller** : la manière dont Kanto 2026 modernise la Team
  Rocket (personnages, activités, narration). À demander à Kevin lors de la conception de ces jalons.
- Pour mémoire, le dossier 06 (§4) prévoit déjà une présence progressive (« l'influence se ressent
  avant l'affrontement ») ; ce qui précède le Mont Sélénite reste à concevoir avec Kevin.
- Il s'agit d'un **jalon narratif**, pas d'une demande d'implémentation.

### Trajectoire du rival (décision de Kevin, 2026-10-06)
Référence actuelle : la structure de Rouge/Bleu, **8 combats majeurs** contre le rival pendant
l'histoire principale. À reprendre à la conception de chaque jalon concerné.

| # | Lieu | État |
|---|---|---|
| 1 | Laboratoire de Chen — Bourg Palette | fait (J4) ; dossier 02 |
| 2 | Route 22 — près de Jadielle | prévu au J7B ; dossier 09 §13–15 (rencontre facultative) |
| 3 | Azuria / Pont Pépite | **fait (J13, 2026-10-14)** ; dossier 16 §7 : **victoire obligatoire**, rejouable après défaite ; Roucoups, Rattata, starter évolué |
| 4 | S.S. Anne — Carmin-sur-Mer | à concevoir |
| 5 | Tour Pokémon — Lavanville | à concevoir ; tournant du rival déjà posé au dossier 06 §6 |
| 6 | Sylphe SARL — Safrania | à concevoir |
| 7 | Route 22 — avant la Ligue Pokémon | à concevoir |
| 8 | Plateau Indigo — combat final contre le rival devenu Maître de la Ligue | à concevoir ; dossier 06 §6 « Final », phase 9 ci-dessus |

- **Chaque combat contre le rival est enregistré comme un Grand moment, victoire comme défaite**
  (précision du 2026-10-11, dossier 16 D-5 : pour un combat **obligatoire et rejouable**, comme le n° 3,
  un seul Grand moment, écrit à la victoire)
  (décision existante : `rival_battle` avec son issue, jalon 5 et jalon 6 §6E).
- **Non décidé, à ne pas verrouiller** : équipes, niveaux, dialogues, mises en scène et
  adaptations propres à Kanto 2026 de chaque combat. Décidés avec Kevin à la conception du jalon.
- Restent valables les décisions déjà prises : progression de son IA (dossier 05, dossier 09 §14),
  arc narratif et tournant de Lavanville (dossier 06 §6), états gagné / perdu / pas affronté comme
  mémoire du monde, jamais comme branches (dossier 09 §15).
- Jalon narratif à ne pas oublier, **pas une demande d'implémentation**.

## Ordre immédiat

```
J5  Route 1 + boucle Pokémon
J6  Menu / Équipe / Sac / Pokédex / Carte / Profil
J7  Jadielle + Centre + Boutique + économie
J8  Route 2
J9  Forêt de Jade
J10 Argenta + Arène Pierre + Badge
J11 Grande passe systèmes (évolutions / CT / statuts / équipe avancée / compagnon)
J12 Route 3 + Mont Sélénite (dossier 15)   ✅
J13 Route 4 + Azuria + Ondine + rival n° 3 + Pont Pépite (dossier 16)   ✅
J14 Route 25 + Cap d'Azuria + Léo + cambriolage (dossier 17)   ← ICI
J15 Route 5 + Pension + souterrain + Route 6 + Carmin-sur-Mer (dossier 18)   (en cours, en parallèle)
J16 S.S. Anne + rival n° 4 + Coupe + Major Bob + Badge Foudre (dossier 16, branche `ccr-fa255d49-wvvacc`)
J17+ Suite de Kanto → Ligue → post-game
```

J11 à J15 sont conçus et développés **en parallèle**, une session par jalon (2026-10-11) ;
l'intégration d'un jalon attend seulement les systèmes qu'elle utilise.
