#!/usr/bin/env bash

# Función para obtener uso de CPU de forma robusta
get_cpu_usage() {
  case "$(uname -s)" in
    Darwin)
      cpu=$(top -l 2 -n 0 2>/dev/null | grep "CPU usage" | tail -1 | awk -F'[:,]' '{gsub(/[^0-9.]/, "", $2); gsub(/[^0-9.]/, "", $4); printf "%.1f", $2 + $4}')
      if [[ -z "$cpu" ]] || ! [[ "$cpu" =~ ^[0-9.]+$ ]]; then
        cpu="--"
      fi
      ;;
    *)
      if command -v top >/dev/null 2>&1; then
        cpu=$(top -bn1 | grep -E "Cpu\(s\)|%Cpu" | head -1 | sed 's/,/\n/g' | grep -E "us|user" | sed 's/[^0-9.]//g' | head -1)
        if [[ -z "$cpu" ]] || ! [[ "$cpu" =~ ^[0-9.]+$ ]]; then
          if command -v vmstat >/dev/null 2>&1; then
            cpu=$(vmstat 1 2 | tail -1 | awk '{print 100-$15}')
          else
            cpu="--"
          fi
        fi
      else
        cpu="--"
      fi
      ;;
  esac
  echo "${cpu}"
}

# Función para obtener uso de RAM de forma robusta
get_ram_usage() {
  case "$(uname -s)" in
    Darwin)
      # Get used memory from vm_stat (pages) and convert to GB
      local page_size=$(sysctl -n hw.pagesize 2>/dev/null || echo 4096)
      local pages_active=$(vm_stat 2>/dev/null | awk '/Pages active/ {gsub(/\./, "", $3); print $3}')
      local pages_wired=$(vm_stat 2>/dev/null | awk '/Pages wired/ {gsub(/\./, "", $4); print $4}')
      local pages_compressed=$(vm_stat 2>/dev/null | awk '/Pages occupied by compressor/ {gsub(/\./, "", $5); print $5}')
      if [[ -n "$pages_active" && -n "$pages_wired" ]]; then
        local used_pages=$(( ${pages_active:-0} + ${pages_wired:-0} + ${pages_compressed:-0} ))
        ram=$(awk "BEGIN {printf \"%.1fGB\", ($used_pages * $page_size) / 1073741824}")
      else
        ram="--GB"
      fi
      ;;
    *)
      if command -v free >/dev/null 2>&1; then
        ram=$(free -m | awk '/^Mem:/ {printf "%.1fGB", $3/1024}')
        if [[ -z "$ram" ]]; then
          ram="--GB"
        fi
      else
        ram="--GB"
      fi
      ;;
  esac
  echo "${ram}"
}

# Obtener información del sistema
cpu=$(get_cpu_usage)
ram=$(get_ram_usage)

# Mostrar información del sistema
echo " ${cpu}%  ${ram} "