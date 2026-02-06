import { Message } from "@/lib/types";

interface Props {
  message: Message;
}

export default function MessageBubble({ message }: Props) {
  const isUser = message.role === "user";

  return (
    <div
      style={{
        display: "flex",
        justifyContent: isUser ? "flex-end" : "flex-start",
        marginBottom: "12px",
      }}
    >
      <div
        style={{
          maxWidth: "70%",
          padding: "10px 16px",
          borderRadius: "16px",
          backgroundColor: isUser ? "#2563eb" : "#e5e7eb",
          color: isUser ? "#fff" : "#1f2937",
          whiteSpace: "pre-wrap",
          wordBreak: "break-word",
          lineHeight: 1.5,
        }}
      >
        {message.text}
      </div>
    </div>
  );
}
