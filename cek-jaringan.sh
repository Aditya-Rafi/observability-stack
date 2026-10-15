#!/bin/bash

Q="http://localhost:9009/prometheus/api/v1/query"
GFPASS=$(grep '^GF_SECURITY_ADMIN_PASSWORD=' ~/Documents/observability/.env | cut -d= -f2-)

# Target jaringan
TARGET_AP="10.0.0.30"

echo "═══ CONTAINER ═══"
docker ps --format '{{.Names}}|{{.Status}}' \
  | grep -E 'grafana|mimir|alloy|blackbox|mktxp|tailscale' \
  | column -t -s'|'

echo
echo "═══ STATUS TARGET ═══"

curl -s --data-urlencode \
  'query=probe_success{job="blackbox_icmp_kantor"}' \
  "$Q" \
  | python3 -c "
import sys, json

try:
    data = json.load(sys.stdin)
    r = data.get('data', {}).get('result', [])

    print('Target:', len(r))

    for s in sorted(r, key=lambda x: x['metric'].get('name', '')):
        metric = s['metric']
        name = metric.get('name', '')
        instance = metric.get('instance', '')
        status = 'HIDUP' if s['value'][1] == '1' else 'MATI'

        print(f'  {name:22} {instance:16} {status}')

except Exception as e:
    print('ERROR:', e)
"

echo
echo "═══ LATENSI ═══"

curl -s --data-urlencode \
  'query=probe_duration_seconds{job="blackbox_icmp_kantor"}' \
  "$Q" \
  | python3 -c "
import sys, json

try:
    data = json.load(sys.stdin)
    r = data.get('data', {}).get('result', [])

    for s in sorted(r, key=lambda x: x['metric'].get('name', '')):
        metric = s['metric']
        name = metric.get('name', '')
        ms = float(s['value'][1]) * 1000

        warning = '  <-- BERMASALAH' if ms > 20 else ''

        print(f'  {name:22} {ms:8.2f} ms{warning}')

except Exception as e:
    print('ERROR:', e)
"

echo
echo "═══ PACKET LOSS 1 JAM ═══"

for t in 8.8.8.8 1.1.1.1 10.0.100.1 10.0.0.1 "$TARGET_AP"; do

    v=$(curl -s --data-urlencode \
      "query=(1-avg_over_time(probe_success{instance=\"$t\"}[1h]))*100" \
      "$Q" \
      | python3 -c "
import sys, json

try:
    r = json.load(sys.stdin)['data']['result']
    print(round(float(r[0]['value'][1]), 2) if r else 'n/a')
except:
    print('n/a')
")

    printf "  %-16s %s%%\n" "$t" "$v"
done

echo
echo "═══ ROUTER ═══"

for m in \
  'mktxp_system_cpu_load|CPU (%)' \
  'rate(mktxp_interface_rx_byte_total{name="ether1"}[5m])*8/1000000|WAN download (Mbps)' \
  'sum(rate(mktxp_queue_tree_dropped_total[10m]))|Queue drop (pkt/dtk)'
do

    q="${m%%|*}"
    lbl="${m##*|}"

    v=$(curl -s --data-urlencode "query=$q" "$Q" \
      | python3 -c "
import sys, json

try:
    r = json.load(sys.stdin)['data']['result']
    print(round(float(r[0]['value'][1]), 2) if r else 'n/a')
except:
    print('n/a')
")

    printf "  %-24s %s\n" "$lbl" "$v"
done

echo
echo "═══ ALERT AKTIF ═══"

curl -s \
  -u "admin:$GFPASS" \
  'http://localhost:3000/api/alertmanager/grafana/api/v2/alerts' \
  | python3 -c "
import sys, json

try:
    d = json.load(sys.stdin)

    print('  Jumlah:', len(d))

    for a in d:
        labels = a.get('labels', {})
        print(
            '   -',
            labels.get('alertname', ''),
            '|',
            labels.get('name', ''),
            labels.get('instance', '')
        )

except Exception as e:
    print('  ERROR:', e)
"

echo
echo "═══ SISTEM ═══"

echo "  netprobe: $(systemctl is-active netprobe.service)"

free -h | awk '/Mem:/{print "  RAM available: "$7}'

df -h / | awk 'NR==2{
    print "  Disk bebas: "$4" ("$5" terpakai)"
}'
