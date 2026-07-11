#!/bin/bash

ENV_FILE="/var/www/ea-nation-server/.env"
ALERT_RAM_THRESHOLD=85
ALERT_DISK_THRESHOLD=85

# --- Load .env if variables not already set ---
if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a
fi

# --- Guards ---
if [ "$1" = "--alert" ]; then
  REQUIRED_VAR="DISCORD_WEBHOOK_ALERTS"
  WEBHOOK="$DISCORD_WEBHOOK_ALERTS"
else
  REQUIRED_VAR="DISCORD_WEBHOOK_MONITORING"
  WEBHOOK="$DISCORD_WEBHOOK_MONITORING"
fi

if [ -z "$WEBHOOK" ]; then
  echo "[health-report] ERROR: $REQUIRED_VAR is not set and could not be loaded from $ENV_FILE" >&2
  exit 1
fi

if ! command -v docker &>/dev/null; then
  echo "[health-report] ERROR: docker command not found" >&2
  exit 1
fi

# --- System metrics ---
RAM_TOTAL=$(free -m | awk '/Mem/{print $2}')
RAM_USED=$(free -m | awk '/Mem/{print $3}')
RAM_PCT=$(( RAM_USED * 100 / RAM_TOTAL ))

DISK_INFO=$(df -h / | awk 'NR==2{print $3, $2, $5}')
DISK_USED=$(echo $DISK_INFO | cut -d' ' -f1)
DISK_TOTAL=$(echo $DISK_INFO | cut -d' ' -f2)
DISK_PCT=$(echo $DISK_INFO | cut -d' ' -f3 | tr -d '%')

# --- Docker containers (all running on host, sorted by RAM desc) ---
CONTAINERS=$(docker stats --no-stream --format "{{.Name}}|{{.MemUsage}}|{{.MemPerc}}|{{.CPUPerc}}" 2>/dev/null \
  | sort -t'|' -k3 -rn)

CONTAINER_LINES=""
while IFS='|' read -r name mem_usage mem_pct cpu_pct; do
  [ -z "$name" ] && continue
  mem_used=$(echo "$mem_usage" | cut -d'/' -f1 | tr -d ' ')
  LINE="• **${name}** — ${mem_used} (${mem_pct}) | CPU ${cpu_pct}"
  [ -z "$CONTAINER_LINES" ] \
    && CONTAINER_LINES="$LINE" \
    || CONTAINER_LINES="${CONTAINER_LINES}\n${LINE}"
done <<< "$CONTAINERS"
[ -z "$CONTAINER_LINES" ] && CONTAINER_LINES="No containers running"

# --- Status icons ---
RAM_ICON="🟢"; [ "$RAM_PCT" -gt 70 ] && RAM_ICON="🟡"; [ "$RAM_PCT" -gt "$ALERT_RAM_THRESHOLD" ] && RAM_ICON="🔴"
DISK_ICON="🟢"; [ "$DISK_PCT" -gt 70 ] && DISK_ICON="🟡"; [ "$DISK_PCT" -gt "$ALERT_DISK_THRESHOLD" ] && DISK_ICON="🔴"

# --- Alert mode ---
if [ "$1" = "--alert" ]; then
  ALERT_MSG=""
  [ "$RAM_PCT" -gt "$ALERT_RAM_THRESHOLD" ] && ALERT_MSG="${ALERT_MSG}⚠️ RAM critical: ${RAM_PCT}%\n"
  [ "$DISK_PCT" -gt "$ALERT_DISK_THRESHOLD" ] && ALERT_MSG="${ALERT_MSG}⚠️ Disk critical: ${DISK_PCT}%"
  [ -z "$ALERT_MSG" ] && exit 0

  curl -s -X POST "$WEBHOOK" \
    -H "Content-Type: application/json" \
    -d "{
  \"content\": \"@here\",
  \"embeds\": [{
    \"title\": \"🚨 Server Alert — EA Nation | ${ENVIRONMENT} (${TCP_HOST_IP})\",
    \"description\": \"${ALERT_MSG}\",
    \"color\": 16711680,
    \"fields\": [
      { \"name\": \"${RAM_ICON} RAM\",   \"value\": \"${RAM_USED}MB / ${RAM_TOTAL}MB (${RAM_PCT}%)\", \"inline\": true },
      { \"name\": \"${DISK_ICON} Disk\", \"value\": \"${DISK_USED} / ${DISK_TOTAL} (${DISK_PCT}%)\",  \"inline\": true },
      { \"name\": \"📦 Containers\", \"value\": \"${CONTAINER_LINES}\", \"inline\": false }
    ]
  }]
}"

# --- Report mode ---
else
  curl -s -X POST "$WEBHOOK" \
    -H "Content-Type: application/json" \
    -d "{
  \"embeds\": [{
    \"title\": \"📊 Health Report — EA Nation | ${ENVIRONMENT} (${TCP_HOST_IP})\",
    \"color\": 3066993,
    \"fields\": [
      { \"name\": \"${RAM_ICON} RAM\",   \"value\": \"${RAM_USED}MB / ${RAM_TOTAL}MB (${RAM_PCT}%)\", \"inline\": true },
      { \"name\": \"${DISK_ICON} Disk\", \"value\": \"${DISK_USED} / ${DISK_TOTAL} (${DISK_PCT}%)\",  \"inline\": true },
      { \"name\": \"📦 Containers\", \"value\": \"${CONTAINER_LINES}\", \"inline\": false }
    ]
  }]
}"
fi
