import type { NextApiRequest, NextApiResponse } from 'next';
import { registerWalletsInBatch, UserBatchData } from '../../services/sui';
type ResponseData = { message: string; digest?: string; error?: string; errorStack?: string; };
export default async function handler(req: NextApiRequest, res: NextApiResponse<ResponseData>) {
  const timestamp = `[${new Date().toISOString()}]`;
  console.log(`${timestamp} API_HIT: /api/batch-register-wallets`);
  if (req.method !== 'POST') {
    res.setHeader('Allow', ['POST']);
    return res.status(405).json({ message: 'Method Not Allowed' });
  }
  console.log(`${timestamp} API_BODY:`, JSON.stringify(req.body, null, 2));
  const { users } = req.body;
  if (!Array.isArray(users) || users.length === 0) {
    return res.status(400).json({ message: 'Request body must contain a non-empty array of users.' });
  }
  try {
    const result = await registerWalletsInBatch(users as UserBatchData[]);
    res.status(200).json({ message: 'Wallets registered successfully in batch', digest: result.digest });
  } catch (error: any) {
    res.status(500).json({ message: 'Failed to register wallets in batch', error: error.message, errorStack: error.stack });
  }
}
