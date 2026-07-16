# Security Notes

This repository should not contain private API keys, SMTP credentials, local `.env` files, or provider-specific secret URLs.

Before publishing an update, scan for literal secret tokens, non-empty credential assignments, machine-local absolute paths, private provider URLs, and status-email metadata footers.

Expected matches should be reviewed manually. Do not commit local runtime files such as:

- `.env`
- `key.cfg`
- `anthropic_cdn_newapi.env`
- raw tmux logs
- mail reports
- Hugging Face caches
- Docker/container caches
