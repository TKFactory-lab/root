rfp scheduler

This folder contains scripts used by the rfp_scheduler service.

cron-entrypoint.sh: simple loop that runs notify_rfps.rb and process_rfps.rb once on start and then every hour.

To enable scheduler in docker-compose, the project defines a service `rfp_scheduler` which mounts this folder and runs the entrypoint.

Logs are written to /tmp in the container and are mapped to ./log on the host.
