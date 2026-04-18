# Security Policy

## The Irony

GLASS is a trust framework. If it has security issues, that's peak irony.

## Reporting

Report security issues to: ceo@winniio.io

Do NOT open a public issue for security vulnerabilities.

## Known Limitations

1. **AI self-reporting is not tamper-proof** — GLASS is a communication convention, not a cryptographic guarantee. The AI can still lie. The framework makes lying structurally harder and more detectable, but not impossible.

2. **The audit script trusts grep output** — A sufficiently adversarial codebase could game the detection heuristics. This is by design — GLASS is for teams that want honesty, not for adversarial environments.

3. **No signed audit logs yet** — The report file is plain markdown. Future versions should support cryptographic signing for audit trail integrity.
