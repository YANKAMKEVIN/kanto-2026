# Kanto 2026 — J40 : Audit de clôture du cycle J0–J39

> Dossier consolidé V1 (ChatGPT), transmis par Kevin le 2026-10-19, **avant le lancement du J40**
> (conception en avance, `strategie-acceleration.md` levier 2). 7 arbitrages verrouillés. Les
> éléments interactifs de la passe d'origine (sélecteurs de décision) sont repris en texte (§12–13).
> Notes de la session de coordination à la fin.

On cesse d'ajouter des fonctionnalités ou des processus pour établir, **preuves à l'appui**, ce qui
existe réellement. Quatre questions : 1. le jeu prévu par J0–J39 est-il implémenté ? 2. peut-on finir
l'aventure du Bourg Palette à Mewtwo sans blocage ni perte de progression ? 3. l'application Android
est-elle stable, reproductible et maintenable ? 4. que reste-t-il avant de déclarer le cycle terminé ?

**Règle fondamentale : un jalon validé dans nos échanges n'est pas un jalon réalisé dans le dépôt.**

## 1. Les sept décisions définitives

| # | Domaine | Décision verrouillée |
|---|---|---|
| 1 | Périmètre | Audit exhaustif J0–J39 et décision de clôture |
| 2 | Dépôt | Comparaison des spécifications avec fichiers, commits, tests et builds |
| 3 | Écarts | Matrice Implémenté / Partiel / Absent / Non vérifiable, avec priorités |
| 4 | Parcours | Tests complets Bourg Palette → Mewtwo, sauvegardes et variantes |
| 5 | Android | APK, Galaxy S24, compatibilité, performances et migrations |
| 6 | Livraison | Archives, sécurité, documentation, droits et diffusion |
| 7 | Sortie | Rapport de clôture, corrections prioritaires et Go/No-Go |

Aucune nouvelle région, espèce, quête ou mécanique.

## 2. Architecture de l'audit

01 inventaire (dépôt, branches, tags, builds, documents) → 02 traçabilité (J0–J39 confrontés au code
et aux ressources) → 03 exécution (tests automatiques, parcours de bout en bout) → 04 Android
(installation, appareils, performance, sauvegardes) → 05 conformité (licences, secrets, archives,
droits) → 06 écarts (priorités, corrections, risques) → 07 décision (rapport et Go/No-Go).

## 3. Méthode : chaque affirmation a une preuve

| État | Définition |
|---|---|
| Implémenté | Code et ressources présents, comportement vérifié par des preuves adaptées |
| Partiel | Présent, mais incomplet ou insuffisamment validé |
| Absent | Éléments nécessaires non trouvés après inspection suffisante |
| Non vérifiable | Preuves insuffisantes, accès manquant ou test inexécutable |

Un script présent ne prouve pas que la fonctionnalité marche ; l'absence de test automatisé ne prouve
pas qu'elle est absente.

**Modèle de matrice** (pas un résultat) :

| ID | Exigence | État | Preuve | Priorité |
|---|---|---|---|---|
| J16-CS-01 | CS hybrides | À auditer | Fichier + test à identifier | À établir |
| J23-SAF-01 | Safari | À auditer | Scènes + règles + test | À établir |
| J30-LIG-01 | Ligue complète | À auditer | Combat + progression | À établir |
| J31-MEW-01 | Mewtwo unique | À auditer | Rencontre + sauvegarde | À établir |
| J34-APK-01 | Export Android | À auditer | APK + manifeste + installation | À établir |
| J38-CI-01 | Pipeline automatisé | À auditer | Workflow + exécution | À établir |

Chaque preuve : chemin ou commit, puis si nécessaire résultat de test, capture ou journal.

## 4. Audit fonctionnel J0–J39

| Domaine | Jalons | Vérifications principales |
|---|---|---|
| Fondations et aventure initiale | J0–J15 | Scènes, contrôles, systèmes, progression, contenu selon les dossiers d'origine |
| CS et exploration | J16–J22 | Conditions d'accès, déplacements, cartes, transitions |
| Safari et Parmanie | J23 | Pas, Safari Balls, Surf, Force, Koga |
| Îles Écume et Cramois'Île | J24–J25 | Donjons, Artikodin, Manoir, clé, Auguste |
| Safrania | J26–J27 | Sylphe SARL, Giovanni, Morgane, Dojo |
| Jadielle et Ligue | J28–J30 | Huitième Badge, Route Victoire, Sulfura, Conseil des Quatre, Champion |
| Post-game | J31–J32 | Grotte Inconnue, Mewtwo, collection |
| Stabilisation et bêta | J33–J36 | QA, builds, retours, corrections, migrations |
| Livraison et pérennisation | J37–J38 | Version 1.0, maintenance, CI, sécurité, documentation |
| Gouvernance | J39 | Backlog, contrats, versions, décisions |

Pour J0–J15, récupérer les **dossiers de conception d'origine** plutôt que des résumés.

**Contrats sensibles** : CS hybrides (J16) ; événements uniques non duplicables (J23–J32) ; Ligue en
cinq combats avec ressources persistantes, reprise depuis le début, Panthéon, post-game (J30) ;
Mewtwo N70 après première victoire à la Ligue (J31) ; collection des 151 en distinguant le
techniquement possible, ce qui dépend de choix exclusifs et l'événementiel (J32).

## 5. Tests de bout en bout

**Parcours de référence** (une vraie aventure, pas des scènes ouvertes une à une) : 1. nouvelle
partie, starter, premiers combats, sauvegarde ; 2. villes, routes, événements et Arènes du début ;
3. Parmanie, Safari, Surf et Force ; 4. Îles Écume, Cramois'Île, Manoir, Auguste ; 5. Sylphe SARL,
libération de Safrania, Morgane, Giovanni ; 6. huit Badges, rival de la Route 22, Route Victoire ;
7. Conseil des Quatre, Champion, Panthéon, retour au monde ; 8. Grotte Inconnue, Mewtwo, sauvegarde
finale.

**Variantes** : les trois starters ; choix exclusifs (fossiles, Dojo) ; chemins non linéaires
autorisés ; défaites ; interruptions. Parcours principal avec de **vraies sauvegardes** ; les états
accélérés complètent sans remplacer.

| Régression obligatoire | Résultat attendu |
|---|---|
| Défaite à la Ligue | Tentative terminée, reprise conforme |
| Interruption pendant une sauvegarde | Dernier état valide récupérable |
| Capture d'un légendaire puis rechargement | Aucun doublon |
| Évolution ou échange local | Données conservées sans duplication |
| Mise à jour Android | Progression compatible |
| Retour au monde après le Panthéon | Post-game accessible |
| Migration d'une sauvegarde ancienne | Inventaire, équipe et événements intacts |

## 6. Audit Android et qualité

| Contrôle | Preuve attendue |
|---|---|
| Export Godot | Journal de compilation réussi |
| APK | Fichier identifié et empreinte SHA-256 |
| Installation | Installation effective sur Android |
| Mise à jour | Conservation de l'application et des données |
| Signature | Cohérence avec les versions précédentes |
| Écran tactile | Commandes et interfaces vérifiées |
| Performances | FPS, chargement et mémoire mesurés |
| Résilience | Veille, notifications, interruptions et reprise |
| Compatibilité | Résultats par appareil réellement disponible |
| Migrations | Sauvegardes anciennes chargées et vérifiées |

Un build qui compile sans s'installer, ou s'installe sans conserver les sauvegardes, ne satisfait
pas le J40. Mesures avec appareil, version Android, version du jeu et conditions. Sans appareil
physique : **Non vérifiable sur appareil**, jamais « Test réussi ».

## 7. Livraison, sécurité et conformité

Artefacts, secrets, licences, permissions Android, dépendances, documents de livraison.

**Dossier de clôture attendu** :

```
audit-j40/
├── 00-executive-summary.md
├── 01-repository-inventory.md
├── 02-requirements-matrix.csv
├── 03-functional-regression.md
├── 04-android-qa.md
├── 05-save-integrity.md
├── 06-security-and-dependencies.md
├── 07-assets-and-rights.md
├── 08-open-defects.md
├── 09-corrective-roadmap.md
├── 10-go-no-go.md
└── evidence/
```

Preuves référencées, sans secrets ni données personnelles inutiles.

**Deux décisions indépendantes** : **Go technique** (gameplay, stabilité, Android, sauvegardes,
tests, maintenance) et **Go de diffusion** (droits sur les ressources, licences, autorisations,
périmètre). Une 1.0 techniquement réussie n'est pas automatiquement distribuable ; les éléments
protégés de l'univers Pokémon exigent un examen spécifique.

## 8. Dépendances

| Prérequis | Origine | Exigence J40 |
|---|---|---|
| Spécifications fonctionnelles | J0–J32 | Exigences complètes et identifiables |
| Stabilisation | J33 | Rapports de tests et corrections |
| Release Candidate | J34 | APK et Go/No-Go documentés |
| Bêta | J35 | Résultats et retours réels |
| Stable Candidate | J36 | Régressions et migrations vérifiées |
| Version 1.0 | J37 | Build, tag, manifeste et archives |
| Pérennisation | J38 | CI, sécurité, documentation et récupération |
| Gouvernance | J39 | Backlog, contrats et décisions |
| Dépôt GitHub | Transversal | Accès en lecture aux sources et à l'historique |
| Appareils Android | Transversal | Tests réels ou limites clairement indiquées |

Cohérent : aucune fonctionnalité nouvelle requise. **Dépendance méthodologique majeure** : les
dossiers de conception ne sont pas des preuves d'implémentation. Si J35, J36 ou J37 n'ont jamais été
exécutés, l'audit le révèle, sans fabriquer de rapports.

## 9. Priorisation des écarts

| Niveau | Signification | Décision |
|---|---|---|
| P0 | Perte de données, corruption majeure ou défaut critique | Blocage immédiat |
| P1 | Progression impossible ou fonction essentielle inutilisable | Blocage de clôture |
| P2 | Défaut significatif, sans blocage général | Correction planifiée ou risque accepté |
| P3 | Défaut mineur ou cosmétique | Documenter et reporter |

« Non vérifiable » n'est pas automatiquement P0 ; mais une exigence critique non vérifiée peut
empêcher un Go. **Registre** : exigence, preuve, attendu, observé, gravité, correctif, coût,
dépendances, test de validation ; aucune correction close sans preuve de retest.

## 10. Découpage

| Lot | Livrable |
|---|---|
| 40.0 | Inventaire du dépôt et collecte des spécifications J0–J39 |
| 40A | Matrice exhaustive exigences ↔ code ↔ preuves |
| 40B | Audit fonctionnel et tests de bout en bout |
| 40C | Android, performances, sauvegardes et migrations |
| 40D | Sécurité, archives, documentation et conformité |
| 40E | Registre des écarts et plan correctif priorisé |
| 40F | Rapport de clôture, Go/No-Go et décision sur la suite |

**« J40 achevé »** : toutes les exigences accessibles couvertes, non-vérifiables recensés, tests
exécutés documentés, écarts classés. La clôture de l'audit n'est pas forcément celle du
développement : un audit peut finir en **No-Go** avec un plan correctif.

## 11. Prompt de transmission à Claude (au lancement du J40)

> **Kanto 2026 — J40 : audit de clôture exhaustif J0–J39.** Rôle : auditeur principal, architecte
> Godot, responsable QA Android, responsable de préparation de livraison. Mission : audit factuel et
> exhaustif de J0 à J39, comparant les spécifications aux fichiers, commits, scènes, ressources,
> tests, APK et rapports réellement disponibles, pour décider si le cycle est terminé ou s'il faut un
> plan correctif.
>
> **Arbitrages verrouillés** (ne pas les rouvrir ; aucun contenu nouveau) : 1. Audit exhaustif et
> décision de clôture. 2. Chaque jalon comparé aux fichiers, commits, tests et builds. 3. Matrice
> Implémenté / Partiel / Absent / Non vérifiable, avec priorités. 4. Progression Bourg Palette →
> Mewtwo, sauvegardes, variantes. 5. APK, Galaxy S24, compatibilité, performances, migrations.
> 6. Archives, sécurité, documentation, droits, statut réel de diffusion. 7. Rapport de clôture,
> corrections prioritaires, Go/No-Go.
>
> **Règles impératives** : une spécification validée n'est pas une fonctionnalité implémentée ; aucun
> test déclaré réussi sans exécution ou preuve ; n'inventer ni APK, ni appareil, ni commit, ni
> résultat de bêta ; pas d'« absent » sans inspection suffisante ; signaler et expliquer le non
> vérifiable ; citer chemins, commits, journaux, artefacts ; aucun secret exposé ; aucune
> modification du code sans autorisation explicite.
>
> **Phases** : 1. Inventaire (branches, tags, historique, scènes, scripts, ressources, exports,
> compilation et signature, tests et CI, documentation J0–J39, tickets, rapports, APK, manifestes,
> archives ; d'abord confirmer ce qui est accessible ; lister les spécifications manquantes).
> 2. Matrice de traçabilité (identifiant, jalon, description, critère, fichiers, tests, résultats,
> état, gravité, action ; ne pas déduire un fonctionnement d'un simple nom). 3. Gameplay (contrats
> J16 à J32 ; spécifications J0–J15 d'origine, pas supposées). 4. Bout en bout (automatisé, manuel,
> impossible dans l'environnement, distingués ; un état préconfiguré ne remplace pas une vraie
> progression). 5. Android (configuration, export, signature, versionnement, APK, installation, mise
> à jour, sauvegardes, tactile, performances, appareils réellement accessibles ; sinon procédure
> exécutable). 6. Sécurité et conformité (dépendances, secrets, CI, signature, provenance, archives,
> documentation, licences, droits Pokémon, statut de diffusion ; Go technique et Go de diffusion
> séparés). 7. Écarts (P0–P3 ; gravité, impact, reproduction, preuve, cause, correction,
> dépendances, validation, risque ; lots ordonnés : progression, sauvegarde, stabilité Android
> d'abord). 8. Rapport final (résumé ; inventaire ; matrice J0–J39 ; couverture des tests ;
> progression ; Android ; sauvegardes ; sécurité ; licences et droits ; registre P0–P3 ; plan
> correctif ; non-vérifiables ; Go/No-Go technique ; décision de diffusion séparée ; recommandation
> pour la suite ; fiches Codex par lot correctif).
>
> **Décision finale** : audit terminé ou incomplet ; produit techniquement prêt ou non ; distribution
> autorisée, non autorisée ou non déterminée. Un No-Go justifié est acceptable. Ne rien coder avant
> validation : la priorité est la **vérité sur l'état du projet**, pas une conclusion positive.

## 12. Décision pour le cycle suivant

Ne pas ouvrir automatiquement un J41 de fonctionnalités : la suite dépend du rapport J40.

- **Scénario A — Go technique** : essentiel vérifié, tests critiques réussis, aucun P0/P1 →
  clôturer le développement, maintenance 1.0.x ; diffusion soumise à une autorisation distincte.
- **Scénario B — No-Go avec corrections ciblées** : jeu largement implémenté, quelques défauts
  bloquants → cycle correctif limité aux écarts documentés, puis retests.
- **Scénario C — No-Go structurel** : systèmes majeurs manquants, sauvegardes peu fiables ou preuves
  trop faibles → nouvelle feuille de route d'implémentation fondée sur les lacunes réelles, avant
  toute prétention à une 1.0.

## 13. Décision à enregistrer après l'audit

- **Résultat technique** : en attente des preuves / Go technique (clôture et maintenance) / No-Go
  (corrections ciblées) / No-Go (reprise structurelle).
- **Statut de diffusion** : droits non déterminés / diffusion autorisée pour un périmètre documenté /
  diffusion non autorisée ou suspendue.

---

## Note de la session de coordination (2026-10-19)

**Le J40 ne peut avoir de sens qu'une fois le code au niveau des dossiers.** Au 2026-10-19, `main`
contient J0 à J18 ; J19 à J25 sont en cours sur leurs branches ; J26 à J40 n'existent qu'en
conception. Lancer le J40.0 maintenant produirait surtout des « Absent » attendus (scénario C par
construction), sans information nouvelle. L'inventaire utile aujourd'hui est déjà tenu par
`docs/tech/etat-projet.md` et la roadmap.
