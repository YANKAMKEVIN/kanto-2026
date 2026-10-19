# Kanto 2026 — Récapitulatif J26 : Safrania sous occupation

> Passe de conception ChatGPT V2, transmise par Kevin le 2026-10-19, **avant le lancement du J26**
> (conception en avance, `strategie-acceleration.md` levier 2). 7 arbitrages validés ; dossier
> consolidé ; implémentation non encore vérifiée. Les images de la passe d'origine (illustrations
> Bulbapedia et Pokémon Zukan) ne sont pas reprises ici. Les notes de la session de coordination
> sont à la fin.

Objectif du jalon : infiltrer la Sylphe SARL, combattre la Team Rocket, vaincre le rival et
Giovanni, libérer Safrania et obtenir la Master Ball.

## 1. Les décisions verrouillées

| Élément | Décision J26 |
|---|---|
| Périmètre | Sylphe SARL complète, rival et Giovanni |
| Bâtiment | 11 étages, ascenseur, téléporteurs et portes |
| Carte Magnétique | À récupérer au 5e étage |
| Team Rocket | Nombreux sbires, majorité des combats facultatifs |
| Rival | Combat obligatoire au 7e étage, équipe adaptée au starter |
| Giovanni | Combat obligatoire au 11e étage |
| Fin | Safrania libérée, exploration libre, Arène de Morgane accessible |

## 2. Le déroulement du jalon

1. **Safrania occupée** : entrée dans la Sylphe SARL.
2. **Exploration des 11 étages** : téléporteurs, sbires, objets et Carte Magnétique.
3. **Combat contre le rival** : victoire obligatoire, puis Lokhlass offert.
4. **Confrontation avec Giovanni** : libération du président et Master Ball unique.
5. **Safrania libérée** : exploration libre, Morgane accessible au J27.

## 3. Les mécaniques importantes

- **Exploration** : les onze étages sont entièrement jouables. Les téléporteurs relient différentes
  salles, l'ascenseur permet de changer d'étage et la Carte Magnétique déverrouille les portes
  électroniques.
- **Combats** : la majorité des sbires peuvent être évités. Les combats contre le rival et Giovanni
  sont obligatoires pour terminer le jalon.
- **Persistance** : les Dresseurs vaincus, les portes ouvertes, les objets récupérés et la
  libération de Safrania restent enregistrés après sauvegarde.
- **Direction artistique** : bureaux et laboratoires en 2D HD peinte, vue orthogonale, contrôles
  adaptés au Galaxy S24, sans minimap ni flèches d'objectif.

## 4. Les deux grands combats

- **Le rival, 7e étage** : équipe évolutive selon le starter initial. Combat obligatoire avant
  Giovanni. Après la victoire, le joueur peut obtenir un Lokhlass offert par un employé.
- **Giovanni, 11e étage** : équipe historique Rouge/Bleu : Nidorino N37 · Kangourex N35 ·
  Rhinocorne N37 · Nidoqueen N41.

## 5. Les récompenses

| Récompense | Remise |
|---|---|
| Lokhlass | Cadeau unique d'un employé |
| Master Ball | Remise unique par le président |

## 6. Découpage technique

| Lot | Contenu |
|---|---|
| J26.0 | Audit des dépendances |
| J26A | Safrania occupée et onze étages |
| J26B | Téléporteurs, ascenseur, portes et Carte Magnétique |
| J26C | Sbires, scientifiques et objets |
| J26D | Rival et Lokhlass |
| J26E | Giovanni, Master Ball et libération |
| J26F | Sauvegardes, tests et QA Galaxy S24 |

## 7. Ce qui doit être vérifié avant de coder

Le dossier est validé, mais le dépôt doit encore confirmer la disponibilité des cartes de Safrania,
du système de téléportation, des variantes du rival, des Pokémon nécessaires, de la Master Ball et
des états persistants.

Deux règles à préserver : le Badge Volcan du J25 n'est pas requis artificiellement pour accéder à
Safrania, et le Dojo de Combat ne doit pas dépendre de la victoire contre Giovanni.

Résultat attendu à la fin du J26 : Safrania est définitivement libérée, le joueur a vaincu
Giovanni, reçu la Master Ball et peut poursuivre librement son exploration. L'Arène de Morgane est
accessible.

Prochain jalon : J27 — Morgane, l'Arène Psy et le Dojo de Combat.

---

## Notes de la session de coordination (2026-10-19), pour l'audit J26.0

Premier repérage dans les branches poussées, à confirmer par l'audit :

- **Déjà écrit au J20** (`jalon-20`, pas encore dans `main`) : ascenseur piloté par les données
  (`game/world/elevator/`, `data/world/elevators.json`, avec objet-clé exigé `key`), dalles
  tournantes (`game/world/spin/`), dons d'objets et de Pokémon (`game/systems/gift/`), postes de
  garde de Safrania (`route_7_gate`, `route_8_gate`, porte **sans warp**), trois boissons dans le Sac.
  La Sylphe peut réutiliser l'ascenseur (11 étages) et le don (Lokhlass, Master Ball).
- **Pas encore trouvé dans le dépôt** : téléporteurs, portes à carte (Carte Magnétique), Master Ball,
  Lokhlass, cartes de Safrania et de la Sylphe. Les téléporteurs et les portes à carte sont des
  **systèmes réutilisables** : **versés dans la passe systèmes 2** par Kevin (2026-10-19). Le J26
  les consomme sans les coder ; le lot J26B se réduit au placement (données et cartes).
- **Entrée dans Safrania : faite au J20** (décision de Kevin du 2026-10-19, T25 du J20, qui remplace
  H-5) : une boisson donnée au garde ouvre les quatre postes. Tant que la carte de Safrania n'existe
  pas, le garde ne demande rien (Q-4 A). **Le J26 n'a qu'à déclarer la carte de Safrania** pour que
  les postes s'ouvrent ; il ne code pas la règle. Dans Rouge/Bleu, il donne
  une boisson au garde d'un poste ; le J20 prépare les boissons et les postes, mais le dossier J26
  ne dit pas qui les ouvre (J20, J26 ou autre).
- **Art** (entre-deux, levier 4) : grilles et une vue générale de la Sylphe avant le code ; le reste
  (11 étages peints, Lokhlass, Nidoqueen, Rhinocorne, Giovanni) va dans un lot d'art.
