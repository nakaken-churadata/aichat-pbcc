# アーキテクチャ

## 概要

このプロジェクトは、AIマルチエージェント開発システムと、それが開発対象とするチャットアプリケーションの2層構造で構成されています。

## チャットアプリケーションのアーキテクチャ

### 階層構造

```
[ブラウザ]
    │ HTTP/HTTPS
    ▼
[フロントエンド (chat-frontend)]
    │ HTTP POST (NEXT_PUBLIC_API_URL)
    ▼
[バックエンド (chat-backend)]
    ├──► [生成AI (Gemini API)]
    └──► [データベース] ※将来的な拡張
```

### 各階層の説明

#### フロントエンド (`chat-frontend/`)
- **役割**: ユーザーインターフェースの提供
- **技術**: Next.js (SSR), React, Tailwind CSS
- **連携**: バックエンドの `/api/chat` エンドポイントにHTTP POSTでリクエスト
- **環境変数**: `NEXT_PUBLIC_API_URL`（バックエンドURL）

#### バックエンド (`chat-backend/`)
- **役割**: APIリクエストの処理・生成AIとの連携
- **技術**: Next.js API Routes, TypeScript
- **エンドポイント**:
  - `POST /api/chat` - チャットメッセージの処理
  - `GET /api/health` - ヘルスチェック
- **連携**: Gemini API (Google Generative AI SDK)
- **セキュリティ**: CORS middleware（`ALLOWED_ORIGINS` 環境変数で制御）

#### 生成AI (Gemini API)
- **役割**: チャットメッセージへの応答生成
- **技術**: Google Gemini API
- **認証**: `GEMINI_API_KEY`（バックエンドのみが保持）

### ディレクトリ構成

```
aichat-pbcc/
├── chat-frontend/          # フロントエンド（Next.js SSR）
│   ├── app/               # Next.js App Router
│   ├── lib/               # API クライアント
│   ├── Dockerfile
│   └── package.json
│
├── chat-backend/          # バックエンド（Next.js API Routes）
│   ├── app/api/          # API エンドポイント
│   │   ├── chat/        # チャットAPI
│   │   └── health/      # ヘルスチェック
│   ├── middleware.ts     # CORS設定
│   ├── Dockerfile
│   └── package.json
│
├── terraform/             # Cloud Run デプロイ用
└── docker-compose.yml     # ローカル開発環境
```

### 設計上の特徴

- **フロントエンド・バックエンド分離**: 独立したスケーリング・デプロイが可能
- **セキュリティ**: APIキーはバックエンドのみが保持し、フロントエンドには露出しない
- **型安全性**: TypeScriptによる一貫した型チェック

## マルチエージェント開発システムのアーキテクチャ

### エージェント階層

```
[おじいさん] ← 統括責任者（別セッション）
      │
      │ agent-send.sh
      ▼
  [桃太郎] ← チームリーダー
      │
      │ agent-send.sh
      ├──► [お供の犬]  ← 実行担当A
      ├──► [お供の猿]  ← 実行担当B
      └──► [お供の雉]  ← 実行担当C
```

### 通信方式
- `agent-send.sh` スクリプトによるエージェント間メッセージ送信
- tmuxセッションを利用した並列エージェント実行
- GitHub issue/PR/worktreeを活用した開発フロー管理
