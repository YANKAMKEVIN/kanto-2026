# Kanto 2026 — UI/UX Bible v0.1

> Conçue par Kevin (avec ChatGPT), reçue le 2026-09-26. Complète `ui-reference.md` et la planche `reference/da-2026-planche-v1.webp`. **Les points où elle contredit la planche sont listés en fin de document et doivent être tranchés par Kevin.**

## Principe fondamental

**Quand tu explores Kanto, tu dois regarder Kanto — pas des boutons.** L'UI est moderne, tactile et très discrète. *Le monde est la star. L'interface n'apparaît que lorsque le joueur en a besoin.*

## 1. Exploration — presque plein écran

- **Gauche** : joystick translucide, qui peut devenir presque invisible après quelques secondes sans interaction.
- **Droite** : **un seul bouton principal, contextuel**. Son contenu change selon la situation, et il **disparaît** s'il n'y a rien à faire :
  - personnage → 💬 **Parler**
  - livre, objet de décor → ◉ **Examiner**
  - Pokémon → 👁 **Observer**
  - objet ramassable → ✋ **Prendre**
- Préféré à quatre boutons permanents.

## 2. Bouton Courir

Piste envisagée : **joystick légèrement poussé → marche, poussé à fond → course** (ou doigt maintenu loin du centre = course), ce qui supprimerait le bouton Courir et libérerait la droite de l'écran.

**Décision actuelle : on garde le bouton Courir tel quel.** On ne refait pas quelque chose qui marche au milieu d'un jalon. Après le jalon 3, test comparatif sur le S24 (course analogique contre bouton) et décision sur le ressenti réel.

## 3. Dialogues

- Pas de « version Game Boy agrandie » (bandeau en majuscules « PROF. CHEN : BONJOUR JEUNE DRESSEUR… »). Quelque chose de plus cinématographique.
- **Panneau inférieur sombre, légèrement translucide**, coins doux, texte très lisible.
- **Nom du locuteur distinct du texte** (au-dessus du texte, dans le panneau).
- **Pas de portrait systématique** : le personnage existe déjà dans la scène, on laisse le joueur le regarder.
- Animation : la boîte ne « pop » pas, elle **monte légèrement depuis le bas en 150–200 ms**.
- Texte rapide, pas lettre par lettre interminable. **Toucher → affiche toute la phrase ; toucher encore → phrase suivante.** Indicateur de suite « › ».

## 4. Choix dans un dialogue

Deux petites cartes au maximum (ex. **OUI** « En savoir plus » / **NON** « Pas maintenant »). Jamais dix réponses façon RPG occidental : Pokémon garde son rythme.

## 5. Nom des lieux

À la première arrivée : **nom en grand + sous-titre**, élégant, **sans rectangle énorme**, texte directement sur le monde. Fondu 300 ms → reste ~2 s → fondu.
- `BOURG PALETTE` / Kanto
- `ROUTE 1` / Bourg Palette — Jadielle
- `LAVANVILLE` / La ville où reposent les souvenirs.
Certains lieux importants peuvent recevoir une petite signature.

## 6. Notifications

Jamais d'interruption (« VOUS AVEZ TROUVÉ UNE POTION ! APPUYEZ SUR OK »). À la place, un **toast** : 🧪 Potion ×1 — *Ajoutée au Sac*, en haut ou dans un coin, ~2 s, puis disparaît ; on continue de marcher.

## 7. Menu principal

Un geste ou un petit bouton ouvre une interface **superposée au monde**, dont l'arrière-plan se floute légèrement. En-tête : nom du dresseur (KEVIN), « Dresseur », ⚙ dans un coin. Cinq entrées seulement : **Équipe · Pokédex · Sac · Carte · Profil**. En bas : **Objectif** (ex. « Rejoins Jadielle »). Paramètres dans un petit coin.

## 8. Équipe

On voit réellement les Pokémon (carte de tête mise en avant : nom, Nv., barre de PV). Fiche d'un Pokémon avec son histoire : *Depuis : Bourg Palette · Rencontré : Route 2 · Combats remportés : 34.*

## 9. Pokédex

Une vraie application scientifique créée par Chen : recherche, filtres, habitats, types, carte des observations. Fiche : numéro, nom, type, lieux observés, taille, poids, modèle/animations, notes de recherche. Informations en « ??? » tant que l'espèce n'est pas assez observée ou capturée (voir dossier 04 §13).

## 10. Carte de Kanto

Se révèle progressivement : au début Bourg Palette → Route 1 → Jadielle ; le reste visible géographiquement mais peu documenté. En explorant : routes, Centres Pokémon, boutiques, points d'intérêt, lieux secrets.

## 11. Pas de pollution visuelle — interdits officiels

❌ monnaie affichée en permanence · ❌ **mini-carte permanente** · ❌ objectif permanent · ❌ niveau permanent · ❌ barre d'XP permanente · ❌ cinq boutons à droite · ❌ **marqueurs au-dessus des PNJ** · ❌ grosses flèches jaunes indiquant où aller.

Où je suis → la Carte. Mon objectif → le Menu. Parler → on s'approche de quelqu'un. Le monde doit respirer.

## 12. Retours haptiques (S24)

Très légers, perçus comme de la qualité : ramasser un objet → tic · ouvrir le menu → presque imperceptible · Poké Ball qui bouge → toc… toc… · coup critique → impact plus marqué · capture réussie → motif particulier.

---

## Règles UI du jalon 3A (extrait donné par Kevin)

Exploration plein écran · un seul bouton contextuel en bas à droite · il n'apparaît qu'à portée d'une interaction · états prévus : Parler / Examiner / Observer / Prendre · dialogue en panneau inférieur moderne et translucide · nom du locuteur distinct du texte · pas de portrait obligatoire · toucher = compléter le texte / continuer · déplacements suspendus pendant un dialogue · aucun marqueur permanent au-dessus des PNJ · pas de journal de quête à l'écran · **on garde le bouton Courir actuel**.

---

## Contradictions avec la planche validée (`ui-reference.md`) — à trancher par Kevin

| Sujet | Planche / `ui-reference.md` | Bible v0.1 |
|---|---|---|
| Boîte de dialogue | boîte **claire**, texte sombre, **portrait au-dessus**, étiquette de nom bleue, ▼ | panneau **sombre translucide**, **pas de portrait**, nom dans le panneau, › |
| Mini-carte | mini-carte circulaire en haut à droite | **interdite** en permanence |
| Bouton menu | bouton rond ☰ en haut à droite | « un geste ou un petit bouton » |
| Menu principal | Équipe · Sac · Pokédex · Carte · **Quêtes** · Options, carte dresseur à gauche | Équipe · Pokédex · Sac · Carte · **Profil**, objectif en bas, ⚙ dans un coin |
| Titre de zone | icône Poké Ball + nom + région, sur un bandeau (implémenté ainsi au jalon 1) | texte directement sur le monde, **sans rectangle** |
