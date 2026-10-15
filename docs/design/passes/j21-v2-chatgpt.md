# J21 — Le repos des esprits : V2 de ChatGPT (reçue le 2026-10-15)

> Reproduite telle que Kevin l'a transmise. Les schémas et illustrations des sections 3 à 7 étaient
> des images, non reproduites. Passe d'alignement : `j21-v2-alignement.md`.

Dossier de conception V2 · 7 arbitrages validés · En attente d'audit par Claude

État d'avancement : les décisions de conception de J19 et J20 sont définies. J21 est désormais
verrouillé sur le plan fonctionnel et narratif. Nous pouvons préparer son dossier de transmission à
Claude, puis lancer J22.

J21 marque un tournant dans notre aventure : le joueur résout enfin le mystère de la Tour Pokémon,
secourt M. Fuji et obtient la Poké Flûte. Les deux Ronflex deviennent alors accessibles, ouvrant de
nouveaux itinéraires à travers Kanto.

## 1. Les sept décisions définitives

| Sujet | Décision validée |
|---|---|
| Périmètre | Tour Pokémon complète, M. Fuji, Poké Flûte et Ronflex |
| Ossatueur | Combat narratif obligatoire, non capturable |
| Team Rocket | Combats au dernier étage, puis sauvetage |
| Poké Flûte | Objet-clé permanent, utilisable hors combat et en combat |
| Ronflex | Deux rencontres uniques, capturables ou pouvant être vaincues |
| Route 12 | Début accessible au J21, suite au J22 |
| Fin du jalon | Exploration libre après la résolution |

La distinction importante est la suivante : les deux Ronflex sont intégrés à J21, mais les Routes 12
à 15 ne sont pas encore développées intégralement.

## 2. Déroulement narratif

1. **Retour à Lavanville.** Le joueur possède désormais le Scope Sylphe obtenu après sa victoire
   contre Giovanni. Les événements laissés en suspens au J19 peuvent reprendre.
2. **Ascension de la Tour Pokémon.** Les spectres deviennent identifiables. Les Dresseurs déjà
   vaincus restent vaincus, et les objets déjà ramassés ne réapparaissent pas.
3. **Rencontre avec Ossatueur.** Le joueur découvre l'identité de l'esprit qui empêchait d'accéder
   aux derniers étages. Un combat narratif obligatoire permet d'apaiser le spectre.
4. **Dernier étage et Team Rocket.** Plusieurs membres Rocket retiennent M. Fuji. Le joueur les
   affronte et libère le passage.
5. **Maison de M. Fuji.** M. Fuji remercie le joueur et lui remet la Poké Flûte, objet-clé unique.
6. **Les deux Ronflex.** Le joueur peut utiliser la Poké Flûte devant chacun des deux Ronflex,
   déclenchant deux combats sauvages uniques.
7. **Retour à l'exploration libre.** Les routes précédemment bloquées deviennent accessibles. Aucun
   déplacement forcé vers Parmanie.

## 3. Ossatueur : une rencontre exceptionnelle

Cette scène doit être émouvante, mais sobre. Pas de jumpscare ni de transformation horrifique.

Règles de conception :
- Le combat se déclenche uniquement lorsque le joueur possède le Scope Sylphe et atteint l'étage
  concerné.
- Ossatueur est identifiable, mais ne peut pas être capturé.
- Une victoire réelle est nécessaire pour poursuivre. Après une défaite, le joueur peut revenir et
  retenter.
- Une fois le combat terminé, le spectre est apaisé et le passage reste ouvert définitivement.

Pour les tentatives de capture, il faut un message spécifique expliquant que ce Pokémon ne peut pas
être capturé, sans consommer inutilement les ressources si l'architecture permet de rejeter l'action
avant son exécution.

À vérifier par Claude : les règles historiques exactes concernant l'utilisation d'objets, la fuite
et la capture pendant cette rencontre. Les adaptations retenues devront être explicites.

## 4. Team Rocket et sauvetage de M. Fuji

Je recommande de conserver les membres Rocket du dernier étage, sans inventer un nouveau chef
intermédiaire.

Leur rôle est de montrer les conséquences concrètes des activités de l'organisation : ils perturbent
un lieu de recueillement et retiennent une personne qui cherche à protéger les Pokémon.

Après leur défaite, M. Fuji est libéré.

La transition vers sa maison doit rester cohérente avec le déroulement historique, tout en évitant
les risques de sauvegarde interrompue entre le sauvetage et la remise de la Poké Flûte.

## 5. Poké Flûte : un nouvel objet-clé

La Poké Flûte est un objet permanent, non consommable.

Elle possède deux usages :

| Situation | Comportement |
|---|---|
| Devant Ronflex | Réveille le Pokémon et déclenche sa rencontre unique |
| En combat | Réveille les Pokémon endormis selon les règles historiques de Rouge/Bleu |
| Hors contexte | Message indiquant qu'aucun Pokémon ne réagit à la mélodie |

Il faudra auditer les règles exactes en combat, notamment les cibles affectées et l'interaction avec
les statuts.

La Poké Flûte ne doit pas devenir un objet de soin général.

## 6. Les deux Ronflex

Nous conservons deux rencontres uniques, chacune avec son propre état de sauvegarde.

| Ronflex | Emplacement |
|---|---|
| Ronflex est | Route 12, au sud de Lavanville |
| Ronflex ouest | Route 16, à l'ouest de Céladopole |

Le Ronflex de la Route 16 implique une dépendance géographique importante : J21 doit inclure l'accès
fonctionnel au point de blocage de la Route 16, même si l'intégralité de la Piste Cyclable est
réservée à un jalon ultérieur.

Je recommande que chaque Ronflex soit capturable, avec possibilité de le vaincre. Une capture ou une
victoire le retire définitivement du monde.

Si le joueur perd le combat ou fuit, la règle de réapparition doit être auditée contre Rouge/Bleu
puis fixée explicitement. L'objectif est d'éviter la duplication, la perte de progression et les
états incohérents.

Le combat doit être clairement identifié comme une rencontre sauvage spéciale, sans écran de boss
artificiel.

## 7. Géographie : ce qui s'ouvre réellement

*(Schéma non reproduit.)* Ce schéma présente deux accès distincts depuis les villes déjà ouvertes ;
le trait pointillé ne représente pas une route directe entre Céladopole et Lavanville.

La Route 12 commence à être explorée au J21, mais son développement complet, avec les pêcheurs, les
passerelles et les connexions vers les Routes 13 à 15, sera traité au J22.

## 8. Dépendances et risques techniques

| Référence | Dépendance | Risque à maîtriser |
|---|---|---|
| J21-A | Scope Sylphe, J20 | Ossatueur accessible sans l'objet |
| J21-B | Tour, J19 | Dresseurs ou objets réinitialisés |
| J21-C | Combat spécial | Ossatueur capturable ou contournable |
| J21-D | Team Rocket | Sauvetage déclenché avant victoire |
| J21-E | Objet-clé Poké Flûte | Remise multiple ou disparition |
| J21-F | Statut Sommeil | Effet en combat incorrect |
| J21-G | Ronflex Route 12 | Collision, capture et état unique |
| J21-H | Ronflex Route 16 | Zone inaccessible ou raccord manquant |
| J21-I | Sauvegarde | Interruption entre combat et récompense |
| J21-J | Assets CB.3 | Fonds de combat Tour et routes extérieures |
| J21-K | QA Galaxy S24 | Reprise, transitions, performances |

**Points critiques**
- Le Scope Sylphe doit être la condition réelle du déblocage, pas simplement la présence d'un drapeau
  J20 terminé.
- Les deux Ronflex doivent avoir des identifiants distincts. Capturer celui de la Route 12 ne doit
  pas faire disparaître celui de la Route 16.
- Le retour à la Tour doit préserver tout J19. Le joueur retrouve le même bâtiment, les mêmes objets
  déjà collectés et les mêmes Dresseurs vaincus.

## 9. Découpage de production

| Lot | Contenu |
|---|---|
| 21.0 | Audit historique, cartes, données et états |
| 21A | Tour Pokémon, spectres identifiés et Ossatueur |
| 21B | Team Rocket, sauvetage et M. Fuji |
| 21C | Poké Flûte, usage extérieur et en combat |
| 21D | Ronflex Route 12 et Route 16 |
| 21E | Accès partiel aux nouvelles routes |
| 21F | QA S24, sauvegardes et non-régression |

**Critère de fin J21** : le joueur peut apaiser Ossatueur, sauver M. Fuji, obtenir la Poké Flûte,
affronter les deux Ronflex et continuer librement son aventure sans blocage.

## 10. Message prêt à transmettre à Claude

Les sept arbitrages J21 sont validés :
1. Tour Pokémon complète + sauvetage de M. Fuji + Poké Flûte + deux Ronflex.
2. Ossatueur : combat narratif obligatoire, non capturable.
3. Team Rocket : combats au dernier étage, puis sauvetage de M. Fuji.
4. Poké Flûte : objet-clé permanent, utilisable devant Ronflex et en combat selon Rouge/Bleu.
5. Deux Ronflex uniques, capturables ou pouvant être vaincus.
6. Route 12 : début accessible au J21, développement complet au J22.
7. Fin du jalon : exploration libre, sans séquence forcée vers Parmanie.

**Continuité impérative** : J19 a préparé la Tour Pokémon, le cinquième combat obligatoire contre le
rival et le blocage par le spectre. J20 a prévu Céladopole, Erika, le repaire Rocket, Giovanni et
l'obtention du Scope Sylphe. J21 doit réutiliser ces systèmes et cartes, sans reconstruire la Tour
ni réinitialiser les combats ou objets du J19.

**Audit demandé**
1. Inspecter le dépôt réel, la roadmap et les dossiers J19/J20. Vérifier ce qui est effectivement
   implémenté, ce qui est seulement documenté et la numérotation disponible.
2. Vérifier la position historique d'Ossatueur, ses règles de combat, l'impossibilité de capture,
   la fuite et la gestion de la défaite.
3. Vérifier les combats Rocket du dernier étage, la libération de M. Fuji et la transition vers sa
   maison.
4. Définir les conditions exactes de remise unique de la Poké Flûte.
5. Auditer l'effet historique de la Poké Flûte en combat, notamment les Pokémon réveillés et les
   interactions avec Sommeil.
6. Vérifier la géographie exacte des deux Ronflex : Route 12 et Route 16.
7. Vérifier les règles historiques des rencontres uniques de Ronflex : capture, victoire, défaite,
   fuite et persistance. Soumettre toute adaptation au lieu de la supposer.
8. Préparer les accès partiels à Route 12 et Route 16 sans développer prématurément toutes les
   routes futures.
9. Définir les flags persistants, les états de rencontre, les migrations et les tests
   d'interruption.
10. Identifier les sprites, illustrations de combat, fonds CB.3, dialogues, sons et animations
    nécessaires.
11. Préparer les tests automatisés et la QA sur Galaxy S24.

**Invariants**
- Impossible de résoudre la Tour sans Scope Sylphe.
- Impossible de capturer Ossatueur.
- Aucun doublon de Poké Flûte.
- Deux Ronflex indépendants, sans duplication.
- Aucun combat ni objet J19 ne réapparaît.
- Les deux accès débloqués ne provoquent aucun softlock.
- Le joueur conserve sa liberté d'exploration à la fin du jalon.

Direction artistique : 2D HD peinte, caméra top-down orthogonale, sans pixel art, isométrie, minimap
ou flèche d'objectif.

Livre une passe d'alignement numérotée, puis le dossier complet après validation. Ne code rien.
Utilise une branche documentaire indépendante.
