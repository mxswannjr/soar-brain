# VPS Setup Guide for soar-brain SOAR Controller

This guide covers the complete configuration of the Hostinger VPS to serve as the SOAR brain for the isolated security sandbox.

## Prerequisites
- Hostinger VPS with Ubuntu/Debian
- Root or sudo access
- Domain name pointing to VPS IP (for SSL)
- SSH access configured

## Automated Setup
Run the installation script:
```bash
chmod +x install-n8n.sh
sudo ./install-n8n.sh
```

## Manual Setup Steps (if needed)
1. Update system and install dependencies
2. Install Node.js 18+
3. Install n8n globally via npm
4. Create n8n user and directories
5. Configure systemd service
6. Set up nginx reverse proxy with rate limiting
7. Configure firewall (ufw)
8. Install fail2ban
9. Obtain SSL certificate with certbot

## n8n Configuration
- Access n8n at `https://your-domain.com`
- Default credentials: admin/admin (change immediately)
- Import workflows from `n8n-workflows/` directory

## Key Features Implemented
- **Rate Limiting**: 10 req/min globally, 2 req/min for webhooks
- **SSL/TLS**: HTTPS enforced via nginx
- **Security**: fail2ban, ufw firewall, no direct SSH from sandbox
- **Reverse Proxy**: nginx handles SSL termination and load balancing

## n8n Workflows
Import the following workflows in order:

### 1. Event Intake Workflow (`event-intake.json`)
- Receives HTTPS POST webhooks
- Validates authentication token
- Validates JSON schema against expected event format
- Normalizes event fields
- Assigns severity score (1-10)
- Stores event in database/logs

### 2. Decision Engine Workflow (`decision-engine.json`)
- Triggered by event intake
- Applies rule-based scoring
- Checks thresholds for automated responses
- Supports manual approval for destructive actions
- Queues approved responses

### 3. Response Dispatch Workflow (`response-dispatch.json`)
- Executes approved responses via reverse SSH tunnel
- Sends commands to Monitor VM
- Awaits execution confirmation
- Logs full response lifecycle

## Authentication
- Use n8n's built-in authentication
- Generate API tokens for webhook endpoints
- Store tokens securely (environment variables)

## Monitoring & Logging
- n8n execution logs: `/home/n8n/.n8n/logs/`
- nginx access logs: `/var/log/nginx/`
- System logs: journalctl
- Monitor via n8n dashboard

## Security Controls
- Token validation for all webhooks
- JSON schema enforcement
- Rate limiting prevents abuse
- No inbound connections from sandbox
- All traffic through reverse SSH tunnel

## Maintenance
- Update n8n: `npm update -g n8n`
- Backup workflows regularly
- Monitor resource usage
- Review logs for anomalies

## Troubleshooting
- Check service status: `systemctl status n8n`
- View logs: `journalctl -u n8n`
- Test webhook: Use curl with valid token
- Rate limit issues: Check nginx logs

## Next Steps
After setup:
1. Test event intake with sample payload
2. Verify reverse SSH tunnel connectivity
3. Run end-to-end test with sandbox
4. Monitor and tune decision rules