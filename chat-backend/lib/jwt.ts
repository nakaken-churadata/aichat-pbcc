import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'default-secret-key-change-in-production';
const JWT_EXPIRES_IN = '7d'; // 7日間有効

export interface JWTPayload {
  userId: string;
  email: string;
  name?: string;
  picture?: string;
}

export function generateToken(payload: JWTPayload): string {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
}

export function verifyToken(token: string): JWTPayload | null {
  try {
    return jwt.verify(token, JWT_SECRET) as JWTPayload;
  } catch (error) {
    console.error('JWT verification failed:', error);
    return null;
  }
}
