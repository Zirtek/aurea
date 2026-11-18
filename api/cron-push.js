import { Redis } from '@upstash/redis';
import webpush from 'web-push';

const redis = Redis.fromEnv();

webpush.setVapidDetails(
  process.env.VAPID_SUBJECT,
  process.env.VAPID_PUBLIC_KEY,
  process.env.VAPID_PRIVATE_KEY
);

function parseUtcDate(yyyyMmDd) {
  const [y, m, d] = yyyyMmDd.split('-').map(Number);
  return Date.UTC(y, m - 1, d);
}

export default async function handler(req, res) {
  // Protezione opzionale per chiamate esterne al cron
  if (process.env.CRON_SECRET && req.headers.authorization !== `Bearer ${process.env.CRON_SECRET}`) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  const subKeys = await redis.smembers('active_subs');
  const nowUtc = new Date();
  let sentCount = 0;

  for (const subKey of subKeys) {
    const record = await redis.get(subKey);
    if (!record || !record.subscription) continue;

    // Calcola ora e data locale dell'utente
    const userLocalMs = nowUtc.getTime() - (record.timezoneOffsetMinutes * 60 * 1000);
    const userLocal = new Date(userLocalMs);
    const localHour = userLocal.getUTCHours();
    const localTodayStr = userLocal.toISOString().slice(0, 10);
    const localTodayMs = parseUtcDate(localTodayStr);

    const messages = [];

    if (record.lastPeriodStart) {
      const lastStartMs = parseUtcDate(record.lastPeriodStart);
      const cycleLen = record.effectiveCycleLength || 28;
      const msPerDay = 24 * 60 * 60 * 1000;

      // 1. Avviso 2 giorni prima del prossimo ciclo (inviato alle 09:00 locali)
      if (record.notifyPeriodBefore) {
        const nextPeriodMs = lastStartMs + cycleLen * msPerDay;
        const daysUntil = Math.round((nextPeriodMs - localTodayMs) / msPerDay);
        if (daysUntil === 2) {
          messages.push({
            title: 'Aurea • Ciclo in arrivo',
            body: 'Il prossimo ciclo è previsto tra 2 giorni.',
          });
        }
      }

      // 2. Avviso inizio finestra fertile (cycleLength - 14 - 4 = cycleLength - 18, alle 09:00 locali)
      if (record.notifyFertileStart) {
        const fertileStartMs = lastStartMs + (cycleLen - 18) * msPerDay;
        const daysUntilFertile = Math.round((fertileStartMs - localTodayMs) / msPerDay);
        if (daysUntilFertile === 0) {
          messages.push({
            title: 'Aurea • Finestra fertile',
            body: 'Oggi inizia la tua finestra fertile stimata.',
          });
        }
      }
    }

    // 3. Promemoria serale diario / farmaci all'ora scelta dall'utente
    if (record.notifyDailyLog) {
      const alreadyLoggedToday = record.hasLoggedToday && record.todayKey === localTodayStr;
      if (!alreadyLoggedToday) {
        messages.push({
          title: 'Aurea • Diario serale',
          body: 'Ricorda di registrare sintomi, umore o farmaci di oggi.',
        });
      }
    }

    for (const msg of messages) {
      try {
        await webpush.sendNotification(
          record.subscription,
          JSON.stringify({ ...msg, url: '/' })
        );
        sentCount++;
      } catch (err) {
        // Se la subscription iOS è scaduta o revocata (410 Gone), pulisci Redis
        if (err.statusCode === 410 || err.statusCode === 404) {
          await redis.del(subKey);
          await redis.srem('active_subs', subKey);
        }
      }
    }
  }

  return res.status(200).json({ ok: true, sent: sentCount });
}