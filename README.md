# Aktos Network Manager

```commands
$ aktos-nm --help

    Connect to 'your-essid':

    	aktos-nm your-essid

    Add a new configuration:

    	aktos-nm --add foo --password 1234 [--name alias]

    --stop      : Disconnect and cleanup
    --search    : Search for available WiFi networks
    --list      : List available saved connections
    --status    : Show current connection status
    --3g        : Connect via 3g usb modem
```
    
# Install 

`aktos-nm` is designed to be used as a submodule. Create your network manager like so: 

```
git init network-manager
cd network-manager
git submodule add https://github.com/aktos-io/aktos-nm
git submodule update --init --recursive
cp aktos-nm/config.sh.sample ./config.sh
# edit ./config.sh accordingly 
./aktos-nm/install.sh

# Add ./aktos-nm/aktos-nm to your $PATH
echo "export PATH=\"$PWD/aktos-nm:\$PATH\"" | tee -a ~/.bashrc
```

# Features 
### Make current machine a gateway

    make-gateway --wan wlp2s0 --lan eth0 --ip 10.0.8.50
    # you should manually connect to the wlp2s0

### Run a command/script on ping loss:

    on-ping-loss command [arguments...]

### Run a command/script on cable detach:

    on-cable-detach command [arguments...]
    on-cable-detach renew-ip eth0

### Search 

    aktos-nm --search

    > to skip first line (column names): 
    > 
    >     aktos-nm --search | sed 1d
