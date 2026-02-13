import { GoogleGenAI } from '@google/genai';
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
    const ai = new GoogleGenAI({ apiKey });

    // メッセージを送信（Google Search grounding を使用）
    const result = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: message,
      config: {
        tools: [{ googleSearch: {} }],
      },
    });

    const text = result.text;

    // グラウンディングメタデータ（検索結果のURL等）を取得
    const groundingMetadata = result.candidates?.[0]?.groundingMetadata;
    const searchEntryPoint = groundingMetadata?.searchEntryPoint;
    const groundingChunks = groundingMetadata?.groundingChunks;

    // レスポンスに引用元URLを含める
    const citations: string[] = [];
    if (groundingChunks) {
      for (const chunk of groundingChunks) {
        if (chunk.web?.uri) {
          citations.push(chunk.web.uri);
        }
      }
    }

    return NextResponse.json({
      response: text,
      citations: citations.length > 0 ? citations : undefined,
      searchEntryPoint: searchEntryPoint?.renderedContent,
    });
  } catch (error) {
    console.error('GEMINI API エラー:', error);
    return NextResponse.json(
      { error: 'チャット処理中にエラーが発生しました' },
      { status: 500 }
    );
  }
}

export async function OPTIONS() {
  return new NextResponse(null, {
    status: 204,
    headers: {
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    },
  });
}
