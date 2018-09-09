FROM openjdk:8-jdk-alpine AS nbx_server_build
LABEL maintainer="vyvakz@gmail.com"

# ----
# Install Maven
RUN apk add --no-cache curl tar bash
ARG MAVEN_VERSION=3.3.9
ARG USER_HOME_DIR="/root"
RUN mkdir -p /usr/share/maven && \
curl -fsSL http://apache.osuosl.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar -xzC /usr/share/maven --strip-components=1 && \
ln -s /usr/share/maven/bin/mvn /usr/bin/mvn
ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"
# speed up Maven JVM a bit
ENV MAVEN_OPTS="-XX:+TieredCompilation -XX:TieredStopAtLevel=1"
ENTRYPOINT ["/usr/bin/mvn"]
# ----
# Install project dependencies and keep sources
# make source folder
ENV NBX_HOME=/usr/local/nbx_server
RUN mkdir -p $NBX_HOME
WORKDIR $NBX_HOME
# install maven dependency packages (keep in image)
COPY pom.xml $NBX_HOME
# copy source files from host (keep in image)
COPY src $NBX_HOME/src
RUN mvn -T 1C clean package 
#ARG CACHEBUST=1
RUN pwd
RUN ls -ln $NBX_HOME/target 

#RUN cat $NBX_HOME/target/bin/webapp
#COPY --from=BUILD $NBX_HOME/target/nbx_server-1.0-SNAPSHOT.war .
#CMD ["sh", "target/bin/webapp"]
 
FROM openjdk:8-jre-alpine
# copy application WAR (with libraries inside)
# COPY target/spring-boot-*.war /app.war
ENV NBX_HOME=/usr/local/nbx_server
RUN mkdir -p $NBX_HOME
WORKDIR $NBX_HOME
COPY --from=nbx_server_build /usr/local/nbx_server/src/main/webapp /usr/local/nbx_server/src/main/webapp
COPY --from=nbx_server_build /usr/local/nbx_server/target /usr/local/nbx_server/target 
RUN ls -ln $NBX_HOME/src/main/webapp
EXPOSE 8080
CMD ["target/bin/webapp"]
#CMD ["/usr/bin/java","-jar","nbx_server.jar"]
# specify default command
#CMD ["/usr/bin/java", "-jar", "/opt/nbx_server/nbx_server.war"]
