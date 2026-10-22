# J19 — Les mystères de la Tour Pokémon : V2 de ChatGPT (reçue le 2026-10-14)

> Reproduite telle que Kevin l'a transmise (les schémas et tableaux vides de la mise en page
> d'origine ne sont pas reproduits). Passe d'alignement : `j19-v2-alignement.md`.

Dossier de conception V2 · 7 arbitrages validés · Audit technique à réaliser par Claude

État d'avancement : J18 est consolidé sur le plan de la conception. Les sept décisions de J19 sont
maintenant verrouillées. Nous pouvons préparer sa transmission à Claude et définir les frontières de
J20.

J19 doit être un jalon narratif fort : le joueur découvre que la Tour Pokémon est à la fois un lieu
de mémoire, un habitat de Pokémon Spectre et le théâtre d'événements inquiétants. Mais il ne peut pas
encore résoudre tous ses mystères.

## 1. Les décisions définitives

| Sujet | Décision validée |
|---|---|
| Périmètre | Exploration partielle de la Tour Pokémon |
| Rival | Cinquième combat, victoire obligatoire |
| Atmosphère | Mystérieuse, émouvante et respectueuse |
| Pokémon sauvages | Fantominus et Spectrum, selon les tables historiques |
| Ossatueur | Rencontre lors du retour avec le Scope Sylphe |
| M. Fuji | Disparu, sauvetage après obtention du Scope |
| Team Rocket | Indices et présence suggérée ; confrontation finale plus tard |

Conséquence structurante : J19 ne donne ni le Scope Sylphe ni la Poké Flûte. Le joueur devra se
rendre à Céladopole pour obtenir le premier, puis revenir à Lavanville pour secourir M. Fuji et
recevoir la seconde.

## 2. Déroulement narratif J19

1. **Retour à Lavanville.** Les habitants évoquent la disparition de M. Fuji. Le joueur apprend
   qu'il s'intéressait à des activités suspectes dans la Tour.
2. **Entrée dans la Tour Pokémon.** Le rez-de-chaussée déjà accessible au J18 sert de transition.
   Des visiteurs viennent rendre hommage à leurs Pokémon disparus.
3. **Cinquième combat contre le rival.** Le rival apparaît dans la partie basse de la Tour. Sa
   présence et ses dialogues traduisent une évolution de son personnage.
4. **Exploration des étages accessibles.** Le joueur rencontre des exorcistes, découvre Fantominus
   et Spectrum et observe des manifestations spectrales.
5. **Le mystère du spectre.** Un esprit impossible à identifier bloque la progression. Sans Scope
   Sylphe, le joueur ne peut pas atteindre les étages supérieurs.
6. **Une nouvelle piste.** Des indices orientent le joueur vers la technologie Sylphe et les
   activités de la Team Rocket à Céladopole, sans flèche d'objectif ni marqueur de quête.

La fin de J19 doit laisser une question ouverte : qu'est-ce qui empêche réellement le joueur de
monter plus haut ?

## 3. La Tour Pokémon : organisation des étages

Je recommande de conserver la structure historique de la Tour, avec sept niveaux au total, mais de
limiter l'exploration de J19 aux niveaux inférieurs.

| Niveau | Contenu |
|---|---|
| Rez-de-chaussée | Déjà ouvert au J18, visiteurs et mémorial |
| 2e niveau | Cinquième combat contre le rival |
| 3e niveau | Premiers phénomènes spectrals, exorcistes |
| 4e niveau | Exploration, combats, objets |
| 5e niveau | Zone de purification et repos, si confirmée par l'audit |
| 6e niveau | Progression bloquée par le spectre non identifié |
| 7e niveau | Inaccessible avant le retour avec le Scope Sylphe |

Point de conception important : les cartes des niveaux bloqués peuvent être préparées en amont, mais
les événements d'Ossatueur, de la Team Rocket et de M. Fuji ne doivent pas se déclencher au J19.

La barrière doit être narrative et mécanique : un spectre empêche le joueur de continuer. Il ne faut
pas inventer une porte verrouillée qui n'existe pas dans la logique de Rouge/Bleu.

## 4. Le rival : cinquième affrontement

Ce combat est obligatoire et sa victoire doit être persistée dans la sauvegarde.

Proposition de mise en scène : le rival conserve son caractère compétitif, mais son discours devient
plus nuancé. Il ne faut pas le transformer soudainement en personnage sentimental ni réécrire
excessivement sa personnalité.

Le dialogue doit évoquer la présence de Pokémon Spectre et son propre parcours, sans imposer une
interprétation unique de son histoire.

Pour les équipes, Claude devra reprendre les trois variantes liées au starter du joueur et vérifier
la continuité avec les quatre affrontements précédents.

En cas de défaite, le joueur revient au dernier Centre Pokémon utilisé et peut retenter le combat.
Aucun drapeau de victoire n'est posé avant une victoire réelle.

## 5. Fantominus, Spectrum et les spectres non identifiés

- **Fantominus** : rencontre sauvage principale de la Tour.
- **Spectrum** : plus rare, à des étages et niveaux cohérents avec les données historiques.

Il faut distinguer deux situations :

- Rencontre avec un Pokémon Spectre identifiable : les règles exactes sans Scope Sylphe doivent être
  vérifiées contre Rouge/Bleu avant implémentation.
- Rencontre avec le spectre d'Ossatueur : l'identité reste cachée et la progression est impossible
  sans Scope Sylphe.

Nous devons éviter d'implémenter Fantominus et Spectrum comme de simples rencontres ordinaires si cela
contredit le fonctionnement retenu pour le Scope.

Le système de spectre non identifié doit être réutilisable, sans créer une espèce Pokédex
artificielle.

## 6. Direction artistique et sonore

La Tour doit être calme, presque solennelle.

Je recommande des pierres gris violacé, une lumière douce, des monuments funéraires discrets et des
animations très limitées : une flamme de bougie, un léger mouvement de brume, quelques particules.

Les sprites restent dans le style HD peint du jeu, sans contours noirs et sans pixel art.

La musique peut reprendre l'esprit mélancolique de Lavanville, mais avec une ambiance intérieure plus
feutrée. Les sons de pas et les silences doivent contribuer à l'atmosphère.

Aucun effet d'horreur agressif, aucun jumpscare.

## 7. Dépendances techniques et risques

| Référence | Dépendance | Risque |
|---|---|---|
| J19-A | Tour, rez-de-chaussée J18 | Transitions et positions de retour |
| J19-B | Rival, combats précédents | Mauvaise variante d'équipe ou victoire non persistée |
| J19-C | Système de rencontres | Gestion des spectres sans Scope |
| J19-D | Données Pokémon | Fantominus, Spectrum, capacités et immunités |
| J19-E | Éclairage et ambiance | Lisibilité des étages et performances S24 |
| J19-F | Sauvegarde | Dresseurs, objets, rival et état du blocage |
| J19-G | Scope Sylphe futur J20 | Activation ultérieure sans casser les sauvegardes J19 |
| J19-H | Retour à la Tour | Ossatueur, Rocket et M. Fuji réservés à un jalon ultérieur |
| J19-I | Assets CB.3 | Fonds de combat intérieurs propres à la Tour |

Trois points à auditer impérativement :

1. **Les rencontres sans Scope Sylphe.** Dans Rouge/Bleu, le comportement des spectres non identifiés
   est particulier. Claude doit vérifier les règles historiques exactes avant de proposer une
   adaptation.
2. **La cinquième équipe du rival.** Elle doit dépendre du starter, respecter la continuité des
   affrontements précédents et rester cohérente avec le niveau de progression atteint.
3. **Le retour après J20.** La Tour ne doit pas nécessiter une reconstruction ou une migration risquée
   lorsque le Scope Sylphe sera obtenu. Les événements doivent être conditionnés par les bons drapeaux
   dès leur conception.

## 8. Découpage de production J19

| Lot | Contenu |
|---|---|
| 19.0 | Audit de la Tour, des spectres et des variantes du rival |
| 19A | Étages, transitions, monuments et PNJ |
| 19B | Cinquième combat du rival |
| 19C | Rencontres spectrales et exorcistes |
| 19D | Blocage narratif et mécanique sans Scope |
| 19E | Indices vers Céladopole et préparation du retour |
| 19F | QA Galaxy S24 et tests de sauvegarde |

Critère de validation : le joueur peut explorer les étages autorisés, vaincre le rival, rencontrer
les phénomènes spectrals et découvrir le blocage, mais ne peut ni atteindre M. Fuji ni recevoir la
Poké Flûte.

## 9. Message transmis à Claude

Nous avons validé les sept arbitrages suivants :

1. Tour Pokémon partiellement explorable au J19 ; Scope Sylphe obtenu à Céladopole au J20.
2. Cinquième combat contre le rival, victoire obligatoire.
3. Atmosphère mystérieuse, émouvante et respectueuse.
4. Fantominus et Spectrum selon les tables historiques.
5. Rencontre et résolution du spectre d'Ossatueur uniquement après obtention du Scope Sylphe.
6. M. Fuji disparu ; sauvetage réservé au retour avec le Scope.
7. Team Rocket suggérée par des indices, sans confrontation finale au J19.

Contexte : J18 a ouvert Lavanville et le rez-de-chaussée de la Tour Pokémon.

Objectif J19 : développer l'exploration partielle de la Tour, le cinquième combat contre le rival,
les phénomènes spectraux et le blocage narratif qui conduit le joueur vers Céladopole.

Audits obligatoires :

- Vérifier le dépôt, la roadmap, les dossiers précédents et la numérotation documentaire.
- Reconstituer fidèlement les sept niveaux historiques de la Tour Pokémon et leurs connexions.
- Vérifier les règles exactes de Rouge/Bleu concernant les rencontres spectrales sans Scope Sylphe :
  identification, combat, fuite et capture. Ne pas supposer que Fantominus et Spectrum sont
  normalement capturables avant le Scope.
- Vérifier la position du rival, ses variantes d'équipe selon le starter et les niveaux cohérents
  avec nos combats précédents.
- Vérifier la position historique du spectre d'Ossatueur et le blocage associé.
- Préparer les événements conditionnels du futur retour avec Scope Sylphe sans les activer au J19.
- Vérifier les exorcistes, les zones de repos, les objets et les rencontres.
- Préparer les PNJ, dialogues et indices menant vers Céladopole.
- Définir les drapeaux de sauvegarde, les transitions et les tests de non-régression.
- Lister les assets requis : Fantominus, Spectrum, environnements de Tour, fonds de combat peints
  CB.3, animations et ambiance sonore.
- Prévoir la QA sur Galaxy S24.

Contraintes : direction artistique 2D HD peinte, caméra top-down orthogonale, sans pixel art,
isométrie, minimap ou flèche d'objectif. Respecter les décisions validées. Signaler toute
contradiction avec les données historiques ou l'architecture réelle avant de proposer un changement.
Produire d'abord une passe d'alignement numérotée, puis le dossier détaillé après validation. Ne pas
coder. Utiliser une branche documentaire indépendante. Nous préparons J20 en parallèle.
