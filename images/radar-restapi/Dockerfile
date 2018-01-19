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


FROM tomcat:8.0.44-jre8

ENV JAVA_OPTS=-Djava.security.egd=file:/dev/urandom

MAINTAINER @fnobilia, @afolarin

LABEL description="RADAR-CNS Rest Api docker container"

# Install Rest API
ADD https://github.com/RADAR-CNS/RADAR-RestApi/releases/download/v0.1.1/radar-0.1.1.war /usr/local/tomcat/webapps/radar.war

EXPOSE 8080

CMD ["catalina.sh", "run"]
