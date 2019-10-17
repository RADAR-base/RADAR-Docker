# Migrating from ManagementPortal:0.5.3 to higher versions

If you are setting up a new environment of RADAR-Base using RADAR-Docker, we highly recommend to use `radarbase/management-portal:0.5.5` or higher with `radarbase/radar-gateway:0.3.8` or higher.
If you are using this version of RADAR-Docker, then these versions are packaged and should work with current configurations.

## Background
`radarbase/management-portal::0.5.4` or higher has important security dependency upgrades. During this upgrades we have also improved how we verify JWT tokens.
Current method complies to the standards of OpenID connect to share valid public-keys of tokens using `/oauth/token_key` endpoint. 

Verifying components can use the latest `'org.radarcns:radar-auth:0.5.7'` library to use these features to verify tokens.
This enables ManagementPortal to be the single point of truth to validate token signatures.
 
By default, the `/oauth/token_key` endpoint will share all public-keys added to the keystore mounted to ManagementPortal service.

If you wish to add additional public-keys or use older public-keys, then the user should move existing `radar-is.yml` from `etc/gateway` to `etc/managementportal/config` to enable ManagementPortal to still support old public-keys.
This can also be automatically done by running `bin/keystore-init`. This will regenerate the public-keys and create the file at the correct location.

You should also perform an additional change to explicitly state to use additional public-keys from radar-is.yml.
This can be done by adding these two environment variables
    ```
    MANAGEMENTPORTAL_OAUTH_ENABLE_PUBLIC_KEY_VERIFIERS: "true"
    RADAR_IS_CONFIG_LOCATION: /mp-includes/config/radar-is.yml
    ``` 

## Migrating from ManagementPortal:0.5.3 to higher
If you already have an environment where you are using ManagementPortal:0.5.3 or lower and wish to upgrade to higher versions, please follow these steps.

**Please make a back-up of the `etc/gateway/radar-is.yml` before modifying the environment.**
 
1. Upgrade your environment to latest RADAR-Docker.
2. Move existing radar-is.yml from `etc/gateway/radar-is.yml` to `etc/managementportal/config/radar-is.yml`. 
3. Modify the `resourceName` of `etc/managementportal/config/radar-is.yml` to `res_ManagementPortal`
4. Modify service definition of `managementportal-app` on your `docker-compose.yml`

    4.1 Add these two environment variables to your `docker-copmose.yml`
        MANAGEMENTPORTAL_OAUTH_ENABLE_PUBLIC_KEY_VERIFIERS: "true"
        RADAR_IS_CONFIG_LOCATION: /mp-includes/config/radar-is.yml
        
    Your `managementportal-app` service definition would look like below in your `docker-compose.yml`
    
    ```yaml
          #---------------------------------------------------------------------------#
          # Management Portal                                                         #
          #---------------------------------------------------------------------------#
          managementportal-app:
            image: radarbase/management-portal:0.5.6
            networks:
              - default
              - api
              - management
              - mail
            depends_on:
              - radarbase-postgresql
              - smtp
              - catalog-server
            environment:
              SPRING_PROFILES_ACTIVE: prod,swagger
              SPRING_DATASOURCE_URL: jdbc:postgresql://radarbase-postgresql:5432/managementportal
              SPRING_DATASOURCE_USERNAME: ${POSTGRES_USER}
              SPRING_DATASOURCE_PASSWORD: ${POSTGRES_PASSWORD}
              MANAGEMENTPORTAL_MAIL_FROM: ${FROM_EMAIL}
              MANAGEMENTPORTAL_COMMON_BASEURL: https://${SERVER_NAME}
              MANAGEMENTPORTAL_COMMON_MANAGEMENT_PORTAL_BASE_URL: https://${SERVER_NAME}/managementportal
              MANAGEMENTPORTAL_FRONTEND_CLIENT_SECRET: ${MANAGEMENTPORTAL_FRONTEND_CLIENT_SECRET}
              MANAGEMENTPORTAL_OAUTH_CLIENTS_FILE: /mp-includes/config/oauth_client_details.csv
              MANAGEMENTPORTAL_CATALOGUE_SERVER_ENABLE_AUTO_IMPORT: ${MANAGEMENTPORTAL_CATALOGUE_SERVER_ENABLE_AUTO_IMPORT}
              MANAGEMENTPORTAL_CATALOGUE_SERVER_SERVER_URL: http://catalog-server:9010/source-types
              MANAGEMENTPORTAL_COMMON_ADMIN_PASSWORD: ${MANAGEMENTPORTAL_COMMON_ADMIN_PASSWORD}
              MANAGEMENTPORTAL_COMMON_PRIVACY_POLICY_URL: ${MANAGEMENTPORTAL_COMMON_PRIVACY_POLICY_URL}
              MANAGEMENTPORTAL_OAUTH_META_TOKEN_TIMEOUT: PT2H
              MANAGEMENTPORTAL_OAUTH_ENABLE_PUBLIC_KEY_VERIFIERS: "true"
              RADAR_IS_CONFIG_LOCATION: /mp-includes/config/radar-is.yml
              MANAGEMENTPORTAL_COMMON_ACTIVATION_KEY_TIMEOUT_IN_SECONDS: 172800
              SPRING_APPLICATION_JSON: '{"managementportal":{"oauth":{"checkingKeyAliases":["${MANAGEMENTPORTAL_OAUTH_CHECKING_KEY_ALIASES_0}","${MANAGEMENTPORTAL_OAUTH_CHECKING_KEY_ALIASES_1}"]}}}'
              JHIPSTER_SLEEP: 10 # gives time for the database to boot before the application
              JAVA_OPTS: -Xms256m -Xmx512m # maximum heap size for the JVM running ManagementPortal, increase this as necessary
            volumes:
              - ./etc/managementportal/:/mp-includes/
            healthcheck:
              test: ["CMD", "wget", "--spider", "localhost:8080/managementportal/oauth/token_key"]
              interval: 1m30s
              timeout: 5s
              retries: 3
    ```

5. Modify service definition of `gateway` in your `docker-compose.yml` as follows
    5.1   Remove `RADAR_IS_CONFIG_LOCATION` environment variable from gateway definition.
    
    Your `gateway` definiton on `docker-compose.yml` may look like below.
    ```yaml

      #---------------------------------------------------------------------------#
      # RADAR Gateway                                                             #
      #---------------------------------------------------------------------------#
      gateway:
        image: radarbase/radar-gateway:dev
        networks:
          - api
          - kafka
        depends_on:
          - rest-proxy-1
        volumes:
          - ./etc/gateway:/etc/radar-gateway
        command: ["radar-gateway", "/etc/radar-gateway/gateway.yml"]
        healthcheck:
          # should give an unauthenticated response, rather than a 404
          test: ["CMD-SHELL", "curl -I localhost/radar-gateway/topics 2>&1 | grep -q 401 || exit 1"]
          interval: 1m30s
          timeout: 5s
          retries: 3

    ```
6. Restart both services.
    `bin/radar-docker restart managementportal-app gateway`

    
        