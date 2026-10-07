# J9 T3 — validation de la sauvegarde v4 sur S24 (PARTIEL : S24 déconnecté)

Verdict global : NON TERMINÉ (le S24 a disparu d'adb entre l'étape 1 et l'étape 2). Rien n'a été installé ni modifié sur le téléphone.

- Étape 0 : l'APK installé sur le S24 n'est PAS celui de `main` : sha1 feb097451387…, identique à `worktrees/j8/build/kanto2026-debug.apk` (branche docs/dossier-11-route-2, « J8 T6 : 8.1 (la Route 2) », écrit la v3). Copié tel quel en `kanto2026-v3.apk` comme référence v3 (pas de réinstallation de `main`, qui aurait rétrogradé le contenu pour rien). `apk-main` est périmé (73c1308, en retard de MM.1-MM.3 sur main).
- Étape 1 relevé : OK. `save_v3_kevin_avant.json` (5048 octets, JSON valide, version 3, route_22 (6,20), Salamèche N7 + Rattata N4 + Roucool N3, 3000 ₽, 78110 s). Copie dans le scratchpad. Elle diffère de la fixture J7 : ajoutée en `tests/fixtures/save/v3_kevin_s24.json` (à signaler à l'architecte : doubler le test de migration).
- Étape 1 répétition Mac : OK. Journal `Sauvegarde chargée : route_22 (6, 20) (temps de jeu 78110 s)` puis une seule ligne `[qa] sauvegarde v3 → v4`, aucune erreur ; `diff.py` : IDENTIQUE ; statuts tous vides. Fichier Mac remis dans son état d'origine (aucun).
- Tests GUT : 2943/2943. Import : 0 erreur. APK J9 construit : 72 682 652 octets.
- Constat : un `debug_start.json` (route_2) traînait sur le S24 (déposé à 15:59 par un déploiement antérieur) ; `deploy_s24.sh` sans option le retire.
- Étapes 2 à 6 : non faites (S24 introuvable : `adb devices` vide après redémarrage du démon, 60 s de nouvelles tentatives).

État du téléphone : inchangé (APK J8 T6, partie v3 de Kevin intacte au dernier relevé).
