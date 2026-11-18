#!/usr/bin/env bash

# Get current active SSID
active_ssid=$(nmcli -t -f ACTIVE,SSID device wifi list | awk -F: '$1=="ja"{print $2}')

nmcli -t -f SSID,SIGNAL,SECURITY device wifi list | awk -F: -v active="$active_ssid" '
  $1 != "" {
    gsub(/"/, "\\\"", $1)

    # Rebuild security column (in case of WPA2 WPA3)
    sec = $3
    for (i=4; i<=NF; i++) {
      sec = sec " " $i
    }

    # Keep strongest signal per SSID
    if (!($1 in sig) || $2 > sig[$1]) {
      sig[$1] = $2
      secu[$1] = sec
    }
  }
  END {
    print "["
    first = 1

    # Print active SSID first (if available)
    if (active != "" && active in sig) {
      printf "{ssid: \"%s\", signal: %s, security: \"%s\"}", active, sig[active], secu[active]
      delete sig[active]
      delete secu[active]
      first = 0
    }

    # Collect remaining SSIDs sorted by signal
    n = 0
    for (s in sig) {
      arr[n] = s
      n++
    }
    # sort by signal descending
    for (i=0; i<n; i++) {
      for (j=i+1; j<n; j++) {
        if (sig[arr[j]] > sig[arr[i]]) {
          tmp=arr[i]; arr[i]=arr[j]; arr[j]=tmp
        }
      }
    }

    # Print them
    for (i=0; i<n; i++) {
      if (!first) print ","
      printf "{ssid: \"%s\", signal: %s, security: \"%s\"}", arr[i], sig[arr[i]], secu[arr[i]]
      first = 0
    }

    print "]"
  }
'
