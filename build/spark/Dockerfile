ARG JRE_VERSION=11-jre
FROM openjdk:${JRE_VERSION} AS base

LABEL org.opencontainers.image.title="Apache Spark 3.2.0 with python 3.8"
LABEL org.opencontainers.image.authors="angelmaroco@gmail.com"
LABEL org.opencontainers.image.url="angelmaroco/spark:3.2.0-hadoop-3.2-aws-sdk-1.12.132-python-3.8"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.base.name="openjdk:11-jre"

ARG SPARK_VERSION_DEFAULT=3.2.0
ARG HADOOP_VERSION_DEFAULT=3.2
ARG HADOOP_AWS_VERSION_DEFAULT=3.2.2
ARG AWS_SDK_BUNDLE_VERSION_DEFAULT=1.12.132

# Define ENV variables
ENV SPARK_VERSION=${SPARK_VERSION_DEFAULT}
ENV HADOOP_VERSION=${HADOOP_VERSION_DEFAULT}
ENV HADOOP_AWS_VERSION=${HADOOP_AWS_VERSION_DEFAULT}
ENV AWS_SDK_BUNDLE_VERSION=${AWS_SDK_BUNDLE_VERSION_DEFAULT}

RUN apt-get update \
    && apt-get install -y bash tini libc6 libpam-modules krb5-user libnss3 procps

FROM base AS spark-base

# Download and extract Spark
RUN curl -L https://downloads.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -o spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz \
    && tar -xvzf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz \
    && mv spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} /opt/spark \
    && rm spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz

COPY entrypoint.sh /opt/spark

RUN chmod a+x /opt/spark/entrypoint.sh

FROM spark-base AS sparkbuilder

# Set SPARK_HOME
ENV SPARK_HOME=/opt/spark

# Extend PATH environment variable
ENV PATH=${PATH}:${SPARK_HOME}/bin

# Create the application directory
RUN mkdir -p /app

FROM sparkbuilder AS spark-with-s3

# Download S3
RUN curl -L https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_AWS_VERSION}/hadoop-aws-${HADOOP_AWS_VERSION}.jar -o ${SPARK_HOME}/jars/hadoop-aws-${HADOOP_AWS_VERSION}.jar \
    && curl -L https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/${AWS_SDK_BUNDLE_VERSION}/aws-java-sdk-bundle-${AWS_SDK_BUNDLE_VERSION}.jar -o ${SPARK_HOME}/jars/aws-java-sdk-bundle-${AWS_SDK_BUNDLE_VERSION}.jar

FROM spark-with-s3 AS spark-with-python

ENV PYTHONPATH=$SPARK_HOME/python/:$PYTHONPATH

RUN apt-get update -y \
    && apt-get install -y python3 python3-pip \
    && pip3 install --upgrade pip setuptools \
    # Removed the .cache to save space
    && rm -r /root/.cache && rm -rf /var/cache/apt/*

WORKDIR /app

USER root

ENTRYPOINT [ "/opt/spark/entrypoint.sh" ]
