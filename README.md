# Lemvalstuff
Scripts, configs, and code for Lem Validators 

## monit configs
Note: While this monitoring will alert on various health issues on the server, if the server crashes, there is a good chance that no alerts will be generated. It would be a good idea to have another server running a monit host_check on your validator.

  #### Main configration file
  - **/etc/monit/monitrc**
     - This is the main configuration file for monit. The main part that needs to be modified in this file is email server configuration and email destination for alerting.
  #### Monitoring configuration file
  - **/etc/monit/conf-enabled/extraFS**
     - this will alert when /extra is > 90% full
  - **/etc/monit/conf-enabled/opera**
     - this will alert when the validator process is not running
  - **/etc/monit/conf-enabled/system**
     - this will alert when the system load is too high - memory, cpu, load, etc.
  - **/etc/monit/conf-enabled/host_check**
     - this is an optional file - it can ping other nodes on the network.
     - If you had multiple validators in the same network, this could be used for each one to check others.
