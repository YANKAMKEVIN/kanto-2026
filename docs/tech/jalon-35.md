# Jalon 35 — Bêta privée et validation terrain

> **PLAN — aucun code n'est écrit par ce document.** Source de vérité :
> `docs/design/passes/j35-v1-chatgpt.md` (7 arbitrages verrouillés). Arbitrages et textes
> recommandés **validés par Kevin le 2026-10-21 (validation d'avance des textes recommandés)**.
> Texte manquant : proposition marquée **[D]**.

> Objectif : **savoir si une personne extérieure peut installer, comprendre et jouer à Kanto 2026
> seule**, avec le contrôle des versions et des retours. Aucune nouvelle région, espèce ni campagne.
>
> **Condition d'entrée** : une RC acceptée sans P0/P1 (J34) **et** une décision de conformité
> adaptée à des testeurs externes. Sans cela, le jalon produit son protocole et ses outils, et la
> distribution reste **suspendue**.

## 0. État et dépendances (relu sur le dépôt)

| Point | Réel aujourd'hui | Manque |
|---|---|---|
| Build identifié | Rien (voir J34) | Version, commit, SHA-256 par build |
| Écran d'options / menu | Menu Dresseur et options existent (`game/ui/`) | Entrée « Signaler un problème » |
| Informations appareil | Disponibles via `OS` de Godot (modèle, version Android, version du jeu) | Rien d'envoyé : copie locale seulement |
| Canal de retours | Aucun | Formulaire (T3) et registre (T5) |
| Cadre de diffusion | Projet personnel ; aucun droit établi | **Décision Kevin** (J34) |
| Suivi des anomalies | `docs/tech/etat-projet.md` (« Reportés ») | Source unique : voir §7 |

### 0.1 Ce qui peut commencer tout de suite
- **T1** protocole de bêta (documents) ; **T3** conception de l'écran « Signaler un problème » et de
  son contenu ; **T5** modèle de registre et de tri ; **T2** fiche de distribution (champs).

### 0.2 Ce qui attend
- Invitations et téléchargements : la RC (J34) **et** la conformité. Campagne et corrections (T4, T6) :
  les retours réels. **Aucun résultat de bêta ne sera inventé.**

## 1. Contrats

- **Testeurs** : 8 à 12 volontaires (proposition, pas un arbitrage), profils variés (familier,
  occasionnel, découverte, attentif aux détails, appareil ancien). La matrice note les appareils
  **réellement** utilisés : 12 testeurs ne font pas 12 configurations.
- **Chaque retour est lié à une version précise.** Un retour d'une ancienne bêta n'est pas présenté
  comme un défaut de la build corrigée.
- **Confidentialité** : minimisation. Recueilli : modèle de téléphone, version Android, version du
  jeu, description volontaire. Facultatif : capture après vérification, journaux minimaux **avec
  consentement explicite**. Jamais : identifiants personnels, localisation précise, contacts,
  photos, messages, suivi de session. **Aucune télémétrie automatique.**
- **Retrait** : retirer un lien ne désinstalle pas une APK déjà installée ; aucune révocation à
  distance n'est promise (le jeu est hors ligne).
- **Gel** : aucune suggestion de fonctionnalité intégrée au J35 ; elles vont au registre des idées.

## 2. Tâches

### T1 — Protocole de bêta (35A, Sonnet)
`docs/tech/beta/protocole.md` [D] : profils, recrutement, consignes, limites, durée, canal de
support, conditions d'arrêt, procédure de retrait.

### T2 — Distribution privée et contrôle des versions (35B)
Fiche par build : version (`0.35.0-beta.1` en exemple), commit, APK signé, SHA-256, date réelle,
canal, compatibilité, notes. Invitation individuelle avec consignes d'installation.
Critère : on sait toujours quelle build chaque testeur a reçue.

### T3 — Formulaire et écran « Signaler un problème » (35C, Sonnet — code après J34)
Champs du formulaire validé : type de retour (bug, difficulté d'utilisation, performance, impression
générale) ; zone ; appareil ; version ; impact (impossible de continuer / important / gênant /
mineur) ; étapes pour reproduire ; plaisir de jeu sur 5 ; bouton **« Copier le rapport »** (copie
locale, **rien n'est envoyé**). L'écran préremplit modèle, version Android, version du jeu et zone
courante ; les journaux ne sont joints qu'après consentement.
Tests : `ReportBuilder` pur (texte de sortie, champs obligatoires, aucun identifiant personnel) ;
écran : boutons ≥ taille tactile du reste du jeu.

### T4 — Campagne de tests (35D, Kevin)
Installation, premier lancement, première session, exploration, combats, sauvegarde et reprise.
Consolidation des mesures du §6.

### T5 — Tri et cycle correctif (35E, Sonnet puis Opus)
Signalement → reproduction → classification → correction ciblée → régression → nouvelle build
identifiée → confirmation sur l'appareil concerné puis sur le S24. P0 : arrêt des tests concernés.
P1 : correction avant poursuite. La priorité est donnée par l'équipe ; l'impact du testeur est un signal.

### T6 — Rapport bêta et décision (35F)
Versions testées, appareils, parcours, résultats, incidents, corrections, problèmes ouverts,
décision de poursuite.

## 3. Textes
Validés par Kevin le 2026-10-21 : champs et options du formulaire (ci-dessus) ; principes de
confidentialité ; « Copier le rapport » sans transmission. Propositions **[D]** :
- Titre de l'écran : « Signaler un problème » ; aide : « Rien n'est envoyé. Tu copies le rapport et
  tu me l'envoies. »
- Consentement journaux : « Joindre des informations techniques (sans données personnelles) ? »
- Message d'invitation : un paragraphe sur les limites de la bêta et la suppression possible de la sauvegarde.

## 4. Critères d'acceptation (« J35 terminé »)
Protocole exécuté sur une build identifiée ; résultats documentés ; défauts critiques traités ;
décision explicite ; aucun P0/P1 ouvert sur la build candidate finale.

## 5. QA téléphone (S24)
Écran « Signaler un problème » : copie du rapport collée dans une note ; contenu relu (aucune donnée
personnelle) ; lisibilité et zones de contact.

## 6. Mesures de réussite (sans cible inventée)
Installations réussies / tentatives ; testeurs atteignant le menu, puis finissant le parcours
initial ; crashes reproductibles ; reprises réussies après fermeture ; difficultés par écran ;
problèmes par modèle ; note de plaisir ; P0/P1 ouverts, corrigés, retestés ; couverture réelle.

## 7. Points ouverts pour Kevin
1. **Qui sont les testeurs et peux-tu les inviter ?** Cela dépend du Go juridique du J34.
2. Canal de retour : messagerie personnelle, ou fiche GitHub privée ? [D : messagerie au début]
3. Registre unique des anomalies (voir J33 et J39) : tickets GitHub ou fichier du dépôt ? [D : tickets]
4. Durée de la bêta (nombre de builds) ? [D : 2 semaines, 3 builds au plus]
