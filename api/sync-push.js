import { Redis } from '@upstash/redis';

const redis = Redis.fromEnv();

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const {
      subscription,
      enabled,
      lastPeriodStart,       // "YYYY-MM-DD"
      effectiveCycleLength,  // es. 28
      notifyPeriodBefore,    // bool (2 giorni prima)
      notifyFertileStart,    // bool (inizio finestra fertile)
      notifyDailyLog,        // bool (promemoria serale diario/farmaci)
      dailyLogHour,          // es. 20 (ora locale 0-23)
      timezoneOffsetMinutes, // es. -60 per CET (UTC+1)
      hasLoggedToday,        // bool
      todayKey,              // "YYYY-MM-DD"
    } = req.body;

    if (!subscription || !subscription.endpoint) {
      return res.status(400).json({ error: 'Subscription mancante' });
    }

    const subKey = `sub:${Buffer.from(subscription.endpoint).toString('base64url')}`;

    if (!enabled) {
      await redis.del(subKey);
      await redis.srem('active_subs', subKey);
      return res.status(200).json({ ok: true, removed: true });
    }

    await redis.set(subKey, {
      subscription,
      lastPeriodStart,
      effectiveCycleLength: Number(effectiveCycleLength) || 28,
      notifyPeriodBefore: Boolean(notifyPeriodBefore),
      notifyFertileStart: Boolean(notifyFertileStart),
      notifyDailyLog: Boolean(notifyDailyLog),
      dailyLogHour: Number(dailyLogHour ?? 20),
      timezoneOffsetMinutes: Number(timezoneOffsetMinutes ?? -60),
      hasLoggedToday: Boolean(hasLoggedToday),
      todayKey: todayKey || '',
      updatedAt: new Date().toISOString(),
    });
    await redis.sadd('active_subs', subKey);

    return res.status(200).json({ ok: true });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}