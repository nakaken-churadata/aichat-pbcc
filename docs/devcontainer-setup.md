# devcontainer セットアップガイド

## 概要
このプロジェクトでは、VSCode の Dev Containers 機能を使用して、再現可能な開発環境を提供しています。devcontainer を使用することで、**開発の利便性を重視しながら `--dangerously-skip-permissions` を使用**できます。

## 目的と効果

### なぜ devcontainer を使うのか？
Claude Code を使用する際、`--dangerously-skip-permissions` オプションを使用すると、ファイルの読み書きやコマンド実行が自由にできるため、AI エージェントの能力を最大限に活用できます。

devcontainer を使用することで：
- **開発の利便性向上**: `--dangerously-skip-permissions` を使用して効率的に開発
- **再現性**: チーム全体で統一された開発環境を提供
- **ホスト環境との分離**: ホスト環境では `--dangerously-skip-permissions` を使用せず、より慎重に操作

**⚠️ 重要な注意事項:**
- devcontainer 内でも `--dangerously-skip-permissions` を使用するため、危険な操作が可能です
- **プロジェクトディレクトリはホストとマウント共有されるため、ファイル削除などの操作はホストにも影響します**
- 完全な安全性を保証するものではありません
- 開発の利便性を優先していますが、慎重に操作してください

## 前提条件

### 必須
- [VSCode](https://code.visualstudio.com/) がインストールされている
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) がインストールされ、起動している
- [Dev Containers 拡張機能](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) がインストールされている
- **[Claude Code](https://claude.ai/download) がホストマシンにインストールされている**
  - devcontainer 内からホストの Claude Code を使用します
  - ホストマシンで Claude Code の認証を完了させてください

### 推奨
- 8GB 以上の RAM
- 十分なディスク容量（Docker イメージとコンテナ用）

## Appleシリコン対応

このプロジェクトの devcontainer は、**Intel Mac と Appleシリコン Mac の両方でネイティブ動作**するよう設計されています。

### マルチアーキテクチャサポート

- **Intel Mac (x86_64)**: ネイティブで動作
- **Appleシリコン Mac (ARM64)**: ネイティブで動作（エミュレーションなし）

### 動作確認方法

コンテナ内で以下のコマンドを実行して、アーキテクチャを確認できます：

```bash
# アーキテクチャの確認
uname -m
# Intel Mac: x86_64
# Appleシリコン Mac: aarch64 (または arm64)

# gitleaks のアーキテクチャ確認
file /usr/local/bin/gitleaks
# Intel Mac: ELF 64-bit LSB executable, x86-64
# Appleシリコン Mac: ELF 64-bit LSB executable, ARM aarch64
```

### 技術的な詳細

Dockerfile では、`dpkg --print-architecture` を使用してコンテナのアーキテクチャを自動検出し、適切なバイナリをダウンロードします。これにより：

- パフォーマンスが最適化されます（ネイティブ実行）
- エミュレーションによる速度低下を回避できます
- 両方のアーキテクチャで同じ Dockerfile を使用できます

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

**コンテナにインストールされるツール:**
- Node.js 20
- git、tmux、vim などの開発ツール
- GitHub CLI (gh)
- gitleaks
- Claude Code CLI（自動インストールを試行、失敗した場合は手動インストールが必要）

**Claude Code について:**
- 自動インストールが失敗した場合は、コンテナ内で手動インストールが必要です
- インストール方法は「Claude Code の手動インストール」セクションを参照してください

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
# 注: エラーが出た場合は、手動インストールが必要です（下記参照）
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

### Claude Code がインストールされていない

**原因**: Claude Code の自動インストールが失敗した

**解決策（手動インストール）**:

コンテナ内のターミナルで以下を実行：

```bash
# Claude Code の公式インストール方法に従ってください
# 例: npm を使用する場合
npm install -g @anthropic-ai/claude-code

# または: curl を使用する場合
curl -fsSL https://claude.ai/install.sh | bash

# インストール後、確認
claude --version
```

**注意**: Claude Code の正式なインストール方法は、公式ドキュメントを確認してください。

### Claude Code が認証を要求する

**原因**: 認証情報がない、または `~/.claude` ディレクトリがマウントされていない

**解決策**:
1. コンテナ内で Claude Code の認証を完了させる:
   ```bash
   claude login
   ```
2. または、ホストマシンで認証を完了させてからコンテナを再起動
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

### Appleシリコン Mac で動作が遅い

**原因**: エミュレーションモードで動作している可能性がある

**確認方法**:
コンテナ内で以下を実行：
```bash
uname -m
```
`x86_64` と表示される場合はエミュレーションモード、`aarch64` または `arm64` と表示される場合はネイティブモードです。

**解決策**:
1. devcontainer.json に `"platform": "linux/amd64"` のような指定がないことを確認
2. コンテナを再ビルド: `Dev Containers: Rebuild Container`
3. Docker Desktop の設定で「Use Rosetta for x86/amd64 emulation」が無効になっていることを確認

### Appleシリコン Mac で gitleaks が動作しない

**原因**: 古いバージョンの Dockerfile が使用されている可能性がある

**解決策**:
1. 最新の Dockerfile を取得：
   ```bash
   git pull origin main
   ```
2. コンテナを再ビルド: `Dev Containers: Rebuild Container`
3. コンテナ内で gitleaks が正しいアーキテクチャか確認：
   ```bash
   file /usr/local/bin/gitleaks
   # ARM aarch64 と表示されるべき
   ```

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
