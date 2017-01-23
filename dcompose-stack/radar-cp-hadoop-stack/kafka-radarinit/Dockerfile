FROM confluentinc/cp-kafka:3.1.1

COPY ./topic_init.sh /home/

RUN chmod +x /home/topic_init.sh

CMD ["/etc/confluent/docker/run", "./home/topic_init.sh", "shutdown -h now"]
