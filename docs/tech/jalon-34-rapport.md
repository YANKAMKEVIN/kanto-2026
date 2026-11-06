# Jalon 34 — rapport de la Release Candidate 0.34.1 (T7, lot 34F)

> Plan : `docs/tech/jalon-34.md`. Procédure : `docs/tech/release.md`. Rédigé le 2026-11-05.
> **Décisions (§6) : Go juridique consigné ; Go technique de Kevin pour le T4 (2026-11-05).**

## 1. Build identifié

| Élément | Valeur |
|---|---|
| Version | Pokemake **0.34.1**, code Android **3401** [D] (la 0.34.0 du 34B est déjà signée) |
| Commit | `012bdc8c295fe7ad1dc9489ec5a13b2f1298b659`, branche `release/0.34` |
| Contenu | **Kanto seul, décision de Kevin du 2026-11-04 (« Kanto seul (B) »)** : sauvegarde v9, aucune carte de Johto |
| Moteur | Godot 4.7.2 stable, preset Android, arm64-v8a, `minSdk` 24, `targetSdk` 36 |
| CI | **Succès**, run 41912534271, 8 lots sur 8 : 7 869 tests passants, 771 scripts |
| APK | `pokemake-0.34.1.apk`, 646 055 267 octets |
| SHA-256 | `b96e5dab6e0786716af5b3ae5c7bfbc578793f168f62140535af89e4c1452d90` |
| Signature | clé du 2026-11-04, certificat SHA-256 `01e2b98f…2c6d73` (même clé que la 0.34.0) |
| Contrôles de l'APK | `debuggable` absent, `allowBackup=false`, seule permission `VIBRATE`, zéro fichier de GUT, de tests, d'outils, de prototypes ou de Johto |
| Paquet archivé | `~/.pokemake/rc/0.34.1/` (APK, `manifest.json`, `SHA256SUMS`, consignes), hors dépôt |

**Composition de la branche.** Départ `99cae44d`, dernier commit de `main` sans Johto. Reports :

| Objet | Commits | Comment |
|---|---|---|
| Bande-annonce v2.1 | `d63e7d8c`, `c58bccc6` | fusion, puis reprise un par un |
| Résilience 34D | `54890e2c`, `fc0b2e22` | fusion, puis reprise un par un |
| Fiche 34E et Go juridique | `0d61019d`, `b0dbdc68` | reprise (documents) |
| Surf peint (Kevin : « Oui, les ajouter ») | `81702083`, `88bd8f59` | reprise |
| Dos peints de combat (idem) | `85ae12af`, `e12bcf64`, `37946728` | reprise |

Conflits : `etat-projet.md` et `jalon-34.md` seulement, aucun dans le code. Les fichiers de jeu repris
sont identiques à ceux de `main`. Aucun correctif de Kanto de `main` ne manque : les commits restants
hors Johto sont de la documentation et des départs de QA (`3bede56a`, `436b4f3d`, `6b3efe71`).

**Build refait** (critère 1) : deux exports du même commit ont le même listing de 10 841 lignes. Seuls
diffèrent les trois fichiers de signature, attendus, et le paquet de données `assets/assets.sparsepck`.
Cette dernière différence n'a pas été analysée ; le plan ne promet pas l'identité binaire. Le second
APK n'a été ni lancé ni conservé : l'équivalence fonctionnelle n'est donc montrée que par le listing.

## 2. Résultats T1 à T6

| Tâche | Résultat | Sur ce build ? |
|---|---|---|
| T1 version | Source unique, `tools/version.py check` cohérent, « v0.34.1 (3401) » lu à l'écran titre | oui |
| T2 build | `tools/build_rc.sh` sur arbre propre et CI verte, manifeste et SHA-256 | oui |
| T3 installation | Rejoué sur l'A17, §3 | oui |
| T4 première utilisation | **Pas fait** : à Kevin avec un proche (`jalon-34-t4-consignes.md`) | — |
| T5 résilience | 9 scénarios sur 10 sans P0/P1 (`jalon-34-34d.md`), joués sur un **APK debug** du 34D, évolution interrompue et stockage plein en simulation | partiel, §3 |
| T6 licences | Inventaire `jalon-34-34e.md` ; Go juridique au §14 | décision inchangée |

## 3. QA de la branche sur l'A17 (2026-11-04, 23 h 43 à 23 h 59)

Galaxy A17 (`SM-A175F`, Android 16, USB), Ne pas déranger actif. Aucune erreur de script, aucun
`FATAL EXCEPTION` ni ANR au journal. Captures : `build/qa-34f/` (hors Git).

| # | Scénario | Constaté | Résultat |
|---|---|---|---|
| 0 | RC par-dessus l'app debug | `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, app debug intacte | conforme |
| 1 | Mise à jour 0.33.0 re-signée → 0.34.1, vraie sauvegarde **v6** de Kevin jamais lancée | `pm install -r` réussi en 15 s ; carte « Continuer — Kevin, Jadelle, 23 h 36, 4 capturés » ; `Sauvegarde chargée : viridian_city (42, 22)`, 85 005 s | conforme |
| 2 | Écriture par la RC | Accueil, arrêt forcé, relance : 85 045 s, même position | conforme |
| 3 | Désinstallation puis installation propre | `sauvegarde NONE`, plus de « Continuer » | conforme |
| 4 | Premier lancement | Ident et bande-annonce, titre interactif après ≈ 64 s ; PSS 959 à 976 Mo (graphique 580 Mo) | conforme |
| 5 | Nouvelle partie | Chen, apparences, prénoms, chambre, `nouvelle partie écrite` | conforme |
| 6 | Arrêt forcé, relance | Sans bande-annonce, `player_house_2f (3, 4)`, PSS 900 Mo | conforme |
| 7 | Surf peint (**APK debug du même commit**, `trailer_surf`) | Bouton SURFER, joueur assis sur le nageur peint, 54 à 58 i/s | conforme |
| 8 | Combat sur l'eau (idem) | Tentacool, interface et fuite correctes | conforme |
| 9 | Dos peint du joueur | **Non vu** : l'entrée du premier combat a été manquée, pas de seconde rencontre en 8 essais | CI seulement |
| 9 bis | Dos peint du joueur, **rejoué le 2026-11-06** (APK debug de `main` @ `c26932f5` + correctif d'Hydrocanon) | Dresseur à terre (Basile) en tenue d'origine puis en costume Tanjiro, Dresseur sur l'eau (Tanguy) en costume : poses debout et lancer, monture peinte, Surf en costume sur la carte ; 47 à 48 i/s, aucune erreur au journal. Le dos ne s'affiche qu'en combat de Dresseur. Non vus : la joueuse et les 15 autres costumes (CI seulement) | conforme |

**Régression.** Les parcours scriptés du J33 (`tests/parcours/`, 01 à 09 et starters, 10 scripts) font
partie de la suite et sont passés dans la CI de ce commit. Les tronçons au doigt de
`jalon-33-t6-checklist.md` n'ont pas été rejoués, Kevin les ayant clos au J33.

**Défauts.** Zéro P0 et zéro P1 ouverts dans `reportes.md` : les lignes RP-133, 143 et 150, encore
marquées « corrigé sur la branche », viennent de branches fusionnées depuis. **Réserve** : RP-099 et
RP-160 sont en P2 « à reproduire » et deviendraient P0 si le texte restait illisible ; ils n'ont pas été
reproduits ici. Environ 50 P2 et 60 P3 restent ouverts, acceptés par Kevin à la clôture du J33. Aucun
nouveau défaut de jeu trouvé.

## 4. Limites de ce rapport

- Un seul appareil. **Le S24 n'a pas reçu la RC** : une RC ne s'installe pas sur un APK debug, et le
  désinstaller peut effacer la vraie partie de Kevin. À faire seulement avec son accord.
- Installation depuis un fichier (« sources inconnues ») toujours pas éprouvée ; elle sert pourtant aux proches.
- Mise à jour testée depuis la 0.33.0 re-signée : l'APK 0.34.0 n'existe plus sur le Mac.
- T5 non rejoué en entier sur APK signé, contrairement au plan ; seuls l'Accueil et l'arrêt forcé l'ont été.

## 5. Page des limitations de la RC

- **Le jeu s'arrête à Kanto** : pas de Chapitre Johto, post-game de Kanto seulement.
- **APK de 646 Mo**, lourd à envoyer ; première installation forcément propre.
- **Désinstaller supprime la sauvegarde**, sans restauration ; pas de retour à une version plus ancienne.
- **Sauvegarde sur le téléphone uniquement.**
- **Visuels** : quelques dos de combat restent en pixels (RP-010, dont Tortank), et des décors restent à
  polir (P2 et P3 ouverts).
- **Performances** : 50 à 58 i/s sur l'A17 selon les zones.
- **Premier lancement** : ≈ 1 minute avant le titre, sauf si on touche l'écran pour passer.
- **Mises à jour** : après la fusion, `main` porte aussi le numéro 0.34.1 mais contient Johto. La prochaine
  version pour les proches sera en 0.34.2 ou plus, et migrera la sauvegarde de v9 en v10.

## 6. Décisions

| Décision | État |
|---|---|
| **Go juridique** | **Go de Kevin pour le cercle de la maison seulement**, droits non déterminés (`jalon-34-34e.md` §14). Rien au-delà. |
| **Go technique** | **Go de Kevin pour le T4** (« Go pour le T4 », 2026-11-05) : cet APK peut aller chez un proche pour la première utilisation. La diffusion au reste du cercle attend que le T4 soit réussi (critère 3). |
