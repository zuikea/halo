# Build jar
FROM gradle:6.9.0-jdk11 AS build-env
WORKDIR /application
ADD --chown=gradle:gradle . /application
RUN gradle build -x test --info;
    

FROM eclipse-temurin:11-jre as builder
WORKDIR /application
#ARG VERSION=SNAPSHOT
#ARG JAR_FILE=/application/build/libs/*${VERSION}.jar
ARG JAR_FILE=/application/build/libs/*.jar
COPY --from=build-env ${JAR_FILE}  application.jar
RUN  java -Djarmode=layertools -jar application.jar extract

FROM adoptopenjdk:11-jre-hotspot
MAINTAINER johnniang <johnniang@fastmail.com>
WORKDIR /application
COPY --from=builder application/dependencies/ ./
COPY --from=builder application/spring-boot-loader/ ./
COPY --from=builder application/snapshot-dependencies/ ./
COPY --from=builder application/application/ ./

# JVM_XMS and JVM_XMX configs deprecated for removal in halov1.4.4
ENV JVM_XMS="256m" \
    JVM_XMX="256m" \
    JVM_OPTS="-Xmx256m -Xms256m" \
    TZ=Asia/Shanghai

RUN ln -sf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone

ENTRYPOINT java -Xms${JVM_XMS} -Xmx${JVM_XMX} ${JVM_OPTS} -Djava.security.egd=file:/dev/./urandom org.springframework.boot.loader.JarLauncher
