"use client";

import { useState, KeyboardEvent } from "react";

interface Props {
  onSend: (text: string) => void;
  disabled: boolean;
}

export default function MessageInput({ onSend, disabled }: Props) {
  const [text, setText] = useState("");

  const handleSend = () => {
    const trimmed = text.trim();
    if (!trimmed || disabled) return;
    onSend(trimmed);
    setText("");
  };

  const handleKeyDown = (e: KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  return (
    <div style={{ display: "flex", gap: "8px", padding: "16px" }}>
      <textarea
        value={text}
        onChange={(e) => setText(e.target.value)}
        onKeyDown={handleKeyDown}
        placeholder="メッセージを入力..."
        disabled={disabled}
        rows={1}
        style={{
          flex: 1,
          padding: "10px 14px",
          borderRadius: "12px",
          border: "1px solid #d1d5db",
          resize: "none",
          fontSize: "16px",
          fontFamily: "inherit",
          outline: "none",
        }}
      />
      <button
        onClick={handleSend}
        disabled={disabled || !text.trim()}
        style={{
          padding: "10px 20px",
          borderRadius: "12px",
          border: "none",
          backgroundColor: disabled || !text.trim() ? "#9ca3af" : "#2563eb",
          color: "#fff",
          fontSize: "16px",
          cursor: disabled || !text.trim() ? "default" : "pointer",
        }}
      >
        送信
      </button>
    </div>
  );
}
