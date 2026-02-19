# セキュリティガイドライン

## 概要
このドキュメントは、aichat-pbcc プロジェクトにおけるセキュリティのベストプラクティスをまとめたものです。
APIキーやシークレットなどのセンシティブ情報を適切に管理し、リポジトリに保存されないようにするための指針を提供します。

## センシティブ情報の扱い

### 絶対にコミットしてはいけないもの
- API キー（Google, AWS, OpenAI など）
- アクセストークン
- パスワード
- 秘密鍵（.pem, .key ファイル）
- データベース接続文字列
- OAuth シークレット
- その他の認証情報

### 環境変数の使用

**推奨される方法:**
1. `.env.example` または `.env.template` ファイルを作成し、必要な環境変数のキー名のみを記載
2. 実際の値は `.env.local` などのローカルファイルに保存（Git追跡対象外）
3. 本番環境では環境変数または Secret Manager を使用

**例:**

`.env.example`:
```bash
# Google Gemini API Key
GEMINI_API_KEY=YOUR_GEMINI_API_KEY_HERE

# Allowed Origins (comma-separated)
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
```

`.env.local` (Git追跡対象外):
```bash
GEMINI_API_KEY=AIzaSy... # 実際のAPIキー
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
```

## セキュリティツール

### 1. .gitignore
以下のファイルパターンは自動的に除外されます：
- `.env`, `.env.local`, `.env.*.local`
- `*.pem`, `*.key`, `*.crt` などの証明書・鍵ファイル
- `secrets/`, `credentials/` ディレクトリ
- その他、API Key やトークンを含む可能性のあるファイル

### 2. Pre-commit Hook
コミット前に自動的にセンシティブ情報をチェックします。

**インストール方法:**
```bash
# setup.sh を実行すると自動的にインストールされます
./setup.sh

# または手動でインストール
cp hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

**検出されるパターン:**
- Google API Key: `AIzaSy[A-Za-z0-9_-]{33}`
- AWS Access Key ID: `AKIA[0-9A-Z]{16}`
- GitHub Personal Access Token: `ghp_[A-Za-z0-9]{36}`
- OpenAI API Key: `sk-[A-Za-z0-9]{48}`
- Private Key: `-----BEGIN [TYPE] PRIVATE KEY-----` (正規表現パターン)
- その他の API Key、パスワード、シークレット

**フックをバイパスする場合（緊急時のみ）:**
```bash
git commit --no-verify
```

### 3. Gitleaks
リポジトリ全体をスキャンしてセンシティブ情報を検出します。

**ローカルでの実行:**
```bash
# Gitleaks のインストール（Homebrew）
brew install gitleaks

# リポジトリ全体をスキャン
gitleaks detect -v

# 特定のファイルをスキャン
gitleaks detect -v --source=/path/to/file
```

**CI/CD での自動実行:**
- GitHub Actions で PR ごとに自動実行されます
- `.gitleaks.toml` で検出ルールをカスタマイズ可能

## セキュリティインシデント発生時の対応

### API Key が漏洩した場合

1. **即座に実施すべきこと:**
   - 漏洩した API Key を無効化
   - 新しい API Key を生成
   - `.env.local` などのローカルファイルに新しい API Key を設定

2. **Git 履歴から削除（必要な場合）:**
   ```bash
   # BFG Repo-Cleaner を使用（推奨）
   # https://rtyley.github.io/bfg-repo-cleaner/

   # または git filter-branch を使用（高度）
   # 注意: これはリポジトリの履歴を書き換えます
   ```

3. **報告:**
   - プロジェクトオーナーに報告
   - 影響範囲を確認
   - 必要に応じてチームメンバーに通知

## ベストプラクティス

### 1. 開発環境のセットアップ
- 最初に `.env.example` をコピーして `.env.local` を作成
- 実際の API Key を `.env.local` に設定
- `.env.local` は絶対にコミットしない

### 2. ドキュメント作成時
- サンプルコードには実際の API Key を記載しない
- `your_api_key_here` などのプレースホルダーを使用
- 環境変数の設定方法を明記

### 3. コードレビュー時
- API Key やシークレットが含まれていないか確認
- `.env.example` が最新の状態か確認
- セキュリティツールの警告を無視しない

### 4. 定期的な確認
- 月に1回、使用していない API Key を無効化
- アクセス権限の見直し
- セキュリティツールのアップデート

## 参考リンク
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [GitHub Secret Scanning](https://docs.github.com/en/code-security/secret-scanning/about-secret-scanning)
- [Gitleaks Documentation](https://github.com/gitleaks/gitleaks)
- [Git Hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)

## 問い合わせ
セキュリティに関する質問や報告は、プロジェクトオーナーまでご連絡ください。
