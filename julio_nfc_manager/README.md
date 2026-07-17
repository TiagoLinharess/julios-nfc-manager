# NFC Manager

Aplicativo Flutter para gerenciar NFCs, clientes, produtos e devolucoes, com login Google e sincronizacao em tempo real via Firebase/Firestore.

## Requisitos

- Flutter instalado e configurado.
- Android Studio ou Android SDK instalado.
- JDK instalado.
- Firebase CLI instalado, se for alterar regras/configuracoes Firebase.
- Um projeto Firebase configurado para o app Android.

Verifique o ambiente com:

```powershell
flutter doctor
```

## Arquivos privados

Alguns arquivos sao necessarios para rodar/gerar o app, mas nao devem ser commitados.

Ao preparar o projeto em outro computador, copie os arquivos do backup para estes caminhos:

```text
android/app/google-services.json
android/app/upload-keystore.jks
android/key.properties
```

O que cada arquivo faz:

- `google-services.json`: configuracao Firebase do app Android.
- `upload-keystore.jks`: chave usada para assinar builds release.
- `key.properties`: senhas e alias da keystore release.

Esses arquivos devem ficar em backup seguro, por exemplo Drive privado com 2FA ou um cofre de senhas.

## O que nao commitar

Nao commite:

```text
android/app/google-services.json
android/app/upload-keystore.jks
android/key.properties
build/
.dart_tool/
```

Esses arquivos ja estao protegidos pelo `.gitignore`.

Tambem nao commite APKs gerados:

```text
build/app/outputs/apk/debug/app-debug.apk
build/app/outputs/apk/release/app-release.apk
```

## Instalacao em outro computador

Clone o repositorio:

```powershell
git clone <url-do-repositorio>
cd julios-nfc-manager\julio_nfc_manager
```

Restaure os arquivos privados nos caminhos corretos:

```text
android/app/google-services.json
android/app/upload-keystore.jks
android/key.properties
```

Instale as dependencias:

```powershell
flutter pub get
```

Confira se o ambiente esta pronto:

```powershell
flutter doctor
```

## Rodar em Android debug

Conecte o celular com depuracao USB ativa ou abra um emulador.

Liste os dispositivos:

```powershell
flutter devices
```

Rode o app:

```powershell
flutter run
```

## Gerar APK release assinado

Confirme que estes arquivos existem:

```text
android/app/upload-keystore.jks
android/key.properties
android/app/google-services.json
```

Gere o APK release:

```powershell
flutter build apk --release
```

Ou pelo Gradle:

```powershell
cd android
.\gradlew.bat assembleRelease
```

O APK final fica em:

```text
build/app/outputs/apk/release/app-release.apk
```

## Firebase e Google Login release

Para o login Google funcionar no APK release, o Firebase precisa ter os hashes da chave release cadastrados.

Para consultar os hashes localmente, rode:

```powershell
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload
```

O comando vai mostrar os campos `SHA1` e `SHA256`. Cadastre esses valores no Firebase.

Se precisar recadastrar pelo Firebase CLI:

```powershell
firebase login --reauth
firebase apps:android:sha:create 1:441378487264:android:f5cc1ce6f0bd4931cfc985 <SHA1_DA_KEYSTORE> --project julio-nfc-manager
firebase apps:android:sha:create 1:441378487264:android:f5cc1ce6f0bd4931cfc985 <SHA256_DA_KEYSTORE> --project julio-nfc-manager
```

Depois de alterar hashes/configuracao no Firebase, baixe novamente a config Android e atualize `android/app/google-services.json`.

## Firestore Rules

As regras ficam em:

```text
firestore.rules
```

Para validar/deployar:

```powershell
firebase deploy --only firestore:rules --project julio-nfc-manager
```

## Observacoes importantes

- A keystore release deve ser preservada. Perder `upload-keystore.jks` pode impedir atualizacoes futuras do app assinado.
- `key.properties` contem senhas. Nao envie esse arquivo por chat, email ou Git.
- `google-services.json` nao e uma senha, mas tambem fica fora do Git neste projeto.
- Se o icone do app nao atualizar no Android apos instalar uma nova build, desinstale o app antes de instalar novamente. Alguns launchers mantem cache do icone.
