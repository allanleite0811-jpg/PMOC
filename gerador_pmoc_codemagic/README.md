# Gerador PMOC — Codemagic Ready (APK)

Pronto para gerar **APK** no Codemagic com:
- Nome do app: **Gerador PMOC**
- Ícone: **logo AD Climatização** (`assets/logo.png`) via `flutter_launcher_icons`
- PDF com **marca d’água central grande e transparente**
- Pipeline `codemagic.yaml` que:
  1) Gera `android/` se não existir
  2) `flutter pub get`
  3) `dart run flutter_launcher_icons`
  4) Define o nome do app
  5) `flutter build apk --release`

## Como usar no Codemagic
1. Suba este projeto para um repositório no **GitHub**.
2. No **codemagic.io**, adicione o app e selecione este repositório.
3. Inicie o workflow **Build APK (Gerador PMOC)**.
4. Baixe o artefato **app-release.apk** ao final do build.

## Uso local (opcional)
```bash
flutter create . --platforms=android
flutter pub get
dart run flutter_launcher_icons
flutter build apk --release
```