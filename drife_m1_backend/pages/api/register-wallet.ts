import type { NextApiRequest, NextApiResponse } from 'next';
import { registerNewWallet } from '../../services/sui';
type ResponseData = { message: string; digest?: string; error?: string; errorStack?: string; };
export default async function handler(req: NextApiRequest, res: NextApiResponse<ResponseData>) {
  const timestamp = `[${new Date().toISOString()}]`;
  console.log(`${timestamp} API_HIT: /api/register-wallet`);
  if (req.method !== 'POST') {
    res.setHeader('Allow', ['POST']);
    return res.status(405).json({ message: 'Method Not Allowed' });
  }
  console.log(`${timestamp} API_BODY:`, JSON.stringify(req.body, null, 2));
  const { userId, suiAddress, role } = req.body;
  if (!userId || !suiAddress || !role) {
    return res.status(400).json({ message: 'Missing required fields: userId, suiAddress, role' });
  }
  try {
    const result = await registerNewWallet(userId, suiAddress, role);
    res.status(200).json({ message: 'Wallet registered successfully', digest: result.digest });
  } catch (error: any) {
    res.status(500).json({ message: 'Failed to register wallet', error: error.message, errorStack: error.stack });
  }
}
