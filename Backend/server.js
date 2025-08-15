// Simple Node.js backend for Nomos anonymous events
// Deploy to Vercel, Netlify, or any serverless platform

const express = require('express');
const cors = require('cors');
const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// In-memory storage (use Redis or a database in production)
let events = [];

// POST /api/event - Submit anonymous event
app.post('/api/event', (req, res) => {
    try {
        const { eventType, timezone } = req.body;
        
        // Validate input
        if (!eventType || !timezone) {
            return res.status(400).json({ error: 'Missing required fields' });
        }
        
        if (!['committed', 'upheld', 'forfeited'].includes(eventType)) {
            return res.status(400).json({ error: 'Invalid event type' });
        }
        
        // Create event (completely anonymous)
        const event = {
            eventType,
            timezone,
            timestamp: new Date().toISOString()
        };
        
        // Add to beginning of array
        events.unshift(event);
        
        // Keep only last 100 events
        if (events.length > 100) {
            events = events.slice(0, 100);
        }
        
        res.json({ success: true });
        
    } catch (error) {
        console.error('Error submitting event:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// GET /api/events - Get recent events
app.get('/api/events', (req, res) => {
    try {
        // Return last 50 events
        const recentEvents = events.slice(0, 50);
        res.json({ events: recentEvents });
        
    } catch (error) {
        console.error('Error fetching events:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Nomos backend running on port ${PORT}`);
});

module.exports = app;
