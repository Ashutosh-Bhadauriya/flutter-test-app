#!/usr/bin/env node

/**
 * Simple test server for Authsignal Flutter SDK testing
 * This server provides the backend endpoints needed for complete testing
 */

const express = require('express');
const cors = require('cors');
const { Authsignal } = require('@authsignal/node');

const app = express();
const PORT = process.env.PORT || 3000;

// Your actual Authsignal credentials
const AUTHSIGNAL_SECRET = 'xOX1iU1j3XaReIR37YBmI1yMHbaHzKJPIiAq/4I/gsZZ1lR8e3KdzA==';
const AUTHSIGNAL_TENANT_ID = '87902a54-1902-47a6-b492-43acb0dca6d2';
const AUTHSIGNAL_BASE_URL = 'https://api.authsignal.com/v1';

const authsignal = new Authsignal({
  apiSecretKey: AUTHSIGNAL_SECRET,
  apiUrl: AUTHSIGNAL_BASE_URL,
});

app.use(cors());
app.use(express.json());

// Middleware for logging
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`, 
    req.body ? JSON.stringify(req.body, null, 2) : '');
  next();
});

/**
 * Track an action and return a token
 * Used for both registration tokens and challenge tokens
 */
app.post('/api/track', async (req, res) => {
  try {
    const { userId, action, attributes } = req.body;
    
    console.log(`Tracking action: ${action} for user: ${userId}`);
    
    const trackResponse = await authsignal.track({
      userId,
      action,
      attributes,
    });
    
    console.log('Track response:', JSON.stringify(trackResponse, null, 2));
    res.json(trackResponse);
  } catch (error) {
    console.error('Track error:', error);
    res.status(500).json({ 
      error: 'Failed to track action', 
      details: error.message 
    });
  }
});

/**
 * Validate a challenge token
 * Used to verify completed challenges
 */
app.post('/api/validate', async (req, res) => {
  try {
    const { token } = req.body;
    
    console.log('Validating token...');
    
    const validationResponse = await authsignal.validateChallenge({ token });
    
    console.log('Validation response:', JSON.stringify(validationResponse, null, 2));
    res.json(validationResponse);
  } catch (error) {
    console.error('Validation error:', error);
    res.status(500).json({ 
      error: 'Failed to validate challenge', 
      details: error.message 
    });
  }
});

/**
 * Get user details
 */
app.get('/api/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    console.log(`Getting user details for: ${userId}`);
    
    const userResponse = await authsignal.getUser({ userId });
    
    console.log('User response:', JSON.stringify(userResponse, null, 2));
    res.json(userResponse);
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ 
      error: 'Failed to get user', 
      details: error.message 
    });
  }
});

/**
 * Webhook endpoint for Authsignal events
 * This would typically handle push notifications
 */
app.post('/webhook/authsignal', (req, res) => {
  console.log('Webhook received:', JSON.stringify(req.body, null, 2));
  
  const { type, data } = req.body;
  
  switch (type) {
    case 'deviceChallenge':
      console.log(`Device challenge created for user ${data.userId}: ${data.challengeId}`);
      // In a real app, you would send a push notification here
      break;
    case 'pushChallenge':
      console.log(`Push challenge created for user ${data.userId}: ${data.challengeId}`);
      // In a real app, you would send a push notification here
      break;
    default:
      console.log(`Unknown webhook type: ${type}`);
  }
  
  res.status(200).send('OK');
});

/**
 * Test endpoints for manual testing
 */

// Create a registration token for device credentials
app.post('/test/registration-token', async (req, res) => {
  try {
    const userId = req.body.userId || `test_user_${Date.now()}`;
    
    const trackResponse = await authsignal.track({
      userId,
      action: 'addAuthenticator',
    });
    
    res.json({
      userId,
      token: trackResponse.token,
      state: trackResponse.state,
      message: 'Use this token for device registration'
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create a challenge token for authentication
app.post('/test/challenge-token', async (req, res) => {
  try {
    const { userId, phoneNumber } = req.body;
    
    console.log(`Creating challenge for user: ${userId}`);
    
    // First check if user has device credentials
    const userResponse = await authsignal.getUser({ userId });
    console.log('Full user response:', JSON.stringify(userResponse, null, 2));
    console.log('User authenticators:', userResponse.userAuthenticators);
    
    const trackResponse = await authsignal.track({
      userId,
      action: 'signIn',
      attributes: {
        phoneNumber,
      },
    });
    
    console.log('Track response:', JSON.stringify(trackResponse, null, 2));
    
    // If challenge is required and user has device authenticators, create device challenge
    if (trackResponse.state === 'CHALLENGE_REQUIRED' && userResponse.userAuthenticators?.some(auth => auth.userAuthenticatorType === 'DEVICE')) {
      console.log('Creating device challenge...');
      
      try {
        // Get the device authenticator
        const deviceAuth = userResponse.userAuthenticators.find(auth => auth.userAuthenticatorType === 'DEVICE');
        
        if (deviceAuth) {
          // Create a device challenge using the device's credential ID
          const deviceChallengeResponse = await authsignal.createChallenge({
            userId,
            userAuthenticatorId: deviceAuth.userAuthenticatorId,
            action: 'signIn'
          });
          
          console.log('Device challenge created:', JSON.stringify(deviceChallengeResponse, null, 2));
          
          res.json({
            userId,
            token: trackResponse.token,
            state: trackResponse.state,
            challengeId: deviceChallengeResponse.challengeId,
            deviceChallenge: deviceChallengeResponse,
            message: 'Device challenge created successfully'
          });
          return;
        }
      } catch (deviceError) {
        console.error('Device challenge creation failed:', deviceError);
        // Fall back to regular token
      }
    }
    
    res.json({
      userId,
      token: trackResponse.token,
      state: trackResponse.state,
      challengeId: trackResponse.challengeId,
      message: 'Use this token for challenge authentication'
    });
  } catch (error) {
    console.error('Challenge creation error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    tenant: AUTHSIGNAL_TENANT_ID 
  });
});

// Root endpoint with usage instructions
app.get('/', (req, res) => {
  res.json({
    message: 'Authsignal Flutter Test Server',
    endpoints: {
      'POST /api/track': 'Track an action and get token',
      'POST /api/validate': 'Validate a challenge token',
      'GET /api/user/:userId': 'Get user details',
      'POST /webhook/authsignal': 'Webhook for Authsignal events',
      'POST /test/registration-token': 'Get registration token for testing',
      'POST /test/challenge-token': 'Get challenge token for testing',
      'GET /health': 'Health check'
    },
    examples: {
      registrationToken: {
        url: 'POST /test/registration-token',
        body: { userId: 'test_user_123' }
      },
      challengeToken: {
        url: 'POST /test/challenge-token', 
        body: { userId: 'test_user_123', phoneNumber: '+1234567890' }
      }
    }
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Authsignal test server running on http://localhost:${PORT}`);
  console.log(`📱 Tenant ID: ${AUTHSIGNAL_TENANT_ID}`);
  console.log(`🔗 Base URL: ${AUTHSIGNAL_BASE_URL}`);
  console.log('\n📋 Quick test URLs:');
  console.log(`   Health: http://localhost:${PORT}/health`);
  console.log(`   Registration token: curl -X POST http://localhost:${PORT}/test/registration-token -H "Content-Type: application/json" -d '{"userId":"test_user_123"}'`);
  console.log(`   Challenge token: curl -X POST http://localhost:${PORT}/test/challenge-token -H "Content-Type: application/json" -d '{"userId":"test_user_123","phoneNumber":"+1234567890"}'`);
});
