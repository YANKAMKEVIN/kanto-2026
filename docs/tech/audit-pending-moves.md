# Audit des capacités incomplètes

78 espèces, 120 capacités, 12 capacités avec effets en attente.

Les niveaux ci-dessous sont des apprentissages déclarés dans les données ;
ils ne prouvent pas qu'une espèce est déjà rencontrable dans l'aventure.

| Capacité | Effets ignorés | Apprentissages déclarés |
|---|---|---|
| Buée Noire (`haze`) | haze | Nosferalto N43, Smogo N45, Nosferapti N36 |
| Empal'Korne (`horn_drill`) | ohko | Poissirène N45, Nidoran♂ N36, Nidorino N41 |
| Mur Lumière (`light_screen`) | light_screen | Mélofée N48, Stari N42, Voltorbe N29 |
| Métronome (`metronome`) | metronome | Mélodelfe N1, Mélofée N31 |
| Mimique (`mirror_move`) | mirror | Rapasdepic N25, Roucarnage N54, Roucoups N49, Roucool N44, Piafabec N22 |
| Danse Fleur (`petal_dance`) | rampage | Ortide N38, Mystherbe N33 |
| Frénésie (`rage`) | rage | Dardargnan N25, Dracaufeu N24, Salamèche N22, Reptincel N24, Osselait N46, Ossatueur N55, Onix N25 |
| Soin (`recover`) | heal_half | Kadabra N31, Stari N27 |
| Protection (`reflect`) | reflect | Noeunoeuf N25, Kadabra N42 |
| Coud'Krâne (`skull_bash`) | two_turn, charge_def_up | Tortank N42, Carapuce N35, Carabaffe N39 |
| Lance-Soleil (`solar_beam`) | two_turn | Bulbizarre N48, Noeunoeuf N42, Ortide N52, Herbizarre N54, Mystherbe N46, Florizarre N65 |
| Mania (`thrash`) | rampage | Osselait N38, Férosinge N39, Ossatueur N41, Nidoking N1, Nidoking N23, Colossinge N46 |

Généré par `python3 tools/audit_pending_moves.py`. Aucun effet n'est
activé ou remplacé par cet outil. Compléter les règles et leur présentation
avant de retirer un marqueur `pending_effects`.
