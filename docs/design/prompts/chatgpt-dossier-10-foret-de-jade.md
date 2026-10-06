# Prompt ChatGPT — dossier 10 : la Forêt de Jade

> Préparé par Claude le 2026-10-06, à coller dans ChatGPT pour concevoir la Forêt de Jade (jalon 9
> de la roadmap). Joindre à ChatGPT : `docs/design/reference/route-1-vue-generale-v1.png`,
> `docs/design/reference/bourg-palette-vue-generale-v1.png` et, si elle est validée, la vue
> d'étude de la Forêt de Jade (`build/art/CONCEPT_FORET_JADE_VUE_GENERALE_r1.png`, **ambiance
> seulement, son tracé est provisoire**). Le texte entre les deux lignes est le prompt.

---

Tu m'aides à concevoir **la Forêt de Jade** pour *Kanto 2026*, mon remake personnel de Pokémon Rouge/Bleu en 2D HD peinte, sur smartphone (Android, paysage, déplacement case par case). Je suis le directeur du jeu ; un autre assistant (Claude) implémente à partir de ton dossier. Il a besoin d'un dossier **complet, précis et sans ambiguïté** : tout ce que tu ne tranches pas, il devra me le redemander.

## Ce qui est déjà décidé dans le projet (à respecter, ne pas remettre en cause)

- **Esprit** : « comme si Pokémon n'avait jamais quitté la 2D ». On reconnaît Rouge/Bleu, enrichi, jamais remplacé. Rythme historique : Bourg Palette → Route 1 → Jadielle → Route 2 → **Forêt de Jade** → Argenta (première Arène).
- **Échelle A+** : environ 3 à 4 fois l'original, mais chaque agrandissement apporte du gameplay, de l'atmosphère ou de la narration. **Dense plutôt que gigantesque.** Une route est un lieu, pas un couloir.
- **Grille** : 1 case ≈ 1 mètre ; le joueur se déplace **case par case, uniquement à l'horizontale et à la verticale** : tous les chemins sont à angles droits, aucune diagonale. Écran ≈ 11 cases de haut et ≈ 24 de large.
- **Rebords** franchissables vers le sud seulement (raccourcis de retour) : ils existent déjà.
- **Hautes herbes** = rencontres aléatoires (ADN Gen 1 conservé) ; **Pokémon d'ambiance** visibles dans le décor, qui ne déclenchent pas forcément de combat.
- **Aucune faune non-Pokémon** (ni insectes, ni oiseaux réels) : les signes de vie animale sont des Pokémon.
- **PNJ** : une petite routine plutôt que planté, quand ça a du sens ; jamais cinq personnes inutiles.
- **Dresseurs** : il te voit → s'approche → quelques mots → combat. IA progressive : les Dresseurs de début de jeu font des choix simples.
- **Déjà vécu par le joueur avant la forêt** : starter, rival à Bourg Palette, Route 1 (Roucool, Rattata, une Potion cachée), Jadielle (Centre Pokémon, Boutique, économie, Pokédex activé), Route 22 (rival n°2), puis Route 2 (**pas encore conçue** : dis-moi si la forêt suppose quelque chose sur elle).
- **Roadmap de la phase** (Route 2 / Forêt de Jade, jalons 8–9) : nouveaux Pokémon, **premiers vrais Dresseurs**, **poison / antidotes**, plus d'objets, capture plus intéressante, équipe qui se construit, premières évolutions selon les niveaux.
- **Direction artistique** (déjà en cours de test) : forêt dense et profonde mais jamais effrayante, canopée continue, sous-bois plus sombre et plus frais que la Route 1, taches et rais de lumière dans les clairières. Règle des lieux calmes : **nature dense, objets rares** ; chaque objet posé a une raison d'être.
- **Sauvegarde automatique** aux moments importants (pas de point de sauvegarde à placer).

## Ce que j'attends : le « dossier 10 — Forêt de Jade »

Rédige-le en français, en sections numérotées, avec les **textes définitifs** des PNJ et des panneaux. Pour chaque point, tranche ; si tu hésites, propose une valeur par défaut et signale-la.

1. **Intention** : ce que le joueur doit ressentir et apprendre ici (en une ou deux phrases), et ce qui distingue la forêt de la Route 1.
2. **Taille et durée** : dimensions approximatives en cases (largeur × hauteur), temps de traversée directe et temps d'exploration attentive.
3. **Entrées et sorties** : par où on entre (depuis la Route 2) et on sort (vers Argenta) ; postes de garde (bâtiments-portes comme dans Rouge/Bleu) ou transition directe ? Ce qu'il y a dedans s'il y en a.
4. **Tracé** : un plan ASCII **à angles droits** avec une légende (sentier, sous-bois praticable, forêt infranchissable, hautes herbes, clairières, rebords, objets, Dresseurs, PNJ, entrées/sorties). Indique le chemin principal et les détours.
5. **Zones de hautes herbes** : combien, où, leur rôle (contournable / obligatoire / recoin), comme je l'ai fait pour la Route 1 (initiation, exploration, passage obligatoire).
6. **Rencontres sauvages** : espèces, niveaux min–max et fréquence relative (en %) ; rencontres rares éventuelles. Différences jour/nuit si tu en veux (le cycle jour/nuit viendra plus tard : dis-le simplement).
7. **Pokémon d'ambiance** : lesquels, où, ce qu'ils font (et s'ils fuient, se cachent, réagissent au joueur).
8. **Dresseurs** : nombre, emplacement, champ de vision (en cases), type (Scout, Gamin…), **équipe exacte** (espèce + niveau), argent gagné, **répliques avant et après le combat**. Sont-ils évitables ?
9. **PNJ non-combattants** : qui, où, routine, répliques définitives.
10. **Objets** : visibles et cachés (nom, quantité, emplacement, comment on les trouve), dont ce qui sert à apprendre le **poison / l'antidote** ; texte de découverte des objets cachés (comme « Quelque chose est coincé entre les racines. » sur la Route 1).
11. **Secrets et recoins** : ce qui récompense l'exploration, sans gros scintillement.
12. **Ce que la forêt enseigne** (statut poison, Dresseurs, gestion des soins loin d'un Centre, nouveaux types…) et **comment, sans tutoriel lourd**.
13. **Événements et narration** : y a-t-il une petite scène (premier Dresseur, rencontre marquante, indice sur la suite) ? Le rival ? Des allusions à la Team Rocket ? (Attention à l'ordre narratif : rien qui spoile Argenta ou le Mont Sélénite.)
14. **Ambiance** : lumière, sons, musique (intention), météo éventuelle, repères visuels pour s'orienter (un grand arbre, une souche, un rocher…). Rappel : aucune faune non-Pokémon.
15. **Défaite** : où le joueur se réveille s'il perd dans la forêt (Centre de Jadielle ?), et texte éventuel.
16. **Données et sauvegarde** : ce qu'il faut mémoriser (Dresseurs battus, objets ramassés, événements vus).
17. **Questions ouvertes** : ce que tu n'as pas pu trancher, avec ta recommandation pour chacune, numérotées.
18. **Tableau final « Décisions verrouillées »** (élément | décision), comme dans mes autres dossiers.

**Contraintes de forme** : pas de mécanique de jeu nouvelle sans le signaler explicitement (je dois pouvoir dire oui ou non) ; pas de spoiler sur la suite de l'aventure ; textes courts, adaptés à un écran de téléphone (2 lignes de ~40 caractères par bulle).

---

## Après ChatGPT

Colle sa réponse à Claude : il fait la **passe d'alignement** habituelle (contradictions avec `vision.md`, la roadmap et les dossiers, systèmes ajoutés en douce, coûts techniques, textes à relire), avec des arbitrages numérotés à trancher, puis il écrit `docs/design/dossier-10-foret-de-jade.md`. Le tracé du dossier remplacera le tracé provisoire de l'étude de DA.
