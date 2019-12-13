FROM maven:slim as builder

RUN apt-get update \
 && apt-get install -y git \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /opt
RUN git clone https://github.com/zxing/zxing.git
WORKDIR /opt/zxing
RUN mvn install -Dmaven.javadoc.skip=true
WORKDIR /opt/zxing/javase
RUN mvn -DskipTests -Dmaven.javadoc.skip=true package assembly:single

FROM debian:buster-slim
RUN apt-get update \
 && mkdir -p /usr/share/man/man1 \
 && apt-get install -y \
    default-jre-headless \
    gawk \
    imagemagick \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /opt/dreamer
COPY --from=builder /opt/zxing/javase/target/javase-3.4.1-SNAPSHOT-jar-with-dependencies.jar zxing/javase/target/javase-3.4.1-SNAPSHOT-jar-with-dependencies.jar
COPY RECURSEDSHEEP_9b290bff-96d6-504f-becb-e9824ee71f0d.png .
COPY solve.sh .

ENTRYPOINT ["./solve.sh"]
CMD ["RECURSEDSHEEP_9b290bff-96d6-504f-becb-e9824ee71f0d.png"]