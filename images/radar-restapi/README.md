## Dockerised RADAR-RestApi 

Create the docker image:
```
$ docker build -t radarcns/radar-restapi ./
```

Or pull from dockerhub:
```
$ docker pull radarcns/radar-restapi:latest 
```

Run the docker image locally:
```
$ docker run -d -p 8080:8080 --name radar-restapi radarcns/radar-restapi:0.1
```

The RestApi will be running at http://localhost:8080. To test them, access the [Swagger Documentation](http://localhost:8080/radar/api/swagger.json)

## Runtime environment variables  

Environment variables used by the RestApi

```bash
# mongoDb user and password
MONGODB_USER='restapi'
MONGODB_PASS='radar'

# mongoDb database
MONGODB_DATABASE='hotstorage'

# mongoDb instance
MONGODB_HOST='localhost:27017'
```
