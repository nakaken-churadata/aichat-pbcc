import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  const clientId = process.env.GOOGLE_CLIENT_ID;

  if (!clientId) {
    return NextResponse.json(
      { error: 'Google Client ID が設定されていません' },
      { status: 500 }
    );
  }

  // リダイレクト先URLを取得（元のページに戻るため）
  const returnTo = request.nextUrl.searchParams.get('returnTo') || '/';

  // Google OAuth 2.0 の認証URL
  const redirectUri = `${process.env.NEXTAUTH_URL || 'http://localhost:8081'}/api/auth/google/callback`;
  const scope = 'openid email profile';

  const authUrl = new URL('https://accounts.google.com/o/oauth2/v2/auth');
  authUrl.searchParams.set('client_id', clientId);
  authUrl.searchParams.set('redirect_uri', redirectUri);
  authUrl.searchParams.set('response_type', 'code');
  authUrl.searchParams.set('scope', scope);
  authUrl.searchParams.set('state', returnTo); // リダイレクト先を state に保存

  return NextResponse.redirect(authUrl.toString());
}
