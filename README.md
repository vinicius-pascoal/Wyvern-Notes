# Wyvern Notes

**Wyvern Notes** é um aplicativo mobile desenvolvido em **Flutter** com **Firebase**, criado para funcionar como um bloco de notas organizado por pastas. O usuário pode criar pastas, cadastrar múltiplas anotações dentro delas, editar conteúdos e exportar notas em PDF.

A proposta visual do projeto utiliza uma identidade inspirada em fantasia, com fundo azul escuro e uma logo de dragão/wyvern em estilo vetorial.

---

## Visão geral

O projeto foi pensado como um app simples, funcional e com boa organização de código, ideal para estudo, portfólio e evolução futura.

Principais recursos:

- Autenticação de usuários com e-mail e senha;
- Criação, edição e exclusão de pastas;
- Criação, edição e exclusão de notas;
- Organização de notas por pasta;
- Persistência dos dados no Cloud Firestore;
- Exportação de notas em PDF;
- Uso de logo SVG dentro do app;
- Uso da logo como ícone do aplicativo;
- Interface com tema azul escuro.

---

## Tecnologias utilizadas

- Flutter
- Dart
- Firebase Core
- Firebase Authentication
- Cloud Firestore
- Flutter SVG
- PDF
- Printing
- Intl
- Flutter Launcher Icons

---

## Estrutura do projeto

```txt
lib/
 ├── main.dart
 ├── firebase_options.dart
 │
 ├── core/
 │   ├── constants/
 │   │   ├── app_assets.dart
 │   │   └── app_colors.dart
 │   └── utils/
 │       └── date_formatter.dart
 │
 ├── models/
 │   ├── folder_model.dart
 │   └── note_model.dart
 │
 ├── services/
 │   ├── auth_service.dart
 │   ├── folder_service.dart
 │   ├── note_service.dart
 │   └── pdf_export_service.dart
 │
 ├── features/
 │   ├── auth/
 │   │   ├── login_screen.dart
 │   │   └── register_screen.dart
 │   │
 │   ├── splash/
 │   │   └── splash_screen.dart
 │   │
 │   ├── folders/
 │   │   └── home_screen.dart
 │   │
 │   └── notes/
 │       ├── notes_screen.dart
 │       └── note_editor_screen.dart
 │
 └── widgets/
     ├── app_text_field.dart
     └── primary_button.dart
```

Estrutura de assets recomendada:

```txt
assets/
 ├── images/
 │   └── wyvern_logo.svg
 └── icons/
     └── wyvern_launcher_icon.png
```

---

## Estrutura dos dados no Firestore

As notas são salvas no **Cloud Firestore**, vinculadas ao usuário autenticado.

```txt
users
 └── userId
      ├── name
      ├── email
      ├── createdAt
      │
      └── folders
           └── folderId
                ├── name
                ├── createdAt
                ├── updatedAt
                │
                └── notes
                     └── noteId
                          ├── title
                          ├── content
                          ├── createdAt
                          └── updatedAt
```

Caminho de uma nota:

```txt
users/{userId}/folders/{folderId}/notes/{noteId}
```

---

## Funcionalidades

### Autenticação

- Cadastro com nome, e-mail e senha;
- Login com e-mail e senha;
- Logout;
- Controle de sessão com Firebase Auth.

### Pastas

- Criar pasta;
- Editar nome da pasta;
- Excluir pasta;
- Listar pastas do usuário autenticado.

### Notas

- Criar nota dentro de uma pasta;
- Editar título e conteúdo;
- Excluir nota;
- Listar notas por pasta;
- Ordenar notas pela última atualização.

### Exportação em PDF

- Exportar uma nota individual em PDF;
- O PDF contém título, nome da pasta e conteúdo da anotação;
- A exportação utiliza os pacotes `pdf` e `printing`.

### Identidade visual

- Fundo azul escuro;
- Logo SVG do dragão/wyvern dentro do app;
- Ícone personalizado do aplicativo usando `flutter_launcher_icons`.

---

## Instalação

Clone o repositório:

```bash
git clone https://github.com/seu-usuario/wyvern_notes.git
cd wyvern_notes
```

Instale as dependências:

```bash
flutter pub get
```

---

## Dependências principais

No arquivo `pubspec.yaml`, adicione ou confira as dependências:

```yaml
dependencies:
  flutter:
    sdk: flutter

  firebase_core: ^3.8.0
  firebase_auth: ^5.3.3
  cloud_firestore: ^5.5.0
  flutter_svg: ^2.0.16
  pdf: ^3.11.1
  printing: ^5.13.4
  intl: ^0.19.0

dev_dependencies:
  flutter_launcher_icons: ^0.14.4
```

Configure os assets:

```yaml
flutter:
  uses-material-design: true

  assets:
    - assets/images/wyvern_logo.svg
    - assets/icons/wyvern_launcher_icon.png
```

---

## Configuração do Firebase

### 1. Instalar o Firebase CLI

Instale o Firebase CLI e faça login:

```bash
firebase login
```

### 2. Instalar o FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### 3. Configurar o Firebase no Flutter

Na raiz do projeto, execute:

```bash
flutterfire configure
```

Esse comando irá gerar o arquivo:

```txt
lib/firebase_options.dart
```

### 4. Inicialização no `main.dart`

O app deve inicializar o Firebase antes de executar a aplicação:

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

---

## Configuração do Authentication

No Firebase Console:

1. Acesse **Authentication**;
2. Vá em **Sign-in method**;
3. Ative o provedor **Email/Password**.

---

## Regras do Firestore

Use estas regras para garantir que cada usuário acesse somente os próprios dados:

```js
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    match /users/{userId} {
      allow read, write: if request.auth != null
        && request.auth.uid == userId;

      match /folders/{folderId} {
        allow read, write: if request.auth != null
          && request.auth.uid == userId;

        match /notes/{noteId} {
          allow read, write: if request.auth != null
            && request.auth.uid == userId;
        }
      }
    }
  }
}
```

---

## Configuração do ícone do app

Crie o arquivo `flutter_launcher_icons.yaml` na raiz do projeto:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icons/wyvern_launcher_icon.png"
  min_sdk_android: 21
  remove_alpha_ios: true

  web:
    generate: true
    image_path: "assets/icons/wyvern_launcher_icon.png"
    background_color: "#061A3A"
    theme_color: "#061A3A"

  windows:
    generate: true
    image_path: "assets/icons/wyvern_launcher_icon.png"
    icon_size: 48

  macos:
    generate: true
    image_path: "assets/icons/wyvern_launcher_icon.png"
```

Depois execute:

```bash
dart run flutter_launcher_icons -f flutter_launcher_icons.yaml
```

---

## Como rodar o projeto

Execute:

```bash
flutter clean
flutter pub get
flutter run
```

Caso o projeto ainda não esteja vinculado ao Firebase, execute antes:

```bash
flutterfire configure
```

---

## Fluxo principal do app

1. Usuário abre o app;
2. Splash verifica se existe sessão ativa;
3. Se não houver sessão, o usuário vai para login;
4. Se houver sessão, o usuário vai para a tela inicial;
5. Na tela inicial, o usuário cria pastas;
6. Dentro de cada pasta, cria e edita notas;
7. A nota pode ser exportada em PDF.

---

## Paleta de cores

```txt
Azul escuro:  #061A3A
Azul médio:   #0A2A5A
Azul principal: #1A73E8
Azul claro:   #53BEFF
Branco:       #FFFFFF
Texto escuro: #172033
Cinza claro:  #B8C7E0
Vermelho:     #E53935
```

---

## Próximas melhorias

- Busca de notas por título e conteúdo;
- Favoritar notas;
- Fixar notas importantes;
- Exportar uma pasta inteira em PDF;
- Editor com Markdown;
- Mecânica de checklist dentro das notas, permitindo marcar itens como concluídos;
- Opção para marcar uma nota como concluída, fazendo com que ela saia automaticamente da lista principal de notas ativas;
- Modo offline;
- Sincronização em tempo real;
- Compartilhamento de notas;
- Upload de imagens usando Firebase Storage;
- Modo claro/escuro;
- Tags para organização;
- Lixeira para recuperar notas excluídas.

---

## Objetivo do projeto

O **Wyvern Notes** foi criado como um projeto de estudo e portfólio para demonstrar conhecimentos em:

- Desenvolvimento mobile com Flutter;
- Integração com Firebase;
- Autenticação de usuários;
- Banco de dados NoSQL com Firestore;
- CRUD completo;
- Organização de arquitetura em camadas;
- Manipulação de assets SVG;
- Geração de PDF;
- Customização de ícone do app.

---

## Autor

Desenvolvido por **vinicius pascoal**.

---

## Licença

Este projeto está disponível para fins de estudo e portfólio.
