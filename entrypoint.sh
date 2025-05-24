#!/usr/bin/env bash
set -e


# Clean up old PulseAudio state (optional, but helps avoid conflicts)
echo "Cleaning up old PulseAudio state..."
rm -rf /var/run/pulse /var/lib/pulse /root/.config/pulse

if [ "${RUN_MIGRATIONS:-1}" = "1" ]; then
  echo "Running Django migrations…"
  python manage.py migrate --noinput
fi

# Start PulseAudio in daemon mode with verbose logging
echo "Starting PulseAudio..."
pulseaudio -D --exit-idle-time=-1 --verbose

# Wait for PulseAudio to be ready
MAX_RETRIES=5
COUNT=0
until pactl info >/dev/null 2>&1; do
  COUNT=$((COUNT + 1))
  if [ $COUNT -ge $MAX_RETRIES ]; then
    echo "PulseAudio failed to initialize after $MAX_RETRIES attempts"
    exit 1
  fi
  echo "Waiting for PulseAudio ($COUNT/$MAX_RETRIES)..."
  sleep 1
done

echo "PulseAudio initialized successfully"

exec "$@" 