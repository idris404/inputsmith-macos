# Feuille de route InputSmith

## Phase 0 — Socle hors matériel

- [x] application macOS native ;
- [x] scanner HID limité au Vendor ID GameSir ;
- [x] catalogue prudent des PID publiquement documentés ;
- [x] état d'entrée normalisé ;
- [x] simulateur et moniteur animé ;
- [x] inspecteur de rapports bruts simulés avec diff et export JSON ;
- [x] auto-vérification exécutable sans Xcode complet.

## Phase 1 — Première connexion réelle

- [ ] relever les descripteurs USB de l'exemplaire reçu ;
- [ ] confirmer le PID pour les connexions filaire et 2,4 GHz ;
- [ ] lister toutes les interfaces et collections HID ;
- [ ] exporter un diagnostic local anonymisé ;
- [ ] conserver le logiciel en lecture seule.

## Phase 2 — Décodage des entrées

- [ ] connecter l'inspecteur existant aux rapports IOHID réels ;
- [ ] associer chaque bit aux boutons physiques ;
- [ ] décoder les sticks et gâchettes ;
- [ ] mesurer les valeurs min/max, centres et bruit ;
- [ ] décoder le gyroscope, la batterie et les boutons arrière ;
- [ ] mesurer le polling rate observé.

## Phase 3 — Lecture de configuration

- [ ] identifier sans ambiguïté l'interface de configuration ;
- [ ] lire les profils sans les modifier ;
- [ ] produire une sauvegarde versionnée et vérifiable ;
- [ ] comparer deux configurations au niveau des registres.

## Phase 4 — Écritures contrôlées

- [ ] modifier un seul réglage réversible ;
- [ ] relire et vérifier chaque écriture ;
- [ ] restaurer automatiquement en cas d'écart ;
- [ ] ajouter courbes, zones mortes, remappage et vibrations ;
- [ ] ne jamais toucher au bootloader ou au firmware dans l'application.

## Phase 5 — Produit open source

- [ ] paquet `.app` signé ;
- [ ] diagnostics et journaux exportables ;
- [ ] documentation pour ajouter un nouveau contrôleur ;
- [ ] fixtures anonymisées et tests de régression ;
- [ ] prise en charge progressive d'autres périphériques.
