# Prompt ChatGPT — dossier 11 : la Route 2 (jalon 8)

> Préparé par Claude le 2026-10-06, à coller dans ChatGPT pour concevoir la **Route 2** (jalon 8 de
> la roadmap), première étape du J8. Joindre à ChatGPT : `docs/design/reference/route-1-vue-generale-v1.png`,
> `docs/design/reference/route-1-plan-v1.png`, `docs/design/reference/jadielle-vue-generale-v1.webp`
> et `docs/design/reference/foret-jade-etude-ambiance-v1.png` (**ambiance seulement**). Coller aussi,
> si possible, le dossier 10 (`docs/design/dossier-10-foret-de-jade.md`) : la Route 2 doit s'y
> raccorder. Le texte entre les deux lignes est le prompt.

---

Tu m'aides à concevoir **la Route 2** pour *Kanto 2026*, mon remake personnel de Pokémon Rouge/Bleu en 2D HD peinte, sur smartphone (Android, paysage, déplacement case par case). Je suis le directeur du jeu ; un autre assistant (Claude) implémente à partir de ton dossier. Il a besoin d'un dossier **complet, précis et sans ambiguïté** : tout ce que tu ne tranches pas, il devra me le redemander.

## Ce qui est déjà décidé dans le projet (à respecter, ne pas remettre en cause)

- **Esprit** : « comme si Pokémon n'avait jamais quitté la 2D ». On reconnaît Rouge/Bleu, enrichi, jamais remplacé. Rythme historique : Bourg Palette → Route 1 → Jadielle → **Route 2** → Forêt de Jade → Route 2 nord → Argenta (première Arène).
- **Échelle A+** : environ 3 à 4 fois l'original, mais chaque agrandissement apporte du gameplay, de l'atmosphère ou de la narration. **Dense plutôt que gigantesque.** Une route est un lieu, pas un couloir.
- **Grille** : 1 case ≈ 1 mètre ; déplacement **case par case, uniquement à l'horizontale et à la verticale** : tous les chemins sont à angles droits, aucune diagonale. Écran ≈ 11 cases de haut et ≈ 24 de large.
- **Rebords** franchissables vers le sud seulement (raccourcis de retour) : ils existent déjà.
- **Hautes herbes** = rencontres aléatoires (ADN Gen 1) ; **Pokémon d'ambiance** visibles dans le décor, qui ne déclenchent pas forcément de combat.
- **Aucune faune non-Pokémon** (ni insectes, ni oiseaux réels).
- **PNJ** : une petite routine plutôt que planté, quand ça a du sens ; jamais cinq personnes inutiles. Règle des lieux calmes : **nature dense, objets rares** ; chaque objet posé a une raison d'être ; espaces vides gardés.
- **Sauvegarde automatique** aux moments importants (pas de point de sauvegarde à placer).
- **Déjà vécu par le joueur avant la Route 2** : starter et rival à Bourg Palette ; Route 1 (Roucool, Rattata, une Potion cachée) ; Jadielle (Centre Pokémon et point de repos, Boutique et argent, colis rapporté à Chen, **Pokédex activé**, Stockage) ; Route 22 (Nidoran ♀ et ♂, Férosinge, Piafabec, Rattata ; **rival n° 2**). Il peut **changer de Pokémon en combat** et voit un **bilan d'XP** en fin de combat. La sortie nord de Jadielle mène aujourd'hui à « ROUTE 2 — À venir » : la Route 2 la remplace simplement.
- **Décidé dans le dossier 10 (Forêt de Jade, jalon 9), donc contraintes pour toi** :
  - **aucun Dresseur sur la Route 2 avant la forêt** : le Scout Léo, dans la forêt, reste **le premier vrai Dresseur** ;
  - la Route 2 est **interrompue par la Forêt de Jade** et **ne permet pas de la contourner** lors de la première progression ;
  - entrée de la forêt par un **poste de garde sud** (petit bâtiment-porte d'une pièce, garde inclus, conçu dans le dossier 10) ; sortie par le poste nord vers **la Route 2 nord**, puis Argenta ;
  - le **poison** (statut) et l'Antidote arrivent au **jalon 9**, pas avant ; les **premières évolutions** aussi (jalon 9).
- **Roadmap de la phase** (jalons 8–9) : nouveaux Pokémon, plus d'objets, capture plus intéressante, équipe qui se construit, premier apprentissage de nouvelles capacités.
- **Direction artistique** : 2D HD peinte, lumière de fin d'après-midi chaude (« golden hour »), décor dense et lisible ; la Route 2 annonce la forêt (lisière de grands arbres de plus en plus serrés vers le nord).

## Ce que j'attends : le « dossier 11 — Route 2 »

Rédige-le en français, en sections numérotées, avec les **textes définitifs** des PNJ et des panneaux. Pour chaque point, tranche ; si tu hésites, propose une valeur par défaut et signale-la.

1. **Intention** : ce que le joueur doit ressentir et apprendre ici, en une ou deux phrases ; ce qui distingue la Route 2 de la Route 1 et de la Route 22, alors qu'il n'y a pas de Dresseur.
2. **Périmètre du jalon 8** : la **Route 2 sud** seulement (Jadielle → poste sud de la forêt), ou aussi la Route 2 nord (poste nord → Argenta) ? Si tu proposes la partie nord, dis ce qui y est accessible maintenant et ce qui attend.
3. **Taille et durée** : dimensions approximatives en cases (largeur × hauteur), temps de traversée directe et d'exploration attentive.
4. **Entrées et sorties** : raccord avec la sortie nord de Jadielle, entrée du poste sud de la forêt ; autres passages éventuels.
5. **Tracé** : un plan ASCII **à angles droits** avec une légende (chemin, herbe praticable, végétation infranchissable, hautes herbes, rebords, objets, PNJ, entrées/sorties, éléments bloquants). Indique le chemin principal et les détours.
6. **Ce qui ne s'ouvre que plus tard** (Rouge/Bleu en a : arbres à couper, passage vers la Grotte Taupiqueur, aide du Professeur) : propose ce que tu gardes, **visible mais fermé** maintenant, avec un obstacle **justifié dans le monde** et une simple réplique ; rien qui demande un système nouveau au jalon 8 (pas de CS Coupe). Signale chaque mécanique future.
7. **Zones de hautes herbes** : combien, où, leur rôle (contournable, obligatoire, recoin).
8. **Rencontres sauvages** : espèces, niveaux min–max et fréquence (%) ; rencontres rares éventuelles. Indique ce qui est **nouveau** par rapport à la Route 1 et à la Route 22, et ce qui annonce la forêt **sans la déflorer** (la forêt a Chenipan, Aspicot, Coconfort, Chrysacier, Pikachu à 5 %).
9. **Pokémon d'ambiance** : lesquels, où, ce qu'ils font, s'ils fuient ou réagissent au joueur.
10. **PNJ non-combattants** : qui, où, routine, répliques définitives (dont, si tu veux, une personne qui **échange un Pokémon** ou **donne un objet** : signale-le comme mécanique nouvelle).
11. **Objets** : visibles et cachés (nom, quantité, emplacement, comment on les trouve, texte de découverte d'un objet caché comme « Quelque chose est coincé entre les racines. » sur la Route 1). Pas d'Antidote utile avant le jalon 9.
12. **« Capture plus intéressante » et « équipe qui se construit »** : comment la Route 2 y contribue concrètement (espèces, niveaux, situations), sans Dresseur.
13. **Apprentissage de capacités** : y a-t-il un moment ou un PNJ qui fait découvrir qu'un Pokémon apprend une capacité en montant de niveau (le système existe déjà) ? Comment, sans tutoriel lourd ?
14. **Événements et narration** : petite scène éventuelle, indices sur la suite **sans spoiler** Argenta ou le Mont Sélénite ; le rival ne revient pas ici (il vient de combattre sur la Route 22).
15. **Ambiance** : lumière, sons, musique (intention), repères visuels pour s'orienter, transition visuelle vers la forêt.
16. **Défaite** : réveil au Centre de Jadielle (règle existante) ; texte éventuel.
17. **Données et sauvegarde** : ce qu'il faut mémoriser (objets ramassés, événements vus, échanges…).
18. **Textes à valider** : toutes les répliques et panneaux regroupés.
19. **Questions ouvertes** : numérotées, avec ta recommandation pour chacune.
20. **Tableau final « Décisions verrouillées »** (élément | décision).

**Contraintes de forme** : pas de mécanique de jeu nouvelle sans le signaler explicitement (je dois pouvoir dire oui ou non) ; pas de Dresseur ; pas de spoiler ; textes courts, adaptés à un écran de téléphone (2 lignes de ~40 caractères par bulle).

---

## Après ChatGPT

Colle sa réponse à Claude : il fait la **passe d'alignement** habituelle (contradictions avec
`vision.md`, la roadmap et les dossiers 07, 09 et 10, systèmes ajoutés en douce, coûts techniques,
textes à relire), avec des arbitrages numérotés à trancher, puis il écrit
`docs/design/dossier-11-route-2.md`. Ensuite seulement : plan technique `docs/tech/jalon-08.md`.
