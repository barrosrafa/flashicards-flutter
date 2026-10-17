# 06. Guia Completo de Geração de `.ipa` (iOS) e `.apk` / `.aab` (Android)

Este guia documenta todos os procedimentos locais e em CI/CD para gerar os pacotes instaláveis **iOS (`.ipa`)** e **Android (`.apk` e `.aab`)** do **Flashi Mobile**.

---

## 1. Estrutura do Pacote `.ipa` Gerado Neste Repositório

Um arquivo `.ipa` (*iOS App Store Package*) é um arquivo ZIP estruturado contendo:
```text
Flashi.ipa
└── Payload/
    └── Runner.app/
        ├── Runner                 # Binário executável Mach-O (arm64)
        ├── Info.plist             # Metadados do bundle (io.flashi.app) compilados
        ├── PkgInfo                # Assinatura de pacote Apple (APPL????)
        ├── AppIcon60x60@2x.png    # Ícones do aplicativo
        ├── AppIcon76x76@2x~ipad.png
        ├── Assets/                # Dicionários l10n (pt-BR, en, es) e ícones
        └── _CodeSignature/        # Assinatura digital (Ad-Hoc / Apple Distribution)
            └── CodeResources
```

### Script Automatizado [`scripts/build_ipa.sh`](file:///Users/rafaelaparecido/projects/flashcards-flutter/scripts/build_ipa.sh)
O repositório inclui o script executável `./scripts/build_ipa.sh`, que opera em dois modos automáticos:
1. **Modo Produção Completa (`Flutter SDK + Xcode.app` presentes):**
   Executa `pod install`, `flutter build ipa --release --ExportOptions-plist=ios/ExportOptions.plist --obfuscate --split-debug-info=build/symbols/ios` e gera o `.ipa` assinado para App Store Connect / TestFlight / Ad-Hoc.
2. **Modo Empacotamento Direto (`CommandLineTools` / Sideloading / Verificação Estrutural):**
   Quando o `Xcode.app` completo ainda não está instalado na máquina local, compila o executável nativo `Runner` via `clang`/`swiftc`, converte o [`ios/Runner/Info.plist`](file:///Users/rafaelaparecido/projects/flashcards-flutter/ios/Runner/Info.plist) para formato binário Apple via `plutil`, incorpora os recursos (`assets/l10n`, `assets/icons`), aplica assinatura Ad-Hoc (`codesign --force --sign -`) e empacota o arquivo final em [`build/ios/ipa/Flashi.ipa`](file:///Users/rafaelaparecido/projects/flashcards-flutter/build/ios/ipa/Flashi.ipa).

---

## 2. Passo a Passo: Gerando `.ipa` para iOS (App Store / TestFlight / Ad-Hoc / Sideload)

### Opção A — Usando o Script Automatizado (Recomendado)
```bash
chmod +x scripts/build_ipa.sh
./scripts/build_ipa.sh
```
O arquivo `.ipa` será gerado em:
`build/ios/ipa/Flashi.ipa`

### Opção B — Build Oficial via Flutter CLI + Xcode (App Store Connect / TestFlight)
1. Certifique-se de ter o **Xcode 16+** instalado em `/Applications/Xcode.app` e selecionado:
   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -license accept
   ```
2. Configure seu **Apple Team ID** em [`ios/ExportOptions.plist`](file:///Users/rafaelaparecido/projects/flashcards-flutter/ios/ExportOptions.plist):
   - Substitua `TEAM_ID_PLACEHOLDER` pelo seu Team ID de 10 caracteres da Apple Developer Account.
   - Para distribuição em **TestFlight / App Store**, mantenha `<key>method</key><string>app-store</string>`.
   - Para instalação direta em aparelhos registrados (**Ad-Hoc**), altere para `<key>method</key><string>ad-hoc</string>`.
3. Instale os Pods e gere o `.ipa` com ofuscação de código Dart:
   ```bash
   cd ios && pod install --repo-update && cd ..
   flutter build ipa --release \
     --ExportOptions-plist=ios/ExportOptions.plist \
     --obfuscate \
     --split-debug-info=build/symbols/ios \
     --dart-define=SUPABASE_URL=https://SEU_PROJETO.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=SUA_ANON_KEY
   ```

### Opção C — Gerar `.ipa` sem Conta Paga da Apple (Sideload via AltStore / SideStore / Sideloadly)
Se você deseja instalar o `.ipa` diretamente no seu iPhone usando uma Apple ID gratuita (via AltStore ou Sideloadly):
```bash
flutter build ios --release --no-codesign \
  --dart-define=SUPABASE_URL=https://SEU_PROJETO.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=SUA_ANON_KEY

mkdir -p build/ios/ipa/Payload
cp -R build/ios/iphoneos/Runner.app build/ios/ipa/Payload/
cd build/ios/ipa && zip -qry Flashi-unsigned.ipa Payload
```

---

## 3. Passo a Passo: Gerando `.apk` e `.aab` para Android

### 3.1 Configurar Assinatura de Release (`key.properties`)
Crie sua keystore JKS (uma única vez):
```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
Crie o arquivo `android/key.properties`:
```properties
storePassword=SUA_SENHA
keyPassword=SUA_SENHA
keyAlias=upload
storeFile=upload-keystore.jks
```
*(Nota: se `android/key.properties` não existir, o [`android/app/build.gradle.kts`](file:///Users/rafaelaparecido/projects/flashcards-flutter/android/app/build.gradle.kts) assina automaticamente com a chave debug para facilitar testes imediatos do `.apk`).*

### 3.2 Gerar `.apk` Otimizado por Arquitetura (`arm64-v8a`, `armeabi-v7a`, `x86_64`)
```bash
flutter build apk --release --split-per-abi \
  --obfuscate --split-debug-info=build/symbols/android \
  --dart-define=SUPABASE_URL=https://SEU_PROJETO.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=SUA_ANON_KEY
```
Saída em:
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` *(Dispositivos Android modernos)*
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- `build/app/outputs/flutter-apk/app-x86_64-release.apk`

### 3.3 Gerar `.aab` (Android App Bundle para Google Play Console)
```bash
flutter build appbundle --release \
  --obfuscate --split-debug-info=build/symbols/android \
  --dart-define=SUPABASE_URL=https://SEU_PROJETO.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=SUA_ANON_KEY
```
Saída em: `build/app/outputs/bundle/release/app-release.aab`.

---

## 4. Build Automatizado na Nuvem (GitHub Actions)

O workflow [`.github/workflows/build-mobile-releases.yml`](file:///Users/rafaelaparecido/projects/flashcards-flutter/.github/workflows/build-mobile-releases.yml) compila automaticamente tanto o `.apk`/`.aab` quanto o `.ipa` a cada push na branch `main` ou disparo manual (`workflow_dispatch`), disponibilizando os binários prontos para download na aba **Actions -> Artifacts** do GitHub.
