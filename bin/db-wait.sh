#!/bin/sh

host=$(printf "%s\n" "$1"| cut -d : -f 1)
port=$(printf "%s\n" "$1"| cut -d : -f 2)

shift 1

echo "silently waiting for $host:$port"
while ! nc -z "$host" "$port"
do
  sleep 1
done

# Reset the PATH environment variable
`echo "export PATH='/usr/local/bundle/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'"`

exec "$@"