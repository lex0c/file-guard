# File Guard

This script monitors specified events in a given file and provides log about the occurred event, including current network state.

## Prerequisites

- Ensure that `inotify-tools` is installed as it includes `/bin/inotifywait`.
- The script should be run on a system where the `/bin/lsof`, `/bin/ss` and `/bin/ps` command is available.

## Usage

Make `fguard.sh` executable:
```sh
chmod +x fguard.sh
```

Run:
```sh
./fguard.sh [file_to_monitor] [event1,event2,...]
```

- `[file_to_monitor]`: The file path you want to monitor.
- `[event1,event2,...]`: The events you want to watch, separated by commas without spaces.

### Example Output:

```sh
File ./foobar was opened at dom 22 out 2023 19:06:51 -03
Hostname: testpc
Processes interacting with the file:
COMMAND  PID USER   FD   TYPE DEVICE SIZE/OFF     NODE NAME
tail    1775  foo    3r   REG    8,1        0 12869135 ./foobar
Process Info for PID 1775:
UID          PID    PPID  C STIME TTY          TIME CMD
foo         1775    1679  0 19:06 pts/3    00:00:00 tail -f foobar
Connections established on the server:
Netid Recv-Q Send-Q         Local Address:Port Peer Address:PortProcess
udp   0      0      192.168.0.102%enp60s0:68    192.168.0.1:67  
```

## Events

- `ACCESS`
- `MODIFY`
- `OPEN`
- `CLOSE_WRITE`
- `MOVE_SELF`
- `DELETE_SELF`

## Customization

- The `notify()` function within the script can be customized to send notifications through various channels like email, messaging apps, or logging systems.

## Installation

**Change owner to root user:**

```sh
sudo chown root:root fguard.sh
sudo chmod 700 fguard.sh
sudo mv fguard.sh /root/
```

**Configure the script to run at system startup:**

### Using `systemd`:

Create service:
`sudo vim /etc/systemd/system/fguard.service`
```sh
[Unit]
Description=File monitor

[Service]
ExecStart=/root/fguard.sh /path/to/your/file ACCESS,MODIFY,OPEN,CLOSE_WRITE,MOVE_SELF,DELETE_SELF
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=default.target
```

Reload daemon:
```sh
sudo systemctl daemon-reload
```

Start service:
```sh
sudo systemctl start fguard.service
sudo systemctl enable fguard.service
```

Uninstall:
```sh
sudo systemctl stop fguard.service
sudo systemctl disable fguard.service
sudo rm /etc/systemd/system/fguard.service
sudo systemctl daemon-reload
sudo systemctl reset-failed # systemd maintains a crash counter, so reset it
```

**Disclaimer**: The fguard only monitors one file per execution, so to monitor others it is necessary to create a service for each file to be monitored.

### Using `crontab`

Open the root crontab:
```sh
sudo crontab -e
```

Add this line to run script at every reboot:
```sh
@reboot /root/fguard.sh /path/to/your/file ACCESS,MODIFY,OPEN,CLOSE_WRITE,MOVE_SELF,DELETE_SELF
```

