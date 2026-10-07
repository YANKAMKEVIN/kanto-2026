# Prompt ChatGPT — dossier 12 : Argenta et l'Arène de Pierre

> Préparé par Claude le 2026-10-07, à coller dans ChatGPT pour concevoir **Argenta, la Route 2 nord,
> l'Arène de Pierre et le système de badges** (jalon 10 de la roadmap). Joindre à ChatGPT :
> `docs/design/reference/jadielle-vue-generale-v1.webp`, `docs/design/reference/route-2-vue-generale-v1.png`,
> `docs/design/reference/centre-pokemon-v1.webp`, `docs/design/reference/boutique-jadielle-v1.webp`
> et `docs/design/reference/combat-v1.webp` (**ambiance et DA seulement**). Coller aussi, si possible,
> le dossier 10 (`docs/design/dossier-10-foret-de-jade.md`) : Argenta est atteinte par sa sortie nord.
> Le texte entre les deux lignes est le prompt.

---

Tu m'aides à concevoir **Argenta et sa première Arène** pour *Kanto 2026*, mon remake personnel de Pokémon Rouge/Bleu en 2D HD peinte, sur smartphone (Android, paysage, déplacement case par case). Je suis le directeur du jeu ; un autre assistant (Claude) implémente à partir de ton dossier. Il a besoin d'un dossier **complet, précis et sans ambiguïté** : tout ce que tu ne tranches pas, il devra me le redemander.

## Ce qui est déjà décidé dans le projet (à respecter, ne pas remettre en cause)

- **Esprit** : « comme si Pokémon n'avait jamais quitté la 2D ». On reconnaît Rouge/Bleu, enrichi, jamais remplacé. On garde l'ADN, on supprime les frictions héritées de la Game Boy. Chaque nouveauté répond à : « qu'est-ce que cela apporte au plaisir de jouer ? »
- **Rythme historique** : Bourg Palette → Route 1 → Jadielle → Route 2 → Forêt de Jade → poste nord → **Route 2 nord → Argenta** (jalon 10) → Route 3 → Mont Sélénite (jalon 12 et plus). Entre les deux, le **jalon 11** est une grande passe de systèmes (CT, statuts complets, compagnon Pokémon, mise en scène des évolutions).
- **Identité d'Argenta** (constitution) : **pierre, musée, montagne**. Chaque ville doit être reconnaissable sans lire son nom.
- **Échelle A+** : environ 3 à 4 fois l'original, mais **dense plutôt que gigantesque** ; chaque espace ajouté apporte du gameplay, de l'atmosphère ou de la narration. Jadielle mesure 56 × 36 cases et compte environ 6 habitants significatifs.
- **Grille** : 1 case ≈ 1 mètre ; déplacement **case par case, à angles droits seulement**, aucune diagonale. Écran ≈ 11 cases de haut et ≈ 24 de large. Rebords franchissables vers le sud seulement (raccourcis de retour).
- **PNJ** : une petite routine plutôt que planté, quand ça a du sens. **Aucun PNJ guide ni marqueur d'interface** : l'architecture fait reconnaître le Centre, la Boutique et l'Arène. Aucun PNJ omniscient : un personnage ne sait que ce qu'il a vécu. **Aucune faune non-Pokémon.** Règle des lieux : nature dense, objets rares, espaces vides gardés.
- **Pas de tutoriel** quand un système peut se découvrir naturellement. Pas de checklist, de pourcentage d'histoire ni de GPS.
- **Objectif du tableau de bord** : une ligne discrète, mise à jour en silence (jamais de fenêtre « OBJECTIF MIS À JOUR »). Actuel : « continuer vers le nord. », vrai jusqu'à Argenta.
- **Centre Pokémon** (existe à Jadielle) : soin en ≈ 3 s, **le dernier Centre utilisé devient le point de retour après une défaite** (toast « Point de repos enregistré — Jadielle » la première fois), Stockage Pokémon accessible seulement dans un Centre, sauvegarde automatique au soin.
- **Boutique** (existe à Jadielle) : ACHETER / VENDRE dans une interface tactile. **Jamais d'objet pour une mécanique qui n'existe pas encore.** Au jalon 10, seuls existent le **poison** (statut) et l'**Antidote** : paralysie, sommeil, brûlure et gel arrivent au jalon 11. Stock de Jadielle : Poké Ball (200 ₽), Potion (300 ₽), Antidote (100 ₽) depuis la Forêt de Jade.
- **Économie** : seuls les Dresseurs donnent de l'argent ; **aucune perte d'argent à la défaite** (réveil au dernier Centre, c'est la seule conséquence).
- **Combat** : tour par tour classique, 1 contre 1, 4 capacités, types, **combat dans le décor où l'on se trouve** (pas de fond générique), SAC utilisable contre les Dresseurs, changement de Pokémon, bilan d'XP en fin de combat, évolutions depuis le jalon 9. Transition de Dresseur : il te voit → « ! » → s'approche → quelques mots → combat. **IA progressive** : débutants simples, « Champion : stratégie propre à son identité ». **Pas de nouvelle mécanique de combat au jalon 10** (pas de capacité qui piège, pas de Patience/Bide, pas de nouveaux statuts).
- **Pierre, première leçon de Dresseur : « comprendre les types »** (dossier 06). Premier vrai test, **sans tutoriel**. Plus difficile avec Salamèche : « Vas-tu utiliser ton starter pour tout ? »
- **Badges** : les 8 badges sont déjà dans les données (« Badge Roche — Argenta — Pierre »). L'écran Dresseur a 8 emplacements ; un badge inconnu ne montre ni son nom ni son apparence ; toucher un badge obtenu affiche nom, ville, Arène, Champion (et plus tard l'équipe au moment de la victoire). Le journal « Grands moments » s'enregistre automatiquement (départ, premier Pokémon, première capture, arrivées, combats du rival…).
- **Capacités d'exploration** (ex-CS : Coupe, Flash…) : utilisables dans le monde **sans occuper d'emplacement de capacité**, mais **aucune n'existe encore**. Un obstacle « pour plus tard » est **visible mais fermé**, justifié dans le monde par une simple réplique.
- **Team Rocket** : première vraie apparition et premiers combats **au Mont Sélénite**. **Avant : aucune confrontation directe.** L'influence peut se ressentir avant (rumeurs…), mais la manière dont Kanto 2026 modernise la Team Rocket **n'est pas décidée** : propose, je trancherai.
- **Rival** : 8 combats majeurs comme dans Rouge/Bleu ; le n° 2 vient d'avoir lieu sur la Route 22 et le n° 3 est à Azuria. **Pas de combat contre le rival à Argenta.** Il a « toujours une longueur d'avance » et prend ses badges vite.
- **Déjà vécu par le joueur en arrivant** : starter (Bulbizarre, Salamèche ou Carapuce), Route 1 (Roucool, Rattata), Route 22 (Nidoran ♀ et ♂, Férosinge, Piafabec), Route 2 (Férosinge rare), Forêt de Jade (Chenipan, Aspicot, leurs évolutions, Pikachu rare ; 5 Dresseurs, IA simple ; poison ; premières évolutions). Équipe probablement autour du **niveau 10–12**. La sortie nord du poste de la forêt mène aujourd'hui à « ROUTE 2 NORD — À venir ».
- **Direction artistique** : 2D HD peinte, lumière de fin d'après-midi (« golden hour »), personnages et Pokémon peints simplifiés. Chaque nouvelle espèce coûte des données **et** un sprite peint : en ajouter peu, et seulement si elles servent.
- **Textes** : courts, adaptés à un téléphone (bulles de 2 lignes de ~40 caractères).

## Ce que j'attends : le « dossier 12 — Argenta »

Rédige-le en français, en sections numérotées, avec les **textes définitifs** des PNJ, panneaux et Dresseurs. Pour chaque point, tranche ; si tu hésites, propose une valeur par défaut et signale-la.

1. **Intention** : ce que le joueur doit ressentir à Argenta et en sortant de l'Arène ; ce qui distingue Argenta de Jadielle. Le jalon 10 ferme la « première grande boucle » (routes → captures → ville → préparation → Arène → badge) : comment le joueur le sent-il ?
2. **Périmètre** : Route 2 nord, Argenta, Centre, Boutique, Musée, Arène, autres intérieurs éventuels. Pour chacun : maintenant ou plus tard.
3. **Route 2 nord** : rôle (simple sas ou vrai lieu ?), taille, tracé ASCII à angles droits, hautes herbes et rencontres (espèces, niveaux, %), PNJ, objets, et ce qui reste **visible mais fermé** (Rouge/Bleu y a un passage vers la Grotte Taupiqueur et une maison d'échange : garde-les ou non, en signalant toute mécanique nouvelle, par exemple l'échange).
4. **Argenta — structure** : plan logique en micro-zones (ASCII, angles droits, pas au pixel), taille approximative en cases, entrées et sorties (sud depuis la Route 2 nord, est vers la Route 3 et le Mont Sélénite, qui affiche « ROUTE 3 — À venir » en développement), place du Musée, de l'Arène, du Centre, de la Boutique, et la vue sur la montagne.
5. **Arrivée** : première impression (titre, éventuelle micro-scène muette de quelques secondes comme à Jadielle, ce qu'on voit en premier).
6. **Habitants** : qui (environ 6 significatifs), où, routine, répliques avant **et après** le badge (le monde réagit à la victoire). Pokémon des habitants et Pokémon d'ambiance : lesquels (sans multiplier les espèces).
7. **Le Musée** : contenu (fossiles, Pierre Lune…), entrée payante ou non (Rouge/Bleu : 50 ₽), salles, PNJ, ce qui reste fermé pour plus tard (Rouge/Bleu : l'Ambre Vieille par la porte arrière). Peut-il **semer le mystère scientifique** de l'aventure (Mewtwo, Mew) sans rien révéler ? Une éventuelle rumeur liée à la Team Rocket : propose, sans confrontation et en me disant si elle est nommée.
8. **Centre et Boutique d'Argenta** : différences avec ceux de Jadielle, ou même modèle (comme une enseigne) ? **Stock de la Boutique** (rappel : rien pour une mécanique absente au jalon 10 ; si tu veux la Corde Sortie, signale-la comme mécanique nouvelle).
9. **Accès à la Route 3 avant le badge** : dans Rouge/Bleu, un gamin bloque la sortie est et t'emmène à l'Arène. Garde, modernise ou supprime ce verrou ? Il ne doit être ni condescendant ni un faux obstacle à justifier plus tard.
10. **L'Arène** : architecture et ambiance (pierre, roche), plan intérieur ASCII, éventuel parcours ou « énigme » légère (**sans mécanique nouvelle**, ou signale-la), Dresseurs de l'Arène (nom, champ de vision, équipe, niveaux, récompense en ₽, répliques avant / après), et le « guide d'Arène » de Rouge/Bleu : garde-le ou non, sachant que Pierre doit enseigner les types **sans tutoriel**.
11. **Pierre** : personnalité, répliques (avant, pendant éventuellement, victoire, défaite du joueur, après le badge), **équipe exacte** (espèces, niveaux, 4 capacités au plus chacune, **uniquement des mécaniques existantes** : dégâts, baisse ou hausse de statistiques, pas de piège ni de Patience), stratégie de son IA en quelques règles simples, objets en combat ou non, récompense en ₽. Vérifie que **chaque starter a une réponse accessible** avant Argenta (espèces des Routes 1, 22, 2 et de la forêt), et que Salamèche reste plus exigeant sans être bloquant.
12. **Défaite contre Pierre** : texte, retour au dernier Centre, ce qui se passe si on revient (Pierre redit-il tout ? les Dresseurs de l'Arène déjà battus restent-ils battus ?).
13. **Remise du badge** : mise en scène (courte, pas une cérémonie de 30 s), ce que le joueur voit et ressent (caption « BADGE ROCHE » ?), toast, Grand moment, mise à jour de l'écran Dresseur. **Que fait le badge en jeu ?** Dans Rouge/Bleu : Attaque augmentée en secret, Flash hors combat, obéissance des Pokémon échangés. Propose un effet clair et moderne, ou aucun effet mécanique, en le justifiant.
14. **La CT de Pierre** : dans Rouge/Bleu, il donne une CT. Les CT n'existent qu'à partir du **jalon 11**. Propose : pas de CT au jalon 10 (et comment la rattraper au jalon 11 pour une partie déjà au-delà d'Argenta), une CT remise mais inutilisable (contraire à la règle « rien pour une mécanique absente »), ou autre chose.
15. **Rival** : présence indirecte seulement (une réplique de Pierre ou d'un habitant qui dit qu'il est passé avant toi ?), ou absence totale.
16. **Objectif du tableau de bord** : les lignes à afficher de l'arrivée à Argenta jusqu'après le badge (« continuer vers le nord. » doit être remplacé).
17. **Ambiance** : lumière, sons, musique (intention, sans implémentation), matériaux d'Argenta, repères visuels.
18. **Données et sauvegarde** : ce qu'il faut mémoriser (Dresseurs battus, badge, Musée visité ou payé, objets, équipe au moment de la victoire…).
19. **Textes à valider** : toutes les répliques, panneaux et captions regroupés.
20. **Questions ouvertes** : numérotées, avec ta recommandation pour chacune.
21. **Tableau final « Décisions verrouillées »** (élément | décision).

**Contraintes de forme** : pas de mécanique de jeu nouvelle sans le signaler explicitement (je dois pouvoir dire oui ou non) ; pas de combat contre le rival ni contre la Team Rocket ; pas de spoiler du Mont Sélénite ni de Giovanni ; peu d'espèces nouvelles, chacune justifiée ; textes courts.

---

## Après ChatGPT

Colle sa réponse à Claude : il fait la **passe d'alignement** habituelle (contradictions avec
`vision.md`, la roadmap, les dossiers 05, 06, 08, 09, 10 et 11 et le code réel, systèmes ajoutés en
douce, coûts techniques, textes à relire), avec des arbitrages numérotés à trancher, puis il écrit
`docs/design/dossier-12-argenta.md`. Ensuite seulement : plan technique `docs/tech/jalon-10.md`,
après la fusion du J9.

### Points que Claude vérifiera de toute façon (relevés le 2026-10-07)

- **CT** (jalon 11) et **badge sans effet visible** : conflit avec la récompense historique de Pierre.
- **Données** : Racaillou, Onix, Jet-Pierres, Boul'Armure, Grincement… n'existent pas encore ; la
  table des types et les étages de statistiques existent (Rugissement, Mimi-Queue).
- **IA** : `random` (débutants) et `smart` (rival n° 2) existent ; une IA de Champion « à identité »
  est un ajout du moteur.
- **Équipe au moment de la victoire** (écran Dresseur, « plus tard en polish ») : règle « données
  avant interface », à enregistrer dès la victoire.
- **Stock de la Boutique** : seul l'Antidote est nouveau depuis le jalon 9 ; Anti-Brûle, Réveil,
  Anti-Para : jalon 11.
- **Route 2 nord** : raccord au poste nord de la forêt (« ROUTE 2 NORD — À venir » au J9).
- **Team Rocket** : toute rumeur est une décision de Kevin (roadmap, 2026-10-06).
- **Intérieurs** : réutiliser l'enveloppe peinte du Centre et de la Boutique de Jadielle réduirait
  fortement le coût d'art.
