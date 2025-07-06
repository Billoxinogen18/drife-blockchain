import type { NextApiRequest, NextApiResponse } from 'next';
import { pauseContract, unpauseContract } from '../../services/sui';

type ResponseData = { message: string; digest?: string; error?: string; errorStack?: string; };

export default async function handler(req: NextApiRequest, res: NextApiResponse<ResponseData>) {
  const timestamp = `[${new Date().toISOString()}]`;
  console.log(`${timestamp} API_HIT: /api/contract-control`);
  
  if (req.method !== 'POST') {
    res.setHeader('Allow', ['POST']);
    return res.status(405).json({ message: 'Method Not Allowed' });
  }
  
  console.log(`${timestamp} API_BODY:`, JSON.stringify(req.body, null, 2));
  const { action } = req.body;
  
  if (!action || (action !== 'pause' && action !== 'unpause')) {
    return res.status(400).json({ message: "Missing or invalid 'action' field. Must be 'pause' or 'unpause'" });
  }
  
  try {
    let result;
    if (action === 'pause') {
      result = await pauseContract();
      res.status(200).json({ message: 'Contract paused successfully', digest: result.digest });
    } else {
      result = await unpauseContract();
      res.status(200).json({ message: 'Contract unpaused successfully', digest: result.digest });
    }
  } catch (error: any) {
    res.status(500).json({ 
      message: `Failed to ${action} contract`, 
      error: error.message, 
      errorStack: error.stack 
    });
  }
} 