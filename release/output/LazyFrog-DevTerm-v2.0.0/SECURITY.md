# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.1.x   | ✅ Yes             |
| < 1.1   | ❌ No              |

## Reporting a Vulnerability

If you discover a security issue, please report it privately:

1. **Do not** open a public issue
2. Contact the maintainers directly via GitHub
3. Provide details about the vulnerability and steps to reproduce

We will respond within 48 hours and work with you to address the issue.

## Security Considerations

LazyFrog DevTerm is a local terminal utility. Keep in mind:

- **GitHub API** — Uses unauthenticated requests (rate-limited to 60/hour)
- **Task execution** — Commands in `tasks.json` run with your user permissions
- **No network services** — The app doesn't open ports or accept connections
- **Local storage only** — All data stays in your local folders

## Best Practices

- Review `tasks.json` before running unknown tasks
- Don't add sensitive data to task commands
- Keep PowerShell and Windows updated
