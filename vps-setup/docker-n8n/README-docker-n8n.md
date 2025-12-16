# Docker n8n Configuration for soar-brain SOAR Controller

This guide configures the SOAR workflows in your existing Docker n8n instance without affecting current workflows.

## Prerequisites
- Docker container running n8n (your existing setup)
- Access to n8n web interface
- No modifications to existing workflows required

## Workflow Import Process
1. Access your n8n instance at the Docker container's exposed port
2. Import each workflow JSON from `docker-n8n/` directory
3. Activate workflows after verification
4. Configure credentials for external services (SSH, email, logging)

## Included Workflows
Import in this order to ensure proper triggering:

### 1. Event Intake Workflow (`soar-event-intake.json`)
- Dedicated webhook endpoint: `/webhook/soar-event`
- Validates authentication tokens
- Enforces JSON schema for security events
- Normalizes and scores events
- Triggers decision engine workflow

### 2. SOAR Decision Engine (`soar-decision-engine.json`)
- Processes scored events
- Applies rule-based response logic
- Supports manual approval for high-risk actions
- Queues approved responses for dispatch

### 3. Response Dispatch (`soar-response-dispatch.json`)
- Executes approved actions via reverse SSH tunnel
- Logs execution results and confirmations
- Sends notifications for completed responses

## Configuration Notes
- **Endpoint Isolation**: All new workflows use `/webhook/soar-*` paths to avoid conflicts
- **Credential Separation**: Create new credentials specifically for SOAR operations
- **Tag Organization**: All SOAR workflows tagged with "soar-brain" for easy management
- **Error Handling**: Workflows include error paths that don't affect existing flows

## Security Considerations
- Webhook authentication uses separate tokens from existing workflows
- SSH credentials are isolated to SOAR operations only
- Rate limiting can be configured at Docker/nginx level if needed
- All command execution is through pre-approved allowlist

## Testing
1. Test webhook endpoint with sample event payload
2. Verify token validation rejects invalid requests
3. Confirm SSH commands execute safely
4. Check logging and notification systems

## Maintenance
- Export workflows regularly for backup
- Monitor execution logs in n8n interface
- Update credentials as needed
- Review decision rules periodically

## Integration Points
- **Event Source**: Monitor VM HTTPS webhooks
- **Response Target**: Reverse SSH tunnel to Monitor VM
- **Logging**: External services (email, spreadsheets)
- **Notifications**: Email for manual approvals and confirmations