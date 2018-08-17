# Aktos Network Manager

    aktos-nm [--help]

# Make current machine a gateway

    make-gateway --wan wlp2s0 --lan eth0 --ip 10.0.8.50
    # you should manually connect to the wlp2s0

# Run a command/script on ping loss:

    on-ping-loss command [arguments...]

# Run a command/script on cable detach:

    on-cable-detach command [arguments...]
