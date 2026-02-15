import { NextResponse } from 'next/server';

export async function POST() {
  const response = NextResponse.json({ success: true });

  // クッキーから auth_token を削除
  response.cookies.set('auth_token', '', {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    maxAge: 0, // 即座に削除
    path: '/',
  });

  return response;
}
