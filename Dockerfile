FROM hone/mruby-cli

# Install the JDK
RUN apt-get update -y
RUN apt-get install openjdk-7-jdk -y
ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64

ENV CFLAGS "-I/usr/lib/jvm/java-7-openjdk-amd64/include -I/usr/lib/jvm/java-7-openjdk-amd64/include/linux"
ENV LD_LIBRARY_PATH "/usr/lib/jvm/java-7-openjdk-amd64/jre/lib/amd64/server"

# Install JRuby (for testing)
RUN mkdir -p /app/.jruby
ENV JRUBY_HOME /app/.jruby
RUN curl -s --retry 3 -L https://s3.amazonaws.com/jruby.org/downloads/9.0.0.0/jruby-bin-9.0.0.0.tar.gz | tar xz -C /app/.jruby --strip-components=1
ENV PATH /app/.jruby/bin:$PATH

# For mtest only
RUN mkdir -p /opt/jdk/bin
RUN mkdir -p /opt/jdk/jre/lib/amd64/server
RUN mkdir -p /opt/jdk/jre/lib/amd64/client
RUN touch /opt/jdk/bin/java
RUN touch /opt/jdk/bin/jdb
RUN touch /opt/jdk/jre/lib/amd64/server/libjvm.so
RUN touch /opt/jdk/jre/lib/amd64/client/libjvm.so
RUN mkdir -p /opt/jre/bin
RUN mkdir -p /opt/jre/lib/amd64/client
RUN touch /opt/jre/bin/java
RUN touch /opt/jre/lib/amd64/client/libjvm.so
