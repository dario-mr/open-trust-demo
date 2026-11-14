# Build: --build-arg VARIANT=vulnerable adds log4j-core 2.14.1 (demo of a failing assessment).
ARG RUNTIME=gcr.io/distroless/java21-debian12:nonroot@sha256:7e37784d94dccbf5ccb195c73b295f5ad00cd266512dfbac12eb9c3c28f8077d

FROM maven:3.9-eclipse-temurin-21@sha256:99e61abcff91a9b1333463bd8451fb18495d6eba9250ac66a338b518f8278320 AS build
ARG VARIANT=clean
WORKDIR /src
COPY pom.xml .
COPY src src
RUN mvn -q -B -ntp package -DskipTests $([ "$VARIANT" = vulnerable ] && echo -Pvulnerable)

FROM ${RUNTIME}
COPY --from=build /src/target/app.jar /app/app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
