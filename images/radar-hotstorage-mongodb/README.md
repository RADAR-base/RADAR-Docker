# DockerisedRADAR-HotStorage

Upon the first start, this dockerised version of MongoDB 3.2.10 creates a db named `RADAR_DB` owned by user `RADAR_USER` with password `RADAR_PWD`.

Create the docker image:
```
$ docker build -t radarcns/radar-mongo ./
```

Or pull from dockerhub:
```
$ docker pull radarcns/radar-mongo:latest 
```

Run the docker image locally:
```
$ docker run -d -p 27017:27017 -p 28017:28017 --name radar-hotstorage radarcns/radar-mongo:latest -e RADAR_USER="restapi" -e RADAR_PWD="radar" -e RADAR_DB="hotstorage"
```

To test MongoDB, access the [Mongo Dashboard](http://localhost:28017)

## Runtime environment variables  

Environment variables used by the RestApi

```bash
# authentication flag for MongoDB
AUTH yes

# mongoDb user and password
RADAR_USER restapi
RADAR_PWD radar

# mongoDb database
RADAR_DB hotstorage
```