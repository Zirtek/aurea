import webpush from 'web-push';

webpush.setVapidDetails(
  process.env.VAPID_SUBJECT,
  process.env.VAPID_PUBLIC_KEY,
  process.env.VAPID_PRIVATE_KEY
);

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).end();

  try {
    const { subscription } = req.body;
    await webpush.sendNotification(
      subscription,
      JSON.stringify({
        title: 'Aurea • Test riuscito',
        body: 'Le notifiche sono attive sul tuo iPhone!',
        url: '/',
      })
    );
    return res.status(200).json({ ok: true });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}