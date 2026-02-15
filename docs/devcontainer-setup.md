# devcontainer セットアップガイド

## 概要
このプロジェクトでは、VSCode の Dev Containers 機能を使用して、安全で再現可能な開発環境を提供しています。devcontainer を使用することで、`--dangerously-skip-permissions` オプションを使用せずに Claude Code を安全に実行できます。

## 目的
- **セキュリティ**: ホストマシンを保護しながら Claude Code を安全に使用
- **再現性**: チーム全体で統一された開発環境を提供
- **隔離性**: コンテナ内で開発を行うことで、ホストマシンへの影響を最小限に抑える

## 前提条件

### 必須
- [VSCode](https://code.visualstudio.com/) がインストールされている
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) がインストールされ、起動している
- [Dev Containers 拡張機能](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) がインストールされている

### 推奨
- 8GB 以上の RAM
- 十分なディスク容量（Docker イメージとコンテナ用）

## セットアップ手順

### 1. Dev Containers 拡張機能のインストール

VSCode で以下の手順を実行：
1. 拡張機能ビュー（Cmd+Shift+X / Ctrl+Shift+X）を開く
2. "Dev Containers" を検索
3. "Dev Containers" (ms-vscode-remote.remote-containers) をインストール

### 2. コンテナでプロジェクトを開く

**方法1: コマンドパレットから**
1. VSCode でこのプロジェクトを開く
2. Cmd+Shift+P (Mac) / Ctrl+Shift+P (Windows/Linux) でコマンドパレットを開く
3. "Dev Containers: Reopen in Container" を選択

**方法2: 通知から**
1. VSCode でこのプロジェクトを開く
2. 右下に表示される通知「Reopen in Container」をクリック

### 3. コンテナのビルド

初回起動時は、Docker イメージのビルドに数分かかります。
- Node.js 20
- git、tmux、vim などの開発ツール
- GitHub CLI (gh)
- gitleaks
- Claude Code CLI

### 4. 開発環境の確認

コンテナが起動したら、ターミナルで以下を確認：

```bash
# Node.js のバージョン確認
node --version  # v20.x.x

# git の確認
git --version

# GitHub CLI の確認
gh --version

# gitleaks の確認
gitleaks version

# Claude Code の確認
claude --version
```

### 5. マルチエージェント環境のセットアップ

```bash
# setup.sh を実行（devcontainer 環境では --dangerously-skip-permissions なしで実行）
./setup.sh
```

devcontainer 環境では、setup.sh が自動的に環境を検出し、安全なモードで Claude Code を起動します。

## ファイル構成

### `.devcontainer/devcontainer.json`
コンテナの設定ファイル：
- ベースイメージの指定
- VSCode 拡張機能の自動インストール
- ポート転送の設定
- 環境変数の設定
- ボリュームマウントの設定

### `.devcontainer/Dockerfile`
Docker イメージのビルド手順：
- ベースイメージ: Node.js 20 with Debian
- 必要なツールのインストール
- devcontainer マーカーファイルの作成

## 環境変数

### `IN_DEVCONTAINER`
devcontainer 環境であることを示すフラグ（`true` / `false`）

### `AGENT_ROLE`
エージェントの役割を指定（ホストマシンから継承）
- `おじいさん`
- `桃太郎`
- `お供の犬`
- `お供の猿`
- `お供の雉`

## ボリュームマウント

### `~/.claude`
Claude Code の設定とキャッシュを保持するため、ホストマシンの `~/.claude` ディレクトリをコンテナ内にマウントします。

**重要**: これにより、ホストマシンとコンテナで Claude Code の認証情報を共有できます。

## ポート転送

以下のポートが自動的に転送されます：
- `3000`: フロントエンド開発サーバー
- `8080`: バックエンド開発サーバー（代替）
- `8081`: バックエンド API サーバー

## トラブルシューティング

### コンテナのビルドが失敗する

**原因**: Docker が起動していない、またはリソース不足

**解決策**:
1. Docker Desktop が起動していることを確認
2. Docker Desktop の設定でメモリを増やす（推奨: 4GB 以上）
3. VSCode でコマンドパレットを開き、"Dev Containers: Rebuild Container" を実行

### Claude Code が認証を要求する

**原因**: `~/.claude` ディレクトリがマウントされていない、または認証情報がない

**解決策**:
1. ホストマシンで Claude Code の認証を完了させる
2. コンテナを再起動: "Dev Containers: Rebuild Container"
3. コンテナ内で `ls -la ~/.claude` を実行し、設定ファイルが存在することを確認

### tmux セッションが起動しない

**原因**: tmux がインストールされていない、または設定エラー

**解決策**:
1. `tmux --version` でインストールを確認
2. `./setup.sh` を再実行
3. エラーメッセージを確認して対処

### ファイルの変更が反映されない

**原因**: ボリュームマウントの問題

**解決策**:
1. ファイルを保存したことを確認
2. VSCode でファイルを再読み込み
3. コンテナを再起動

## カスタマイズ

### 拡張機能の追加

`.devcontainer/devcontainer.json` の `customizations.vscode.extensions` に追加：

```json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "your.extension.id"
      ]
    }
  }
}
```

### 追加パッケージのインストール

`.devcontainer/Dockerfile` に追加：

```dockerfile
RUN apt-get update && apt-get install -y \
    your-package \
    && rm -rf /var/lib/apt/lists/*
```

### ポート転送の追加

`.devcontainer/devcontainer.json` の `forwardPorts` に追加：

```json
{
  "forwardPorts": [3000, 8080, 8081, 9000]
}
```

## 通常の開発環境に戻る

devcontainer を使用せず、ホストマシンで直接開発する場合：

1. VSCode でコマンドパレットを開く
2. "Dev Containers: Reopen Folder Locally" を選択

これにより、コンテナを終了し、ホストマシンでプロジェクトを開きます。

## ベストプラクティス

### 1. コンテナの定期的な再ビルド
依存関係が更新された場合は、コンテナを再ビルド：
```
Dev Containers: Rebuild Container
```

### 2. 不要なイメージの削除
ディスク容量を節約するため、不要な Docker イメージを定期的に削除：
```bash
docker system prune -a
```

### 3. ホストマシンとの同期
重要なファイル（`.env.local` など）は、コンテナ内で直接編集せず、ホストマシンで管理し、ボリュームマウントで共有する。

## 参考リンク
- [VSCode Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers)
- [devcontainer.json reference](https://containers.dev/implementors/json_reference/)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Claude Code Documentation](https://github.com/anthropics/claude-code)

## サポート
問題が発生した場合は、GitHub Issues で報告してください。
