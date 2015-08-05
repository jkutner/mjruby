FROM hone/mruby-cli

# Install the JDK
RUN mkdir -p /home/jdk
ENV JAVA_HOME /home/jdk
RUN curl -s --retry 3 -L https://lang-jvm.s3.amazonaws.com/jdk/cedar-14/openjdk1.8-latest.tar.gz | tar xz -C /home/jdk
ENV PATH /home/jdk/bin:$PATH

ENV CFLAGS "-I/home/jdk/include -I/home/jdk/include/linux"
ENV LD_LIBRARY_PATH "/home/jdk/jre/lib/amd64/server"
ENV LDFLAGS "-ldl"
