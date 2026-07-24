import nodemailer from 'nodemailer';

function getTransport() {
  const user = process.env.GMAIL_USER;
  const pass = process.env.GMAIL_APP_PASSWORD;
  if (!user || !pass) {
    throw new Error('GMAIL_USER/GMAIL_APP_PASSWORD is not set');
  }
  return nodemailer.createTransport({
    service: 'gmail',
    auth: { user, pass },
  });
}

export async function sendPasswordResetEmail(to: string, resetUrl: string): Promise<void> {
  const transport = getTransport();
  await transport.sendMail({
    from: process.env.GMAIL_USER,
    to,
    subject: 'Redefinir senha — Buggo',
    html: `
      <p>Você pediu para redefinir sua senha no Buggo.</p>
      <p><a href="${resetUrl}">Clique aqui para criar uma nova senha</a></p>
      <p>Se você não pediu isso, pode ignorar este e-mail. O link expira em 1 hora.</p>
    `,
  });
}
