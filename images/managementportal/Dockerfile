FROM openjdk:8-jre-alpine

ENV SPRING_OUTPUT_ANSI_ENABLED=ALWAYS \
    JHIPSTER_SLEEP=0

# add directly the war
ADD https://github.com/RADAR-CNS/ManagementPortal/releases/download/v0.1-alpha/management-portal-0.0.1-SNAPSHOT.war /app.war

VOLUME /tmp
EXPOSE 8080 5701/udp
VOLUME /changelogs
CMD echo "The application will start in ${JHIPSTER_SLEEP}s..." && \
    sleep ${JHIPSTER_SLEEP} && \
    java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -cp /changelogs:/app.war org.springframework.boot.loader.WarLauncher
