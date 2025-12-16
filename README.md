## Purpose
Build a fully isolated cyber range where security events are safely detonated and observed, while an external VPS (Hostinger) acts as a SOAR controller using automation workflows (n8n). The sandbox must be disposable and incapable of impacting the host workstation, LAN, or VPS.

---

## High-Level Architecture

### Trust Model
- Sandbox VMs are untrusted
- VPS is trusted
- Workstation is management-only

### Direction of Control
- Events: Sandbox → VPS (push)
- Actions: VPS → Sandbox (via reverse SSH tunnel)
- No inbound connections from VPS to sandbox network

```
Attack VM → Victim VM → Monitor VM → VPS (n8n SOAR) → Reverse SSH Tunnel → Monitor VM
```

---

## Components

### Local Sandbox (Isolated)
Runs on a local hypervisor (VirtualBox, VMware, or Proxmox).

#### Required VMs
- **Attack VM**  
  Kali Linux or equivalent; used to generate malicious activity
- **Victim VM**  
  Linux server exposing services such as SSH or HTTP
- **Monitor VM**  
  Minimal Linux system that observes events and executes response actions

#### Networking Rules
- Use Internal Network or Host-Only networking
- No bridged networking
- No LAN access
- Optional controlled outbound internet via NAT only for the Monitor VM

---

### VPS (Hostinger)
Acts exclusively as the SOAR brain.

**Runs:**
- n8n
- Event validation and normalization
- Decision logic
- Response orchestration

**Does NOT:**
- Collect raw logs
- Accept shell access from sandbox systems
- Initiate inbound connections to the sandbox

---

## Detection Layer (Monitor VM)

The Monitor VM is the only sandbox system allowed external communication.

### Detection Sources
- Fail2ban
- auditd (minimal ruleset)
- systemd journal
- Optional: Suricata in alert-only mode

### Detection Philosophy
- No bulk log forwarding
- Only high-signal, intentional events
- Each event is structured and curated

---

## Event Export (Sandbox → VPS)

### Transport
- HTTPS webhook to n8n
- Per-sandbox authentication token
- JSON payloads only

### Example Event Payload
```json
{
  "lab_id": "range-01",
  "sensor": "monitor-01",
  "target": "victim-01",
  "event_type": "ssh_bruteforce",
  "severity": 6,
  "source_ip": "10.0.0.23",
  "timestamp": "UTC"
}
```

**Mandatory Requirements:**
- Token validation
- JSON schema validation
- Rate limiting
- Rejection of unknown fields

---

## Command Execution (VPS → Sandbox)

### Overview
The Monitor VM establishes a persistent outbound SSH tunnel to the VPS. The VPS sends response commands through this tunnel. No inbound ports are opened on the sandbox network.

### SSH Constraints
- Dedicated low-privilege user
- Key-based authentication only
- No interactive shell
- Forced command execution
- Command allowlist enforcement

### Command Execution Safety
**Mandatory Controls:**
- All commands executed through a wrapper script
- No arbitrary shell execution
- Hard-coded command allowlist
- Full logging of every executed action

**Example Allowed Commands:**
- `/usr/local/bin/soar-action apply_firewall_block <ip>`
- `/usr/local/bin/soar-action restart_service sshd`
- `/usr/local/bin/soar-action lock_user <username>`

---

## VPS (n8n) Responsibilities

### Event Intake Workflow
- Validate authentication token
- Validate JSON schema
- Normalize event fields
- Assign severity score

### Decision Engine
- Rule-based scoring
- Threshold-based responses
- Manual approval for destructive actions (optional)

### Response Dispatch
- Queue approved command
- Send through reverse SSH tunnel
- Await execution confirmation
- Log outcome

---

## Attack Emulation (Sandbox Only)

**Permitted:**
- SSH brute-force attacks
- Credential stuffing
- Port scanning
- Service termination
- Privilege escalation attempts
- Malware execution in non-persistent VMs

**Prohibited:**
- Bridged networking
- LAN or internet-wide scanning
- Use of real credentials
- Persistence beyond VM lifecycle

---

## Safety Guarantees
- Sandbox cannot access LAN
- Sandbox cannot access workstation
- VPS is not directly reachable from sandbox
- Monitor VM is disposable
- Trust boundaries are explicit and enforced

---

## MVP Milestones

### Phase 1: Sandbox Setup
- Build isolated sandbox network
- Deploy Monitor VM
- Establish reverse SSH tunnel

### Phase 2: Basic Workflow
- Emit first event type (SSH brute-force)
- Trigger n8n workflow
- Alert-only response

### Phase 3: Automated Response
- Enable automated response
- Execute remote action safely
- Log full response lifecycle

---

## Project Identity
This project demonstrates:
- Zero-trust architecture
- Distributed SOAR principles
- Event-driven security automation
- Safe cyber range validation

**Note:** This is not a SIEM. It is a lightweight SOAR controller paired with a disposable sandbox.
