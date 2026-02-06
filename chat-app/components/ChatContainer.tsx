"use client";

import { useState, useRef, useEffect } from "react";
import { Message, ChatResponse } from "@/lib/types";
import MessageBubble from "./MessageBubble";
import MessageInput from "./MessageInput";

export default function ChatContainer() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [loading, setLoading] = useState(false);
  const bottomRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  const handleSend = async (text: string) => {
    const userMessage: Message = { role: "user", text };
    const updated = [...messages, userMessage];
    setMessages(updated);
    setLoading(true);

    try {
      const res = await fetch("/api/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ messages: updated }),
      });

      if (!res.ok) throw new Error("API request failed");

      const data: ChatResponse = await res.json();
      setMessages((prev) => [...prev, data.message]);
    } catch {
      setMessages((prev) => [
        ...prev,
        { role: "model", text: "エラーが発生しました。もう一度お試しください。" },
      ]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        height: "100vh",
        maxWidth: "768px",
        margin: "0 auto",
      }}
    >
      <header
        style={{
          padding: "16px",
          borderBottom: "1px solid #e5e7eb",
          textAlign: "center",
          fontWeight: "bold",
          fontSize: "18px",
        }}
      >
        Gemini Chat
      </header>
      <div
        style={{
          flex: 1,
          overflowY: "auto",
          padding: "16px",
        }}
      >
        {messages.length === 0 && (
          <p style={{ textAlign: "center", color: "#9ca3af", marginTop: "40px" }}>
            メッセージを送信して会話を始めましょう
          </p>
        )}
        {messages.map((msg, i) => (
          <MessageBubble key={i} message={msg} />
        ))}
        {loading && (
          <div style={{ color: "#9ca3af", padding: "8px 16px" }}>考え中...</div>
        )}
        <div ref={bottomRef} />
      </div>
      <div style={{ borderTop: "1px solid #e5e7eb" }}>
        <MessageInput onSend={handleSend} disabled={loading} />
      </div>
    </div>
  );
}
