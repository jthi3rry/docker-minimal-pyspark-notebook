FROM jupyter/minimal-notebook

USER root

# Oracle JDK
# Uses Ubuntu Xenial Repository for Debian as per instructions at
# http://www.webupd8.org/2014/03/how-to-install-oracle-java-8-in-debian.html
RUN apt-get remove -y --auto-remove openjdk* && \
    apt-get update && \
    apt-get install -y software-properties-common && \
    echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | tee /etc/apt/sources.list.d/webupd8team-java.list && \
    echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list  && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886 && \
    apt-get update && \
    echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections && \
    echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections && \
    sudo apt-get --no-install-recommends -y --force-yes install oracle-java8-installer oracle-java8-set-default && \
    rm -r /var/cache/oracle-jdk* && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Spark
RUN cd /tmp && \
    APACHE_SPARK_VERSION=2.0.0 && \
    HADOOP_VERSION=2.7 && \
    wget http://archive.apache.org/dist/spark/spark-${APACHE_SPARK_VERSION}/spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
    echo "3d46e990c06a362efc23683cf0ec15e1943c28e023e5b5d4e867c78591c937ad *spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" | sha256sum -c - && \
    tar xzf spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -C /usr/local && \
    rm spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
    cd /usr/local && ln -s spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} spark

# Mesos
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv E56151BF && \
    DISTRO=$(lsb_release -is | tr '[:upper:]' '[:lower:]') && \
    CODENAME=$(lsb_release -cs) && \
    echo "deb http://repos.mesosphere.io/${DISTRO} ${CODENAME} main" > /etc/apt/sources.list.d/mesosphere.list && \
    apt-get -y update && \
    apt-get --no-install-recommends -y --force-yes install mesos=1.0.1-2.0.93.debian81 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Elaticsearch Hadoop
RUN apt-get install -y unzip && \
    ELASTICSEARCH_HADOOP_VERSION=2.4.0 && \
    wget http://download.elastic.co/hadoop/elasticsearch-hadoop-${ELASTICSEARCH_HADOOP_VERSION}.zip && \
    unzip elasticsearch-hadoop-${ELASTICSEARCH_HADOOP_VERSION}.zip && \
    cp elasticsearch-hadoop-${ELASTICSEARCH_HADOOP_VERSION}/dist/elasticsearch-spark_2.11-${ELASTICSEARCH_HADOOP_VERSION}.jar /usr/local/spark/jars/ && \
    rm -rf elasticsearch-hadoop-${ELASTICSEARCH_HADOOP_VERSION} && \
    rm -rf elasticsearch-hadoop-${ELASTICSEARCH_HADOOP_VERSION}.zip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Hadoop AWS
RUN HADOOP_AWS_VERSION=2.7.2 && \
    AWS_JAVA_SDK_VERSION=1.7.4 && \
    wget http://central.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_AWS_VERSION}/hadoop-aws-${HADOOP_AWS_VERSION}.jar && \
    mv hadoop-aws-${HADOOP_AWS_VERSION}.jar /usr/local/spark/jars/ && \
    wget http://central.maven.org/maven2/com/amazonaws/aws-java-sdk/${AWS_JAVA_SDK_VERSION}/aws-java-sdk-${AWS_JAVA_SDK_VERSION}.jar && \
    mv aws-java-sdk-${AWS_JAVA_SDK_VERSION}.jar /usr/local/spark/jars/

# Spark and Mesos config
ENV SPARK_HOME /usr/local/spark
ENV PYTHONPATH $SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.1-src.zip
ENV MESOS_NATIVE_JAVA_LIBRARY /usr/local/lib/libmesos.so
ENV SPARK_OPTS --driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info

USER $NB_USER
