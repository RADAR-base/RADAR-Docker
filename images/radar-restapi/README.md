## Dockerised RADAR-RestApi 

Create the docker image:
```
$ docker build -t radarcns/radar-restapi ./
```

Or pull from dockerhub:
```
$ docker pull radarcns/radar-restapi:latest 
```

Edit `radar.yml` and `device-catalog.yml`, and place them under `/path/to/config`

Run the docker image locally:
```
$ docker run -d -p 8080:8080 -v /path/to/config:/usr/local/tomcat/conf/radar --name radar-restapi radarcns/radar-restapi:0.1
```

The RestApi will be running at http://localhost:8080. To test them, access the [Swagger Documentation](http://localhost:8080/radar/api/swagger.json)

## Runtime environment variables  
