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

Resources:  
http://wangkejie.me/2018/01/08/remote-gui-app-in-docker/  
https://blog.yadutaf.fr/2017/09/10/running-a-graphical-app-in-a-docker-container-on-a-remote-server/  
