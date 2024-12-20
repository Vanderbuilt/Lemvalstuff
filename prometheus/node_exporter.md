### Setup Node Exporter to grab Validator Metrics

Install Node Exporter first - I followed these instructions: https://linuxhint.com/install-prometheus-on-ubuntu/

Add this to crontab - run: 
   ```crontab -e```
   ```*/5 * * * * /home/ubuntu/scripts/promValStats.sh > /var/lib/prometheus/node-exporter/valStats.prom```

Copy the promValStats.sh script to the /home/ubuntu/scripts directory and make sure it has executable permissions
   ```chmod +x /home/ubuntu/scripts/promValStats.sh```



    
Next we'll need to tell node-exporter to export in text files.
Edit */etc/systemd/system/node-exporter.service* with your favorite text editor
