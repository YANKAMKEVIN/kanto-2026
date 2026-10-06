# Demande de conception n° 1 — Rendre visibles l'XP et la montée de niveau

> Pour Kevin, à valider avec ChatGPT. Réponds par numéro (« 1 ok, 3 : … »). Rien n'est codé avant ta réponse. Date : 2026-10-06.

## Le constat (jeu actuel, jalon 7)

- **Pendant le combat**, seul le Pokémon **en jeu** a une carte : « +21 XP » s'affiche sur sa carte et sa fine barre d'XP glisse. Les autres Pokémon qui ont participé (depuis le changement de Pokémon, ajouté au J7) reçoivent leur part **sans rien à l'écran**.
- **Montée de niveau** : une phrase « Salamèche monte au niveau 9 ! » (ajoutée le 2026-10-02, car la seule pulsation de « Nv. » passait inaperçue sur S24), puis l'apprentissage d'une capacité s'il y en a une.
- En QA sur téléphone, les gains défilent trop vite pour être lus. **Ta demande** : la progression ne doit pas passer inaperçue ; on peut montrer ses Pokémon et leur barre d'XP qui se remplit.
- Rappel des règles écrites : dossier 04 §6 « XP après combat… Présentation propre : « PIKACHU +142 XP », barre, « Nv. 17 », **sans cinq fenêtres successives** » ; bible UI/UX : « le monde est la star », pas de gros rectangles opaques en combat (dossier 05 §3).

## La proposition (par défaut)

**Un bilan de fin de combat**, une seule carte, après la dernière phrase du combat (victoire contre un sauvage, un dresseur ; capture : seulement si de l'XP a été gagnée) et avant le retour au monde :

- Le décor du combat reste visible derrière (voile léger, comme le Sac et l'ÉQUIPE de combat).
- **Une ligne par Pokémon qui a gagné de l'XP** (1 à 6) : portrait peint, nom, niveau, **barre d'XP qui se remplit** de l'ancienne à la nouvelle valeur, « +11 XP ».
- **Montée de niveau** : quand la barre atteint le bout, elle se vide et repart, le niveau passe de « Nv. 8 » à « Nv. 9 » avec une petite mise en valeur (éclat, léger rebond, vibration courte), et une ligne « PV +2 · Attaque +1 … » (les gains de stats, comme Rouge/Bleu) ou seulement « Nv. 9 ».
- Les Pokémon qui n'ont rien gagné (K.O. avant la fin, pas sortis) ne sont pas listés (ou listés grisés : question 4).
- Toucher l'écran accélère les barres, un second toucher ferme le bilan. Rien ne se ferme tout seul trop vite.
- **Apprentissage d'une capacité** et **évolution** (futur) passent **après** le bilan, une par une, dans le décor du combat.
- Pendant le combat, rien ne change : « +XP » sur la carte du Pokémon en jeu reste tel quel.

## Questions (avec ma recommandation)

1. **Bilan de fin de combat** (une carte, barres d'XP qui se remplissent pour tous les participants) plutôt que des messages tour par tour ? — *Reco : oui.*
2. **Quand l'afficher** : après chaque combat gagné, sauvage compris, ou seulement si au moins un Pokémon monte de niveau ? — *Reco : après chaque combat qui rapporte de l'XP ; il dure ~2 s s'il n'y a pas de niveau, on peut le passer d'un toucher.*
3. **Montée de niveau** : afficher les gains de stats (« PV +2 · Attaque +1 · … », Rouge/Bleu) ou seulement le nouveau niveau ? — *Reco : les gains de stats, sur une ligne, uniquement pour le Pokémon qui monte.*
4. **Pokémon sans XP** (K.O. ou restés dans l'équipe) : absents du bilan, ou présents en grisé pour voir toute l'équipe ? — *Reco : absents ; le bilan parle de ceux qui ont combattu.*
5. **Le message « X monte au niveau N ! »** pendant le combat : on le garde en plus du bilan, ou le bilan le remplace ? — *Reco : le bilan le remplace (évite le doublon) ; l'apprentissage de capacité garde ses messages.*
6. **Retour haptique** à la montée de niveau (vibration courte, comme le soin au Centre) ? — *Reco : oui, désactivable avec les vibrations.*
7. **Partage de l'XP** : rester à Rouge/Bleu (parts égales entre les participants encore debout, déjà codé) ? — *Reco : oui ; le Multi Exp viendra comme objet plus tard.*
8. **Hors combat** : la barre d'XP visible dans l'Équipe du Menu Dresseur suffit (déjà là au J6) ? — *Reco : oui, rien de plus.*
9. **Textes** (brouillons, à valider avec le lot) : titre du bilan « Bilan » ou aucun titre ? « +11 XP », « Nv. 9 ! », « PV +2 », « Attaque +1 »… — *Reco : pas de titre (la carte se comprend seule), libellés courts.*

## Coût et place dans le planning

- Petit à moyen : une carte d'interface (ui-mobile), un événement de fin de combat qui résume l'XP par Pokémon (déjà calculée), des tests. Aucun changement de sauvegarde.
- Proposé dans le **J7** (avant la QA finale), puisque le changement de Pokémon y est entré et rend le partage d'XP visible pour la première fois.

---

## Décisions de Kevin (2026-10-06, validées avec ChatGPT) — font foi

Référence visuelle : `docs/design/reference/bilan-xp-v1.webp` (**DA et composition seulement**, CLAUDE.md règle 10 : le décor marin, les nombres d'XP « 112 / 173 » et la consigne « Touchez l'écran pour continuer » de l'image ne sont **pas** validés et ne sont pas implémentés).

1. **Oui** : bilan de fin de combat, une carte, une ligne par Pokémon ayant gagné de l'XP, barres qui se remplissent.
2. **Après chaque combat qui rapporte de l'XP** (pas seulement en cas de montée de niveau). Rapide quand il ne se passe rien de particulier, **accélérable au toucher**.
3. **Gains de stats affichés à la montée de niveau** (« PV +2 · Attaque +1 · Défense +1… »), **uniquement** quand il y a montée de niveau.
4. **Pokémon sans XP absents** : c'est un écran de progression, pas un récapitulatif d'équipe.
5. **Le bilan remplace « X monte au niveau N ! »** pendant le combat (pas de doublon). La montée de niveau doit être un **petit moment gratifiant** dans le bilan : remplissage complet de la barre → passage au niveau suivant → légère mise en valeur → gains de stats.
6. **Vibration courte** à la montée de niveau, soumise au réglage des vibrations.
7. **Partage Rouge/Bleu conservé** (déjà codé) ; le Multi Exp viendra avec l'objet.
8. **Hors combat** : la barre d'XP de l'Équipe du Menu Dresseur suffit.
9. **Pas de titre.** Libellés courts validés : « +11 XP », « Nv. 9 », « PV +2 », « Attaque +1 »…

**Précisions UX** :
- Pas un tableau administratif où six lignes s'animent toutes pareil : les Pokémon sont présentés ensemble, la progression reste très lisible ; plusieurs barres peuvent progresser **ensemble** ; quand un Pokémon monte de niveau, son animation **attire brièvement l'attention sur sa ligne**.
- **Plusieurs niveaux d'un coup** : l'animation enchaîne correctement plusieurs remplissages de barre sans perdre l'information (chaque niveau passé, gains de stats cumulés ou par niveau, lisibles).
- **Après le bilan** : apprentissage de capacité, puis évolution (quand elle existera).
- **Intégré au J7**, avant la QA finale.
