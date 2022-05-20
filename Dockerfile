# Build jar
# FROM gradle:6.9.0-jdk11 AS build-env
# WORKDIR /application
# ADD --chown=gradle:gradle . /application
# RUN gradle build -x test --info;
# RUN mkdir build/libs; \
#    wget https://github.com/halo-dev/halo/releases/download/v1.5.3/halo-1.5.3.jar;
RUN \
    mkdir /build; \
    cd /build; \
    mkdir /libs; \
    wget https://github.com/halo-dev/halo/releases/download/v1.5.3/halo-1.5.3.jar; 
    
    
FROM adoptopenjdk:11-jre-hotspot as builder
WORKDIR /application

COPY  /build/libs/*.jar application.jar
RUN java -Djarmode=layertools -jar application.jar extract

################################

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
