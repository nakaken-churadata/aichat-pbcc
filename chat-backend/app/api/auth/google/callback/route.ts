import { NextRequest, NextResponse } from 'next/server';
import { OAuth2Client } from 'google-auth-library';
import { generateToken } from '@/lib/jwt';

export async function GET(request: NextRequest) {
  const code = request.nextUrl.searchParams.get('code');
  const state = request.nextUrl.searchParams.get('state') || '/';

  if (!code) {
    return NextResponse.json(
      { error: '認証コードが取得できませんでした' },
      { status: 400 }
    );
  }

  const clientId = process.env.GOOGLE_CLIENT_ID;
  const clientSecret = process.env.GOOGLE_CLIENT_SECRET;

  if (!clientId || !clientSecret) {
    return NextResponse.json(
      { error: 'Google OAuth の設定が不完全です' },
      { status: 500 }
    );
  }

  try {
    // OAuth2Client を初期化
    const client = new OAuth2Client(
      clientId,
      clientSecret,
      `${process.env.NEXTAUTH_URL || 'http://localhost:8081'}/api/auth/google/callback`
    );

    // 認証コードをトークンに交換
    const { tokens } = await client.getToken(code);
    client.setCredentials(tokens);

    // ユーザー情報を取得
    const ticket = await client.verifyIdToken({
      idToken: tokens.id_token!,
      audience: clientId,
    });

    const payload = ticket.getPayload();
    if (!payload) {
      return NextResponse.json(
        { error: 'ユーザー情報の取得に失敗しました' },
        { status: 500 }
      );
    }

    // JWT を生成
    const jwtToken = generateToken({
      userId: payload.sub,
      email: payload.email!,
      name: payload.name,
      picture: payload.picture,
    });

    // フロントエンドのURLにリダイレクト（JWTをクッキーに保存）
    const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
    const response = NextResponse.redirect(`${frontendUrl}${state}`);

    // クッキーに JWT を保存（httpOnly で安全に）
    response.cookies.set('auth_token', jwtToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      maxAge: 60 * 60 * 24 * 7, // 7日間
      path: '/',
    });

    return response;
  } catch (error) {
    console.error('Google OAuth callback error:', error);
    return NextResponse.json(
      { error: '認証処理中にエラーが発生しました' },
      { status: 500 }
    );
  }
}
