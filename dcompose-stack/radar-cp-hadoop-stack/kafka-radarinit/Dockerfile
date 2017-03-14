FROM confluentinc/cp-kafka:3.1.2-1

# Copy bash file
COPY ./topic_init.sh /home/
RUN chmod +x /home/topic_init.sh

CMD ["./home/topic_init.sh", "shutdown -h now"]
