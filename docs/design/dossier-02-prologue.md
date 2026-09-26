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
- **Léo** (enfant du village) — joue avec son Rattata près d'une clôture.
  > **Léo** — « Regarde ! Il commence à comprendre quand je l'appelle ! » (Rattata réagit) « ...enfin, presque. »
- **Haru** (pêcheur) — sur le littoral.
  > **Haru** — « La mer est calme aujourd'hui. » / « Les Pokémon le sentent avant nous. »
  Plus tard, il pourra parler de Pokémon inhabituels aperçus en mer.
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
