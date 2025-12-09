# Exclude Gaming Devices from Pi-hole and Tailscale

Guide to exclude your son's gaming laptop and Xbox from network filtering and VPN.

## Devices to Exclude

- Gaming Laptop (Windows)
- Xbox Console

---

## Method 1: Pi-hole Group Management (RECOMMENDED)

### Step 1: Find Device Information

From any computer on your network:

```bash
# Find devices on network
arp -a

# Or on MheimNetOps
nmap -sn 192.168.1.0/24
```

Note down:

- Gaming Laptop IP and MAC address
- Xbox IP and MAC address

### Step 2: Configure Pi-hole Groups

1. **Access Pi-hole Admin:**
   - Open browser to `http://100.87.198.53/admin` (Tailscale IP)
   - Or `http://192.168.1.x/admin` (local IP of MheimNetOps)

2. **Create Bypass Group:**
   - Go to **Group Management → Groups**
   - Click **Add a new group**
   - Name: `Gaming-Devices-Bypass`
   - Description: `Gaming devices with no filtering`
   - Click **Add**

3. **Add Devices to Group:**
   - Go to **Group Management → Clients**
   - Click **Add a new client**
   - For Gaming Laptop:
     - Enter IP address or MAC address
     - Comment: `Son's Gaming Laptop`
     - Assign to group: `Gaming-Devices-Bypass`
   - Repeat for Xbox

4. **Disable Blocking for Group:**
   - Go to **Group Management → Adlists**
   - For each adlist, uncheck the `Gaming-Devices-Bypass` group
   - This disables all blocking for these devices

---

## Method 2: Router DHCP Configuration (ALTERNATIVE)

Configure your router to give gaming devices different DNS servers.

### Step 1: Set Static DHCP Reservations

1. Log into your router admin panel
2. Find DHCP settings
3. Create static reservations for:
   - Gaming Laptop (by MAC address)
   - Xbox (by MAC address)

### Step 2: Assign Different DNS

For each reservation, set DNS servers to:

- Primary: `8.8.8.8` (Google DNS)
- Secondary: `1.1.1.1` (Cloudflare DNS)

This bypasses Pi-hole completely for these devices.

---

## Method 3: Pi-hole Local DNS Records

Add conditional forwarding to bypass Pi-hole filtering:

```bash
# SSH into MheimNetOps
ssh monso@100.87.198.53

# Edit Pi-hole custom DNS
sudo nano /etc/pihole/custom.list

# Add entries (replace with actual IPs)
192.168.1.100 gaming-laptop.bypass
192.168.1.101 xbox.bypass
```

Then configure devices to use router DNS instead of Pi-hole.

---

## Tailscale Exclusion

### For Gaming Laptop

If Tailscale is installed:

```powershell
# Uninstall Tailscale
winget uninstall Tailscale.Tailscale

# Or just disable the service
Stop-Service Tailscale
Set-Service Tailscale -StartupType Disabled
```

### For Xbox

- Tailscale doesn't run on Xbox, so nothing to do
- Just ensure it's using router DNS, not Pi-hole

---

## Verification Steps

### Test Pi-hole Bypass

```bash
# From gaming laptop, test DNS
nslookup doubleclick.net

# Should resolve (not blocked) if bypass is working
# If blocked, you'll see Pi-hole block page IP
```

### Test DNS Server

```powershell
# From gaming laptop (PowerShell)
Get-DnsClientServerAddress -AddressFamily IPv4

# Should show:
# - Pi-hole IP (192.168.1.x) if using Method 1
# - 8.8.8.8 or 1.1.1.1 if using Method 2
```

### Test Tailscale

```bash
# From gaming laptop
tailscale status

# Should show "Stopped" or command not found
```

---

## Recommendation

### Best Option: Use Method 1 (Pi-hole Groups)

- ✅ Centralized management
- ✅ Easy to enable/disable
- ✅ No client-side changes needed
- ✅ Works for both devices

### Why avoid other methods

- Method 2 (Router DHCP): Requires router access, harder to manage
- Method 3: More complex, not necessary

---

## Quick Reference Commands

### Find Gaming Devices

```bash
# From MheimNetOps
nmap -sn 192.168.1.0/24 | grep -B 2 "Xbox\|Gaming"

# Or check Pi-hole queries
sudo pihole -t
```

### Pi-hole Admin Locations

- Local: `http://<MheimNetOps-Local-IP>/admin`
- Tailscale: `http://100.87.198.53/admin`
- Password: (set during Pi-hole installation)

### Restart Pi-hole (if needed)

```bash
ssh monso@100.87.198.53
pihole restartdns
```

---

## Notes

- Gaming performance may improve without Pi-hole filtering
- Xbox Live and game updates won't be blocked
- Gaming laptop can still access blocked sites
- These devices won't appear in Tailscale network
- Pi-hole will still log queries from these devices (just won't block)

---

## Rollback

To re-enable Pi-hole for these devices:

1. Go to Pi-hole **Group Management → Clients**
2. Find the gaming devices
3. Remove from `Gaming-Devices-Bypass` group
4. Or delete the client entries entirely
