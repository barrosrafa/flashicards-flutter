# Flashi Mobile (Flutter — Android `.apk`/`.aab` & iOS `.ipa`)

Aplicativo nativo mobile em **Flutter 3.27+ / Dart 3.6+** convertido a partir de [`barrosrafa/app-flashi`](https://github.com/barrosrafa/app-flashi) com design system futurista **Spatial Aurora ("Cyber-Glass")**, motor **FSRS-6 de 21 pesos** offline-first, sincronização incremental por cursor `BigInt` **USN** em 28 tabelas e integração total com o backend Supabase (`barrosrafa/Flashi`).

> Documentação completa de arquitetura e especificação arquivo a arquivo disponível em [`FLASHI_FLUTTER_SDD.md`](./FLASHI_FLUTTER_SDD.md).

---

## 1. Requisitos de Ambiente

- **Flutter SDK:** `>= 3.27.0` (Dart `>= 3.6.0`)
- **Android:** JDK 17 + Android SDK 35 (`compileSdk = 35`, `minSdk = 24`)
- **iOS (macOS):** Xcode 16+ + CocoaPods (`platform :ios, '15.0'`)

---

## 2. Configuração e Execução Local

1. Copie o arquivo de variáveis de ambiente de referência:
   ```bash
   cp .env.example .env
   ```
2. Instale os pacotes Flutter:
   ```bash
   flutter pub get
   ```
3. Execute os testes unitários (TemplateRenderer, SyncEngine USN `BigInt`, Outbox Queue e Image Occlusion):
   ```bash
   flutter test
   ```
4. Execute o aplicativo em modo desenvolvimento (ou pressione **"Modo Demo"** na tela inicial para testar offline sem configurar chaves Supabase):
   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=https://SEU_PROJETO.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=SUA_ANON_KEY
   ```

---

## 3. Como Gerar o `.apk` e `.aab` (Android)

### APK de Release (com `--split-per-abi` e ofuscação Dart)
```bash
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/symbols/android \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```
Os APKs gerados ficam em:
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- `build/app/outputs/flutter-apk/app-x86_64-release.apk`

### Android App Bundle (`.aab` para Google Play Store)
```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols/android \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```
Arquivo gerado em: `build/app/outputs/bundle/release/app-release.aab`.

---

## 4. Como Gerar o `.ipa` (iOS / App Store Connect / TestFlight)

```bash
cd ios && pod install --repo-update && cd ..
flutter build ipa --release --ExportOptions-plist=ios/ExportOptions.plist \
  --obfuscate --split-debug-info=build/symbols/ios \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```
Arquivo `.ipa` gerado em: `build/ios/ipa/*.ipa`.

---

## 5. CI/CD Automatizado (GitHub Actions)

O workflow [`.github/workflows/build-mobile-releases.yml`](./.github/workflows/build-mobile-releases.yml) executa automaticamente:
1. `flutter analyze` & `flutter test`
2. Build Android `.apk` + `.aab`
3. Build iOS `.ipa` em runner `macos-15`
