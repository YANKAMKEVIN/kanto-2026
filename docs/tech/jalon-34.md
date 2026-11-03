# Jalon 34 — Release Candidate Android

> **PLAN — aucun code n'est écrit par ce document.** Source de vérité :
> `docs/design/passes/j34-v1-chatgpt.md` (7 arbitrages verrouillés). Arbitrages et textes
> recommandés **validés par Kevin le 2026-10-21 (validation d'avance des textes recommandés)**.
> Texte manquant : proposition marquée **[D]**.

> Objectif : **une Release Candidate installable, traçable et testée hors de l'environnement de
> développement** (installation propre, mise à jour, interruptions Android). Aucun nouveau contenu.
> Deux décisions séparées : **Go technique** et **Go juridique**. Un Go technique ne remplace
> jamais un Go juridique.

## 0. État et dépendances (relu sur le dépôt)

| Point | Réel aujourd'hui | Manque |
|---|---|---|
| Export | `export_presets.cfg` : un preset « Android » **debug**, `build/kanto2026-debug.apk`, arm64-v8a, `package/signed=true`, `dev.kevin.kanto2026` | Preset release, `version/code`, `version/name`, signature release |
| Version dans le jeu | Aucun `config/version` dans `project.godot` | Source unique de version (T1) |
| Build | `tools/build_android.sh` (debug) ; `tools/deploy_s24.sh` (installation sur S24) | Script de build RC avec manifeste |
| Secrets | Aucun keystore suivi par Git | Garder ce principe ; clé hors dépôt |
| Licences | `addons/gut` (GUT 9.7.1, exclu de l'export) ; polices suivies : seulement celles de GUT ; `assets/fonts/` vide | Inventaire complet des sprites, musiques, polices, art généré |
| Sauvegarde | Atomique, versionnée ; `SessionLifecycle` sauve à la pause | Vérifier sur **APK signé** |
| Appareils | S24 connu (`tools/s24_serial.sh`) | Autres appareils : **seulement ceux réellement disponibles** |
| Tag Git | Un seul tag (`j9-t3-base`), aucune branche `release/*` | Conventions posées ici (T1) |

### 0.0 Périmètre réduit (décision de Kevin, 2026-11-03) et avancement

**Diffusion = moins d'une dizaine de proches de la maison de Kevin, par adb ou par APK release
signé partagé en privé ; jamais de store.** Les arbitrages 1 à 7 restent, lus à cette échelle : pas de
Play Console ni d'AAB, une seule clé gardée par Kevin, `versionCode` croissant, appareils réellement
disponibles seulement. Le jeu s'appelle **Pokemake** (orthographe à l'écran à confirmer avec Kevin
avant de peindre le logo). Procédure complète : `docs/tech/release.md`.

| Tâche | État (2026-11-03, branche `claude/j34-rc`) |
|---|---|
| T1 version | **Fait** : `config/version="0.34.0"` dans `project.godot` (source unique), code Android dérivé `MAJEUR × 10000 + MINEUR × 100 + CORRECTIF` = 3400 [D] (plus de second nombre à tenir à jour ; > 33 du J33), `tools/version.py show/set/check`, `GameVersion` (`game/systems/game_version.gd`), test `tests/unit/test_version.gd`, étiquette « v0.34.0 (3400) » en bas de l'écran titre du côté du logo [D]. Convention de tags `v0.34.0` (sans `-rc.N` : pas de cérémonie RC pour la maison) [D]. |
| T2 build | **Fait** : `tools/build_rc.sh` (arbre propre, version cohérente, clé exigée hors dépôt, CI verte du commit, `--export-release Android`, splash Android 12+ re-signé release, `apksigner verify`, `aapt` identifiant/version, `manifest.json` + `SHA256SUMS` dans `build/rc/`, `--install`) ; `tools/make_keystore.sh` (clé RSA 4096 PKCS12, 30 ans, mot de passe par variable d'environnement) ; preset `Android` : `keystore/release*` vides, lus dans `GODOT_ANDROID_KEYSTORE_RELEASE_*`. |
| Nom | `config/name`, `package/name`, description et ligne du générique renommés « Pokemake » (fusionné). **Orthographe tranchée par Kevin le 2026-11-03 : « Pokemake », sans accent.** Logo peint par Codex dans la famille du logo r2 (`tools/art/prompts/ouverture/LOGO_POKEMAKE_r1.txt`, mot seul sur un filet doré ; r2 = variante avec « 2026 », non retenue [D]), détouré par `detourer_logo.py` → `assets/ui/opening/logo_pokemake.png` (1280 × 546), `splash_pokemake.png`, ombre `logo_pokemake_ombre.png` ; branché au titre, au générique et au `boot_splash` ; ancien logo gardé en `docs/design/reference/logo-kanto-2026-v1.png` ; l'icône garde son « K » [D]. Branche `claude/j34-logo`, à valider. |
| Ident | **Fait, à valider** (demande de Kevin du 2026-11-03) : carton « Les studios Kevin & Co / vous présentent » puis lettres de POKEMAKE depuis la droite, filet, halo, fondu vers le titre (`IntroTimeline` logique pure + `IdentSequence`, ≈ 7 s, réduite ≈ 3,2 s, passage au toucher ou au retour) ; lettres découpées du logo par `detourer_logo.py` (`assets/ui/opening/logo_pokemake_parts/`) ; musique du titre sur `title_revealed` ; jamais quand `speed_scale` = 0 (tests, captures). Vidéo `tools/capture_ident_video.gd`. |
| Bande-annonce | **Fait, à valider** (Kevin : « un trailer magnifique », 15 à 20 s) : 13 plans réels du jeu (Bourg Palette, course, Forêt de Jade, vélo, Surf, Mont Sélénite, évolution, VS « Rose, Championne de la Ligue », combat sur la plage, Menu Dresseur, Pokédex, Tour Pokémon, Mewtwo) de 2 à 2,4 s, fondus enchaînés de 0,7 s, lent travelling, bandes noires 7 % : ≈ 19 s entre le carton et les lettres ; `data/opening/trailer.json` + `TrailerReel` (lecture stricte) + `assets/ui/opening/trailer/*.webp` (1755 × 810, ≈ 3,3 Mo) ; outil `tools/capture_trailer.gd` (vraie scène Boot sur un départ de débogage, HUD caché). L'ident complet dure ≈ 27 s, passable d'un toucher ; pas de bande-annonce en « Réduire les animations ». |
| T3 à T7 | À faire, réduits au cercle de la maison (`release.md` §5). T3 attend la vraie clé de Kevin et un téléphone. |

### 0.1 Ce qui peut commencer tout de suite
- **T1** conventions de version et source unique ; **T2** script de build et manifeste ;
  **T6** inventaire des licences et ressources (lecture seule, utile même si la diffusion n'est jamais décidée).

### 0.2 Ce qui attend
- T3 à T5 et T7 : une version stabilisée **(fin du J33)**. T6 « Go juridique » : décision de Kevin,
  éclairée par un avis compétent, jamais par une session de développement.

## 1. Contrats

- **Identité du build** : nom de version `0.34.0-rc.1` (convention proposée, pas une version
  générée), code Android entier croissant, commit exact, version exacte de Godot (4.7.2 en CI),
  configuration d'export, signature, identifiant stable `dev.kevin.kanto2026`, SHA-256, journal des
  modifications.
- **Ne jamais changer l'identifiant ni la clé de signature** : sinon plus de mise à jour par-dessus.
- **Pipeline** : commit identifié → tests réussis → export → signature → SHA-256 et manifeste →
  installation sur appareils → rapport QA → Go/No-Go. Chaque test est rattaché au **même build identifié**.
- **Clé de signature** : jamais dans le dépôt, les journaux de CI ni un APK. Chemin et mots de passe
  par variables d'environnement du Mac [D].
- Un correctif après QA exige une **nouvelle identification** de build et le rejeu des tests concernés.

## 2. Tâches

### T1 — Versionnement et source unique (34A, Sonnet)
`config/version` dans `project.godot` ; `version/name` et `version/code` du preset lus **depuis la
même source** par un script [D : `tools/version.py`]. Convention de tags : `v0.34.0-rc.1`.
Tests : un test GUT lit la version et refuse un format invalide ; `tools/check_json_keys.py` inchangé.

### T2 — Build RC, signature, manifeste (34A, Sonnet)
`tools/build_rc.sh` [D] : refuse si l'arbre Git est sale ou si les tests n'ont pas été lancés sur
ce commit ; exporte un preset **release** signé ; écrit `manifest.json` (version, code, commit,
Godot, SHA-256 de l'APK, date, preset) et `SHA256SUMS`. Le keystore est lu hors dépôt.
Critère : le même commit relancé produit un APK fonctionnellement équivalent (l'identité binaire
n'est pas promise).

### T3 — Installation propre, mise à jour, désinstallation (34B)
Trois scénarios sur chaque appareil réel : installation propre (nouvelle partie) ; **mise à jour
par-dessus une version précédente avec une vraie sauvegarde ancienne** (pas créée par la RC) ;
désinstallation (la sauvegarde locale peut disparaître : à dire clairement au testeur).
Fiche : modèle, version Android, résultat, build.

### T4 — Première utilisation (34C, Kevin avec un tiers)
Parcours : lancement, menu, introduction, choix du personnage et du starter, première exploration,
premier combat. Une personne qui n'a jamais vu le jeu joue **sans aide du développeur**.

### T5 — Résilience Android (34D, Opus)
Accueil pendant un combat, verrouillage, appel, rotation, fermeture forcée, stockage presque plein,
mémoire sous pression, permission refusée. Opérations uniques interrompues : capture légendaire,
échange, évolution, remise d'objet, Panthéon. Jamais deux Pokémon pour une capture, jamais un
Pokémon supprimé sans transfert terminé. Tests automatiques sur les règles ; scénarios réels sur APK signé.

### T6 — Licences, ressources, confidentialité (34E, Sonnet puis Kevin)
Tableau : sprites Pokémon, personnages, cartes, musiques, polices, plugins, art généré par IA (outils
`tools/art/`), marques et noms, données de testeurs. Colonnes : provenance, droits connus, statut.
Aucune affirmation « libre de droits » sans preuve. Exclusion de `addons/gut` vérifiée dans l'APK.

### T7 — Régression finale, rapport, Go/No-Go (34F)
Suite complète, parcours du J33, rapport QA, **deux décisions écrites** : Go technique, Go juridique
(ou « droits non déterminés »). Paquet RC archivé hors dépôt.

## 3. Textes
Validés par Kevin le 2026-10-21 : grille de décision RC (APK signé et versionné ; installation et
mise à jour documentées ; première utilisation sans assistance ; résilience vérifiée ; zéro P0/P1 ;
conformité documentée ; décision signée) ; dialogues de 2 lignes de 40 caractères.
Propositions **[D]** : avertissement de désinstallation pour les testeurs : « Désinstaller le jeu
peut supprimer ta sauvegarde. » ; page de limitations de la RC (liste en fin de rapport).

## 4. Critères d'acceptation
1. APK signé, versionné, avec manifeste et SHA-256 ; build refait à l'identique en équivalence fonctionnelle.
2. Installation propre, mise à jour (vraie sauvegarde ancienne) et désinstallation documentées sur chaque appareil réellement testé.
3. Parcours de première utilisation réussi sans aide.
4. Interruptions Android rejouées sans corruption ni doublon.
5. Zéro P0/P1 ; inventaire des ressources écrit ; deux décisions Go/No-Go signées.

## 5. QA téléphone (S24 et autres appareils réels)
Installation propre, mise à jour, désinstallation ; Accueil pendant un combat ; écran verrouillé
puis déverrouillé ; appel entrant simulé si possible ; tuer l'appli pendant une sauvegarde.

## 6. Risques
Clé de signature perdue (plus de mise à jour) ; clé exposée ; liste d'appareils inventée ; une
optimisation qui change les coordonnées ; diffusion présumée autorisée parce que gratuite.

## 7. Points ouverts pour Kevin
1. **Go juridique** : le projet est « un remake personnel » (`CLAUDE.md`). Toute diffusion, même
   privée, relève de toi et d'un avis compétent. La bêta (J35) en dépend.
2. Où garder le keystore et sa sauvegarde ? (gestionnaire de mots de passe, disque chiffré)
3. Appareils réellement disponibles en plus du S24 ?
4. Version minimale d'Android à annoncer : à mesurer, pas à supposer.
