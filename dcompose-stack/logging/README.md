# Docker logging with Graylog2

This directory sets up a graylog2 instance that docker can stream data to.

## Usage

Set up this container by moving `graylog.env.template` to `graylog.env` and editing it. See instructions inside the `graylog.env.template` on how to set each variable.

Start the logging container with
```shell
sudo docker-compose up -d
```
On macOS, omit `sudo` in the command above.

Then go to the [Graylog dashboard](http://localhost:9000). Log in with your chosen password, and navigate to `System -> Inputs`. Choose `GELF UDP` as a source and click `Launch new input`. Set the option to allow Global logs, and name the input `RADAR-Docker`. Now your Graylog instance is ready to collect data from docker on the host it is running on, using the GELF driver with URL `udp://localhost:12201` (replace `localhost` with the hostname where the Graylog is running, if needed).

Now, other docker containers can be configured to use the `gelf` log driver. In a docker-compose file, add the following lines to a service to let it use Graylog:
```yaml
logging:
  driver: gelf
  options:
    gelf-address: udp://localhost:12201
```
Now all docker logs of that service will be forwarded to Graylog
