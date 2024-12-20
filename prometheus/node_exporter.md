### Setup Node Exporter to grab Validator Metrics

Install Node Exporter first - I followed these instructions: https://linuxhint.com/install-prometheus-on-ubuntu/

Add this to crontab <crontab -e>
    */5 * * * * /home/ubuntu/scripts/promValStats.sh > /var/lib/prometheus/node-exporter/valStats.prom

    
