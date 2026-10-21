# Kanto 2026 — J34 : Release Candidate Android

> Dossier de conception consolidé V1 (ChatGPT), transmis par Kevin le 2026-10-19, **avant le
> lancement du J34** (conception en avance, `strategie-acceleration.md` levier 2). 7 arbitrages
> verrouillés. Notes de la session de coordination à la fin.

Dernière phase de préparation technique : transformer la version stabilisée en **Release Candidate
(RC) Android** installable, testable et distribuable en privé, avec des critères vérifiables. On ne
démontre plus que chaque fonctionnalité existe : on démontre que le jeu fonctionne **hors de
l'environnement de développement** (installation propre, mise à jour, interruption Android).

## 1. Les sept arbitrages définitifs

| # | Domaine | Décision verrouillée |
|---|---|---|
| 1 | Périmètre | Release Candidate Android, sans nouveau contenu |
| 2 | Compatibilité | Installation propre, mise à jour et désinstallation sur plusieurs appareils |
| 3 | Distribution | APK signé, versionné, distribué en privé |
| 4 | Première utilisation | Audit du lancement, de la nouvelle partie, des paramètres et des commandes |
| 5 | Résilience | Stockage faible, interruptions, permissions, veille et fermeture forcée |
| 6 | Conformité | Licences, ressources, confidentialité et propriété intellectuelle |
| 7 | Acceptation | Tests documentés, zéro P0/P1, décision Go/No-Go |

Aucun ajout de Pokémon, de carte, de quête ou de fonctionnalité majeure.

## 2. Position dans la feuille de route

J32 (collection et rejouabilité) → J33 (stabilisation globale, APK de référence) → **J34 (Release
Candidate : installation, résilience, conformité, décision de sortie)** → J35 (préparation de
diffusion privée : documentation, retours testeurs, maintenance).

**Condition d'entrée** : le J34 ne peut pas être déclaré terminé tant que le J33 n'a pas produit une
base suffisamment stable.

## 3. Construction de la Release Candidate

**Identité du build** (chaque APK traçable jusqu'à son code et sa configuration) :

| Élément | Exigence |
|---|---|
| Nom de version | Exemple : `0.34.0-rc.1` (convention proposée, pas une version générée) |
| Code de version Android | Entier croissant à chaque build distribué |
| Commit Git | SHA exact du code compilé |
| Version de Godot | Version exacte, pas seulement majeure |
| Export Android | Configuration et architecture documentées |
| Signature | Clé de signature privée stable et sécurisée |
| Identifiant d'application | Stable entre les versions |
| Empreinte APK | SHA-256 publiée dans le manifeste interne |
| Journal des modifications | Correctifs et limitations de la RC |

**Pipeline cible** : commit identifié → tests automatisés réussis → export Android de
production-test → signature → SHA-256 et manifeste → installation sur appareils de test → rapport
QA et décision Go/No-Go.

La clé de signature n'est **jamais** dans le dépôt Git, les logs de CI ou un APK. Prévoir une gestion
des secrets et une procédure de conservation sécurisée.

## 4. Installation et compatibilité Android

| Profil | Objectif |
|---|---|
| Galaxy S24 | Appareil principal, tests complets |
| Android récent, autre constructeur | Comportements non spécifiques à Samsung |
| Android plus ancien, compatible avec le projet | Compatibilité minimale |
| Appareil avec moins de mémoire | Problèmes de chargement et de ressources |
| Résolution ou densité différente | Interface et contrôles tactiles |

Appareils choisis selon ce qui est **réellement disponible** ; ne jamais inventer une liste
d'appareils « testés ».

**Trois scénarios obligatoires** :

- **Installation propre** : aucun reste de Kanto 2026 ; le jeu démarre, crée ses données, lance une
  nouvelle partie.
- **Mise à jour** : version précédente installée avec une sauvegarde ; la RC s'installe par-dessus
  (même identifiant, signature compatible) ; progression conservée.
- **Désinstallation** : suppression propre ; conséquences sur les sauvegardes locales clairement
  expliquées au testeur (la désinstallation peut supprimer les données).

Le test de migration utilise une **vraie sauvegarde ancienne**, pas une sauvegarde créée par la RC.

## 5. Première expérience utilisateur

Parcours critique : 1. premier lancement (logo, chargement, orientation, affichage) ; 2. menu
principal (nouvelle partie, continuer, paramètres) ; 3. introduction (dialogues, lisibilité,
rythme) ; 4. choix du personnage et du starter (contrôles, confirmation, sauvegarde) ; 5. première
exploration (déplacements, interactions, collisions) ; 6. premier combat (attaques, Sac,
changements, retour au monde).

Objectif : une personne qui n'a jamais vu le projet comprend les commandes et joue **sans
intervention du développeur**. Aides courtes, contextuelles, non intrusives. DA inchangée (vue
orthogonale peinte, ni minimap ni flèches). Dialogues de deux lignes d'environ 40 caractères.

## 6. Résilience Android

| Scénario | Résultat attendu |
|---|---|
| Appui sur Accueil pendant un combat | Reprise cohérente |
| Verrouillage de l'écran | Aucun état corrompu |
| Appel ou notification | Commandes restaurées correctement |
| Rotation de l'appareil | Orientation prévue conservée |
| Fermeture forcée | Reprise depuis un état sauvegardé valide |
| Stockage presque plein | Échec de sauvegarde détecté, sans écraser la dernière copie valide |
| Mémoire sous pression | Comportement maîtrisé |
| Permissions refusées | Pas de crash ; fonctionnement adapté |
| Mise à jour avec sauvegarde ancienne | Migration réussie |
| Réinstallation après désinstallation | Comportement documenté, sans promesse de récupération automatique |

**Politique de sauvegarde** : vérifier dans l'**APK signé** les protections du J33 (écriture
atomique, version de schéma, validation au chargement, secours, migrations). Scénario le plus
sensible : interruption pendant une opération unique (capture d'un légendaire, échange, évolution,
remise d'objet, entrée au Panthéon). Jamais deux Pokémon pour une capture, jamais un Pokémon
supprimé sans transfert terminé.

## 7. Conformité et propriété intellectuelle

Kanto 2026 s'inspire de Pokémon Rouge/Bleu et utilise potentiellement des noms, personnages,
créatures, environnements, musiques et autres éléments protégés. **Gratuit, personnel ou distribué à
un petit groupe ne suffit pas à garantir que la distribution est autorisée.**

| Catégorie | Vérification |
|---|---|
| Sprites Pokémon | Auteur, provenance et droits |
| Personnages | Illustrations originales ou reprises |
| Cartes et décors | Création, adaptation et ressources tierces |
| Musiques et sons | Licence, droits d'utilisation et de diffusion |
| Polices | Licence d'intégration et de redistribution |
| Plugins Godot | Licence et obligations de mention |
| Ressources générées par IA | Provenance, conditions d'utilisation et droits éventuels |
| Marques et noms | Risques d'usage de propriétés intellectuelles tierces |
| Données des testeurs | Collecte, conservation et confidentialité |

Conformité technique, absence de monétisation et distribution privée sont trois sujets distincts ;
aucun n'autorise l'usage d'une propriété intellectuelle protégée.

**Deux décisions séparées** : **Go technique** (build stable, installé, testé) et **Go juridique /
conformité** (diffusion compatible avec les droits et obligations, après vérification appropriée).
Un Go technique ne remplace jamais un Go juridique. Sans droits établis, le projet peut rester en
développement et tests internes strictement contrôlés, sans présumer que cela élimine tout risque.

## 8. Dépendances

| Dépendance | Origine | Condition J34 |
|---|---|---|
| Version de référence | J33 | Build stabilisé disponible |
| Sauvegardes et migrations | J33 | Tests sur APK signé |
| Parcours complet | J33 | Aucune régression P0/P1 |
| Collection et stockage | J32 | Intégrité des données |
| Post-game et Mewtwo | J31 | Événements persistants |
| Ligue et Panthéon | J30 | Reprise et historique |
| CS et puzzles | J16–J29 | Contrôles tactiles fiables |
| Configuration Android | Projet Godot | Export reproductible |
| Ressources et licences | Ensemble du dépôt | Inventaire complet |
| Distribution privée | Nouveau J34 | Procédure documentée |

**Incompatibilités à éviter** : changer l'identifiant d'application ou la clé de signature (plus de
mise à jour par-dessus) ; une optimisation de textures qui change collisions ou coordonnées ; une
modification de sauvegarde qui rend illisibles les anciennes parties ; un correctif après QA sans
nouvelle identification de build ni réexécution des tests concernés.

## 9. Découpage technique

| Lot | Livrable |
|---|---|
| 34.0 | Audit du J33, inventaire du dépôt et critères d'entrée |
| 34A | Export Android, signature, versionnement et traçabilité |
| 34B | Installation propre, mise à jour, désinstallation et compatibilité |
| 34C | Première utilisation et ergonomie mobile |
| 34D | Résilience Android, sauvegardes et interruptions |
| 34E | Audit licences, ressources, confidentialité et propriété intellectuelle |
| 34F | Régression finale, rapport QA, décision Go/No-Go et paquet RC |

**Grille de décision RC** : APK signé et versionné (build reproductible et traçable) ; installation et
mise à jour (tests documentés sur plusieurs appareils) ; première utilisation (parcours sans
assistance validé) ; résilience (sauvegardes et interruptions vérifiées) ; qualité (zéro P0/P1
ouvert) ; conformité (inventaire et risques documentés) ; décision finale (Go/No-Go signé et
justifié). Une RC n'est pas acceptée parce que l'APK s'installe : tests et décision sont rattachés
au **même build identifié**.

## 10. Prompt de transmission à Claude (au lancement du J34)

> **Kanto 2026 — J34 : Release Candidate Android.** Prépare la validation finale d'une Release
> Candidate Android.
>
> **Arbitrages verrouillés** (n'en rouvrir aucun) : 1. RC Android, stabilisation finale, sans nouveau
> contenu. 2. Installation propre, mise à jour et désinstallation sur plusieurs appareils. 3. APK de
> test signé, versionné et distribué en privé. 4. Audit du lancement, de la nouvelle partie, des
> paramètres, des commandes et des premières minutes. 5. Tests de stockage faible, interruptions,
> permissions, veille et fermeture forcée. 6. Audit des licences, ressources, confidentialité et
> risques de propriété intellectuelle. 7. RC acceptée uniquement avec tests documentés, zéro P0/P1 et
> décision Go/No-Go.
>
> **Audit préalable** : dépôt, branche active, configuration Godot, exports Android, sauvegardes,
> résultats du J33 ; si le J33 n'a pas livré une base stable, lister précisément les prérequis
> manquants. Classer : implémenté et vérifié ; présent mais incomplet ; spécifié seulement ; absent ;
> non vérifiable. N'inventer aucun APK, commit, appareil testé ou résultat de performance.
>
> **Construction RC** : pipeline reproductible (commit et branche, version Godot, version et code
> Android, export, signature sécurisée, SHA-256, journal des changements, manifeste). N'exposer aucune
> clé ni secret.
> **Compatibilité** : matrice fondée sur les appareils réellement disponibles ; installation propre,
> mise à jour avec sauvegarde ancienne, désinstallation, premier démarrage ; identifiant, signature,
> migrations.
> **Première expérience** : menu principal, nouvelle partie, paramètres, introduction, starter,
> premières interactions, premier combat ; DA 2D HD peinte, dialogues courts, contrôles S24.
> **Résilience** : arrière-plan, veille et verrouillage, notifications et appels, fermeture forcée,
> stockage faible, mémoire sous pression, permissions refusées, sauvegardes interrompues, reprise
> après mise à jour ; opérations uniques (légendaires, échanges, évolutions, objets, Panthéon).
> **Conformité** : inventaire des ressources et de leur provenance ; licences de code, plugins,
> polices, musiques, sons, sprites, illustrations, ressources IA ; risques distincts sur la propriété
> intellectuelle Pokémon, les marques et la confidentialité des testeurs ; une distribution gratuite
> ou privée n'est pas automatiquement autorisée ; Go technique et Go juridique séparés.
>
> **Livrables** : 1. Rapport d'audit factuel du dépôt et des prérequis J33. 2. Configuration de build
> RC. 3. Procédure de signature et de versionnement. 4. Matrice multiappareil. 5. Tests
> d'installation, mise à jour, désinstallation. 6. Audit de première utilisation. 7. Tests de
> résilience et sauvegardes. 8. Inventaire des licences et risques. 9. Lots 34.0 à 34F. 10. Rapport
> QA et registre P0–P3. 11. Checklist Go/No-Go. 12. Plan de transmission à Codex. Citer pour chaque
> constat les chemins, configurations ou résultats réellement observés.
>
> Conception et audit uniquement. Ne rien coder avant validation ; ne pas prétendre avoir généré une
> RC si elle n'existe pas.

---

## Notes de la session de coordination (2026-10-19), pour l'audit 34.0

- **Cadre du projet** : `CLAUDE.md` définit Kanto 2026 comme un remake **personnel**. Toute
  distribution au-delà (même privée, même gratuite) relève du **Go juridique** du §7 : c'est une
  décision de Kevin, à éclairer par un avis compétent, pas par les sessions de développement.
- **Export Android aujourd'hui** (`export_presets.cfg`) : un seul preset **debug**
  (`build/kanto2026-debug.apk`), arm64-v8a seulement, paquet `dev.kevin.kanto2026` ; **aucun
  numéro de version** (`version/code`, `version/name`) et aucune configuration de signature release.
  Le lot 34A part de zéro sur ces points.
- **Secrets** : aucun keystore ni fichier d'identifiants n'est suivi par Git aujourd'hui ; garder ce
  principe (identifiants d'export Godot hors dépôt).
- **Licences** : seul plugin présent, `addons/gut` (GUT 9.7.1, licence dans
  `addons/gut/LICENSE.md`) ; c'est un outil de test, à exclure de l'export si possible. Aucune police
  trouvée dans `assets/fonts/` lors de ce repérage.
- **Sauvegardes** : voir les notes du J33 (atomique et versionné depuis le jalon 5 ; secours et
  arrière-plan Android à ajouter).
