'use client';

import { useState, useRef, useEffect } from 'react';
import { useAuth } from '@/contexts/AuthContext';

export default function Header() {
  const { user, isAuthenticated, isLoading, login, logout } = useAuth();
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);

  // メニュー外をクリックしたら閉じる
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        setIsMenuOpen(false);
      }
    };

    if (isMenuOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }

    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [isMenuOpen]);

  const handleLogout = async () => {
    await logout();
    setIsMenuOpen(false);
  };

  return (
    <header className="border-b bg-white px-4 py-4 shadow-sm">
      <div className="mx-auto flex max-w-7xl items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-800">GEMINI チャット</h1>

        {/* 認証状態表示 */}
        <div className="relative" ref={menuRef}>
          {isLoading ? (
            <div className="flex items-center gap-2">
              <div className="h-8 w-8 animate-pulse rounded-full bg-gray-200"></div>
              <span className="text-sm text-gray-500">読み込み中...</span>
            </div>
          ) : isAuthenticated && user ? (
            // 認証済み時
            <button
              onClick={() => setIsMenuOpen(!isMenuOpen)}
              className="flex items-center gap-2 rounded-lg px-3 py-2 transition-colors hover:bg-gray-100"
            >
              {user.picture ? (
                <img
                  src={user.picture}
                  alt={user.name || 'ユーザー'}
                  className="h-8 w-8 rounded-full"
                />
              ) : (
                <div className="flex h-8 w-8 items-center justify-center rounded-full bg-blue-500 text-white">
                  <svg
                    className="h-5 w-5"
                    fill="currentColor"
                    viewBox="0 0 20 20"
                  >
                    <path
                      fillRule="evenodd"
                      d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z"
                      clipRule="evenodd"
                    />
                  </svg>
                </div>
              )}
              <span className="text-sm font-medium text-gray-700">
                {user.name || user.email}
              </span>
              <svg
                className={`h-4 w-4 text-gray-500 transition-transform ${
                  isMenuOpen ? 'rotate-180' : ''
                }`}
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M19 9l-7 7-7-7"
                />
              </svg>
            </button>
          ) : (
            // 未認証時
            <button
              onClick={() => setIsMenuOpen(!isMenuOpen)}
              className="flex items-center gap-2 rounded-lg px-3 py-2 transition-colors hover:bg-gray-100"
            >
              <div className="flex h-8 w-8 items-center justify-center rounded-full bg-gray-300 text-gray-600">
                <svg
                  className="h-5 w-5"
                  fill="currentColor"
                  viewBox="0 0 20 20"
                >
                  <path
                    fillRule="evenodd"
                    d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z"
                    clipRule="evenodd"
                  />
                </svg>
              </div>
              <span className="text-sm font-medium text-gray-700">匿名ユーザー</span>
              <svg
                className={`h-4 w-4 text-gray-500 transition-transform ${
                  isMenuOpen ? 'rotate-180' : ''
                }`}
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M19 9l-7 7-7-7"
                />
              </svg>
            </button>
          )}

          {/* ドロップダウンメニュー */}
          {isMenuOpen && (
            <div className="absolute right-0 mt-2 w-48 rounded-lg bg-white py-2 shadow-lg ring-1 ring-black ring-opacity-5">
              {isAuthenticated ? (
                <button
                  onClick={handleLogout}
                  className="block w-full px-4 py-2 text-left text-sm text-gray-700 transition-colors hover:bg-gray-100"
                >
                  ログアウト
                </button>
              ) : (
                <button
                  onClick={() => {
                    login();
                    setIsMenuOpen(false);
                  }}
                  className="flex w-full items-center gap-2 px-4 py-2 text-left text-sm text-gray-700 transition-colors hover:bg-gray-100"
                >
                  <svg className="h-5 w-5" viewBox="0 0 24 24">
                    <path
                      fill="#4285F4"
                      d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                    />
                    <path
                      fill="#34A853"
                      d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                    />
                    <path
                      fill="#FBBC05"
                      d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                    />
                    <path
                      fill="#EA4335"
                      d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                    />
                  </svg>
                  Google でログイン
                </button>
              )}
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
