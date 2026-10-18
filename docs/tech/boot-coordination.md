# Coordination de Boot

Branche : `refactor/boot-coordination`, base `f0d3c4fb` (J16 terminé).

## Responsabilités

- `Boot` assemble les composants, conserve les contrats publics et capture la position
  au moment de l'écriture. Les règles de stabilité et de permission restent explicites.
- `SaveCoordinator` coalesce les demandes jusqu'à un état stable. Il reçoit trois
  callbacks : permission, stabilité et écriture. Il ne connaît ni autoload ni disque.
  Les écritures immédiates des scènes gardent leur exception de stabilité, mais jamais
  une exception de permission. En cas d'échec : demande conservée, délai de 5 s simulées,
  puis nouvelle tentative sur l'état courant, sans boucler à chaque image.
- `SettingsApplier` reçoit les composants au câblage ; les écrans optionnels créés plus tard
  (évolution, ouverture, décor du titre) sont relus à chaque application. Aucune lecture
  des réglages ni dépendance à Boot.
- `SessionLifecycle` interprète les notifications et calcule le temps de jeu au premier
  plan, hors ouverture, borné à 0,5 s par image.

Aucun nouvel autoload. Pas de changement de contenu, de règles de combat, d'interface
ou de format de sauvegarde. La rotation des fichiers corrompus reste un travail distinct.

## Validation

- Godot 4.7.2 et GUT 9.7.0 : 17 nouveaux tests unitaires, 49 assertions réussies dans
  un projet isolé utilisant les vrais scripts SaveCoordinator et SessionLifecycle.
- Deux nouveaux tests avec le vrai Boot et MemoryFs : reprise après panne sur l'état
  courant et absence d'écriture pendant un dialogue.
- Les tests existants `test_settings_apply`, `test_save_boot`, `test_opening_boot` et
  `test_debug_start_boot` restent les contrats de non-régression.
- Workflow `Godot tests` : import strict puis `tools/test.sh`, logs conservés.
- Avant fusion : vérifier les résultats du workflow et effectuer la validation téléphone
  (reprise v7, menu/réglages, arrière-plan, combat, départ du navire).

## Points de sauvegarde critiques

`CutsceneDirector.save_handler` renvoie Error. Une étape `save` attend OK avant de passer
à la suivante. En cas d'erreur, `save_failed` alimente un toast dans Boot, puis la même
étape réessaie après 5 s. Les effets précédents ne sont pas rejoués. Les écritures passent
toujours par SaveCoordinator et sa garde de permission. Sans gestionnaire : erreur et
arrêt de la scène. Un arrêt de l'application pendant une panne conserve le précédent fichier.

La CI répartit tous les scripts `test_*.gd` en huit lots déterministes. Le diagnostic sur la base f0d3c4fb
a reproduit les deux échecs préexistants ; ce lot temporaire est retiré après comparaison.
Tous les lots de la branche restent bloquants.

## Contrôles portables

Le test de soin conserve sa mesure d'animation en temps simulé, avec une garde réelle
plus large pour les runners lents. Le test du dialogue de Chloé isole les autres
Dresseurs afin que le défi légitime de Gabin ne remplace pas la réplique testée.
Le test de halo utilise le dégradé radial côté CPU en headless, et l'image effective
lorsqu'un serveur de rendu existe ; aucune assertion de shader ou de contraste supprimée.

Inventaire sans modification des combats : `tools/audit_pending_moves.py`, rapport
`docs/tech/audit-pending-moves.md` (15 capacités avec effets en attente).

## Simulation explicite des outils

Un départ de débogage dont autosave=false, ou un Boot d'outil sans SaveSystem injecté,
simule le point critique sans écriture. Ce chemin n'est jamais activé pour une vraie
partie dont le fichier est refusé. Deux tests vérifient la simulation sans écriture et
le refus intact d'une sauvegarde future.
