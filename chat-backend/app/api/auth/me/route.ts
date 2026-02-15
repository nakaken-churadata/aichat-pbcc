import { NextRequest, NextResponse } from 'next/server';
import { verifyToken } from '@/lib/jwt';

export async function GET(request: NextRequest) {
  // クッキーから JWT を取得
  const token = request.cookies.get('auth_token')?.value;

  if (!token) {
    return NextResponse.json(
      { authenticated: false, user: null },
      { status: 200 }
    );
  }

  // JWT を検証
  const payload = verifyToken(token);

  if (!payload) {
    return NextResponse.json(
      { authenticated: false, user: null },
      { status: 200 }
    );
  }

  return NextResponse.json({
    authenticated: true,
    user: {
      id: payload.userId,
      email: payload.email,
      name: payload.name,
      picture: payload.picture,
    },
  });
}
