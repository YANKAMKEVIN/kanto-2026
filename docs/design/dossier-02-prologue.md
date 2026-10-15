# Dossier 02 — Prologue v1 (PNJ, dialogues, départ de l'aventure)

> Document de conception de Kevin (directeur du jeu), reçu le 2026-09-26. **Source de vérité** pour les textes et les intentions du prologue. Les répliques ci-dessous sont **définitives** pour la v1 (pas des textes provisoires).

## Intention

Ce jalon est un vrai morceau du jeu. Le but n'est pas de remplir Bourg Palette : **chaque personnage doit contribuer à l'impression que ce village existait avant le joueur.**

Très peu de texte. Pokémon reste une aventure, pas un visual novel. Aucun tutoriel explicite, aucun « OBJECTIF MIS À JOUR ».

Structure émotionnelle : **Maman = foyer · Rival = compétition · Chen = mentor · Bourg Palette = maison · Route 1 = aventure.**

Ce que le joueur apprend sans tutoriel : marcher → explorer → examiner → parler → danger des hautes herbes → Pokémon → laboratoire → starter → premier combat.

## Découpage décidé par Kevin

- **Jalon 3A — PNJ, interactions, dialogues, vie de Bourg Palette** (§1 à §4 ci-dessous).
- **Jalon 3B — événement de la Route 1 : Chen arrête le joueur et le ramène au laboratoire** (§5, et l'arrivée au labo du §6). Le jalon 3 s'arrête lorsque Chen ramène le joueur au laboratoire.
- **Jalon 4 — starter et premier combat** (§6 à §10).

Une couche solide avant la suivante : on ne construit pas en même temps dialogues, IA des PNJ, Pokémon, équipe, statistiques et combat.

---

## 1. Maman — le foyer

Elle ne donne pas de tutoriel, n'explique pas comment marcher, n'envoie pas artificiellement chez Chen. Quand le joueur descend de sa chambre, elle est dans la pièce principale, près de la cuisine.

**Premier dialogue, automatique** (à la première descente) :

> **Maman** — « Bonjour ! Tu es enfin réveillé ? »
> « J'ai laissé quelque chose à manger sur la table. »

Le joueur récupère immédiatement le contrôle. Aucune quête ne commence officiellement.

**Si on lui reparle :**

> **Maman** — « Tu sors ? Profite de cette belle journée. »
> « Et évite les hautes herbes, d'accord ? »

(La deuxième phrase plante une règle du monde sans afficher de tutoriel.)

**Table — Examiner :**

> *Ton petit-déjeuner est encore chaud.*

(Récupérer des PV en mangeant à la maison : peut-être plus tard, **pas** de mécanique maintenant.)

## 2. Le rival

Quelqu'un que le joueur connaît depuis l'enfance. Compétitif, intelligent, un peu arrogant, mais pas méchant. Et surtout : **il est préparé**.

Si le joueur visite sa maison avant la Route 1, il le trouve dans sa chambre : sac ouvert, carte de Kanto, quelques affaires posées sur le lit. Il prépare manifestement quelque chose.

**Premier dialogue :**

> **Rival** — « Ah. Enfin réveillé. »
> (il regarde le joueur) « T'as choisi ton jour pour faire la grasse matinée. »
> (petit silence) « Moi, je suis prêt. »

Puis il retourne à ses affaires. Le joueur ne sait pas **prêt pour quoi**.

**Si on lui reparle :**

> **Rival** — « Quoi ? »
> « Va faire un tour. Tu comprendras. »

**Carte de Kanto — Examiner :**

> *Une carte de Kanto.*
> *Plusieurs villes ont été entourées au crayon.*

## 3. Le laboratoire avant Chen

On peut entrer, mais **Chen n'est pas là**. La chercheuse principale, **Maya**, travaille devant un écran.

> **Maya** — « Bonjour ! Tu cherches le professeur Chen ? »
> « Il est sorti tôt ce matin. Encore. »
> (petit temps) « Quand il commence à observer des Pokémon, il oublie complètement l'heure. »

**Les starters sont déjà visibles** — Bulbizarre, Salamèche et Carapuce — mais on ne peut pas les prendre.

**Observer :**

> Bulbizarre — *Il t'observe calmement.*
> Salamèche — *Sa flamme s'agite lorsqu'il te voit.*
> Carapuce — *Il te regarde avec curiosité.*

Jamais de fiche technique (« BULBIZARRE TYPE PLANTE POISON ») : on privilégie l'émotion.

## 4. Quelques habitants (quatre pour commencer)

- **Mme Aoki** (voisine) — près de la place centrale, elle nourrit quelques Roucool.
  > **Mme Aoki** — « Ils reviennent tous les matins. » / « Je crois qu'ils savent exactement à quelle heure je sors. »
  Aucune quête, aucune récompense : elle vit ici.
- **Nils** (enfant du village ; ex-« Léo », renommé au J14, dossier 17 E-1) — joue avec son Rattata près d'une clôture.
  > **Nils** — « Regarde ! Il commence à comprendre quand je l'appelle ! » (Rattata réagit) « ...enfin, presque. »
- **Haru** (pêcheur) — sur le littoral.
  > **Haru** — « La mer est calme aujourd'hui. » / « Les Pokémon le sentent avant nous. »
  Plus tard, il pourra parler de Pokémon inhabituels aperçus en mer.
- **Chercheur** (assistant du labo, DA.2) — va et vient entre l'entrée du labo et la serre des jardins de recherche. Réplique validée par Kevin le 2026-10-06, la même avant et après le départ du labo :
  > **Chercheur** — « Le professeur nous fait tout noter. » / « Même la couleur des feuilles des serres ! »
- **Maya** (chercheuse du laboratoire) — PNJ récurrent, future responsable de certaines mises à jour du Pokédex. On crée **Maya**, pas « CHERCHEUR #4 ».

## 5. Le déclencheur (jalon 3B)

Le joueur a exploré Bourg Palette. Il monte vers le nord : prairie, quelques Pokémon visibles, puis les **véritables hautes herbes de la Route 1**.

Le joystick cesse brièvement de répondre. Pas de gros écran noir. Une voix arrive de derrière :

> **???** — « Hé ! Attends ! »

Le personnage se retourne. Chen arrive, légèrement essoufflé.

> **Chen** — « Tu allais vraiment entrer là-dedans tout seul ? »
> (il regarde les hautes herbes) « Les Pokémon qui vivent ici ne sont pas tous aussi tranquilles que ceux du village. »
> « Sans Pokémon à tes côtés, tu prends un risque inutile. »
> (il réfléchit une seconde) « ...Viens avec moi. »

Pas d'« OBJECTIF MIS À JOUR ». Chen commence simplement à marcher ; le joueur le suit automatiquement quelques secondes, ou reprend le contrôle avec Chen qui avance devant lui.

## 6. Retour au laboratoire (arrivée : jalon 3B ; suite : jalon 4)

En entrant, **le rival est déjà là**. Il regarde Chen, puis le joueur.

> **Rival** — « Enfin. »
> **Chen** — « Un peu de patience. »
> **Rival** — « Ça fait une heure que tu dis ça. »
> **Chen** — « Et pourtant, tu es toujours là. »

(Le rival connaît très bien Chen ; pas de dialogue artificiel.)

## 7. Le moment des starters (jalon 4)

> **Chen** — « Vous voulez tous les deux découvrir Kanto. »
> « Mais découvrir ce monde seul serait une mauvaise idée. »
> (il regarde les trois Pokémon) « Eux aussi ont encore beaucoup à découvrir. »
> « Alors... pourquoi ne pas commencer ensemble ? »

Seulement alors l'interface apparaît : **CHOISIS TON PREMIER PARTENAIRE**. Pas trois grosses cartes : on **marche jusqu'aux Pokémon**. En approchant : **Rencontrer** → petite animation, le Pokémon s'approche, fiche très légère :

- **BULBIZARRE** — 🌿 Plante / Poison — *Calme et tenace.*
- **SALAMÈCHE** — 🔥 Feu — *Fougueux et courageux.*
- **CARAPUCE** — 💧 Eau — *Vif et malicieux.*

Boutons **CHOISIR** / **RETOUR**.

## 8. Le choix a une petite conséquence immédiate (jalon 4)

La Poké Ball s'ouvre, le Pokémon apparaît et **reste devant le joueur** au lieu d'être aspiré dans l'inventaire. Il le regarde, s'approche légèrement.

> **Chen** — « On dirait que le choix est réciproque. »

Premier véritable moment Pokémon.

## 9. Le rival choisit ensuite (jalon 4)

Logique originale conservée : il choisit le Pokémon avantagé contre celui du joueur. Il observe le choix, regarde les deux restants, choisit :

> **Rival** — « Alors ce sera toi. »
> (son Pokémon apparaît ; il le regarde, puis le joueur, petit sourire) « Ça devrait être intéressant. »

## 10. Premier combat (jalon 4)

Combat immédiat dans le laboratoire, comme dans Rouge/Bleu, mais très mis en scène. Le rival commence à partir, s'arrête, regarde son Pokémon puis celui du joueur, se retourne :

> **Rival** — « Attends. »
> (petit sourire) « On ne va quand même pas partir sans savoir ce qu'ils savent faire. »

**Premier combat** : première découverte de l'interface de combat 2026.

---

## Ajouts de Kevin (2026-09-26, textes définitifs)

- **Nom affiché de Chen** : « **Prof. Chen** » dans l'étiquette des dialogues. Les autres personnages peuvent l'appeler « le professeur Chen » ou « Chen » selon leur relation avec lui.
- **Maya après le retour de Chen** (elle ne devient pas muette) :
  > **Maya** — « Ah, le professeur est revenu. »
  > « Et à voir son air, j'imagine qu'il a encore quelque chose en tête. »
  (Elle évoluera encore après le choix du starter.)
- **Hautes herbes avant le starter** : tant que le joueur n'a pas de Pokémon, il ne peut pas y entrer. Après l'événement de Chen, pas de nouvelle cinématique : le joueur s'arrête et pense
  > *« Je ne devrais pas aller là sans Pokémon. »*
  La restriction disparaît une fois le starter obtenu (jalon 4).
- **Haru** est sur la **plage**, au bord de l'eau : il se tourne légèrement vers le joueur quand on lui parle, puis se retourne vers la mer.
- **Mme Aoki et Nils** se tournent vers le joueur pendant le dialogue, puis reprennent leur orientation et leur activité.
- Après le 3B, le joueur continue d'explorer Bourg Palette, de parler aux habitants et d'entrer dans les bâtiments ; seule la sortie par les hautes herbes reste verrouillée jusqu'au starter.
- **Au labo, après la scène de la Route 1 et avant le jalon 4** (décision du 2026-09-26) : Chen et le rival ne sont pas muets. Répliques d'attente, remplacées dès le jalon 4 :
  > **Prof. Chen** — « Un peu de patience. J'ai quelque chose à vous montrer. »
  > **Rival** — « Tu vois ? Je t'avais dit que j'étais prêt. »

### Jalon 4 (décisions du 2026-09-26)

Décisions de Kevin reportées de [`docs/tech/jalon-04.md`](../tech/jalon-04.md) §8 (n° 1, 2, 6, 7, 8, 9, 11, 12, 15, 16) et du dossier 07 §8 (Poké Balls). Elles **priment** sur les §8 à §10 ci-dessus quand elles diffèrent (Poké Ball). Textes définitifs, mot pour mot.

- **Le starter descend de la table** (décisions n° 1 et 16), sans Poké Ball : Bulbizarre descend calmement puis s'approche ; Salamèche descend avec plus d'enthousiasme ; Carapuce descend rapidement, vif et joueur. Il atterrit sur une **case libre à côté ou légèrement devant le joueur**, choisie d'après l'espace disponible (jamais « sur la tête » du joueur ni caché par lui) : il descend → s'approche → s'arrête → le joueur se tourne vers lui (sans jamais lui tourner le dos) → petit temps d'observation mutuelle.
  > **Prof. Chen** — « On dirait que le choix est réciproque. »
  C'est **ensuite** que le Pokémon rejoint officiellement l'équipe. **Pas de compagnon temporaire** : il reste près du joueur pendant la séquence du labo, puis rejoint sa Poké Ball ; il ne le suit pas dans Bourg Palette (le vrai compagnon aura son jalon).
- **Pendant la phase de choix** (décision n° 16), dès que Chen a présenté les starters et jusqu'au choix, répliques d'attente (remplacent celles du 3B) :
  > **Prof. Chen** — « Prends ton temps. »
  > « Choisis celui avec qui tu as envie de partir. »

  > **Rival** — « Tu comptes les regarder encore longtemps ? »
  > « Dépêche-toi de choisir. »
- **Sortie du labo empêchée** pendant le choix (décision n° 2), sur le tapis de sortie avant d'avoir choisi :
  > **Prof. Chen** — « Pas si vite. Tu n'as pas encore choisi ton partenaire. »
- **Le rival choisit le starter avantagé** (décisions n° 11 et 16) :
  > **Rival** — « Alors ce sera toi. »
  (son Pokémon vient vers lui et se pose à côté de lui, jamais derrière sa tête ; le rival regarde le Pokémon du joueur, puis le joueur ; temps mort, petit sourire)
  > **Rival** — « Ça devrait être intéressant. »
  (plus tard, quand il s'apprête à partir)
  > **Rival** — « Attends. »
  (il regarde son Pokémon, puis celui du joueur)
  > **Rival** — « On ne va quand même pas partir sans savoir ce qu'ils savent faire. »
  Le combat commence.
- **Après le combat** (décision n° 6) : aucune sanction ; Prof. Chen soigne les deux Pokémon quelle que soit l'issue.
  - Victoire du joueur : le rival rappelle son Pokémon ; petit silence.
    > **Rival** — « ...Pas mal. »
    > (il regarde son Pokémon / sa Poké Ball) « On a encore du travail. »
    > (il regarde le joueur) « La prochaine fois, ce sera différent. »
    > (il commence à partir) « Essaie de ne pas trop prendre de retard. »
    Il sort.
  - Défaite du joueur : le rival rappelle son Pokémon.
    > **Rival** — « Pas mal pour un premier combat. »
    > (petit sourire) « Mais je t'avais prévenu : j'étais prêt. »
    > « Rattrape-moi quand tu le seras aussi. »
    Il sort.
- **Chen après le départ du rival** (décision n° 7) :
  > **Prof. Chen** — « Pour un premier combat, vous vous êtes bien débrouillés. »
  > « Mais gagner n'est qu'une partie de ce qu'un Dresseur doit apprendre. »
  > « Apprends à connaître ton Pokémon. Il fera de même avec toi. »
- **Les premières Poké Balls** (dossier 07 §8, fin du jalon 4) : après les dernières paroles de Chen, avant que le joueur parte :
  > **Prof. Chen** — « Une dernière chose. »
  > (il remet quelque chose au joueur) **Poké Balls ×5**
  > « Observer les Pokémon t'apprendra beaucoup. Mais parfois, le meilleur moyen de les comprendre est encore de voyager avec eux. »
  > « Utilise-les avec discernement. »
  Pas de tutoriel de capture. Les Poké Balls vont dans le Sac (toast, bible UI §6).
- **Premier combat volontairement simple** (décisions n° 9, 12 et 15) : ATTAQUER mis en avant ; SAC, ÉQUIPE et FUITE visibles mais atténués ; **aucune indication de Chen** pendant le combat (il observe) ; **pas de message générique de fin** (« Tu as battu… ») : les répliques du rival en tiennent lieu. Le starter du joueur rentre dans sa Poké Ball à la fin de la séquence du labo.
- Les répliques répétées de la fin provisoire du 4A (Chen « On dirait que le choix est réciproque. », rival « On ne va quand même pas partir… » quand on leur reparle) disparaissent au 4B : le combat s'enchaîne, puis le rival quitte le labo.
- **Répliques d'attente après le jalon 4** (décision n° 8, remplacent celles du 3B), **réservées à l'après-combat** (décision n° 16) : ni Chen ni Maya ne les disent avant le premier combat ; avant, Maya garde « Ah, le professeur est revenu. »… :
  > **Prof. Chen** — « Le monde qui vous attend est bien plus vaste que Bourg Palette. »
  > « Prends le temps de l'observer. Les Pokémon ont beaucoup à nous apprendre. »

  > **Maya** — (elle regarde le starter) « Alors, c'est lui que tu as choisi ? »
  > « Vous avez l'air de déjà bien vous entendre. »

  Accord selon le sexe du starter (décision n° 16) : pour une femelle, « Alors, c'est elle que tu as choisi ? ».
