# Prompt ChatGPT — dossier 14 : la grande passe de systèmes (jalon 11)

> **Renuméroté le 2026-10-10** (ex-« dossier 13 ») : le numéro 13 revient au chantier d'ouverture (OUV,
> `dossier-13-ouverture.md`, branche locale `docs/dossier-13-ouverture`). Le dossier issu de ce prompt est
> `docs/design/dossier-14-systemes-j11.md`. Le prompt ci-dessous parle encore du « dossier 13 » : texte d'origine conservé.

> Préparé par Claude le 2026-10-10, à coller dans ChatGPT pour concevoir le **jalon 11** de la
> roadmap : statuts complets, CT, changement de Pokémon enrichi, mise en scène des évolutions et
> **compagnon Pokémon**. Joindre à ChatGPT : `docs/design/reference/combat-v1.webp`,
> `docs/design/reference/route-1-vue-generale-v1.png` et `docs/design/reference/menu-equipe-v1.jpg`
> (**ambiance et DA seulement**). Coller aussi, si possible, les dossiers 04
> (`dossier-04-systeme-pokemon.md`) et 05 (`dossier-05-combat.md`). Le texte entre les deux lignes
> est le prompt.

---

Tu m'aides à concevoir **la grande passe de systèmes** de *Kanto 2026*, mon remake personnel de Pokémon Rouge/Bleu en 2D HD peinte, sur smartphone (Android, paysage, déplacement case par case). Je suis le directeur du jeu ; un autre assistant (Claude) implémente à partir de ton dossier. Il a besoin d'un dossier **complet, précis et sans ambiguïté** : tout ce que tu ne tranches pas, il devra me le redemander.

Ce jalon n'ajoute **aucune zone** : il rend complets les systèmes Pokémon avant qu'on étende Kanto (Route 3, Mont Sélénite, Azuria… au jalon 12 et après). Tout ce qu'il pose servira jusqu'à la Ligue : il doit être **général**, pas taillé pour Argenta.

## Ce qui est déjà décidé dans le projet (à respecter, ne pas remettre en cause)

- **Esprit** : « comme si Pokémon n'avait jamais quitté la 2D ». On reconnaît Rouge/Bleu, enrichi, jamais remplacé. On garde l'ADN, on supprime les frictions héritées de la Game Boy. Chaque nouveauté répond à : « qu'est-ce que cela apporte au plaisir de jouer ? »
- **Où en est le joueur** : starter, Route 1, Jadielle (Centre, Boutique, économie, Pokédex), Route 22 (rival n° 2), Route 2, Forêt de Jade (5 Dresseurs, poison, premières évolutions), Route 2 nord et **Argenta (Badge Roche contre Pierre, jalon 10)**. Équipe vers le niveau 12–16. 32 espèces existent dans les données (les trois lignées de starters, Chenipan → Papilusion, Aspicot → Dardargnan, Roucool → Roucarnage, Rattata, Piafabec, Pikachu, Raichu, les deux lignées Nidoran, Férosinge, Colossinge), plus Racaillou et Onix au jalon 10.
- **Combat existant** : tour par tour 1 contre 1, 4 capacités, types, précision, critiques, étages de statistiques (Rugissement, Mimi-Queue…), recul, Vampigraine, SAC contre les Dresseurs, **changement volontaire de Pokémon** (panneau latéral, le combat reste visible) et **remplacement après un K.O.**, fuite contre les sauvages, bilan d'XP, apprentissage d'une capacité avec « oublier une capacité ». IA des Dresseurs : `simple` (choix au hasard) et `smart` (meilleur dégât) ; **aucun Dresseur ne change de Pokémon** aujourd'hui. Combat dans le décor où l'on se trouve. Dossier 05 : « Dresseur expérimenté : types, changements, statuts · Champion : stratégie propre à son identité ».
- **Poison (jalon 9)** : un seul statut à la fois ; 1/8 des PV max en fin de tour ; types Poison immunisés ; persistant après le combat, **aucun dégât en marchant** ; guéri par Antidote (100 ₽) ou Centre ; capture facilitée (×1,5) ; « PSN » écrit partout (combat, Équipe, Sac) et voile violet sur le Pokémon quand il souffre. Le jalon 11 **complète** ce système, il ne le refait pas.
- **Statuts prévus** (dossier 05 §13) : « Paralysie → petites décharges occasionnelles ; poison → légère aura ; sommeil → respiration différente ; brûlure → petites braises intermittentes. **On voit l'état sans lire l'interface.** » Abréviations déjà réservées dans le Menu (dossier 08) : **K.O., PSN, PAR, SOM, BRÛ, GEL**.
- **Capacités déjà dans les données dont l'effet attend ce jalon** (elles infligent leurs dégâts mais l'effet secondaire est ignoré, avec parfois la mention « Sans effet dans le moteur actuel ») : Cage-Éclair et Para-Spore (paralysie), Éclair (paralysie 10 %), Plaquage et Fatal-Foudre (paralysie 30 %), Poudre Dodo (sommeil), Ultrason (confusion), Choc Mental / Rafale Psy (confusion 10 %), Flammèche / Lance-Flammes (brûlure 10 %), Double Pied / Double-Dard (deux coups), Furie / Combo-Griffe / Dard-Nuée (2 à 5 coups), Morsure / Croc de Mort (apeurement), Hurlement (fin du combat contre un sauvage / changement forcé), Lance-Soleil / Coud'Krâne (deux tours), Danse Flamme (piège), Frénésie, Mimique, Puissance, Croc Fatal, Frappe Atlas, Mania, Empal'Korne. **Aucune capacité ne gèle encore.**
- **Évolutions (jalon 9)** : séquence propre et **définitive fonctionnellement** (après la victoire ou la capture, nuit bleutée, silhouettes qui alternent, flash, « Félicitations ! », annulation par **ARRÊTER** ou retour Android, nouvelles capacités apprises). Le jalon 11 **n'enrichit que la mise en scène** (roadmap : nouvelles stats, Pokédex…), sans refaire la logique. Évolution par objet déjà prévue dans les données (Pikachu → Raichu par Pierre Foudre, Nidorina / Nidorino par Pierre Lune) mais **jamais déclenchée**.
- **CT** : n'existent pas encore. **Décision verrouillée (dossier 12 §14)** : pas de CT au jalon 10 ; au jalon 11, **Pierre remet sa CT** aux parties qui ont déjà le badge (« J'allais oublier. » / « Ceci devrait t'être utile. », drapeau propre à la CT) ; une partie commencée après enchaîne badge puis CT. Dans Rouge/Bleu, la CT de Pierre est **Patience** (CT34), qui demande une mécanique propre (encaisser deux tours puis rendre le double) : à toi de dire si on la garde ou si on change de CT.
- **Capacités d'exploration** (ex-CS : Coupe, Flash, Surf…) : utilisables dans le monde **sans occuper d'emplacement de capacité**, mais **elles ne font pas partie de ce jalon** (elles arrivent avec les zones qui en ont besoin). Dis seulement si ta conception des CT les gêne.
- **Compagnon (dossier 04 §4 et vision)** : « Un **Pokémon compagnon visible, contextuel** : le jeu décide quand c'est pertinent (Pikachu court autour de toi, Bulbizarre marche tranquillement, Carapuce s'approche de l'eau ; **Dracaufeu ne se promène pas dans ta cuisine**). » ; « l'équipe existe hors combat : humeur, historique ; le Pokémon de tête suit le joueur. » Roadmap : « sortir de sa Ball et suivre le joueur, **proprement** (comportements par espèce, vitesse, obstacles, intérieurs, réactions, animations, rappel automatique, interactions). **Pas un sprite collé derrière le joueur.** » Dossier 08 : **aucun bouton grisé pour un système qui n'existe pas** (le bouton « FAIRE SORTIR » n'apparaît qu'avec le compagnon).
- **Monde** : grille de 1 case ≈ 1 m, déplacement case par case **à angles droits**, marche et course, rebords franchissables vers le sud, hautes herbes (rencontres aléatoires), portes et changements de carte avec fondu, intérieurs, PNJ avec petites routines, Pokémon d'ambiance dans le décor, cinématiques (le joueur peut être déplacé par le jeu). Écran ≈ 11 cases de haut, ≈ 24 de large.
- **Art** : Pokémon peints simplifiés ; chaque espèce présente dans le monde a déjà (ou aura) une **planche de marche peinte en 4 directions** (repos + marche) ; un Pokémon ≈ 56 px (Rattata) à ≈ 1 case. **Chaque animation par espèce coûte une image peinte** : une règle qui demande 10 animations par espèce n'est pas tenable sur 151. En combat, ton Pokémon est vu de dos (dos peints en production, intégrés à ce jalon : rien à concevoir côté jeu).
- **Boutique** : **jamais d'objet pour une mécanique qui n'existe pas encore** ; quand une mécanique arrive, ses objets arrivent avec. Économie : seuls les Dresseurs donnent de l'argent, aucune perte à la défaite.
- **Interface** : moderne, tactile, pas de pixel art ; pas de tutoriel quand un système peut se découvrir ; pas de fenêtre « OBJECTIF MIS À JOUR » ; textes courts (bulles de 2 lignes de ~40 caractères).
- **Sauvegarde** automatique ; une partie existante (déjà au-delà d'Argenta) doit continuer sans rien perdre ni casser.

## Ce que j'attends : le « dossier 13 — Grande passe de systèmes »

Rédige-le en français, en sections numérotées, avec les **textes définitifs** (messages de combat, noms et descriptions d'objets et de capacités, répliques). Pour chaque point, tranche ; si tu hésites, propose une valeur par défaut et signale-la. Pour chaque règle, dis si elle suit **Rouge/Bleu**, une **génération plus récente**, ou une **invention de Kanto 2026**, et pourquoi.

1. **Intention** : ce que ce jalon change pour le joueur, en une ou deux phrases ; comment il le sent sans zone nouvelle (le jalon se joue sur les lieux existants).
2. **Périmètre et découpage** : la liste de ce qui est dedans et de ce qui est **explicitement reporté**, puis un ordre en 4 à 6 sous-jalons jouables (chacun validé sur téléphone avant le suivant), du moins risqué au plus risqué.
3. **Statuts majeurs** — paralysie, sommeil, brûlure, gel (et le poison existant) : pour chacun, règle exacte en combat (chance de ne pas agir, durée, dégâts, effet sur les statistiques, guérison spontanée), immunités par type, effet sur la capture, comportement **hors combat** (persistant ? dégâts en marchant ? réveil ?), interaction avec le changement de Pokémon et le K.O. Tranche les bizarreries de Rouge/Bleu (gel quasi permanent, sommeil 1–7 tours, paralysie qui divise la Vitesse par 4, Toxik qui s'aggrave, poudres et type Plante).
4. **Statuts temporaires** — confusion, apeurement, piège (Danse Flamme), Vampigraine (existe) : lesquels entrent au jalon 11, avec leurs règles, et ce qu'ils deviennent au changement de Pokémon.
5. **Présentation des statuts** : sur le Pokémon (dossier 05 §13, une animation légère par statut, peu coûteuse), sur la carte de PV, dans les menus, messages de combat définitifs (infligé, déjà atteint, immunisé, ne peut pas agir, se réveille, dégel, guéri…), et un mode « Réduire les animations ».
6. **Effets de capacités en attente** : pour **chaque** capacité de la liste ci-dessus, ce qu'elle fait au jalon 11 (règle exacte) ou si elle reste en attente, et pourquoi. Dis si une règle demande une mécanique nouvelle (deux tours, piège, Mimique, Patience…).
7. **Objets de soin des statuts** : Anti-Para, Réveil, Anti-Brûle, Antigel, Total Soin, éventuels autres : prix, description, **où et quand ils deviennent achetables** (Jadielle, Argenta), et une règle générale « l'objet arrive avec la mécanique » appliquée aux zones futures.
8. **CT** : réutilisables (modernes) ou à usage unique (Rouge/Bleu) ; catégorie et présentation dans le Sac ; parcours tactile pour apprendre (Sac → CT → liste des Pokémon avec compatible / déjà connue / incompatible → remplacer une capacité) ; utilisation en combat ou non ; compatibilités (règle de données) ; la **CT de Pierre** (Patience ou une autre, texte de la remise, rattrapage pour les parties badgées) ; y a-t-il d'autres CT trouvables **dans les lieux existants** (Routes 1, 2, 22, Forêt, Argenta) et lesquelles ? Peut-on revendre une CT ? Les CT de Boutique (Céladopole) plus tard : règle seulement.
9. **Gérer ses capacités hors combat** : le dossier 08 annonce « Réorganiser les capacités » plus tard. Est-ce dans ce jalon ? Peut-on réapprendre une capacité oubliée (Maître des capacités) — maintenant ou plus tard ?
10. **Changement de Pokémon** : ce qui existe suffit-il ? Enrichissements de mise en scène (rappel, lancer, apparition ; dossier 05 §14 : pas d'écran noir). **IA des Dresseurs** : quels Dresseurs changent de Pokémon, quand (désavantage de type, PV bas, statut), à quelle fréquence, et ce qu'en fait le rival. Question « changer de Pokémon quand l'adversaire envoie le suivant » (mode Choix de Rouge/Bleu) : oui / non.
11. **Mise en scène des évolutions** : ce qu'on ajoute (nouvelles statistiques avant / après, entrée du Pokédex, cri, capacités apprises, Grand moment ?), durée totale maximale, ce qui ne change pas. **Évolutions par pierre** : Pierre Foudre et Pierre Lune existent-elles au jalon 11 (où les trouve-t-on, peut-on les acheter), et le parcours Sac → Pierre → Pokémon.
12. **Compagnon Pokémon** — le cœur du jalon, à concevoir avec le plus de précision :
    1. **Qui** : toujours le Pokémon de tête, ou celui que le joueur choisit (« FAIRE SORTIR » / « RAPPELER ») ? Peut-on n'avoir **aucun** compagnon ? Quand le débloque-t-on (dès maintenant pour les parties existantes ? un événement narratif ?).
    2. **Quand il sort et quand il rentre** (« contextuel ») : règles par **taille** ou catégorie d'espèce (petit / moyen / grand / volant / aquatique), intérieurs, routes, villes, eau, cinématiques, combats (rentre-t-il dans sa Ball ? est-ce lui qui combat en premier ?), K.O. (un Pokémon K.O. peut-il suivre ?), statut (endormi, empoisonné : comment le montrer ?).
    3. **Déplacement** : suit-il la case précédente du joueur (comme un wagon) ou se déplace-t-il librement à proximité ? Vitesse (marche, course), rebords, hautes herbes (déclenche-t-il des rencontres ? non, j'imagine : confirme), portes et changements de carte, cases étroites, impasses, le joueur qui fait demi-tour contre lui. **Bloque-t-il les PNJ, ou les PNJ le bloquent-ils ?** Peut-il gêner une ligne de vue de Dresseur ?
    4. **Comportements par espèce** : un petit nombre de **profils** réutilisables (ex. « vif », « calme », « volant », « aquatique », « massif ») plutôt que 151 comportements ; ce que fait chaque profil à l'arrêt (s'assoit, regarde autour, s'éloigne d'une case, revient) et en mouvement ; attribution des 34 espèces existantes à un profil.
    5. **Réactions et interactions** : parler à son compagnon (répliques ? humeur ? quelques réactions selon le lieu, les PV, le statut, l'heure ?), réactions aux lieux (Carapuce près de l'eau, Salamèche sous la pluie plus tard), aux Pokémon d'ambiance, aux PNJ (un PNJ commente-t-il ton compagnon ?). **Humeur / affection** : système nouveau ou simple décor ? Tout système qui a un effet mécanique doit être signalé.
    6. **Animations nécessaires par espèce** (le coût) : la liste minimale (repos et marche en 4 directions existent déjà ou sont prévus) et ce qui serait souhaitable en plus ; ce qui peut être fait par le moteur sans nouvelle image (sautillement, émotes « ! », « ♪ », « … », ombre, rebond).
    7. **Mise en scène de la sortie et du rappel** (Ball, lumière, durée) et du **rappel automatique**.
    8. **Ce qui est reporté** (monter sur un Pokémon, compagnon qui trouve des objets, etc.).
13. **Pokédex, Équipe et Dresseur** : ce que ces systèmes affichent de nouveau (statuts, CT connues, compagnon, statistiques après évolution).
14. **Rattrapage des parties existantes** : CT de Pierre, compagnon, objets de statut en Boutique, Pokémon déjà atteints d'un statut… Rien ne doit être perdu ni bloqué.
15. **Données et sauvegarde** : ce qu'il faut mémoriser (CT obtenues, compagnon choisi, statuts et compteurs éventuels, humeur…).
16. **Textes à valider** : tous les textes regroupés et numérotés.
17. **Questions ouvertes** : numérotées, avec ta recommandation pour chacune.
18. **Tableau final « Décisions verrouillées »** (élément | décision).

**Contraintes de forme** : pas de mécanique nouvelle sans le signaler explicitement (je dois pouvoir dire oui ou non) ; pas de zone nouvelle ni d'espèce nouvelle (sauf si une CT ou une pierre l'exige, signalé) ; ne rien spoiler de l'aventure ; textes courts ; garde en tête le coût d'art par espèce et la lisibilité sur un écran de téléphone.

---

## Après ChatGPT

Colle sa réponse à Claude : il fait la **passe d'alignement** habituelle (contradictions avec
`vision.md`, la roadmap, les dossiers 04, 05, 08, 09, 10 et 12 et le code réel, systèmes ajoutés en
douce, coûts techniques et d'art, textes à relire), avec des arbitrages numérotés à trancher, puis il
écrit `docs/design/dossier-13-systemes.md` (devenu `dossier-14-systemes-j11.md`). Ensuite seulement : plan technique `docs/tech/jalon-11.md`
(après la fusion du J10). **La conception du compagnon et de la sauvegarde v5 peut justifier un appel
à Fable** (`CLAUDE.md`), sur demande de Kevin.

### Points que Claude vérifiera de toute façon (inventaire du code, 2026-10-10)

- **Statuts** : `StatusRules` (`game/pokemon/status_rules.gd`) n'a qu'un statut (`POISON`) et chaque
  règle teste `== POISON` ; aucun compteur (sommeil), aucun volatil hors Vampigraine. Le statut est
  un seul champ du Pokémon, déjà sauvegardé (v4). Test qui verrouille l'absence de paralysie :
  `tests/unit/test_status_rules.gd` (à retourner au J11). Badge « PSN » : `status_view.gd`,
  `team_member_view.gd`, `battle_info_card.gd` ; voile `status_veil.gdshader`.
- **Effets en attente** : `pending_effects` de `data/pokemon/moves/moves.json` (60 capacités) —
  paralysie ×5, sommeil, confusion ×3, brûlure ×2, deux coups ×2, 2–5 coups ×3, apeurement ×2,
  Hurlement, deux tours ×2, piège, Frénésie, Mimique, Puissance, Croc Fatal, Frappe Atlas, Mania,
  Empal'Korne. **Aucun gel** dans les données.
- **Changement de Pokémon** : volontaire et forcé **existent** (`BattleAction.SWITCH`,
  `Battle.check_switch`, état `REPLACING`, `battle_party_panel`) ; l'IA (`battle_ai.gd`, `simple` /
  `smart`) ne change jamais ; l'adversaire envoie `Party.first_able()` après un K.O.
- **CT** : aucune catégorie dans `ItemData.CATEGORY_NAMES` (`ball, heal, battle, field, key`),
  aucune compatibilité dans `kanto.json` ; le déroulé apprendre / oublier existe
  (`move_learn_prompt.gd`, `move_forget_panel`) et sera réutilisé.
- **Évolution** : écran `game/ui/evolution/` sans statistiques ; méthode `item` dans les données,
  jamais déclenchée ; seuls 4 objets existent (`poke_ball`, `potion`, `antidote`, `oak_parcel`).
- **Compagnon** : aucun code ; pas de suiveur hors cinématiques (`follow_path`) ; planches peintes
  4 directions repos + marche déjà présentes pour une quinzaine d'espèces (`assets/sprites/pokemon/painted/`),
  pas pour les évolutions finales (Dracaufeu, Florizarre…).
- **Dos de combat** : provisoires pixel art (`battle_art.gd`, 36 fichiers) ; prototypes peints non
  branchés (`assets/sprites/pokemon/battle_proto/`) ; industrialisation prévue au J11
  (`fiches-assets/serie-combat-dos-pilote.md` §8).
- **Sauvegarde** : v4 ; le J11 passera en **v5** (CT, compagnon, compteurs de statut) → sous-jalon
  validé **seul** sur S24 (règle 1 de `CLAUDE.md`).
- **J10 non commencé dans le code** au 2026-10-10 : le J11 s'appuie sur Pierre, Racaillou, Onix et
  `badge_boulder` (CT de Pierre).
