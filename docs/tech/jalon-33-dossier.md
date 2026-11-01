# Jalon 33 — Dossier de sortie (T7)

> Relevé du 2026-11-01, branche `claude/j33-t7` depuis `main` @ `8a4c4d4c`. Plan : `jalon-33.md` §T7.
> Une APK compilée ne prouve pas à elle seule que le jalon est terminé : ce dossier rassemble les preuves,
> la décision revient à Kevin (§7).

## 1. Version de référence

| Élément | Valeur |
|---|---|
| Version | **0.33.0**, code **33** [D] (nommage définitif au J34 T1) |
| Commit de l'APK | `74aa4669` (branche `claude/j33-t7` = `main` @ `8a4c4d4c` + version dans le preset) |
| Fichier | `build/kanto2026-0.33.0-debug.apk` (465 Mo, non versionné dans git) |
| SHA-256 | `be3c2aafed395cd30ffa9592b1f403b3c022c6bc014dc50e45b3f24daa154347` |
| Vérifié par `aapt dump badging` | `dev.kevin.kanto2026`, versionCode 33, versionName 0.33.0, SDK cible 36 |
| Godot | `4.7.2.stable.official.ed1daf0bf` |
| Construction | `tools/build_android.sh Android build/kanto2026-0.33.0-debug.apk` (le script accepte désormais un preset et une sortie) |

## 2. Paramètres d'export (preset « Android »)

APK **debug**, signée avec la clé de debug ; arm64-v8a seul ; pas de build Gradle ; plein écran immersif ;
permission vibration ; icônes adaptatives et écran de démarrage (fond `#14100B`, posé par
`tools/android_splash_bg.py`). Exclus de l'export : `tests/`, `tools/`, `docs/`, `addons/gut/`, `build/`,
`proto/`, prototypes de combat. Ce n'est pas une version de publication (pas de clé de release, pas d'AAB).

## 3. Tests

- **Suite complète** : CI GitHub **verte** sur `74aa4669` (run 41340970199, 8 lots) ; dernier `main` vert avant
  la branche : run 41281641042 (`485eb3f7`).
- **Scripts de test** : 748 fichiers `test_*.gd` (731 au T1).
- **Parcours scriptés** : parcours 01 à 06 et starters (T5), parcours 07 à 09 à pied (préparation de T6) :
  aucun P0 ni P1.

## 4. Métriques

| Appareil | Mesure | Source |
|---|---|---|
| A17 | ≈ 50 i/s partout (plafond de l'appareil) ; mémoire stable 900–955 Mo sur 20 min, sans dérive ; textures 225–339 Mo | T3, `jalon-33-profilage.md` |
| A17 | 50–54 i/s sur les cartes repeintes (Îles Écume, Centrale, Ligue) ; textures 244–275 Mo | contrôle du 2026-11-01 |
| S24 | **60 i/s** stables sur la Route 3 et le Mont Sélénite, creux 53–59 aux changements de carte, aucune erreur | QA d'agent T6, 2026-11-01 |
| Mac | chargements headless 77–920 ms selon la carte | T1, `jalon-33-baseline.md` |

Non mesuré : batterie, session de 30 min sur S24.

## 5. Sauvegarde

Copie de secours `save.json.bak` (T4) ; sauvegarde v8 ; contrôlé sur l'A17 le 2026-11-01 : fixture v6
migrée en v8, fermeture forcée après sauvegarde, fichier tronqué → reprise depuis la copie de secours.

## 6. Registre

- **P0 : 0. P1 : 0.** Le critère de sortie du J33 est tenu.
- Ouverts (relevé automatique de `reportes.md`, ordre de grandeur) : **≈ 50 P2, ≈ 65 P3**, tous documentés ;
  les derniers : RP-283 (bande noire hors carte, Centrale), RP-284 (case de reprise après Giovanni),
  RP-285 (départs de débogage incohérents), RP-286 (animations sans trajet, après le J33).
- **RP-263** (à-coup au premier effet du premier combat, 8,1 i/s une image sur S24) n'a **pas de priorité** :
  à classer par Kevin (proposition [D] : P2, à traiter avant la publication).
- Anomalies de la campagne : `registre-anomalies.md`.

## 7. Décision demandée à Kevin

1. **Accepter les P2 et P3 ouverts** pour cette version de référence (`jalon-33.md` §1 : « explicitement acceptés »). **Accepté par Kevin le 2026-11-01** (« oui j'accepte les P2 et P3 »).
2. **Classer RP-263** ([D] : P2). **Kevin, 2026-11-01 : « on le fait après »** : P2, traité après le J33.
3. **Clore le J33** : fusionner `claude/j33-t7` dans `main`, APK 0.33.0 comme version de référence. **Accordé par Kevin le 2026-11-01** (« puis on peut clore le J33 ») : **J33 clos**.

## 8. CI de la branche

**Verte** : run 41340970199 sur `74aa4669`, 8 lots GUT en succès (2026-11-01, 20 min).
