# Ressources visuelles Google Play Store

Placez les fichiers suivants dans les sous-répertoires indiqués.
supply (fastlane) les téléverse automatiquement lorsque `skip_upload_images: false`.

## Ressources requises et dimensions

| Répertoire         | Fichier(s)           | Dimensions / format                              |
|--------------------|----------------------|--------------------------------------------------|
| `icon/`            | `icon.png`           | 512×512 px, PNG, 32 bits                         |
| `featureGraphic/`  | `featureGraphic.png` | 1024×500 px, PNG ou JPG, max 1 Mo                |
| `phoneScreenshots/`| `01.png` … `08.png`  | Min 320 px côté court, max 3840 px, max 8 Mo     |
|                    |                      | Ratio accepté : 16:9 ou 9:16 (portrait/paysage)  |

## Notes
- L'icône du lanceur est déjà générée dans `android/app/src/main/res/`.
  Exportez une copie 512×512 ici pour le créneau icône de la fiche Play Store.
- Les captures d'écran doivent provenir d'un vrai appareil ou d'un émulateur.
  Les captures existantes dans `screenshots/` à la racine du dépôt
  constituent un bon point de départ — redimensionnez-les aux spécifications Play Store.
- featureGraphic est affiché en en-tête de la fiche Play Store.
