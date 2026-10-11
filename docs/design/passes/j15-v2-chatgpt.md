# J15 — En route vers Carmin-sur-Mer : V2 de Kevin (avec ChatGPT), reçue le 2026-10-11

> Copie de travail de la proposition transmise par Kevin, pour la passe d'alignement
> (`j15-v2-alignement.md`). Les images d'ambiance jointes (sites tiers) ne sont pas reprises (droits).
> Les arbitrages proposés par la V2 (« E-1 à E-4 ») sont renommés **V-1 à V-4** : les lettres E-1 à
> E-15 sont déjà prises par la passe du J14.

J15 = jalon de voyage, d'exploration et de découverte, pas centré sur un Champion d'Arène. Après
Azuria, le joueur descend vers le sud, découvre une Pension Pokémon, traverse un passage souterrain
plus travaillé que dans Rouge/Bleu, puis arrive dans une vraie ville portuaire où le S.S. Anne
l'attend.

## 1. Décisions verrouillées

| Élément | Décision |
|---|---|
| Périmètre | Route 5, passage souterrain, Route 6, Carmin-sur-Mer |
| Pension Pokémon | Fonctionnelle dès J15 |
| Passage souterrain | Parcours enrichi, avec découverte facultative |
| Carmin-sur-Mer | Ville portuaire complète |
| S.S. Anne | Visible au port, exploration reportée |
| Arène de Major Bob | Présente, défi reporté |
| Accès à Safrania | Postes de garde fermés, justification narrative |

Ce sont des contraintes de conception, pas encore des fonctionnalités implémentées.

## 2. Structure géographique (enchaînement, pas une carte de production)

- **Route 5** (≈ 42 × 62 cases) : dense, pas un couloir. Pension, poste de garde vers Safrania,
  entrée du souterrain, herbes hautes, quelques découvertes. Chemins orientés vers le sud, retour
  possible vers Azuria. Pension reconnaissable à son architecture et son jardin, sans flèche.
- **Passage souterrain** (≈ 18 × 70, à confirmer par le plan) : discret mais mémorable (éclairage
  mural, pierre ancienne, traces de passage, alcôves). **Pas de Pokémon sauvages** au J15
  (respiration). Découverte facultative = objet caché avec le système du Mont Sélénite ; aucun
  mini-jeu ni système de fouille.
- **Route 6** : plus ouverte, herbes, **4 à 6 Dresseurs dont une minorité obligatoire**, première
  vue sur le port.

## 3. Pension Pokémon (première fonctionnalité de gestion)

Principe RB : déposer, gagner de l'XP au fil des pas, payer pour récupérer. Sans élevage ni
reproduction.

| Règle proposée | Comportement |
|---|---|
| Capacité | Un Pokémon à la fois |
| Dépôt | Depuis l'équipe, hors combat |
| Progression | Expérience selon les pas |
| Retrait | Paiement selon les niveaux gagnés |
| Capacités apprises | Règle explicite, pas de perte silencieuse |
| Évolution | Pas d'évolution automatique à la Pension |
| Sauvegarde | Pokémon déposé et progression conservés |
| Équipe complète | Retrait impossible tant qu'aucune place n'est libérée |

Recommandation forte : jamais d'oubli automatique de capacité ; apprentissage différé ou contrôlé au
retrait. Principal risque du J15 : à tester isolément avant de la connecter à la carte.

## 4. Carmin-sur-Mer

≈ 72 × 54 cases, trois repères : quais, S.S. Anne, Arène de Major Bob. Différente d'Azuria :
« Azuria est traversée par l'eau, Carmin vit autour de la mer ». Palette : façades claires, toitures
chaudes, bois des pontons, cordages, métal du port, mer bleu profond, végétation côtière. Lieux :
Centre, Boutique, Arène, port, Fan Club, maisons, accès aux futures routes. Maison du Pêcheur
préparée, pêche non débloquée (arbitrage dédié). Rendu HD peint, orthogonal, sans isométrie.

## 5. S.S. Anne

Grand repère visuel dès l'arrivée. Quais approchables, personnel à qui parler, **pas d'exploration
au J15, même avec le Passe Bateau**. Justification crédible (préparation de l'embarquement), jamais
« contenu à venir ». Accès et intérieurs au J16.

## 6. Major Bob et Safrania

Arène présente, défi reporté, verrou intégré au monde. Postes de garde vers Safrania présents :
gardes qui refusent le passage (restrictions de circulation), dialogues naturels. La raison doit
rester cohérente avec la future intrigue Rocket et le futur déblocage, sans annoncer trop tôt une
occupation.

## 7. Dépendances et risques signalés

Raccord J14 (sortie sud d'Azuria ouverte après le Rocket du cambriolage) · Pension (stockage hors
équipe, progression, retrait) · pas d'évolution silencieuse · aucun oubli non consenti · sauvegarde
(Pension, objets, Dresseurs, positions) · réutilisation des objets cachés du J12 · espèces,
Dresseurs, artworks, dos peints, Pokédex · Passe Bateau conservé, accès fermé jusqu'au J16 ·
dialogues de Safrania cohérents · S24 (transitions, sauvegardes, Pension, performances, retour
arrière).

## 8. Arbitrages proposés par la V2 (renommés)

| Réf. | Proposition |
|---|---|
| V-1 (ex-E-1) | Pension limitée à un Pokémon, sans reproduction |
| V-2 (ex-E-2) | Capacités apprises à la Pension : apprentissage proposé au retrait, sans oubli automatique |
| V-3 (ex-E-3) | Passage souterrain sans rencontres sauvages, avec une découverte cachée |
| V-4 (ex-E-4) | Maison du Pêcheur présente, pêche reportée à un jalon dédié |

## 9. Audit demandé

Frontières J14/J15/J16 et roadmap ; équipe, identifiants stables, migrations de sauvegarde ;
faisabilité de la Pension (XP, apprentissages, évolutions, retraits) ; espèces, rencontres,
Dresseurs, assets ; objets cachés et persistance ; Passe Bateau et S.S. Anne ; Safrania et autres
sorties de Carmin ; textes complets et derniers arbitrages. Branche documentaire isolée, prochain
numéro de dossier libre, aucun code.

## 10. J16 — avant-projet V1 (reçu en même temps)

Le S.S. Anne, une aventure à bord. Six décisions proposées :
1. Périmètre : S.S. Anne seul, Major Bob au J17 · ou S.S. Anne + Major Bob au J16.
2. Intérieur : plusieurs ponts, cabines, restaurant, pont extérieur · ou version compacte.
3. Rival n° 4 : à bord, victoire obligatoire · ou histoire qui continue après une défaite.
4. Capitaine : mal de mer historique conservé · ou version modernisée.
5. CS01 Coupe : capacité en combat et hors combat dès J16 · ou objet obtenu, usage débloqué au J17.
6. Départ du navire : appareille après la sortie définitive, avec confirmation · ou reste accessible.

Recommandation de la V1 : J16 = navire, rival n° 4, Coupe ; J17 = Major Bob et Badge Foudre.
