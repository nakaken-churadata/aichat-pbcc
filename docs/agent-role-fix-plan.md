# エージェント役割認識問題の分析と対応策

## 問題の症状
- 全てのエージェントが自分自身を「お供の雉」と認識している
- 例: 「お供の猿」のペインでも `agent-init.sh` を実行すると「お供の雉」と表示される

## 現状の確認結果

### 正しく設定されているもの
1. **プロンプト表示**: `set_color_prompt` によるプロンプトは正しい（例: `(お供の猿)`）
2. **現在の @agent_role**: tmux ペインオプションは正しく設定されている
   - %0: 桃太郎
   - %1: お供の犬
   - %2: お供の猿
   - %3: お供の雉

### 問題が発生している箇所
- `agent-init.sh` 実行時に間違った AGENT_ROLE が設定される
- プロンプトは「お供の猿」なのに、AGENT_ROLE は「お供の雉」になる

## 根本原因の仮説

### 仮説1: setup.sh のペイン作成順序とマッピングの不一致
**問題点**:
- ペインは作成順に %0, %1, %2, %3 の ID が割り当てられる
- しかし、物理的な配置とペイン ID の対応が想定と異なる可能性

**検証が必要**:
```bash
# ペイン作成順序:
# 1. セッション作成 → %0 (全体)
# 2. 水平分割 → %1 (右側)、%0 は左側に
# 3. 左側を垂直分割 → %2 (左下)、%0 は左上に
# 4. 右側を垂直分割 → %3 (右下)、%1 は右上に

# 期待される配置:
# %0 (左上) → 桃太郎
# %1 (右上) → お供の犬
# %2 (左下) → お供の猿
# %3 (右下) → お供の雉
```

**問題**:
- `PANE_IDS=($(tmux list-panes -t "agents:agents" -F "#{pane_id}" | sort))`
- このソートは **ペイン ID の文字列ソート** であり、**物理的な配置順** ではない
- 結果は %0, %1, %2, %3 となるが、これが左上→右上→左下→右下の順序を保証しない

### 仮説2: agent-init.sh のペイン ID 取得の問題
**問題点**:
- `agent-init.sh` で `tmux display-message -p '#{pane_id}'` を実行
- しかし、Claude Code の Bash ツールから実行される場合、どのペインで実行されているかが不明確

**検証が必要**:
- `tmux display-message` が正しい current pane を認識しているか
- `source ./agent-init.sh` を直接シェルから実行した場合の動作

### 仮説3: setup.sh のループ変数の問題
**問題点**:
- setup.sh のループで全ペインに設定する際、変数のスコープやタイミングの問題で最後の値が全ペインに設定される可能性

## 対応策の計画

### Phase 1: 詳細なデバッグ情報の追加

#### 1.1 setup.sh にデバッグ出力を追加
```bash
# ペイン作成後、実際の配置を確認
echo "=== ペイン作成結果 ==="
tmux list-panes -t "agents:agents" -F "#{pane_id}: top=#{pane_top} left=#{pane_left}"

# PANE_IDS 取得結果を確認
echo "=== PANE_IDS 取得結果 ==="
echo "PANE_IDS: ${PANE_IDS[@]}"

# ループ内で各設定を確認
for i in {0..3}; do
    PANE_ID="${PANE_IDS[$i]}"
    TITLE="${PANE_TITLES[$i]}"
    echo "ループ $i: PANE_ID=$PANE_ID, TITLE=$TITLE"

    # 設定後、即座に確認
    tmux set-option -p -t "$PANE_ID" @agent_role "${TITLE}"
    VERIFY=$(tmux show-option -pv -t "$PANE_ID" @agent_role 2>/dev/null)
    echo "  設定確認: $VERIFY"
done
```

#### 1.2 agent-init.sh にデバッグ出力を追加
```bash
if [ -n "$TMUX" ]; then
    PANE_ID=$(tmux display-message -p '#{pane_id}')
    echo "🔍 デバッグ: 現在のペインID = $PANE_ID"

    AGENT_ROLE_FROM_TMUX=$(tmux show-option -pv -t "$PANE_ID" @agent_role 2>/dev/null)
    echo "🔍 デバッグ: @agent_role = $AGENT_ROLE_FROM_TMUX"

    if [ -n "$AGENT_ROLE_FROM_TMUX" ]; then
        export AGENT_ROLE="$AGENT_ROLE_FROM_TMUX"
        echo "✅ AGENT_ROLE を設定しました: $AGENT_ROLE"
    else
        echo "⚠️  @agent_role が見つかりません"
    fi
else
    echo "⚠️  tmux 環境外で実行されています"
fi
```

### Phase 2: setup.sh のペイン ID 取得方法を修正

#### 2.1 物理的な位置に基づくソート
```bash
# 修正前（ペインIDの文字列ソート）
PANE_IDS=($(tmux list-panes -t "agents:agents" -F "#{pane_id}" | sort))

# 修正後（物理的な位置でソート: top, left順）
PANE_IDS=($(tmux list-panes -t "agents:agents" -F "#{pane_top} #{pane_left} #{pane_id}" | sort -n -k1,1 -k2,2 | awk '{print $3}'))
```

**理由**:
- ペイン ID は作成順に割り当てられるが、物理的な配置とは必ずしも一致しない
- 明示的に top, left でソートすることで、左上→右上→左下→右下の順序を保証

### Phase 3: 代替案 - 明示的なペイン特定

#### 3.1 位置ベースの直接指定
```bash
# 左上ペイン (top=最小, left=最小)
PANE_TOP_LEFT=$(tmux list-panes -t "agents:agents" -F "#{pane_top} #{pane_left} #{pane_id}" | sort -n -k1,1 -k2,2 | head -1 | awk '{print $3}')

# 右上ペイン (top=最小, left=最大)
PANE_TOP_RIGHT=$(tmux list-panes -t "agents:agents" -F "#{pane_top} #{pane_left} #{pane_id}" | awk '$1==0' | sort -n -k2,2 | tail -1 | awk '{print $3}')

# 左下ペイン (top=最大, left=最小)
PANE_BOTTOM_LEFT=$(tmux list-panes -t "agents:agents" -F "#{pane_top} #{pane_left} #{pane_id}" | awk '$2==0' | sort -n -k1,1 | tail -1 | awk '{print $3}')

# 右下ペイン (top=最大, left=最大)
PANE_BOTTOM_RIGHT=$(tmux list-panes -t "agents:agents" -F "#{pane_top} #{pane_left} #{pane_id}" | sort -n -k1,1 -k2,2 | tail -1 | awk '{print $3}')

# 配列に格納
PANE_IDS=("$PANE_TOP_LEFT" "$PANE_TOP_RIGHT" "$PANE_BOTTOM_LEFT" "$PANE_BOTTOM_RIGHT")
```

**理由**:
- より明示的で、物理的な位置との対応が明確
- 2x2 グリッドの配置を保証

### Phase 4: agent-init.sh の改善

#### 4.1 -t オプションを削除
```bash
# 修正前
AGENT_ROLE_FROM_TMUX=$(tmux show-option -pv -t "$PANE_ID" @agent_role 2>/dev/null)

# 修正後（-t オプションを使わず、現在のペインから直接取得）
AGENT_ROLE_FROM_TMUX=$(tmux show-option -pv @agent_role 2>/dev/null)
```

**理由**:
- `tmux show-option -pv` はデフォルトで現在のペインの情報を取得
- `-t` オプションを使うと、ペイン ID の取得が正しくない場合に問題が発生

### Phase 5: 検証手順

#### 5.1 setup.sh を再実行
```bash
./setup.sh
```

#### 5.2 各ペインで AGENT_ROLE を確認
```bash
# 各ペインにアタッチして確認
tmux attach-session -t agents

# 各ペインで実行
echo "現在の役割: $AGENT_ROLE"
source ./agent-init.sh
echo "agent-init.sh 実行後: $AGENT_ROLE"
```

#### 5.3 agent-send.sh の動作確認
```bash
# おじいさんから桃太郎にメッセージ送信
./agent-send.sh 桃太郎 "テストメッセージじゃ"

# 送信元が正しく表示されるか確認
```

## 推奨する実装順序

1. **Phase 1 (デバッグ)**: まずデバッグ情報を追加して、現在の状態を正確に把握
2. **Phase 2 (物理的位置ソート)**: ペイン ID 取得方法を修正
3. **Phase 5 (検証)**: setup.sh を再実行して、問題が解決したか確認
4. **Phase 4 (agent-init.sh改善)**: 必要であれば agent-init.sh も改善
5. **Phase 3 (代替案)**: Phase 2 で解決しない場合のみ、Phase 3 の代替案を実装

## 懸念事項

1. **tmux のバージョン依存**: tmux のバージョンによってペイン ID の割り当て順序が異なる可能性
2. **既存セッションの影響**: 既存のセッションが残っている場合、setup.sh が正しく動作しない
3. **環境変数の継承**: `export AGENT_ROLE` がシェルの再起動後も保持されるか

## 次のステップ

ユーザーの承認を得て、Phase 1 から順番に実装を進める。
