import type { NextApiRequest, NextApiResponse } from 'next';
import { revokeRole, Role } from '../../services/sui';

type ResponseData = { message: string; digest?: string; error?: string; errorStack?: string; };

export default async function handler(req: NextApiRequest, res: NextApiResponse<ResponseData>) {
  const timestamp = `[${new Date().toISOString()}]`;
  console.log(`${timestamp} API_HIT: /api/revoke-role`);
  
  if (req.method !== 'POST') {
    res.setHeader('Allow', ['POST']);
    return res.status(405).json({ message: 'Method Not Allowed' });
  }
  
  console.log(`${timestamp} API_BODY:`, JSON.stringify(req.body, null, 2));
  const { userAddress, role } = req.body;
  
  if (!userAddress || !role) {
    return res.status(400).json({ message: 'Missing required fields: userAddress, role' });
  }
  
  // Validate role input
  if (!Object.values(Role).includes(role as Role)) {
    return res.status(400).json({ message: `Invalid role: ${role}. Must be one of: ${Object.values(Role).join(', ')}` });
  }
  
  try {
    const result = await revokeRole(userAddress, role as Role);
    res.status(200).json({ message: `Role ${role} revoked successfully from ${userAddress}`, digest: result.digest });
  } catch (error: any) {
    res.status(500).json({ message: 'Failed to revoke role', error: error.message, errorStack: error.stack });
  }
} 