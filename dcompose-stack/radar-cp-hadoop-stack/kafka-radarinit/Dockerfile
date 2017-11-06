FROM confluentinc/cp-kafka:3.2.1-5

# Copy bash file
COPY ./topic_init.sh /
RUN chmod +x /topic_init.sh

CMD ["/topic_init.sh", "shutdown -h now"]
