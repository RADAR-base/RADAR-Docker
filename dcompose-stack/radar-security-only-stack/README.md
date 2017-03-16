# RADAR-CNS Security Platform

This is a dedicated component stack, to get started with security implementation of `RADAR-CNS`.
The `docker-compose` includes `radar-rest-api`, `hotstorage` and `wso2-identity-server` which communicate via 'api' network.

This `docker-compose` reuses a subset of [compose-wso2](https://github.com/ihcsim/compose-wso2).
### Usage
1. Modify `.env` file to configure your persistent-storage
2. Start `docker-compose`
```shell
sudo docker-compose up -d
```

3. Identity Server can be accessed via `https://localhost:9443/carbon`. Note: You may need to add certificate for this URL.


