import express from 'express';
import cors from 'cors';
import { appTierRouter } from '../app-tier/router.js';

const app = express();
const PORT = 3000;

// Middleware (Web Tier)
app.use(cors());
app.use(express.json());

// Static files (simulating CloudFront distribution)
app.use(express.static('public'));

// Route all API requests to App Tier
app.use('/api', appTierRouter);

// Health check endpoint (for ALB)
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

app.listen(PORT, () => {
  console.log(`Web Tier running on port ${PORT}`);
});