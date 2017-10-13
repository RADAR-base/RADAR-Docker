FROM mongo:3.2.10

COPY ["./init.sh", "./db_init.sh", "./"]

RUN chmod +x init.sh && chmod +x db_init.sh

EXPOSE 27017
EXPOSE 28017

CMD ["./init.sh"]