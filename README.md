# InputSmith

**A native macOS workbench for inspecting, testing and eventually configuring game controllers.**

InputSmith commence avec la GameSir G7 Pro, un modèle qui ne dispose pas d'un outil de configuration officiel sur macOS. Le projet sépare l'interface, les données d'entrée et le transport USB afin de pouvoir accueillir d'autres périphériques plus tard.

## État actuel

- interface AppKit native, compatible avec les Command Line Tools installés ;
- détection en lecture seule des interfaces HID GameSir (`VID 0x3537`) ;
- affichage du PID, du transport, de l'usage HID et du numéro de série lorsqu'il est exposé ;
- mode simulation utilisable avant la réception de la manette ;
- moniteur animé des sticks, gâchettes, boutons et du gyroscope ;
- couche d'état indépendante prête à recevoir les vrais rapports USB ;
- aucune commande d'écriture et aucune interaction avec le firmware.

Les noms associés aux PID connus sont des indications communautaires. La détection réelle de l'exemplaire reçu restera la source de vérité.

## Lancer

```bash
git clone <URL_DU_DEPOT>
cd inputsmith-macos
swift run InputSmith
```

Pré-requis : macOS 14 ou supérieur et Swift 5.10 ou supérieur. Le package peut être ouvert directement dans Xcode via `Package.swift`.

## Vérifier

```bash
swift build
swift run InputSmith --self-test
```

## Étapes prévues

1. Confirmer le VID/PID et les interfaces de la manette réelle en USB.
2. Capturer et afficher les rapports d'entrée sans les modifier.
3. Décoder sticks, gâchettes, boutons, gyroscope et batterie.
4. Lire puis sauvegarder la configuration embarquée.
5. Ajouter les écritures avec vérification et restauration automatique.

Les mises à jour de firmware et le bootloader sont explicitement hors périmètre du MVP.

La feuille de route détaillée se trouve dans [`docs/ROADMAP.md`](docs/ROADMAP.md).

## Sécurité

Le MVP est volontairement en lecture seule. Les futures commandes de configuration devront respecter le cycle suivant : sauvegarde, écriture limitée, relecture, vérification et restauration en cas d'échec. InputSmith n'a pas vocation à modifier ou distribuer des firmwares propriétaires.

## Sources de recherche

Les identifiants de produits indiqués dans le catalogue local proviennent de recherches communautaires publiées, notamment [gamesir-linux-tools](https://github.com/broroeror/gamesir-linux-tools). InputSmith n'en reprend pas le code et développera son propre transport macOS.

## Statut du projet

InputSmith est un projet indépendant, non affilié à GameSir. GameSir et les noms de ses produits appartiennent à leurs propriétaires respectifs.

## Licence

MIT — voir [`LICENSE`](LICENSE).
