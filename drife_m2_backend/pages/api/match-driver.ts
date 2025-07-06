import type { NextApiRequest, NextApiResponse } from 'next';
import { matchDriver } from '../../services/sui';

type ResponseData = { message: string; digest?: string; error?: string; errorStack?: string; };

export default async function handler(req: NextApiRequest, res: NextApiResponse<ResponseData>) {
  const timestamp = `[${new Date().toISOString()}]`;
  console.log(`${timestamp} API_HIT: /api/match-driver`);
  
  if (req.method !== 'POST') {
    res.setHeader('Allow', ['POST']);
    return res.status(405).json({ message: 'Method Not Allowed' });
  }
  
  console.log(`${timestamp} API_BODY:`, JSON.stringify(req.body, null, 2));
  const { rideId, driverAddress } = req.body;
  
  if (!rideId || !driverAddress) {
    return res.status(400).json({ message: 'Missing required fields: rideId, driverAddress' });
  }
  
  try {
    const result = await matchDriver(rideId, driverAddress);
    res.status(200).json({ message: 'Driver matched successfully', digest: result.digest });
  } catch (error: any) {
    res.status(500).json({ message: 'Failed to match driver', error: error.message, errorStack: error.stack });
  }
} 