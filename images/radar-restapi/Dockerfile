# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


FROM tomcat:8.0.37

MAINTAINER @fnobilia, @afolarin

LABEL description="RADAR-CNS Rest Api docker container"

RUN mkdir /usr/local/tomcat/conf/radar

# Install Rest API
RUN echo && echo "==> Installing Components" \
    # Download Git RestApi release
    && echo "==> Downloading RADAR-CNS/RADAR-RestApi v0.1-beta.1 release from GitHub" \
    && cd /usr/local && mkdir RADAR-RestApi && cd /usr/local/RADAR-RestApi \
    && wget https://github.com/RADAR-CNS/RADAR-RestApi/releases/download/v0.1-beta.1/radar.war \
    # Deploy the war
    && echo "==> Deploying the WAR" \
    && cp /usr/local/RADAR-RestApi/radar.war /usr/local/tomcat/webapps/ \
    # Remove repository
    && echo "==> Cleaning up" \
    && cd /usr/local && rm -R /usr/local/RADAR-RestApi \
    # Create config folder
    && echo "==> Creating config folder" \
    && mkdir /usr/local/tomcat/conf/radar \
    && echo 

EXPOSE 8080

CMD ["catalina.sh", "run"]