#!/bin/bash

/etc/init.d/nginx restart

# why kill then kill -9 ?
# so that a process has a chance to shut down politely and log its death
/usr/bin/pkill ruby
sleep 3
/usr/bin/pkill -9 ruby

