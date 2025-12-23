#!/bin/bash

if ! command -v openssl &> /dev/null; then
    echo "Error: openssl is required."
    exit 1
fi
DOMAINS_JSON='["amd.com", "aws.com", "c.6sc.co", "j.6sc.co", "b.6sc.co", "intel.com", "r.bing.com", "th.bing.com", "www.amd.com", "www.aws.com", "ipv6.6sc.co", "www.xbox.com", "www.sony.com", "rum.hlx.page", "www.bing.com", "xp.apple.com", "www.wowt.com", "www.apple.com", "www.intel.com", "www.tesla.com", "www.xilinx.com", "www.oracle.com", "www.icloud.com", "apps.apple.com", "c.marsflag.com", "www.nvidia.com", "snap.licdn.com", "aws.amazon.com", "drivers.amd.com", "cdn.bizibly.com", "s.go-mpulse.net", "tags.tiqcdn.com", "cdn.bizible.com", "ocsp2.apple.com", "cdn.userway.org", "download.amd.com", "d1.awsstatic.com", "s0.awsstatic.com", "mscom.demdex.net", "a0.awsstatic.com", "go.microsoft.com", "apps.mzstatic.com", "sisu.xboxlive.com", "www.microsoft.com", "s.mp.marsflag.com", "images.nvidia.com", "vs.aws.amazon.com", "c.s-microsoft.com", "statici.icloud.com", "beacon.gtv-pub.com", "ts4.tc.mm.bing.net", "ts3.tc.mm.bing.net", "d2c.aws.amazon.com", "ts1.tc.mm.bing.net", "ce.mf.marsflag.com", "d0.m.awsstatic.com", "t0.m.awsstatic.com", "ts2.tc.mm.bing.net", "statici.icloud.com", "tag.demandbase.com", "assets-www.xbox.com", "logx.optimizely.com", "azure.microsoft.com", "aadcdn.msftauth.net", "d.oracleinfinity.io", "assets.adobedtm.com", "lpcdn.lpsnmedia.net", "res-1.cdn.office.net", "is1-ssl.mzstatic.com", "electronics.sony.com", "intelcorp.scene7.com", "acctcdn.msftauth.net", "cdnssl.clicktale.net", "catalog.gamepass.com", "consent.trustarc.com", "gsp-ssl.ls.apple.com", "munchkin.marketo.net", "s.company-target.com", "cdn77.api.userway.org", "cua-chat-ui.tesla.com", "assets-xbxweb.xbox.com", "ds-aksb-a.akamaihd.net", "static.cloud.coveo.com", "api.company-target.com", "devblogs.microsoft.com", "s7mbrstream.scene7.com", "fpinit.itunes.apple.com", "digitalassets.tesla.com", "d.impactradius-event.com", "downloadmirror.intel.com", "iosapps.itunes.apple.com", "se-edge.itunes.apple.com", "publisher.liveperson.net", "tag-logger.demandbase.com", "services.digitaleast.mobi", "configuration.ls.apple.com", "gray-wowt-prod.gtv-cdn.com", "visualstudio.microsoft.com", "prod.log.shortbread.aws.dev", "amp-api-edge.apps.apple.com", "store-images.s-microsoft.com", "cdn-dynmedia-1.microsoft.com", "github.gallerycdn.vsassets.io", "prod.pa.cdn.uis.awsstatic.com", "a.b.cdn.console.awsstatic.com", "d3agakyjgjv5i8.cloudfront.net", "vscjava.gallerycdn.vsassets.io", "location-services-prd.tesla.com", "ms-vscode.gallerycdn.vsassets.io", "ms-python.gallerycdn.vsassets.io", "gray-config-prod.api.arc-cdn.net", "i7158c100-ds-aksb-a.akamaihd.net", "downloaddispatch.itunes.apple.com", "res.public.onecdn.static.microsoft", "gray.video-player.arcpublishing.com", "gray-config-prod.api.cdn.arcpublishing.com", "img-prod-cms-rt-microsoft-com.akamaized.net", "prod.us-east-1.ui.gcr-chat.marketing.aws.dev"]'
RESULT_FILE=$(mktemp)
trap "rm -f $RESULT_FILE" EXIT
check_domain() {
    local domain=$1
    local total_time=0
    local loop_count=3
    for ((i=1; i<=loop_count; i++)); do
        local start_ts
        local end_ts
        local diff
        start_ts=$(date +%s%3N)
        timeout 2 openssl s_client -connect "${domain}:443" -servername "${domain}" < /dev/null > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            return
        fi
        end_ts=$(date +%s%3N)
        diff=$((end_ts - start_ts))
        total_time=$((total_time + diff))
    done
    local avg_time=$((total_time / loop_count))
    echo -e "Finished: \033[32m${domain}\033[0m avg: ${avg_time} ms"
    echo "${avg_time} ${domain}" >> "$RESULT_FILE"
}
export -f check_domain
export RESULT_FILE
echo "Starting concurrent speed test (Top 3 will be shown at the end)..."
echo "---------------------------------------------------------------"
echo "$DOMAINS_JSON" | tr -d '[]"' | tr ',' '\n' | tr -d ' ' | \
xargs -P 50 -I {} bash -c 'check_domain "{}"'
echo "---------------------------------------------------------------"
echo -e "\033[1;33m🏆 TOP 3 FASTEST DOMAINS (Average of 3 runs):\033[0m"
if [ -s "$RESULT_FILE" ]; then
    sort -n "$RESULT_FILE" | head -n 3 | awk '{printf "Rank %d: %-40s %s ms\n", NR, $2, $1}'
else
    echo "No domains accessible."
fi
