const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// In-memory timetable slot database
let slots = [
  {
    id: 'slot-1',
    subject: 'Data Structures & Algorithms',
    day: 1, // Monday
    startMinutes: 540, // 09:00 AM
    endMinutes: 630,   // 10:30 AM
    room: 'Hall CS-101',
    instructor: 'Dr. Turing',
    colorValue: 0xFF1E88E5,
    updatedAt: new Date(Date.now() - 3600000).toISOString(),
    version: 1,
    isDeleted: false,
  },
  {
    id: 'slot-2',
    subject: 'Database Systems',
    day: 1, // Monday
    startMinutes: 600, // 10:00 AM (Clashes 10:00 - 10:30)
    endMinutes: 690,   // 11:30 AM
    room: 'Lab DB-202',
    instructor: 'Prof. Codd',
    colorValue: 0xFFFB8C00,
    updatedAt: new Date(Date.now() - 3500000).toISOString(),
    version: 1,
    isDeleted: false,
  },
  {
    id: 'slot-3',
    subject: 'Operating Systems',
    day: 2, // Tuesday
    startMinutes: 660, // 11:00 AM
    endMinutes: 750,   // 12:30 PM
    room: 'Hall OS-105',
    instructor: 'Prof. Tanenbaum',
    colorValue: 0xFF43A047,
    updatedAt: new Date(Date.now() - 3400000).toISOString(),
    version: 1,
    isDeleted: false,
  },
  {
    id: 'slot-4',
    subject: 'Software Engineering',
    day: 4, // Thursday
    startMinutes: 600, // 10:00 AM
    endMinutes: 690,   // 11:30 AM
    room: 'Hall SE-204',
    instructor: 'Prof. Brooks',
    colorValue: 0xFF00897B,
    updatedAt: new Date(Date.now() - 3300000).toISOString(),
    version: 1,
    isDeleted: false,
  },
  {
    id: 'slot-5',
    subject: 'Compiler Design',
    day: 4, // Thursday
    startMinutes: 690, // 11:30 AM (Contiguous, no clash!)
    endMinutes: 780,   // 01:00 PM
    room: 'Hall COMP-4',
    instructor: 'Dr. Aho',
    colorValue: 0xFF5E35B1,
    updatedAt: new Date(Date.now() - 3200000).toISOString(),
    version: 1,
    isDeleted: false,
  }
];

// Server-side clash detector
function detectClashes(slotList) {
  const active = slotList.filter(s => !s.isDeleted);
  const clashingIds = new Set();
  const pairs = [];

  for (let i = 0; i < active.length; i++) {
    for (let j = i + 1; j < active.length; j++) {
      const a = active[i];
      const b = active[j];
      if (a.day === b.day) {
        const overlapStart = Math.max(a.startMinutes, b.startMinutes);
        const overlapEnd = Math.min(a.endMinutes, b.endMinutes);
        if (overlapStart < overlapEnd) {
          clashingIds.add(a.id);
          clashingIds.add(b.id);
          pairs.push({
            slotA: a,
            slotB: b,
            overlapMinutes: overlapEnd - overlapStart,
            overlapRange: `${overlapStart}-${overlapEnd}`
          });
        }
      }
    }
  }

  return {
    clashingSlotIds: Array.from(clashingIds),
    totalConflictPairs: pairs.length,
    clashPairs: pairs
  };
}

// Health check for Render
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    activeSlots: slots.filter(s => !s.isDeleted).length
  });
});

// Root welcome message
app.get('/', (req, res) => {
  res.send(`
    <html>
      <head><title>Timetable Conflict Detector API</title></head>
      <body style="font-family: sans-serif; padding: 40px; line-height: 1.6;">
        <h2>Timetable Clash Detector & Sync Engine API</h2>
        <p>Backend is live on Render!</p>
        <ul>
          <li><a href="/health">/health</a> - Server health status</li>
          <li><a href="/api/slots">/api/slots</a> - List all timetable slots</li>
          <li><a href="/api/clashes">/api/clashes</a> - Server-side clash report</li>
        </ul>
      </body>
    </html>
  `);
});

// Get all slots
app.get('/api/slots', (req, res) => {
  res.json({
    success: true,
    slots: slots,
    timestamp: new Date().toISOString()
  });
});

// Get server-side clash report
app.get('/api/clashes', (req, res) => {
  const report = detectClashes(slots);
  res.json({
    success: true,
    report: report,
    timestamp: new Date().toISOString()
  });
});

// Add a new slot
app.post('/api/slots', (req, res) => {
  const { subject, day, startMinutes, endMinutes, room, instructor, colorValue } = req.body;
  if (!subject || !day || startMinutes === undefined || endMinutes === undefined) {
    return res.status(400).json({ error: 'Missing required slot fields' });
  }

  const newSlot = {
    id: req.body.id || uuidv4(),
    subject,
    day: parseInt(day),
    startMinutes: parseInt(startMinutes),
    endMinutes: parseInt(endMinutes),
    room: room || '',
    instructor: instructor || '',
    colorValue: colorValue || 0xFF1E88E5,
    updatedAt: new Date().toISOString(),
    version: 1,
    isDeleted: false
  };

  slots.push(newSlot);
  res.status(201).json({ success: true, slot: newSlot });
});

// Update slot
app.put('/api/slots/:id', (req, res) => {
  const slotId = req.params.id;
  const index = slots.findIndex(s => s.id === slotId);

  if (index < 0) {
    return res.status(404).json({ error: 'Slot not found' });
  }

  const existing = slots[index];
  const updated = {
    ...existing,
    ...req.body,
    id: slotId,
    version: (existing.version || 1) + 1,
    updatedAt: new Date().toISOString()
  };

  slots[index] = updated;
  res.json({ success: true, slot: updated });
});

// Soft-delete slot (tombstone)
app.delete('/api/slots/:id', (req, res) => {
  const slotId = req.params.id;
  const index = slots.findIndex(s => s.id === slotId);

  if (index < 0) {
    return res.status(404).json({ error: 'Slot not found' });
  }

  slots[index].isDeleted = true;
  slots[index].version += 1;
  slots[index].updatedAt = new Date().toISOString();

  res.json({ success: true, message: 'Slot deleted (tombstone applied)' });
});

// Batch Sync Endpoint (Offline Reconnect Reconciliation)
app.post('/api/sync', (req, res) => {
  const { mutations } = req.body;
  if (!Array.isArray(mutations)) {
    return res.status(400).json({ error: 'mutations array is required' });
  }

  let syncedCount = 0;

  for (const m of mutations) {
    const { action, entityId, payload, timestamp } = m;
    const index = slots.findIndex(s => s.id === entityId);

    if (action === 'create' || action === 'CREATE') {
      if (index >= 0) {
        // Last-Write-Wins (LWW)
        if (new Date(payload.updatedAt || timestamp) > new Date(slots[index].updatedAt)) {
          slots[index] = { ...payload, version: slots[index].version + 1 };
        }
      } else {
        slots.push({ ...payload, version: 1 });
      }
      syncedCount++;
    } else if (action === 'update' || action === 'UPDATE') {
      if (index >= 0) {
        if (new Date(payload.updatedAt || timestamp) > new Date(slots[index].updatedAt)) {
          slots[index] = {
            ...slots[index],
            ...payload,
            version: slots[index].version + 1,
            updatedAt: new Date().toISOString()
          };
        }
      } else {
        slots.push({ ...payload, version: 1 });
      }
      syncedCount++;
    } else if (action === 'delete' || action === 'DELETE') {
      if (index >= 0) {
        slots[index].isDeleted = true;
        slots[index].version += 1;
        slots[index].updatedAt = new Date().toISOString();
      }
      syncedCount++;
    }
  }

  res.json({
    success: true,
    syncedCount: syncedCount,
    slots: slots,
    serverTimestamp: new Date().toISOString()
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Timetable Sync Server listening on port ${PORT}`);
});
