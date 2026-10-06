# Textes en brouillon — lot à relire (2026-10-05)

> **Validé par Kevin le 2026-10-06, tout le lot tel quel** (aucune ligne commentée), y compris les ajouts listés en fin de fichier. Tous les `"draft": true` ont été retirés de `data/` ; le test `tests/integration/test_no_draft_in_data.gd` échoue si un nouveau texte provisoire apparaît. Ce fichier sert désormais de référence des textes validés hors dossiers de conception.

> Comme au J6 : commente ligne par ligne (numéro + correction) ; **tout ce que tu ne commentes pas reste inchangé** et perd son statut de brouillon. Généré depuis toutes les entrées `"draft": true` de `data/` (branche `j7-centre`).

## Jalon 7 — Jadielle, Centre, Boutique, Stockage, Route 22

1. `battle/messages.json` · templates/prize_won · text — « Tu remportes {money}. »
2. `dialogues/viridian_center.json` · storage_terminal/variants/0 · page — « Un terminal de Stockage Pokémon. »
3. `items/items.json` · oak_parcel · name — « Colis pour Chen »
4. `items/items.json` · oak_parcel · description — « Un colis confié par le marchand de Jadielle, à remettre au Professeur Chen. »
5. `pokedex/kanto.json` · species/spearow · description — « Petit mais querelleur, il crie fort pour défendre son coin de prairie et chasse les insectes au ras des herbes. »
6. `pokedex/kanto.json` · species/spearow/notes/0 · text — « Il bat des ailes très vite pour rester sur place, puis pique d'un coup vers le sol. »
7. `pokedex/kanto.json` · species/fearow · description — « Ses grandes ailes le portent longtemps sans qu'il se pose. Son long bec fouille la terre comme l'eau. »
8. `pokedex/kanto.json` · species/nidoran_f · description — « Discrète, elle dresse ses grandes oreilles au moindre bruit. Ses petites épines la protègent quand on l'approche de trop près. »
9. `pokedex/kanto.json` · species/nidoran_f/notes/0 · text — « Elle ne s'éloigne jamais beaucoup des herbes hautes, prête à s'y glisser. »
10. `pokedex/kanto.json` · species/nidorina · description — « Plus douce qu'elle n'en a l'air, elle replie ses épines quand elle se sent en confiance. »
11. `pokedex/kanto.json` · species/nidoran_m · description — « Ses grandes oreilles pivotent pour guetter le danger. La petite corne de son front lui sert à se défendre. »
12. `pokedex/kanto.json` · species/nidoran_m/notes/0 · text — « Avant de charger, il agite les oreilles : un avertissement qu'il vaut mieux écouter. »
13. `pokedex/kanto.json` · species/nidorino · description — « Prompt à s'emporter, il pointe sa corne vers tout ce qui approche. »
14. `pokedex/kanto.json` · species/mankey · description — « Il passe en un instant du calme à la colère. Mieux vaut ne pas le fixer quand il se met à trépigner. »
15. `pokedex/kanto.json` · species/mankey/notes/0 · text — « Des branches qui s'agitent sans vent, à la lisière des bois : c'est souvent lui. »
16. `pokedex/kanto.json` · species/primeape · description — « Quand il s'emporte, plus rien ne l'arrête. Il poursuit longtemps ce qui l'a contrarié. »
17. `world/zones.json` · zones/viridian_city · name — « Jadielle »
18. `world/zones.json` · zones/viridian_city · description — « Une ville de passage entre les forêts, où les routes de Kanto se croisent. On y vient pour se reposer, se ravitailler… et on en repart toujours un peu plus loin. »
19. `world/zones.json` · zones/route_22 · name — « Route 22 »
20. `world/zones.json` · zones/route_22 · description — « Un chemin de terre qui s'éloigne de Jadielle vers l'ouest, au pied d'une falaise basse. Là-haut, on devine déjà le Plateau Indigo. »

## Pokédex (descriptions et notes)

21. `pokedex/kanto.json` · species/bulbasaur · description — « Le bulbe sur son dos se gorge de lumière. Calme, il observe longtemps avant d'approcher. »
22. `pokedex/kanto.json` · species/bulbasaur/notes/0 · text — « Après une averse, il reste immobile dans l'herbe mouillée, comme s'il buvait. »
23. `pokedex/kanto.json` · species/ivysaur · description — « Le bouton sur son dos alourdit sa démarche. Il cherche les clairières où le soleil tombe droit. »
24. `pokedex/kanto.json` · species/venusaur · description — « Il se déplace lentement, sa large fleur tournée vers le ciel. Là où il se repose, l'herbe pousse plus haute. »
25. `pokedex/kanto.json` · species/charmander · description — « Petit et curieux, il suit volontiers ceux qui lui parlent avec douceur. La flamme de sa queue s'agite quand il est content. »
26. `pokedex/kanto.json` · species/charmander/notes/0 · text — « Par temps humide, il se blottit pour garder sa flamme à l'abri. »
27. `pokedex/kanto.json` · species/charmeleon · description — « Plus vif qu'il n'en a l'air, il s'emporte vite. Sa flamme grandit quand il s'agite. »
28. `pokedex/kanto.json` · species/charizard · description — « On le reconnaît de loin à la lueur de sa queue, quand il plane au-dessus des crêtes. »
29. `pokedex/kanto.json` · species/squirtle · description — « Il adore les flaques et les bords de rivière, où il peut nager des heures sans se lasser. »
30. `pokedex/kanto.json` · species/squirtle/notes/0 · text — « Surpris, il rentre dans sa carapace, puis jette un œil avant de ressortir. »
31. `pokedex/kanto.json` · species/wartortle · description — « Il nage vite et longtemps. Les pêcheurs racontent qu'il suit parfois les barques. »
32. `pokedex/kanto.json` · species/blastoise · description — « Massif et posé, il ne s'énerve presque jamais. Sa carapace porte les marques de nombreuses années. »
33. `pokedex/kanto.json` · species/pidgey · description — « Discret et peu farouche, il picore au bord des chemins et s'envole en rase-mottes quand on approche trop. »
34. `pokedex/kanto.json` · species/pidgey/notes/0 · text — « On l'aperçoit souvent près des chemins et des zones boisées. »
35. `pokedex/kanto.json` · species/pidgeotto · description — « On l'entend avant de le voir : son cri porte loin au-dessus des bois. »
36. `pokedex/kanto.json` · species/pidgeot · description — « Ses plumes brillent au soleil quand il plane très haut, sans presque battre des ailes. »
37. `pokedex/kanto.json` · species/rattata · description — « Toujours affairé, il file d'un abri à l'autre en longeant les herbes hautes. On l'entend plus souvent qu'on ne le voit. »
38. `pokedex/kanto.json` · species/rattata/notes/0 · text — « Il traverse les hautes herbes par petits bonds : il s'arrête, écoute, puis repart. »
39. `pokedex/kanto.json` · species/raticate · description — « Méfiant, il guette depuis son terrier et ne se montre qu'une fois sûr de lui. »
40. `pokedex/kanto.json` · species/nidoqueen · description — « Couverte d'écailles dures, elle veille sur son terrier avec une patience immense. »
41. `pokedex/kanto.json` · species/nidoking · description — « On l'entend marteler le sol bien avant de l'apercevoir. Sa queue épaisse peut renverser un arbre. »

## Capacités (noms et descriptions)

42. `pokemon/moves/moves.json` · tackle · name — « Charge »
43. `pokemon/moves/moves.json` · tackle · description — « Le lanceur charge la cible et la percute de tout son corps. »
44. `pokemon/moves/moves.json` · scratch · name — « Griffe »
45. `pokemon/moves/moves.json` · scratch · description — « Lacère la cible avec des griffes acérées. »
46. `pokemon/moves/moves.json` · growl · name — « Rugissement »
47. `pokemon/moves/moves.json` · growl · description — « Un cri mignon qui fait baisser l'Attaque de la cible. »
48. `pokemon/moves/moves.json` · tail_whip · name — « Mimi-Queue »
49. `pokemon/moves/moves.json` · tail_whip · description — « Le lanceur remue la queue pour détourner l'attention. Baisse la Défense de la cible. »
50. `pokemon/moves/moves.json` · leer · name — « Groz'Yeux »
51. `pokemon/moves/moves.json` · leer · description — « Un regard intimidant qui fait baisser la Défense de la cible. »
52. `pokemon/moves/moves.json` · growth · name — « Croissance »
53. `pokemon/moves/moves.json` · growth · description — « Le lanceur grandit d'un coup. Augmente son Attaque et son Attaque Spéciale. »
54. `pokemon/moves/moves.json` · withdraw · name — « Repli »
55. `pokemon/moves/moves.json` · withdraw · description — « Le lanceur se cache dans sa carapace. Augmente sa Défense. »
56. `pokemon/moves/moves.json` · leech_seed · name — « Vampigraine »
57. `pokemon/moves/moves.json` · leech_seed · description — « Plante une graine sur la cible, qui perd des PV à chaque tour au profit du lanceur. »
58. `pokemon/moves/moves.json` · poison_powder · name — « Poudre Toxik »
59. `pokemon/moves/moves.json` · poison_powder · description — « Une poudre toxique qui empoisonne la cible. »
60. `pokemon/moves/moves.json` · sleep_powder · name — « Poudre Dodo »
61. `pokemon/moves/moves.json` · sleep_powder · description — « Une poudre soporifique qui endort la cible. »
62. `pokemon/moves/moves.json` · vine_whip · name — « Fouet Lianes »
63. `pokemon/moves/moves.json` · vine_whip · description — « Fouette la cible avec de fines lianes. »
64. `pokemon/moves/moves.json` · razor_leaf · name — « Tranch'Herbe »
65. `pokemon/moves/moves.json` · razor_leaf · description — « Des feuilles tranchantes frappent la cible. Taux de critique élevé. »
66. `pokemon/moves/moves.json` · solar_beam · name — « Lance-Soleil »
67. `pokemon/moves/moves.json` · solar_beam · description — « Absorbe la lumière au premier tour, puis projette un rayon puissant au second. »
68. `pokemon/moves/moves.json` · ember · name — « Flammèche »
69. `pokemon/moves/moves.json` · ember · description — « De petites flammes frappent la cible. Peut la brûler. »
70. `pokemon/moves/moves.json` · flamethrower · name — « Lance-Flammes »
71. `pokemon/moves/moves.json` · flamethrower · description — « Un torrent de flammes s'abat sur la cible. Peut la brûler. »
72. `pokemon/moves/moves.json` · fire_spin · name — « Danse Flamme »
73. `pokemon/moves/moves.json` · fire_spin · description — « Enferme la cible dans un tourbillon de feu pendant quelques tours. »
74. `pokemon/moves/moves.json` · rage · name — « Frénésie »
75. `pokemon/moves/moves.json` · rage · description — « Le lanceur s'emporte. Son Attaque augmente à chaque coup reçu. »
76. `pokemon/moves/moves.json` · slash · name — « Tranche »
77. `pokemon/moves/moves.json` · slash · description — « Tranche la cible avec des griffes ou des lames. Taux de critique élevé. »
78. `pokemon/moves/moves.json` · bubble · name — « Écume »
79. `pokemon/moves/moves.json` · bubble · description — « Une nuée de bulles frappe la cible. Peut baisser sa Vitesse. »
80. `pokemon/moves/moves.json` · water_gun · name — « Pistolet à O »
81. `pokemon/moves/moves.json` · water_gun · description — « Un jet d'eau puissant frappe la cible. »
82. `pokemon/moves/moves.json` · bite · name — « Morsure »
83. `pokemon/moves/moves.json` · bite · description — « Mord la cible de ses crocs acérés. Peut l'apeurer. »
84. `pokemon/moves/moves.json` · skull_bash · name — « Coud'Krâne »
85. `pokemon/moves/moves.json` · skull_bash · description — « Rentre la tête au premier tour, ce qui augmente sa Défense, puis charge au second. »
86. `pokemon/moves/moves.json` · hydro_pump · name — « Hydrocanon »
87. `pokemon/moves/moves.json` · hydro_pump · description — « Un puissant jet d'eau sous pression frappe la cible. »
88. `pokemon/moves/moves.json` · gust · name — « Tornade »
89. `pokemon/moves/moves.json` · gust · description — « Frappe la cible d'une rafale de vent soulevée par les ailes. »
90. `pokemon/moves/moves.json` · sand_attack · name — « Jet de Sable »
91. `pokemon/moves/moves.json` · sand_attack · description — « Lance du sable au visage de la cible. Baisse sa Précision. »
92. `pokemon/moves/moves.json` · quick_attack · name — « Vive-Attaque »
93. `pokemon/moves/moves.json` · quick_attack · description — « Le lanceur fonce sur la cible si vite qu'on le voit à peine. Frappe en premier. »
94. `pokemon/moves/moves.json` · whirlwind · name — « Cyclone »
95. `pokemon/moves/moves.json` · whirlwind · description — « Un coup de vent renvoie la cible. Sans effet dans le moteur actuel. »
96. `pokemon/moves/moves.json` · wing_attack · name — « Cru-Ailes »
97. `pokemon/moves/moves.json` · wing_attack · description — « Déploie ses grandes ailes pour frapper la cible. »
98. `pokemon/moves/moves.json` · agility · name — « Hâte »
99. `pokemon/moves/moves.json` · agility · description — « Détend le corps pour gagner en légèreté. Augmente beaucoup la Vitesse. »
100. `pokemon/moves/moves.json` · mirror_move · name — « Mimique »
101. `pokemon/moves/moves.json` · mirror_move · description — « Riposte avec la dernière capacité de la cible. Sans effet dans le moteur actuel. »
102. `pokemon/moves/moves.json` · hyper_fang · name — « Croc de Mort »
103. `pokemon/moves/moves.json` · hyper_fang · description — « Mord violemment la cible de ses incisives. Peut l'apeurer. »
104. `pokemon/moves/moves.json` · focus_energy · name — « Puissance »
105. `pokemon/moves/moves.json` · focus_energy · description — « Le lanceur prend une profonde inspiration. Sans effet dans le moteur actuel. »
106. `pokemon/moves/moves.json` · super_fang · name — « Croc Fatal »
107. `pokemon/moves/moves.json` · super_fang · description — « Mord la cible pour lui retirer la moitié de ses PV. Sans effet dans le moteur actuel. »
108. `pokemon/moves/moves.json` · peck · name — « Picpic »
109. `pokemon/moves/moves.json` · peck · description — « Frappe la cible d'un bec pointu. »
110. `pokemon/moves/moves.json` · fury_attack · name — « Furie »
111. `pokemon/moves/moves.json` · fury_attack · description — « Frappe la cible de deux à cinq coups de corne ou de bec. Un seul coup dans le moteur actuel. »
112. `pokemon/moves/moves.json` · drill_peck · name — « Bec Vrille »
113. `pokemon/moves/moves.json` · drill_peck · description — « Le lanceur tourne sur lui-même et transperce la cible de son bec. »
114. `pokemon/moves/moves.json` · karate_chop · name — « Poing Karaté »
115. `pokemon/moves/moves.json` · karate_chop · description — « Un coup du tranchant de la main. Taux de critique élevé. »
116. `pokemon/moves/moves.json` · fury_swipes · name — « Combo-Griffe »
117. `pokemon/moves/moves.json` · fury_swipes · description — « Griffe la cible de deux à cinq coups rapides. Un seul coup dans le moteur actuel. »
118. `pokemon/moves/moves.json` · seismic_toss · name — « Frappe Atlas »
119. `pokemon/moves/moves.json` · seismic_toss · description — « Projette la cible au sol. Sans effet dans le moteur actuel. »
120. `pokemon/moves/moves.json` · thrash · name — « Mania »
121. `pokemon/moves/moves.json` · thrash · description — « Le lanceur se déchaîne pendant plusieurs tours, puis finit étourdi. »
122. `pokemon/moves/moves.json` · screech · name — « Grincement »
123. `pokemon/moves/moves.json` · screech · description — « Un cri strident qui fait beaucoup baisser la Défense de la cible. »
124. `pokemon/moves/moves.json` · poison_sting · name — « Dard-Venin »
125. `pokemon/moves/moves.json` · poison_sting · description — « Pique la cible d'un dard venimeux. Peut l'empoisonner. »
126. `pokemon/moves/moves.json` · double_kick · name — « Double Pied »
127. `pokemon/moves/moves.json` · double_kick · description — « Deux coups de pied rapides. Un seul coup dans le moteur actuel. »
128. `pokemon/moves/moves.json` · horn_attack · name — « Koud'Korne »
129. `pokemon/moves/moves.json` · horn_attack · description — « Frappe la cible d'une corne pointue. »
130. `pokemon/moves/moves.json` · horn_drill · name — « Empal'Korne »
131. `pokemon/moves/moves.json` · horn_drill · description — « Une corne en vrille qui met K.O. d'un coup. Sans effet dans le moteur actuel. »
132. `pokemon/moves/moves.json` · body_slam · name — « Plaquage »
133. `pokemon/moves/moves.json` · body_slam · description — « Le lanceur se jette de tout son poids sur la cible. Peut la paralyser. »
134. `pokemon/moves/moves.json` · struggle · name — « Lutte »
135. `pokemon/moves/moves.json` · struggle · description — « Utilisée quand il ne reste plus aucun PP. Blesse aussi le lanceur. »

## Messages de combat

136. `battle/messages.json` · templates/battle_started · text — « {trainer} veut se battre ! »
137. `battle/messages.json` · templates/sent_out_player · text — « En avant, {pokemon} ! »
138. `battle/messages.json` · templates/move_used · text — « {pokemon} utilise {move} ! »
139. `battle/messages.json` · templates/move_missed · text — « {pokemon} rate son attaque ! »
140. `battle/messages.json` · templates/no_effect · text — « Ça n'affecte pas {pokemon}... »
141. `battle/messages.json` · templates/stat_rose · text — « {stat} {de_pokemon} augmente ! »
142. `battle/messages.json` · templates/stat_rose_2 · text — « {stat} {de_pokemon} augmente beaucoup ! »
143. `battle/messages.json` · templates/stat_rose_3 · text — « {stat} {de_pokemon} augmente énormément ! »
144. `battle/messages.json` · templates/stat_fell · text — « {stat} {de_pokemon} baisse ! »
145. `battle/messages.json` · templates/stat_fell_2 · text — « {stat} {de_pokemon} baisse beaucoup ! »
146. `battle/messages.json` · templates/stat_fell_3 · text — « {stat} {de_pokemon} baisse énormément ! »
147. `battle/messages.json` · templates/stat_no_higher · text — « {stat} {de_pokemon} ne peut plus augmenter ! »
148. `battle/messages.json` · templates/stat_no_lower · text — « {stat} {de_pokemon} ne peut plus baisser ! »
149. `battle/messages.json` · templates/recoil · text — « {pokemon} est blessé par le contrecoup ! »
150. `battle/messages.json` · templates/fainted · text — « {pokemon} est K.O. ! »
151. `battle/messages.json` · templates/battle_won · text — « Tu as battu {trainer} ! »
152. `battle/messages.json` · templates/battle_lost · text — « {trainer} a gagné cette fois... »
153. `battle/messages.json` · templates/wild_appeared · text — « Un {pokemon} sauvage apparaît ! »
154. `battle/messages.json` · templates/fled · text — « Tu prends la fuite ! »
155. `battle/messages.json` · templates/flee_failed · text — « Impossible de fuir ! »
156. `battle/messages.json` · templates/level_up · text — « {pokemon} monte au niveau {level} ! »
157. `battle/messages.json` · templates/move_learned · text — « {pokemon} apprend {move} ! »
158. `battle/messages.json` · templates/move_forget_prompt · text — « {pokemon} veut apprendre {move}, mais connaît déjà quatre capacités. »
159. `battle/messages.json` · templates/move_forgot · text — « {pokemon} oublie {old_move} et apprend {move} ! »
160. `battle/messages.json` · templates/forget_confirm_title · text — « Oublier {old_move} ? »
161. `battle/messages.json` · templates/forget_confirm_detail · text — « {old_move} sera remplacée par {move}. »
162. `battle/messages.json` · templates/forget_confirm_yes · text — « OUBLIER »
163. `battle/messages.json` · templates/forget_confirm_no · text — « GARDER »
164. `battle/messages.json` · templates/move_not_learned · text — « {pokemon} n'apprend pas {move}. »
165. `battle/messages.json` · templates/seeded · text — « Une graine est plantée sur {pokemon} ! »
166. `battle/messages.json` · templates/drained · text — « Vampigraine draine l'énergie {de_pokemon} ! »
167. `battle/messages.json` · templates/ball_thrown · text — « Tu lances une {item} ! »
168. `battle/messages.json` · templates/broke_free · text — « Oh non ! Il s'est libéré ! »
169. `battle/messages.json` · templates/item_used · text — « Tu utilises {item} sur {pokemon}. »
170. `battle/messages.json` · templates/hp_restored · text — « {pokemon} récupère {amount} PV. »

## Autres (objets, zones, moments, objectifs, dialogues)

171. `dialogues/pallet_town.json` · observe_aoki_pidgey · page — « Il picore les graines, l'œil attentif. »
172. `dialogues/pallet_town.json` · observe_leo_rattata · page — « Il te renifle, les moustaches frémissantes. »
173. `dialogues/pallet_town.json` · sign_pallet_town · page — « BOURG PALETTE »
174. `dialogues/player_house.json` · mom/variants/1 · page — « Laisse-moi m'occuper de tes Pokémon. »
175. `dialogues/player_house.json` · mom/variants/1 · page — « Voilà, ils sont en pleine forme. Reviens quand tu veux. »
176. `items/items.json` · poke_ball · name — « Poké Ball »
177. `items/items.json` · poke_ball · description — « Permet de capturer un Pokémon sauvage. »
178. `items/items.json` · potion · name — « Potion »
179. `items/items.json` · potion · description — « Restaure les PV d'un Pokémon. »
180. `story/objectives.json` · 1 · text — « rejoindre Jadielle »
181. `trainer/moments.json` · outcomes/win · text — « Tu l'emportes. »
182. `trainer/moments.json` · outcomes/loss · text — « Il l'emporte, cette fois. »
183. `world/zones.json` · zones/pallet_town · name — « Bourg Palette »
184. `world/zones.json` · zones/pallet_town · description — « Un bourg tranquille entre les prés et la mer. Le vent du large y porte l'odeur de l'herbe coupée. »
185. `world/zones.json` · zones/route_1 · name — « Route 1 »
186. `world/zones.json` · zones/route_1 · description — « Un chemin de campagne qui serpente vers Jadielle, entre clôtures et hautes herbes. Quitter le sentier y est souvent récompensé. »

## Noms affichés des locuteurs (J7, non marqués « draft » mais choisis par défaut)

187. `viridian_city.json` · viridian_courier — « Livreur »
188. `viridian_city.json` · viridian_lass — « Dresseuse »
189. `viridian_city.json` · viridian_kid — « Enfant »
190. `viridian_city.json` · viridian_traveler — « Voyageur »
191. `viridian_city.json` · viridian_old_man — « Vieil homme »
192. `viridian_city.json` · viridian_gym_watcher — « Habitant »
193. `route_22.json` · route22_youngster_sigh — « Jeune Dresseur »
194. `route_22.json` · route22_rival_hesitates — « Rival »
195. `viridian_mart.json` · clerk — « Marchand »
196. `viridian_center.json` · nurse — « Infirmière »

## Ajouts au lot depuis le 2026-10-05 (validés avec lui le 2026-10-06)

197. `battle/messages.json` · templates/recoil · text_f — « {pokemon} est blessée par le contrecoup ! »
198. `battle/messages.json` · templates/wild_appeared · text_f — « Une {pokemon} sauvage apparaît ! »
199. `battle/messages.json` · templates/broke_free · text_f — « Oh non ! Elle s'est libérée ! »
200. `battle/messages.json` · templates/withdrawn · text — « Reviens, {pokemon} ! »
201. `battle/messages.json` · templates/switch_reason_active · text — « Déjà au combat »
202. `battle/messages.json` · templates/switch_reason_fainted · text — « Ne peut plus combattre »
203. `battle/messages.json` · templates/replace_prompt · text — « Qui envoyer au combat ? »
204. `battle/messages.json` · templates/summary_continue · text — « Touchez l'écran pour continuer »
205. `dialogues/oak_lab.json` · oak_parcel_rival_dex · page — « Toi aussi, prends-en un. »
206. `dialogues/viridian_city.json` · viridian_house_door · page — « C'est fermé. »
207. `story/objectives.json` · reach_viridian · text — « rejoindre Jadielle. »
208. `trainer/moments.json` · moments/starter — « Premier Pokémon » / « {species} rejoint ton équipe. »
209. `trainer/moments.json` · moments/rival_battle — « Combat contre le rival » / « {outcome} »
210. `trainer/moments.json` · moments/first_capture — « Première capture » / « {species} rejoint l'aventure. »
211. `trainer/moments.json` · moments/zone_arrival — « {zone} » / « Une nouvelle zone découverte. »
212. `trainer/moments.json` · zone_arrivals/route_1 — « Départ de Bourg Palette » / « Premiers pas sur la Route 1. »
213. `trainer/moments.json` · zone_arrivals/viridian_city — « Arrivée à Jadielle » / « Une nouvelle ville. »
214. `world/zones.json` · zones/route_1 · subtitle — « Bourg Palette — Jadielle »

Textes provisoires écrits dans le code (vues), validés aussi :

215. `ShopViews` · TEXT_NOTHING_TO_SELL — « Tu n'as rien à vendre. »
216. `ShopViews` · confirmation de la vente d'un favori — « Vendre %s ? » / « Vendre %d %s ? », « C'est un de tes favoris. », VENDRE / ANNULER
217. `StorageViews` · LAST_ABLE_TEXT — « Tu dois garder au moins un Pokémon en état de combattre. »
218. `StorageViews` · PARTY_FULL_TEXT — « Ton équipe est déjà complète. »
219. `StorageViews` · EMPTY_TEXT — « Le stockage est vide. »
220. `StorageViews` · RELEASED_TEXT — « %s a été libéré. »
221. `TrainerView` · MONEY_LABEL — « Argent »
222. `BagQuery` · REFUSAL_FORMATS — « %s a déjà tous ses PV. », « %s est K.O. », « Il n'en reste plus. », « Pas maintenant. », « Cela n'aurait aucun effet sur %s. »

Textes d'interface notés « provisoires (règle 4) » dans le code, validés tels quels par Kevin le 2026-10-06 (« oui, valide-les aussi tels quels ») :

223. `SettingsViews` — catégories « JEU », « COMMANDES », « ACCESSIBILITÉ », « GRAPHISMES » ; « Activé » / « Désactivé » ; « Partie sauvegardée » (+ « — 14 h 05 »), « La sauvegarde n'a pas pu être écrite. », « Sauvegarde désactivée pour cette session. », « La partie se sauvegarde aussi toute seule. », « Sauvegarder maintenant » ; « Vitesse du texte » (« Dans les dialogues. » ; Lente, Normale, Rapide, Instantanée) ; « Confirmer certaines actions » (« Avant d'oublier une capacité. ») ; « Taille du joystick » (Petite, Normale, Grande) ; « Opacité du joystick » ; « Taille des boutons » (Normale, Grande) ; « Vibrations » ; « Mode gaucher » (« Joystick à droite, boutons à gauche. ») ; « Taille du texte » (Normale, Grande) ; « Contraste renforcé » ; « Réduire les animations » (« Transitions et animations de combat plus courtes. ») ; « Réduire les flashs » (« Coups et captures sans éclair vif. ») ; « Qualité » (« Économie : 30 images par seconde, pour la batterie. » ; Auto, « Auto (Élevée) », Élevée, Économie).
224. `DashboardViews` — « Objectif : », « Dresseur Pokémon » ; cartes « Équipe » (« Tes Pokémon et leurs capacités. »), « Pokédex » (« Les Pokémon que tu as observés. »), « Sac » (« Utilise et range tes objets. »), « Carte » (« Kanto et tes découvertes. »), « Dresseur » (« Ton profil et ton parcours. »), « Paramètres » (« Jeu, commandes, graphismes et accessibilité. ») ; « 3 vus · 1 capturé » (vu / vus, capturé / capturés).
225. `BagQuery` — tris « Pertinence », « Nom », « Quantité », « Récents » ; « Utilisable en combat » ; raisons « PV déjà au maximum », « Ce Pokémon est K.O. », « Il n'en reste plus », « Pas maintenant », « Sans effet » ; résultat « +20 PV — Salamèche 33/51 » ; « Ton Sac est vide. », « Aucun soin dans ton Sac. ».
226. `PokedexQuery` — « Pokédex » ; filtres « Tous », « Vus », « Capturés », « Habitats » ; « … · 151 espèces », « Aucune espèce ne correspond. », « Aucune espèce enregistrée. », « Aucun habitat noté pour l'instant. », « Rien de noté pour l'instant. », « 3 fois », « Zones observées : 2 », « N° 016 », « Vu 3 fois », « · capturé 1 fois », « 0,3 m », « 1,8 kg ».
227. `TeamViews` — statistiques « PV », « Attaque », « Défense », « Atq. Spé. », « Déf. Spé. », « Vitesse » ; Histoire « Reçu à », « Capturé à », « Rencontré à », « Ton premier Pokémon », « Son histoire reste à écrire. » ; « 112 / 173 XP », « 61 XP avant le niveau suivant ».
228. `PokedexUpdates` — toasts « Pokédex mis à jour », « Nouvel habitat observé », « Évolution découverte ».
229. `TrainerSummary` — « Temps de jeu », « Zones découvertes », « Captures », « Objets trouvés ».
230. `TrainerView` — « Badges », « Grands moments », « Statistiques », « Début de l'aventure », « Argent », « Ton aventure ne fait que commencer. ».
231. Panneau Sac du combat (`BattleBagPanel`) — « SAC », « Aucun objet utilisable pour l'instant. ».
232. Panneau Équipe du combat (`BattlePartyPanel`) — « ÉQUIPE », « ENVOYER ».
