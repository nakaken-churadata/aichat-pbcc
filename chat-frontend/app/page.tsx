'use client';

import { useState } from 'react';
import { sendChatMessage } from '@/lib/api-client';

interface Message {
  role: 'user' | 'assistant';
  content: string;
  citations?: string[];
}

export default function Home() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim() || isLoading) return;

    const userMessage: Message = { role: 'user', content: input };
    setMessages((prev) => [...prev, userMessage]);
    setInput('');
    setIsLoading(true);

    try {
      const data = await sendChatMessage(input);
      const assistantMessage: Message = {
        role: 'assistant',
        content: data.response,
        citations: data.citations,
      };
      setMessages((prev) => [...prev, assistantMessage]);
    } catch (error) {
      const errorMessage: Message = {
        role: 'assistant',
        content: error instanceof Error ? error.message : 'エラーが発生しました。もう一度お試しください。',
      };
      setMessages((prev) => [...prev, errorMessage]);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex flex-1 flex-col bg-gray-50">
      {/* メッセージエリア */}
      <div className="flex-1 overflow-y-auto px-4 py-6">
        <div className="mx-auto max-w-3xl space-y-4">
          {messages.length === 0 && (
            <div className="text-center text-gray-500">
              <p className="text-lg">メッセージを入力してチャットを開始してください</p>
            </div>
          )}
          {messages.map((message, index) => (
            <div
              key={index}
              className={`flex ${
                message.role === 'user' ? 'justify-end' : 'justify-start'
              }`}
            >
              <div
                className={`max-w-[80%] rounded-lg px-4 py-2 ${
                  message.role === 'user'
                    ? 'bg-blue-500 text-white'
                    : 'bg-white text-gray-800 shadow'
                }`}
              >
                <p className="whitespace-pre-wrap break-words">{message.content}</p>
                {message.citations && message.citations.length > 0 && (
                  <div className="mt-2 border-t pt-2">
                    <p className="text-xs text-gray-500 mb-1">参考サイト:</p>
                    <ul className="space-y-1">
                      {message.citations.map((citation, idx) => (
                        <li key={idx}>
                          <a
                            href={citation}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="text-xs text-blue-600 hover:underline break-all"
                          >
                            {citation}
                          </a>
                        </li>
                      ))}
                    </ul>
                  </div>
                )}
              </div>
            </div>
          ))}
          {isLoading && (
            <div className="flex justify-start">
              <div className="max-w-[80%] rounded-lg bg-white px-4 py-2 shadow">
                <p className="text-gray-500">入力中...</p>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* 入力エリア */}
      <div className="border-t bg-white px-4 py-4">
        <form onSubmit={handleSubmit} className="mx-auto max-w-3xl">
          <div className="flex gap-2">
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              placeholder="メッセージを入力..."
              className="flex-1 rounded-lg border border-gray-300 px-4 py-2 focus:border-blue-500 focus:outline-none"
              disabled={isLoading}
            />
            <button
              type="submit"
              disabled={isLoading || !input.trim()}
              className="rounded-lg bg-blue-500 px-6 py-2 text-white transition-colors hover:bg-blue-600 disabled:bg-gray-300 disabled:cursor-not-allowed"
            >
              送信
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
