# Chat with Gemini

Next.jsとGoogle Gemini AIを使用したシンプルなチャットアプリケーションです。

## 機能

- リアルタイムストリーミング応答
- ChatGPTスタイルのUI
- ダークモード対応
- セッション内での会話履歴保持

## セットアップ

### 1. APIキーの設定

`.env.local.example` をコピーして `.env.local` ファイルを作成し、自分のAPIキーを設定してください。

```bash
cp .env.local.example .env.local
```

`.env.local` ファイルを編集して、APIキーを設定します：

```bash
NEXT_PUBLIC_GEMINI_API_KEY=your_actual_api_key_here
```

Google AI Studioで無料のAPIキーを取得できます: https://makersuite.google.com/app/apikey

**注意**: `.env.local` ファイルは `.gitignore` に含まれているため、Gitリポジトリには含まれません。

### 2. 依存関係のインストール

```bash
npm install
```

### 3. 開発サーバーの起動

```bash
npm run dev
```

ブラウザで http://localhost:3000 を開いてください。

## ビルド

```bash
npm run build
npm start
```

## Google Cloud Runへのデプロイ

### 前提条件

- Google Cloud CLIがインストールされていること
- Google Cloudプロジェクトが作成されていること
- Cloud Run APIが有効化されていること

### デプロイ手順

1. Google Cloudにログイン

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

2. Container Registryの有効化

```bash
gcloud services enable containerregistry.googleapis.com
gcloud services enable run.googleapis.com
```

3. Dockerイメージのビルドとプッシュ

```bash
# プロジェクトIDを設定
export PROJECT_ID=YOUR_PROJECT_ID

# イメージをビルド
docker build -t gcr.io/$PROJECT_ID/chat-app:latest .

# Container Registryにプッシュ
docker push gcr.io/$PROJECT_ID/chat-app:latest
```

4. Cloud Runにデプロイ

```bash
gcloud run deploy chat-app \
  --image gcr.io/$PROJECT_ID/chat-app:latest \
  --platform managed \
  --region asia-northeast1 \
  --allow-unauthenticated \
  --port 3000
```

デプロイが完了すると、アクセス可能なURLが表示されます。

## Cloud Build を使った自動デプロイ（オプション）

`cloudbuild.yaml` ファイルを使用して、Cloud Build経由でデプロイすることもできます。

```bash
gcloud builds submit --config cloudbuild.yaml
```

## 環境変数

### ローカル開発環境

上記のセットアップ手順（`.env.local` ファイルの作成）により、ローカル開発環境で環境変数が自動的に読み込まれます。

### 本番環境（Cloud Run）

Cloud Runにデプロイする際は、環境変数を指定してAPIキーを設定します：

```bash
gcloud run deploy chat-app \
  --image gcr.io/$PROJECT_ID/chat-app:latest \
  --platform managed \
  --region asia-northeast1 \
  --allow-unauthenticated \
  --port 3000 \
  --set-env-vars NEXT_PUBLIC_GEMINI_API_KEY=your_actual_api_key
```

または、Cloud Runのコンソールから環境変数を設定することもできます。

## 技術スタック

- **フレームワーク**: Next.js 15 (App Router)
- **言語**: TypeScript
- **スタイリング**: Tailwind CSS
- **AI**: Google Gemini API
- **デプロイ**: Google Cloud Run

## ライセンス

MIT
