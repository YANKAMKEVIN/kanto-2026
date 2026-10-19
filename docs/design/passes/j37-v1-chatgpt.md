# Kanto 2026 — J37 : Version 1.0 et préparation de l'exploitation

> Dossier consolidé V1 (ChatGPT), transmis par Kevin le 2026-10-19, **avant le lancement du J37**
> (conception en avance, `strategie-acceleration.md` levier 2). 7 arbitrages verrouillés. La
> checklist interactive de la passe d'origine est reprise en liste à cocher (§10).

On organise la vie du jeu après sa livraison : versionnement, maintenance, mises à jour,
sauvegardes, support et archivage. Objectif : une **version 1.0** identifiable, reproductible et
maintenable, sans ajout de contenu. Trois états distincts : le dossier est validé ; son
implémentation reste à vérifier ; la diffusion exige une décision de conformité indépendante.

## 1. Les sept décisions définitives

| # | Domaine | Décision verrouillée |
|---|---|---|
| 1 | Périmètre | Préparer la version 1.0 et son exploitation, sans nouveau contenu |
| 2 | Versionnement | Tag Git, build reproductible, traçabilité et archives |
| 3 | Maintenance | Correctifs 1.0.x avec tests de régression ciblés |
| 4 | Sauvegardes | Mises à jour compatibles et récupération documentée |
| 5 | Support | Signalement, FAQ et suivi des anomalies |
| 6 | Distribution | Séparer exploitation interne, diffusion autorisée et publication publique |
| 7 | Livraison | Dossier 1.0, plan de maintenance et décision finale documentée |

Aucune nouvelle région, espèce, quête ou mécanique de gameplay.

## 2. Architecture de livraison 1.0

J36 stable candidate (tests, migrations, anomalies validés) → gel de version (commit exact,
dépendances figées) → build 1.0 (APK signé, export reproductible) → validation (installation, mises à
jour, tests critiques) → archivage (tag Git, manifeste, artefacts, rapports) → exploitation (support,
correctifs, récupération) → décision finale (Go technique et conformité séparés).

La 1.0 se construit à partir d'une J36 **réellement acceptée** ; sinon, le travail reste en correction
et validation.

## 3. Versionnement, tags Git et reproductibilité

| Élément | Convention proposée |
|---|---|
| Version applicative | `1.0.0` |
| Tag Git | `v1.0.0` |
| Branche de maintenance | `release/1.0` |
| Correctifs | `1.0.1`, `1.0.2`, etc. |
| Code Android | Entier croissant |
| Identifiant Android | Stable |
| Signature | Même identité pour les mises à jour compatibles |
| Manifeste | Commit, Godot, SDK, export, signature et SHA-256 |

Propositions : vérifier d'abord les conventions existantes du dépôt pour ne pas créer de système
parallèle.

**Paquet attendu** (décrit, pas encore créé) :

```
releases/1.0.0/
├── kanto-1.0.0.apk
├── manifest.json
├── SHA256SUMS
├── release-notes.md
├── known-issues.md
├── qa-report.md
├── compatibility.md
├── migration-report.md
└── go-no-go.md
```

Le manifeste identifie le commit exact, la version de Godot, les dépendances pertinentes, la
configuration d'export Android et l'empreinte de l'APK. **Clés de signature, mots de passe et secrets
de CI ne sont jamais archivés avec les artefacts.**

**Reproductibilité** : un second environnement reprend le commit et la configuration pour produire un
APK **fonctionnellement équivalent**. La reproductibilité octet pour octet est plus exigeante (outils
de signature, métadonnées) : à vérifier, jamais à présumer.

## 4. Maintenance corrective 1.0.x

`release/1.0` est réservée aux corrections compatibles avec la 1.0.

| Type de modification | Autorisé en 1.0.x ? |
|---|---|
| Correction d'un crash | Oui |
| Correction d'une perte de sauvegarde | Oui, priorité absolue |
| Correction de collision bloquante | Oui |
| Correction d'un problème tactile | Oui |
| Optimisation sans changement fonctionnel | Oui, après tests |
| Ajout d'une nouvelle région | Non |
| Ajout d'une nouvelle espèce | Non |
| Refonte majeure du système de combat | Non |
| Rupture volontaire du format de sauvegarde | Non |

**Cycle** : ticket reproductible → analyse et correction minimale → tests unitaires et ciblés →
régression des dépendances → build 1.0.x signé → installation et migration → publication dans le
canal autorisé. Chaque correctif mentionne le problème, le commit, les tests et les versions
concernées. Une correction de sauvegarde ou de progression déclenche une régression plus large
qu'une correction cosmétique.

## 5. Sauvegardes et récupération

Principe : continuité de progression entre versions compatibles.

| Données | Exigence |
|---|---|
| Pokémon | Aucun individu perdu ou dupliqué |
| Équipe et stockage | Contenu et caractéristiques préservés |
| Pokédex | Entrées vues et capturées conservées |
| Inventaire | Quantités et objets uniques cohérents |
| Badges | Progression intacte |
| Événements | Cadeaux, Dresseurs et légendaires persistants |
| Ligue | Victoire et Panthéon conservés |
| Post-game | Accès et état de Mewtwo inchangés |
| Position | Coordonnées valides au chargement |
| Préférences | Paramètres compatibles conservés |

- Version de **schéma** distincte de la version de l'application ; 1.0.0 → 1.0.1 n'implique pas
  forcément une migration ; tout changement de schéma est explicite, testé et sécurisé.
- Avant migration, préserver une copie valide de l'état précédent ; en cas d'échec, ne jamais
  l'écraser.
- **Guide de récupération** : reconnaître une sauvegarde illisible, actions à éviter, récupérer une
  copie de secours si elle existe, informations à transmettre au support. Aucune promesse de
  récupération après désinstallation sans sauvegarde externe.

## 6. Support et suivi des anomalies

Recommandation : tickets liés au dépôt GitHub si l'organisation le permet, plutôt que dispersés.

**Ticket minimal** : version du jeu et appareil ; description ; étapes de reproduction ; attendu et
observé ; fréquence et gravité ; capture ou journal facultatif, avec précautions de confidentialité.
États : Nouveau, À reproduire, Confirmé, En correction, À retester, Résolu, Reporté.

| Question de la FAQ | Réponse à documenter |
|---|---|
| Comment installer le jeu ? | Procédure selon le canal autorisé |
| Comment mettre à jour ? | Installation compatible par-dessus l'ancienne version |
| Vais-je perdre ma sauvegarde ? | Comportement vérifié et précautions |
| Pourquoi l'APK ne s'installe pas ? | Compatibilité, signature, espace disponible |
| Que faire après un crash ? | Reprise et signalement |
| Comment déclarer un bug ? | Canal et informations nécessaires |
| Comment revenir à une ancienne version ? | Limites techniques et risques de sauvegarde |

La FAQ n'affirme jamais qu'une restauration existe si elle n'est pas implémentée.

## 7. Distribution et conformité : trois décisions distinctes

- **Exploitation interne** : développement, tests techniques, archivage, maintenance.
- **Diffusion autorisée** : partage seulement dans un périmètre couvert par les droits et
  autorisations nécessaires.
- **Publication publique** : décision séparée, après examen juridique et conformité, jamais
  automatique.

Kanto 2026 reprend des éléments de l'univers Pokémon ; gratuité ou absence de publicité n'autorisent
pas leur redistribution. Une version techniquement stable peut être prête pour l'exploitation interne
sans être autorisée à la publication. Le J37 produit **deux décisions** : Go/No-Go technique et
Go/No-Go de distribution, avec preuves et limites.

## 8. Dépendances J0–J36

| Dépendance | Origine | Condition J37 |
|---|---|---|
| Contenu complet et collection | J0–J32 | Aucun blocage de progression connu |
| Stabilité générale | J33 | Régressions critiques validées |
| APK signé et traçable | J34 | Pipeline de build maîtrisé |
| Tests multiappareils | J34/J35 | Compatibilité documentée |
| Retours et anomalies | J35 | Registre exploitable |
| Sauvegardes bêta migrées | J36 | Continuité confirmée |
| Version stable candidate | J36 | Go technique explicite |
| Performances | J33–J36 | Résultats disponibles |
| Documentation | J36 | Mise à jour pour la 1.0 |
| Droits et licences | J34–J36 | Statut de diffusion documenté |
| Support et correctifs | Nouveau J37 | Procédures opérationnelles |

**Vigilance** : pas de tag final juste pour respecter le numéro du jalon (dépend du Go J36) ;
signature Android cohérente (une autre clé empêche la mise à jour directe) ; sauvegardes testées sur
de **vraies mises à jour d'APK**, pas seulement en test unitaire ; maintenance possible après le gel
(outils de build, configurations et informations de signature conservés de façon sécurisée).

## 9. Découpage technique

| Lot | Livrable |
|---|---|
| 37.0 | Audit de J36, prérequis et état réel du dépôt |
| 37A | Versionnement, tag Git, manifeste et archivage |
| 37B | Pipeline reproductible et génération APK 1.0 |
| 37C | Maintenance 1.0.x et politique de correctifs |
| 37D | Compatibilité des sauvegardes et récupération |
| 37E | Support, FAQ, suivi des anomalies et conformité |
| 37F | Dossier de livraison, validations et Go/No-Go final |

Ordre : 37.0 → 37A à 37D (en partie en parallèle) → 37E → 37F. Le dossier final référence **une
seule** version clairement identifiée.

## 10. Critères de sortie : checklist de livraison 1.0

- [ ] Go technique J36 confirmé
- [ ] Version 1.0 identifiée par un commit et un tag
- [ ] APK signé et installation vérifiée
- [ ] Manifeste et empreinte SHA-256 disponibles
- [ ] Mises à jour et sauvegardes validées
- [ ] Tests critiques exécutés sur le build final
- [ ] Procédure de correctifs 1.0.x documentée
- [ ] FAQ et canal de support opérationnels
- [ ] Rapport de conformité et statut de diffusion disponibles
- [ ] Décisions Go/No-Go finales enregistrées

Outil de suivi, pas une validation automatique. **« J37 terminé »** : dossier 1.0 existant, tests
prouvés, décisions finales enregistrées.

## 11. Prompt de transmission à Claude (au lancement du J37)

> **Kanto 2026 — J37 : préparation de la version 1.0 et maintenance.** Rôle : architecte technique,
> auditeur QA et responsable de préparation de livraison (jeu Godot Android, 2D HD peinte, vue
> orthogonale, Galaxy S24 de référence). Mission : auditer le dépôt réel et préparer le J37 (version
> 1.0, reproductibilité, maintenance, sauvegardes, support, conformité, dossier de livraison). Aucun
> nouveau contenu de gameplay.
>
> **Arbitrages verrouillés** (n'en rouvrir aucun) : 1. Version 1.0 et exploitation, sans nouveau
> contenu. 2. Version traçable, tag Git, build reproductible, archives. 3. Correctifs 1.0.x avec
> régression ciblée. 4. Mises à jour compatibles et récupération des sauvegardes. 5. Signalement,
> FAQ, suivi des anomalies. 6. Exploitation interne, diffusion autorisée et publication publique
> séparées. 7. Dossier 1.0, plan de maintenance, décision finale documentée.
>
> **Phase 1 — Prérequis** : dépôt, branche, historique ; Godot ; export Android ; identifiant et
> codes de version ; compilation et signature ; formats de sauvegarde et migrations ; tests ; rapports
> QA J33–J36 ; anomalies ouvertes et état de la stable candidate ; licences et contraintes de
> diffusion. Chemins, commits ou résultats observables pour chaque constat. Classer : implémenté et
> vérifié ; présent mais incomplet ; spécifié uniquement ; absent ; non vérifiable. Si le J36 n'a pas
> produit de stable candidate acceptée, signaler le blocage et ne préparer que ce qui peut l'être.
> **Phase 2 — Versionnement et archivage** : auditer les conventions existantes avant de proposer
> `1.0.0`, `v1.0.0`, `release/1.0`, codes Android croissants, manifeste, SHA-256, journal,
> conservation des artefacts (propositions, pas des éléments existants) ; procédure reproductible
> sans exposer de clé ni de secret.
> **Phase 3 — Maintenance 1.0.x** : ticket → reproduction → correction minimale → tests → build →
> vérification → livraison autorisée ; règles de sélection et tests selon l'impact ; aucune
> fonctionnalité majeure dans un correctif.
> **Phase 4 — Sauvegardes et mises à jour** : schéma versionné, compatibilité entre builds,
> migrations incrémentales, écritures atomiques, copies de secours, reprise après interruption,
> récupération, installation par-dessus une version existante ; Pokémon, stockage, objets, Badges,
> événements uniques, Pokédex, Ligue, Panthéon, post-game ; aucune restauration promise après
> désinstallation sans mécanisme réel.
> **Phase 5 — Support** : modèle de ticket, P0–P3, FAQ, guide d'installation et de mise à jour,
> diagnostic, registre, collecte minimale ; outils déjà présents d'abord.
> **Phase 6 — Distribution et conformité** : exploitation interne / diffusion couverte par les droits
> / publication publique éventuelle ; ne jamais présumer qu'une distribution gratuite ou privée est
> autorisée ; Go technique et Go juridique distincts.
>
> **Livrables** : 1. Audit factuel J36 → J37. 2. Dépendances et blocages. 3. Versionnement et
> archivage. 4. Build et signature. 5. Maintenance 1.0.x. 6. Compatibilité des sauvegardes.
> 7. Récupération. 8. FAQ et support. 9. Dossier de conformité. 10. Lots 37.0 à 37F. 11. Checklist
> 1.0. 12. Matrice Go/No-Go. 13. Prompts d'implémentation pour Codex, par lots contrôlables. Pour
> chaque lot : prérequis, fichiers réellement concernés, modifications, tests, risques, critères
> d'acceptation, retour arrière.
>
> Conception et audit uniquement. Ne rien coder avant validation ; n'annoncer aucun APK, tag, test ou
> résultat sans l'avoir vérifié.

---

## Notes de la session de coordination (2026-10-19), pour l'audit 37.0

- **Conventions existantes** : un seul tag Git dans le dépôt aujourd'hui, aucune branche `release/*`,
  aucun numéro de version dans `project.godot` (`config/version`) ni dans `export_presets.cfg`. Les
  conventions du §3 ne remplacent donc rien ; elles sont à poser au J34 (lot 34A), puis reprises ici.
- **Schéma de sauvegarde** : déjà distinct de la version de l'application, comme le demande le §5
  (`SaveSystem.VERSION = 7`, `game/systems/save/save_system.gd`).
