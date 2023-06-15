#!/usr/bin/env sh

sudo service munge start
sudo service slurmd start
sudo service slurmctld start

# Reset state and show info
sudo scontrol update nodename=localhost state=IDLE
sinfo --all
