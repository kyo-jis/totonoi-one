const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

async function getBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on('data', c => chunks.push(c));
    req.on('end', () => {
      try { resolve(JSON.parse(Buffer.concat(chunks).toString())); }
      catch { resolve({}); }
    });
    req.on('error', reject);
  });
}

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', 'https://totonoi-one.vercel.app');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).end();

  const { userId, userEmail, plan } = await getBody(req);

  // plan: 'yearly' → 年額(¥1,800) / それ以外 → 月額(¥200)。
  // 未設定の環境変数は従来の STRIPE_PRICE_ID にフォールバック。
  const priceId = plan === 'yearly'
    ? (process.env.STRIPE_PRICE_ID_YEARLY  || process.env.STRIPE_PRICE_ID)
    : (process.env.STRIPE_PRICE_ID_MONTHLY || process.env.STRIPE_PRICE_ID);

  try {
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [{ price: priceId, quantity: 1 }],
      mode: 'subscription',
      success_url: 'https://totonoi-one.vercel.app/index.html?pro=success',
      cancel_url:  'https://totonoi-one.vercel.app/index.html',
      customer_email: userEmail || undefined,
      metadata: { userId: userId || '', plan: plan || 'monthly' },
    });
    res.json({ url: session.url });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
