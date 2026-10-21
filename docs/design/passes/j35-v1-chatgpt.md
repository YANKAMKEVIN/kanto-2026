# Kanto 2026 — J35 : Bêta privée et validation terrain

> Dossier de conception consolidé V1 (ChatGPT), transmis par Kevin le 2026-10-19, **avant le
> lancement du J35** (conception en avance, `strategie-acceleration.md` levier 2). 7 arbitrages
> verrouillés. Le prototype interactif de formulaire de la passe d'origine est décrit en texte (§5).
> Notes de la session de coordination à la fin.

On passe de la validation technique du J34 à la confrontation avec de **vrais joueurs**, sur
différents appareils Android, sans perdre le contrôle des versions, des retours et des corrections.
Le but n'est pas de diffuser au plus grand nombre, mais de savoir si une personne extérieure peut
installer, comprendre et jouer à Kanto 2026 de façon autonome et fiable.

## 1. Les sept arbitrages définitifs

| # | Domaine | Décision verrouillée |
|---|---|---|
| 1 | Périmètre | Bêta privée contrôlée, retours et corrections ciblées |
| 2 | Testeurs | Petit groupe volontaire, appareils Android variés |
| 3 | Distribution | Accès individuel, version identifiable, procédure de retrait |
| 4 | Retours | Formulaire structuré : bugs, UX, performances et plaisir |
| 5 | Confidentialité | Aucune télémétrie intrusive, diagnostics minimaux consentis |
| 6 | Corrections | Tri P0–P3, correctifs ciblés et nouvelles builds vérifiées |
| 7 | Sortie | Rapport bêta, stabilité démontrée et décision de poursuite |

Ni nouvelle région, ni Pokémon supplémentaire, ni campagne additionnelle.

## 2. Le parcours de la bêta

J34 (RC techniquement acceptée, conformité examinée) → recrutement (testeurs et appareils
identifiés) → accès contrôlé (APK versionné, consignes, canal de support) → tests terrain
(installation, exploration, combats, sauvegardes) → retours structurés (anomalies, ergonomie,
performance, plaisir) → corrections (priorisation, builds correctives, retests) → rapport bêta
(résultats, risques, décision de poursuite).

**Condition d'entrée** : la bêta ne commence pas parce qu'une APK existe. Il faut une RC acceptée
sans P0/P1 connu **et** une décision de conformité adaptée à la diffusion envisagée.

## 3. Testeurs et couverture Android

Dimensionnement initial proposé (pas un arbitrage) : **8 à 12 testeurs volontaires**.

| Profil | Ce que l'on observe |
|---|---|
| Joueur familier de Pokémon | Cohérence de l'aventure et des mécaniques |
| Joueur occasionnel | Compréhension des menus et des commandes |
| Joueur découvrant le projet | Qualité de la première expérience |
| Testeur attentif aux détails | Dialogues, collisions, objets et événements |
| Utilisateur Android moins récent | Performances, mémoire et compatibilité |

Galaxy S24 reste la référence ; la bêta inclut si possible d'autres constructeurs, tailles d'écran et
versions Android compatibles. 12 testeurs ≠ 12 configurations : la matrice enregistre les appareils
**réellement** utilisés.

## 4. Distribution privée et contrôle des versions

| Champ | Exemple ou exigence |
|---|---|
| Version | `0.35.0-beta.1` (exemple) |
| Commit Git | SHA exact |
| APK | Fichier signé et identifié |
| Empreinte | SHA-256 du fichier |
| Date | Date de génération réelle |
| Canal | Distribution privée autorisée |
| Compatibilité | Versions Android prises en charge |
| Notes | Correctifs, risques et limitations |

**Accès** : invitation individuelle, instructions d'installation, limites de la bêta, moyen de
signaler un problème. Pouvoir retirer l'accès aux futures builds, désactiver un lien, demander l'arrêt
des tests. **Limite** : retirer un lien ne désinstalle pas une APK déjà installée ; sans mécanisme
préexistant, aucune révocation à distance d'un jeu hors ligne ne peut être promise.

**Cadre de diffusion** : une bêta privée n'élimine pas les risques liés aux droits d'auteur et aux
marques associés à Pokémon. L'accès de testeurs externes reste **conditionné à la vérification des
droits et autorisations**. Sinon, le jalon produit son protocole et ses outils, mais la distribution
est suspendue.

## 5. Formulaire de retour des testeurs

Court mais suffisant pour reproduire un bug. Champs du prototype :

- **Type de retour** : bug ou dysfonctionnement ; difficulté d'utilisation ; performance ou
  stabilité ; impression générale.
- **Zone concernée** (ex. exploration et cartes), **appareil Android**, **version testée**.
- **Impact observé** : impossible de continuer ; problème important ; gênant mais je peux jouer ;
  détail mineur.
- **Étapes pour reproduire**.
- **Plaisir de jeu global** (note sur 5).
- Bouton « Copier le rapport » : copie locale, **aucune transmission à un serveur**.

Chaque rapport est associé à une version précise : un retour d'une ancienne bêta n'est pas présenté
comme un défaut encore présent dans une build corrigée.

## 6. Confidentialité et diagnostics

Principe : **minimisation des données**.

| Donnée | Politique recommandée |
|---|---|
| Modèle de téléphone | Recueilli pour le diagnostic |
| Version Android | Utile à la compatibilité |
| Version du jeu | Nécessaire pour reproduire |
| Description du bug | Fournie volontairement |
| Capture d'écran | Facultative, après vérification du contenu |
| Journaux techniques | Minimaux, avec consentement explicite |
| Identifiants personnels | À éviter |
| Localisation précise | Non nécessaire |
| Contacts, photos et messages | Aucun accès requis |
| Sessions détaillées | Aucun suivi intrusif |

Un testeur peut participer sans transmission automatique de diagnostics. Rapports et journaux
conservés pendant une durée définie, accès restreint, suppression possible sur demande selon les
règles applicables.

## 7. Tri des anomalies et cycle correctif

| Priorité | Exemple | Traitement |
|---|---|---|
| P0 | Sauvegarde détruite, crash systématique, perte de Pokémon | Arrêt des tests concernés, correction immédiate |
| P1 | Progression bloquée, fonction majeure inutilisable | Correction avant poursuite de la validation |
| P2 | Défaut tactile ou visuel gênant, sans blocage | Priorisation selon fréquence et impact |
| P3 | Détail cosmétique ou suggestion mineure | Registre de maintenance |

La priorité est attribuée par l'équipe après analyse ; l'impact indiqué par le testeur est un signal.

**Cycle** : signalement → reproduction → classification → correction ciblée → tests de régression →
nouvelle build identifiée → confirmation sur l'appareil concerné si possible, puis sur le S24. Aucune
suggestion de fonctionnalité intégrée au J35 : elles vont au registre des idées.

## 8. Dépendances J33–J34 → J35

| Dépendance | Origine | Exigence J35 |
|---|---|---|
| Stabilisation générale | J33 | Parcours critiques validés |
| Sauvegardes et migrations | J33 | Aucun risque P0/P1 connu |
| APK signé | J34 | Installation et mise à jour possibles |
| Versionnement | J34 | Chaque retour associé à une build |
| Matrice Android | J34 | Appareils compatibles identifiés |
| Première utilisation | J34 | Parcours de démarrage fonctionnel |
| Résilience | J34 | Tests d'interruption documentés |
| Audit des ressources | J34 | Risques et droits examinés |
| Go/No-Go RC | J34 | Autorisation technique d'entrer en bêta |
| Conformité de diffusion | J34 | Autorisation adaptée aux testeurs externes |
| Canal de retours | Nouveau J35 | Collecte sécurisée et structurée |

**Trois blocages possibles** : 1. RC non acceptée (P0/P1 au J34) → la bêta ne démarre pas. 2.
Distribution non autorisée → invitations et téléchargements suspendus. 3. Pas de diagnostic
rattachable à une version et un appareil → protocole prêt **avant** les premières invitations.

## 9. Mesures de réussite

| Indicateur | Mesure |
|---|---|
| Installation | Installations réussies / tentatives |
| Premier lancement | Testeurs atteignant le menu principal |
| Première session | Testeurs terminant le parcours initial |
| Stabilité | Crashes et interruptions reproductibles |
| Sauvegardes | Reprises réussies après fermeture |
| Ergonomie | Difficultés signalées par écran ou action |
| Performance | Problèmes par modèle Android |
| Plaisir | Note de 1 à 5 et commentaires qualitatifs |
| Anomalies | P0/P1 ouvertes, corrigées et retestées |
| Couverture | Appareils, zones et fonctionnalités réellement testés |

Pas de chiffres de succès inventés à l'avance ; distinguer un incident isolé d'un problème
reproductible, sans ignorer un incident grave même rare.

**Rapport final** : versions testées, appareils, parcours, résultats, incidents, corrections livrées,
problèmes ouverts, décisions de poursuite. **Sortie recommandée** : aucun P0/P1 ouvert sur la build
candidate finale, tests critiques réussis, conformité de l'étape suivante examinée.

## 10. Découpage technique

| Lot | Livrable |
|---|---|
| 35.0 | Audit de la RC J34 et conditions d'entrée |
| 35A | Protocole de bêta, testeurs et appareils |
| 35B | Distribution privée et contrôle des versions |
| 35C | Formulaire, consentement et collecte de retours |
| 35D | Campagne de tests et consolidation des résultats |
| 35E | Corrections ciblées, builds et retests |
| 35F | Rapport bêta, anomalies résiduelles et décision de poursuite |

**« J35 terminé »** : protocole exécuté sur une build identifiée, résultats documentés, défauts
critiques traités, décision explicite prise.

## 11. Prompt de transmission à Claude (au lancement du J35)

> **Kanto 2026 — J35 : bêta privée contrôlée.** Prépare la validation terrain auprès d'un petit
> groupe de testeurs Android volontaires.
>
> **Arbitrages verrouillés** (ne pas les rouvrir) : 1. Bêta privée contrôlée, retours et corrections
> ciblées. 2. Petit groupe volontaire, appareils Android variés. 3. Accès individuel contrôlé, version
> identifiée, procédure de retrait. 4. Formulaire structuré : bugs, ergonomie, performances, plaisir
> de jeu. 5. Aucune télémétrie intrusive ; diagnostics minimaux consentis. 6. Tri P0–P3, corrections
> ciblées, nouvelles builds testées. 7. Rapport bêta, stabilité démontrée, décision de poursuite.
>
> **Audit préalable** : dépôt réel, branche active, exports Android, tests, livrables J33/J34 ;
> existence d'une RC acceptée sans P0/P1 ; **séparément**, conditions de conformité et droits
> nécessaires à la diffusion externe. Si elles ne sont pas réunies : préparer le protocole sans
> recommander la distribution. N'inventer aucun APK, testeur, appareil ou résultat.
>
> **Plan** : taille et profils du groupe ; matrice des appareils réellement disponibles ; invitation
> et information des volontaires ; distribution individuelle et retrait ; identification exacte de
> chaque build ; scénarios (installation, première session, exploration, combat, sauvegarde,
> reprise) ; formulaire court et reproductible ; collecte minimale et consentie des diagnostics ;
> registre P0–P3 ; cycle correction, régression, retest ; rapport final et décision.
>
> **Contraintes** : projet Godot Android, S24 de référence ; DA 2D HD peinte, vue orthogonale,
> contrôles tactiles ; aucune région, quête, espèce ou fonctionnalité majeure nouvelle ; idées des
> testeurs consignées pour plus tard ; distribution privée ou gratuite jamais considérée comme une
> autorisation d'utiliser les éléments protégés de Pokémon ; aucune donnée personnelle ou diagnostic
> non nécessaire.
>
> **Livrables** : 1. Audit des prérequis J34. 2. Protocole de bêta. 3. Matrice testeurs et appareils.
> 4. Distribution et retrait. 5. Formulaire de retours. 6. Diagnostics et consentement. 7. Scénarios
> terrain. 8. Registre et cycle correctif. 9. Lots 35.0 à 35F. 10. Modèle de rapport final.
> 11. Critères de sortie et Go/No-Go. 12. Transmission technique à Codex. Distinguer faits vérifiés,
> décisions validées et recommandations nouvelles.
>
> Conception et audit uniquement. Ne rien coder avant validation ; ne pas prétendre avoir exécuté une
> bêta qui n'a pas eu lieu.

---

## Note de la session de coordination (2026-10-19)

Le J35 dépend entièrement du **Go juridique** du J34 (§7 du dossier J34) : sans lui, la bêta reste à
l'état de protocole, et le jeu reste ce que `CLAUDE.md` décrit, un remake **personnel**. Cette
décision appartient à Kevin, éclairé par un avis compétent ; les sessions de développement ne la
prennent pas.
