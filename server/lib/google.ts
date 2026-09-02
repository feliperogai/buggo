import { OAuth2Client } from 'google-auth-library';

// Audience the Google ID token must be issued for. This is the **Web**
// OAuth client id from Google Cloud (not the Android one): the Android app
// asks for a token addressed to the backend, so the backend validates
// against the web client id. Same value goes in the app's
// `GOOGLE_SERVER_CLIENT_ID`.
function requireWebClientId(): string {
  const id = process.env.GOOGLE_WEB_CLIENT_ID;
  if (!id) throw new Error('GOOGLE_WEB_CLIENT_ID is not set');
  return id;
}

const client = new OAuth2Client();

export interface GoogleIdentity {
  googleId: string;
  email: string;
  name: string | null;
  emailVerified: boolean;
}

/// Verifies the ID token's signature, issuer, audience and expiry against
/// Google's public keys. Throws if anything doesn't check out — never trust
/// the payload the app claims without this.
export async function verifyGoogleIdToken(idToken: string): Promise<GoogleIdentity> {
  const ticket = await client.verifyIdToken({
    idToken,
    audience: requireWebClientId(),
  });
  const payload = ticket.getPayload();
  if (!payload?.sub || !payload.email) {
    throw new Error('Token do Google sem sub/email');
  }
  return {
    googleId: payload.sub,
    email: payload.email.trim().toLowerCase(),
    name: payload.name ?? null,
    emailVerified: payload.email_verified === true,
  };
}
