import { GoogleGenerativeAI } from '@google/generative-ai';
import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const { message } = await request.json();

    if (!message) {
      return NextResponse.json(
        { error: 'メッセージが必要です' },
        { status: 400 }
      );
    }

    // 環境変数から API キーを取得
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      return NextResponse.json(
        { error: 'API キーが設定されていません' },
        { status: 500 }
      );
    }

    // GEMINI API クライアントを初期化
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: 'gemini-3-flash-preview' });

    // メッセージを送信
    const result = await model.generateContent(message);
    const response = result.response;
    const text = response.text();

    return NextResponse.json({ response: text });
  } catch (error) {
    console.error('GEMINI API エラー:', error);
    return NextResponse.json(
      { error: 'チャット処理中にエラーが発生しました' },
      { status: 500 }
    );
  }
}
