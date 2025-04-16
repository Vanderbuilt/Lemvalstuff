### Setup Node Exporter to gather Validator Metrics ###  

Install Node Exporter first - I followed these instructions: https://linuxhint.com/install-prometheus-on-ubuntu/ 

Copy the **getValStats.sh** and **formatMetrics.py** scripts to the **/home/ubuntu/scripts** directory and make sure they have executable permissions.  
    `chmod +x /home/ubuntu/scripts/getValStats.sh`  
    `chmod +x /home/ubuntu/scripts/formatMetrics.py`

Make sure that **/var/lib/prometheus/node-exporter** exists and has an ownership of **prometheus:prometheus**.  
    `sudo chown prometheus:prometheus /var/lib/prometheus/node-exporter`  

Add the **ubuntu** user to the **prometheus** group so that it has permissions to write in this new folder.  
    `sudo usermod -a -G prometheus ubuntu`  

Edit crontab:  
    `crontab -e`  

Add these lines to your crontab:  
    `*/1 * * * * /home/ubuntu/scripts/getValStats.sh -p > /var/lib/prometheus/node-exporter/valStats.prom`  
    `*/1 * * * * /home/ubuntu/scripts/formatMetrics.py > /var/lib/prometheus/node-exporter/valMetrics.prom`  

Add this line to crontab if you want togather all validator reword statistics to a file:  
    `*/1 * * * * /home/ubuntu/scripts/getRewards.sh -c >> /home/ubuntu/rewards.csv 2>&1`    

Next we'll need to tell node-exporter to export in text files.
Edit **/etc/systemd/system/node-exporter.service** with your favorite text editor. The contents should look like this:  

  
    [Unit]
    Description=Prometheus exporter for machine metrics
    
    [Service]
    Restart=always
    User=prometheus
    ExecStart=/usr/local/bin/node_exporter --collector.textfile.directory=/var/lib/prometheus/node-exporter
    ExecReload=/bin/kill -HUP $MAINPID
    TimeoutStopSec=20s
    SendSIGKILL=no
    
    [Install]
    WantedBy=multi-user.target  

We'll now need to reload the startup file and restart node exporter.  

    sudo systemctl daemon-reload  
    sudo systemctl restart node-exporter   

Your validator metrics should now be visible in the node-exporter data. You can view this using a browser or the curl command. Here is an example using curl:  
    `curl http://localhost:9100/metrics`  
    
