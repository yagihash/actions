// dump-oidc-token: fetch the GitHub Actions OIDC ID token and print its claims.
// For debugging/inspection only — does not verify the token's signature, so
// never use its output to make authorization decisions.
// No build step required — runs directly on node24 with no external dependencies.

import { appendFileSync } from 'fs';

const actionsToken = process.env.ACTIONS_ID_TOKEN_REQUEST_TOKEN;
const actionsUrl = process.env.ACTIONS_ID_TOKEN_REQUEST_URL;

if (!actionsToken || !actionsUrl) {
    console.log("::error::Missing OIDC environment variables. Set 'id-token: write' in your workflow permissions.");
    process.exit(1);
}

const audience = process.env.INPUT_AUDIENCE;
const url = audience ? `${actionsUrl}&audience=${encodeURIComponent(audience)}` : actionsUrl;

try {
    const res = await fetch(url, {
        headers: { 'Authorization': `Bearer ${actionsToken}` },
    });
    if (!res.ok) {
        const body = await res.text();
        throw new Error(`Failed to fetch OIDC token: ${res.status} ${body}`);
    }
    const { value: idToken } = await res.json();

    // Mask the raw token even though we only display its (non-secret) claims below.
    console.log(`::add-mask::${idToken}`);

    const [, payload] = idToken.split('.');
    const claims = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8'));

    console.log('::group::OIDC token claims');
    console.log(JSON.stringify(claims, null, 2));
    console.log('::endgroup::');

    appendFileSync(process.env.GITHUB_OUTPUT, `claims=${JSON.stringify(claims)}\n`);
} catch (err) {
    console.log(`::error::${err.stack}`);
    process.exit(1);
}
