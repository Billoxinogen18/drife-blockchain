import type { NextApiRequest, NextApiResponse } from 'next';
import { requestRide } from '../../services/sui';

type ResponseData = { message: string; digest?: string; error?: string; errorStack?: string; };

export default async function handler(req: NextApiRequest, res: NextApiResponse<ResponseData>) {
  const timestamp = `[${new Date().toISOString()}]`;
  console.log(`${timestamp} API_HIT: /api/request-ride`);
  
  if (req.method !== 'POST') {
    res.setHeader('Allow', ['POST']);
    return res.status(405).json({ message: 'Method Not Allowed' });
  }
  
  console.log(`${timestamp} API_BODY:`, JSON.stringify(req.body, null, 2));
  const { rideId, fare } = req.body;
  
  if (!rideId || fare === undefined) {
    return res.status(400).json({ message: 'Missing required fields: rideId, fare' });
  }
  
  // Validate fare
  const fareNum = Number(fare);
  if (isNaN(fareNum) || fareNum <= 0) {
    return res.status(400).json({ message: 'Fare must be a positive number' });
  }
  
  try {
    const result = await requestRide(rideId, fareNum);
    res.status(200).json({ message: 'Ride requested successfully', digest: result.digest });
  } catch (error: any) {
    res.status(500).json({ message: 'Failed to request ride', error: error.message, errorStack: error.stack });
  }
} 