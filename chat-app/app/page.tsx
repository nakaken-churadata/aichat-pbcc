'use client';

import { useState, useRef, useEffect } from 'react';
import { GoogleGenerativeAI } from '@google/generative-ai';

// GEMINI APIキーを環境変数から読み込む
const GEMINI_API_KEY = process.env.NEXT_PUBLIC_GEMINI_API_KEY || '';

type Message = {
  role: 'user' | 'assistant';
  content: string;
};

export default function Home() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const sendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim() || isLoading) return;

    const userMessage: Message = { role: 'user', content: input };
    setMessages((prev) => [...prev, userMessage]);
    setInput('');
    setIsLoading(true);

    try {
      const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
      const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

      // 会話履歴を作成
      const chatHistory = messages.map((msg) => ({
        role: msg.role === 'user' ? 'user' : 'model',
        parts: [{ text: msg.content }],
      }));

      const chat = model.startChat({
        history: chatHistory,
      });

      const result = await chat.sendMessageStream(input);

      // ストリーミング応答を処理
      let assistantMessage = '';
      setMessages((prev) => [...prev, { role: 'assistant', content: '' }]);

      for await (const chunk of result.stream) {
        const chunkText = chunk.text();
        assistantMessage += chunkText;
        setMessages((prev) => {
          const newMessages = [...prev];
          newMessages[newMessages.length - 1] = {
            role: 'assistant',
            content: assistantMessage,
          };
          return newMessages;
        });
      }
    } catch (error) {
      console.error('Error:', error);
      setMessages((prev) => [
        ...prev,
        {
          role: 'assistant',
          content: 'エラーが発生しました。APIキーが正しく設定されているか確認してください。',
        },
      ]);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex flex-col h-screen bg-gray-50 dark:bg-gray-900">
      {/* ヘッダー */}
      <header className="bg-white dark:bg-gray-800 shadow-sm p-4 border-b border-gray-200 dark:border-gray-700">
        <h1 className="text-2xl font-bold text-gray-800 dark:text-gray-100">
          Chat with Gemini
        </h1>
      </header>

      {/* メッセージ表示エリア */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.length === 0 && (
          <div className="text-center text-gray-500 dark:text-gray-400 mt-8">
            <p className="text-lg">Gemini AIとの会話を始めましょう</p>
            <p className="text-sm mt-2">
              メッセージを入力して送信してください
            </p>
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
              className={`max-w-[80%] rounded-lg p-4 ${
                message.role === 'user'
                  ? 'bg-blue-500 text-white'
                  : 'bg-white dark:bg-gray-800 text-gray-800 dark:text-gray-100 shadow-md'
              }`}
            >
              <div className="whitespace-pre-wrap break-words">
                {message.content}
              </div>
            </div>
          </div>
        ))}

        {isLoading && (
          <div className="flex justify-start">
            <div className="bg-white dark:bg-gray-800 rounded-lg p-4 shadow-md">
              <div className="flex space-x-2">
                <div className="w-2 h-2 bg-gray-500 rounded-full animate-bounce"></div>
                <div className="w-2 h-2 bg-gray-500 rounded-full animate-bounce delay-100"></div>
                <div className="w-2 h-2 bg-gray-500 rounded-full animate-bounce delay-200"></div>
              </div>
            </div>
          </div>
        )}

        <div ref={messagesEndRef} />
      </div>

      {/* 入力フォーム */}
      <div className="bg-white dark:bg-gray-800 border-t border-gray-200 dark:border-gray-700 p-4">
        <form onSubmit={sendMessage} className="flex gap-2">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            placeholder="メッセージを入力..."
            disabled={isLoading}
            className="flex-1 rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100 dark:disabled:bg-gray-700 disabled:cursor-not-allowed bg-white dark:bg-gray-700 text-gray-800 dark:text-gray-100"
          />
          <button
            type="submit"
            disabled={isLoading || !input.trim()}
            className="bg-blue-500 hover:bg-blue-600 text-white font-medium px-6 py-2 rounded-lg transition-colors disabled:bg-gray-300 dark:disabled:bg-gray-600 disabled:cursor-not-allowed"
          >
            送信
          </button>
        </form>
      </div>
    </div>
  );
}
