# docker_scripts  

Some personal docker scripts I use in my daily life  

## Examples  

### Run a graphical APP in a docker container on a remote server via ssh x11 forwarding:  

1. connect to the server via ssh with x11 forwarding enabled:  

```console
ssh -X <remote_server>  
```

2. start the docker container with:  
    --net=host (shares network with host),  
    --hostname $(hostname) (sets docker hostname same as the host)  
    -v /home/$USER/.Xauthority:/home/$USER/.Xauthority  (maps .Xauthority into docker container, which is also needed)  
```console
./docker_start_with_x.sh -i ubuntu14_04:1 -u $USER -o "--net=host --hostname $(hostname) -v /home/$USER/.Xauthority:/home/$USER/.Xauthority -v /home/$USER/:/working_dir" --rm  
```

3. You should now be able to run X apps from the docker container and they will be displayed on the client which is connected via ssh. 

## Notes: 
### Sound via ALSA
Sound via alsa should work if you specify the ALSA_CARD environment variable (here Generic):
```console
ALSA_CARD=Generic speaker-test
```

If your application uses pulse you can fake pulse via the apulse tool (needs to be installed of course):
```console
ALSA_CARD=Generic apulse retroarch
```

However when using ALSA only one application can use the audio device at a time, otherwise it reports an error "Device busy".

### Mount devices into an already running container
Note: I think this only works when the container was started with "--privileged"

Example with blackmagic debug probe: (/dev/ttyACM0 and /dev/ttyACM1)
1. Start the container with the device unplugged
2. When container is started plug the device
3. Check that the devices ttyACM0 and ttyACM1 were created, they do not appear in the container
4. check the device nodes on the host with:
    ```console
    ls -la /dev/ttyACM*
    ```

    output will be something like:
    ```console
    crw-rw----+ 1 root dialout 166, 0 Dec 24 08:31 /dev/ttyACM0
    crw-rw----+ 1 root dialout 166, 1 Dec 24 08:31 /dev/ttyACM1
    ```
5. Create the device in the container using mknod accordingly
    ```console
    sudo mknod /dev/ttyACM0 c 166 0
    sudo mknod /dev/ttyACM1 c 166 1
    ```

Devices should now be usable within the container.

Resources:  
http://wangkejie.me/2018/01/08/remote-gui-app-in-docker/  
https://blog.yadutaf.fr/2017/09/10/running-a-graphical-app-in-a-docker-container-on-a-remote-server/  
