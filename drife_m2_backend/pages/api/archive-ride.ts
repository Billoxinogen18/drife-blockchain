import type { NextApiRequest, NextApiResponse } from 'next';
import { archiveRide } from '../../services/sui';

type ResponseData = { message: string; digest?: string; error?: string; errorStack?: string; };

export default async function handler(req: NextApiRequest, res: NextApiResponse<ResponseData>) {
  const timestamp = `[${new Date().toISOString()}]`;
  console.log(`${timestamp} API_HIT: /api/archive-ride`);
  
  if (req.method !== 'POST') {
    res.setHeader('Allow', ['POST']);
    return res.status(405).json({ message: 'Method Not Allowed' });
  }
  
  console.log(`${timestamp} API_BODY:`, JSON.stringify(req.body, null, 2));
  const { rideId } = req.body;
  
  if (!rideId) {
    return res.status(400).json({ message: 'Missing required field: rideId' });
  }
  
  try {
    const result = await archiveRide(rideId);
    res.status(200).json({ message: 'Ride archived successfully', digest: result.digest });
  } catch (error: any) {
    res.status(500).json({ message: 'Failed to archive ride', error: error.message, errorStack: error.stack });
  }
} 