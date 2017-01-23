FROM confluentinc/cp-kafka:3.1.1

# Update aptitude with new repo
RUN apt-get update

# Install jq to parse JSON
RUN apt-get install -y jq

# Copy bash file
COPY ./topic_init.sh /home/
RUN chmod +x /home/topic_init.sh

CMD ["./home/topic_init.sh", "shutdown -h now"]