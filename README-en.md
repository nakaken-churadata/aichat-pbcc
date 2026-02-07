# 🤖 Tmux Multi-Agent Communication Demo

A demo system for agent-to-agent communication in a tmux environment.

**📖 Read this in other languages:** [日本語](README.md)

## 🎯 Demo Overview

Experience a hierarchical command system: Ojii-san (Grandpa) → Momotaro → Otomo (Companions)

### 👥 Agent Configuration

```
📊 おじいさん Session (1 pane)
└── おじいさん (Grandpa): Project Manager

📊 nakama Session (4 panes)
├── 桃太郎 (Momotaro): Team Leader
├── お供の犬 (Dog): Otomo A
├── お供の猿 (Monkey): Otomo B
└── お供の雉 (Pheasant): Otomo C
```

## 🚀 Quick Start

### 0. Clone Repository

```bash
git clone https://github.com/nishimoto265/Claude-Code-Communication.git
cd Claude-Code-Communication
```

### 1. Setup tmux Environment

⚠️ **Warning**: Existing `仲間` and `おじいさん` sessions will be automatically removed.

```bash
./setup.sh
```

### 2. Attach Sessions

```bash
# Check nakama session
tmux attach-session -t 仲間

# Check おじいさん session (in another terminal)
tmux attach-session -t おじいさん
```

### 3. Launch Claude Code

**Step 1: おじいさん Authentication**
```bash
# First, authenticate in おじいさん session
tmux send-keys -t おじいさん 'claude' C-m
```
Follow the authentication prompt to grant permission.

**Step 2: Launch All Nakama Sessions**
```bash
# After authentication, launch all nakama sessions at once
for i in {0..3}; do tmux send-keys -t 仲間:0.$i 'claude' C-m; done
```

### 4. Run Demo

Type directly in おじいさん session:
```
あなたはおじいさんです。指示書に従って
```

## 📜 About Instructions

Role-specific instruction files for each agent:
- **おじいさん (Grandpa)**: `instructions/ojiisan.md`
- **桃太郎 (Momotaro)**: `instructions/momotarou.md`
- **お供の犬,猿,雉 (Companions)**: `instructions/otomo.md`

**Claude Code Reference**: Check system structure in `CLAUDE.md`

**Key Points:**
- **おじいさん**: "あなたはおじいさんです。指示書に従って" → Send command to 桃太郎
- **桃太郎**: Receive おじいさん command → Send instructions to all お供 → Report completion
- **お供たち**: Execute Hello World → Create completion files → Last companion reports

## 🎬 Expected Operation Flow

```
1. おじいさん → 桃太郎: "あなたは桃太郎です。Hello World プロジェクト開始指示"
2. 桃太郎 → お供たち: "あなたはお供の[犬/猿/雉]です。Hello World 作業開始"
3. お供たち → Create ./tmp/ files → Last お供 → 桃太郎: "全員作業完了しました"
4. 桃太郎 → おじいさん: "全員完了しました"
```

## 🔧 Manual Operations

### Using agent-send.sh

```bash
# Basic sending
./agent-send.sh [agent_name] [message]

# Examples
./agent-send.sh 桃太郎 "Urgent task"
./agent-send.sh お供の犬 "Task completed"
./agent-send.sh おじいさん "Final report"

# Check agent list
./agent-send.sh --list
```

## 🧪 Verification & Debug

### Log Checking

```bash
# Check send logs
cat logs/send_log.txt

# Check specific agent logs
grep "桃太郎" logs/send_log.txt

# Check completion files
ls -la ./tmp/お供の*_done.txt
```

### Session Status Check

```bash
# List sessions
tmux list-sessions

# List panes
tmux list-panes -t 仲間
tmux list-panes -t おじいさん
```

## 🔄 Environment Reset

```bash
# Delete sessions
tmux kill-session -t 仲間
tmux kill-session -t おじいさん

# Delete completion files
rm -f ./tmp/お供の*_done.txt

# Rebuild (with auto cleanup)
./setup.sh
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

## 🤝 Contributing

Contributions via pull requests and issues are welcome!

---

🚀 **Experience Agent Communication!** 🤖✨
