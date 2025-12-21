# SOAR Workflow Setup Guide

This guide explains how to import and configure the SOAR workflows into your existing n8n Docker instance.

## Prerequisites
- n8n running in Docker (n8n-docker project)
- Access to n8n web interface
- Credentials configured for SSH, email, and logging

## Import Workflows

1. Copy workflow files to n8n-docker project:
   ```bash
   cp /root/rio/projects/soar-brain/n8n-workflows/*.json /root/rio/projects/n8n-docker/
   ```

2. Access n8n

3. Import workflows in order:
   - Go to Workflows → Import from File
   - Import `soar-event-intake.json`
   - Import `soar-decision-engine.json`
   - Import `soar-response-dispatch.json`

## Configure Credentials

### SOAR Webhook Auth
- Create HTTP Header Auth credential
- Header Name: `Authorization`
- Header Value: `Bearer your-soar-secret-token`

### SOAR SSH Credentials
- Create SSH credential for Monitor VM access
- Host: Monitor VM IP
- Username: soar-user
- Private Key: Reverse tunnel SSH key
- Port: 22

### Google Sheets (Logging)
- Create Google Sheets OAuth2 credential
- Spreadsheet ID: Your SOAR logging spreadsheet
- Sheet Name: Events/Responses

### SMTP (Email Notifications)
- Create SMTP credential
- Host: Your SMTP server
- Port: 587/465
- Username/Password: Email credentials

## Workflow IDs
After importing, note the workflow IDs for cross-workflow triggering:
- Event Intake: [ID]
- Decision Engine: [ID]
- Response Dispatch: [ID]

Update the workflow trigger nodes with correct IDs.

## Testing
1. Test event intake webhook with sample payload
2. Verify decision engine routing
3. Confirm SSH command execution (use test VM first)

## Activation
- Activate all three workflows
- Monitor execution logs
- Test end-to-end with sandbox
