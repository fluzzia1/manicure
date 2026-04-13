const express = require('express');
const app     = express();
const PORT    = process.env.PORT || 3000;

app.use(express.static(__dirname));
app.use(express.json());

/* ============================================================
   SEND BOOKING CONFIRMATION EMAIL via Resend
============================================================ */
app.post('/send-booking-email', async (req, res) => {
  const { name, email, service, date, time, duration, price } = req.body;

  if (!email || !name) return res.status(400).json({ error: 'Dados insuficientes.' });

  const RESEND_API_KEY = process.env.RESEND_API_KEY;
  if (!RESEND_API_KEY) return res.status(500).json({ error: 'Serviço de email não configurado.' });

  // Formata duração
  const h = Math.floor(duration / 60), m = duration % 60;
  const durStr = h && m ? `${h}h${String(m).padStart(2,'0')}min` : h ? `${h}h` : `${m}min`;

  // Formata data BR
  const [y, mo, d] = (date || '').split('-');
  const dateBR = date ? `${d}/${mo}/${y}` : '—';

  const html = `<!DOCTYPE html>
<html lang="pt-BR">
<head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/></head>
<body style="margin:0;padding:0;background:#f4f0f1;font-family:'Helvetica Neue',Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f4f0f1;padding:32px 16px;">
    <tr><td align="center">
      <table width="100%" cellpadding="0" cellspacing="0" style="max-width:520px;background:#fff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,.08);">

        <!-- Header -->
        <tr>
          <td style="background:linear-gradient(135deg,#C4607A,#9E3F5A);padding:32px 32px 24px;text-align:center;">
            <img src="https://studiobeauty.fluzzia.com/logo.png" alt="Studio Beauty" style="height:64px;width:auto;margin-bottom:12px;" onerror="this.style.display='none'"/>
            <h1 style="margin:0;font-size:22px;color:#fff;font-weight:700;letter-spacing:.5px;">Agendamento Confirmado!</h1>
            <p style="margin:6px 0 0;color:rgba(255,255,255,.85);font-size:14px;">Estamos ansiosos para receber você 🌸</p>
          </td>
        </tr>

        <!-- Body -->
        <tr>
          <td style="padding:28px 32px;">
            <p style="margin:0 0 20px;font-size:15px;color:#3a2428;">Olá, <strong>${name}</strong>! Seu agendamento foi confirmado com sucesso.</p>

            <!-- Detalhes -->
            <table width="100%" cellpadding="0" cellspacing="0" style="background:#fdf5f6;border-radius:12px;overflow:hidden;border:1px solid #f0dde1;margin-bottom:24px;">
              <tr>
                <td style="padding:14px 18px;border-bottom:1px solid #f0dde1;">
                  <span style="font-size:12px;color:#9e7070;font-weight:600;text-transform:uppercase;letter-spacing:.5px;">Serviço</span><br/>
                  <span style="font-size:15px;color:#2a1418;font-weight:600;">${service}</span>
                </td>
              </tr>
              <tr>
                <td style="padding:14px 18px;border-bottom:1px solid #f0dde1;">
                  <span style="font-size:12px;color:#9e7070;font-weight:600;text-transform:uppercase;letter-spacing:.5px;">Data</span><br/>
                  <span style="font-size:15px;color:#2a1418;font-weight:600;">${dateBR}</span>
                </td>
              </tr>
              <tr>
                <td style="padding:14px 18px;border-bottom:1px solid #f0dde1;">
                  <span style="font-size:12px;color:#9e7070;font-weight:600;text-transform:uppercase;letter-spacing:.5px;">Horário</span><br/>
                  <span style="font-size:15px;color:#2a1418;font-weight:600;">${time} (${durStr})</span>
                </td>
              </tr>
              <tr>
                <td style="padding:14px 18px;">
                  <span style="font-size:12px;color:#9e7070;font-weight:600;text-transform:uppercase;letter-spacing:.5px;">Valor</span><br/>
                  <span style="font-size:15px;color:#2a1418;font-weight:600;">${price || 'A confirmar'}</span>
                </td>
              </tr>
            </table>

            <p style="margin:0 0 24px;font-size:14px;color:#7a5860;line-height:1.6;">Caso precise remarcar ou cancelar, acesse o site e vá em <strong>Meus Agendamentos</strong>.</p>

            <!-- CTA -->
            <table width="100%" cellpadding="0" cellspacing="0">
              <tr>
                <td align="center">
                  <a href="https://wa.me/5531987899520" style="display:inline-block;background:#25D366;color:#fff;font-size:14px;font-weight:600;text-decoration:none;padding:12px 28px;border-radius:50px;">
                    💬 Falar no WhatsApp
                  </a>
                </td>
              </tr>
            </table>
          </td>
        </tr>

        <!-- Footer -->
        <tr>
          <td style="background:#fdf5f6;padding:20px 32px;text-align:center;border-top:1px solid #f0dde1;">
            <p style="margin:0;font-size:12px;color:#b08090;">Studio Beauty — Horizonte, MG</p>
            <p style="margin:4px 0 0;font-size:12px;color:#c9a0a8;">Este email foi enviado automaticamente. Não responda.</p>
          </td>
        </tr>

      </table>
    </td></tr>
  </table>
</body>
</html>`;

  try {
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        from: 'Studio Beauty <contato@fluzzia.com>',
        to: [email],
        subject: '✅ Agendamento Confirmado — Studio Beauty',
        html
      })
    });

    const data = await response.json();
    if (!response.ok) return res.status(500).json({ error: data });
    res.json({ ok: true });
  } catch (err) {
    console.error('Resend error:', err);
    res.status(500).json({ error: 'Falha ao enviar email.' });
  }
});

app.listen(PORT, () => {
  console.log(`Studio Beauty rodando na porta ${PORT}`);
});
