# ARCHIVED

I was too young and this turns out to be stupid. A better practice should be using reverse proxy.

# Original README of this fork

The `Dockerfile` and scripts of this repo enable HTTPS in dockerized [librespeed/speedtest](https://github.com/librespeed/speedtest)

Build the image:

```shell
docker build -t my-speedtest .
```

Run an instance:

1. Linux CLI, bridged

    ```shell
    docker run -d \
        --name speedtest-tls \
        -e TITLE=<your title> \
        -v <host certificate path>:/etc/apache2/certificate \
        -p 8443:8443 \
        my-speedtest
    ```

2. Linux CLI, host network

    ```shell
    docker run -d \
        --name speedtest-tls \
        -e TITLE=<your title> \
        -v <host certificate path>:/etc/apache2/certificate \
        --network host \
        my-speedtest
    ```

3. Synology DSM UI
    - Advanced Settings
        - [x] Enable auto-restart
        - [x] Create shortcut on desktop
    - Volume: mount your certificate folder to `/etc/apache2/`
    - Network:
        - [x] Use the same network as Docker Host
    - Environment: set `TITLE`

4. PowerShell

    ```powershell
    docker run -d `
        --name speedtest-tls `
        -e TITLE=<your title> `
        -v <host certificate path>:/etc/apache2/certificate `
        -p 8443:8443 `
        my-speedtest
    ```
