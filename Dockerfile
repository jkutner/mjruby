FROM hone/mruby-cli

# Install the JDK
RUN mkdir -p /usr/lib/jvm/java-8-openjdk-amd64
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
RUN curl -s --retry 3 -L https://lang-jvm.s3.amazonaws.com/jdk/cedar-14/openjdk1.8-latest.tar.gz | tar xz -C /usr/lib/jvm/java-8-openjdk-amd64
ENV PATH /usr/lib/jvm/java-8-openjdk-amd64/bin:$PATH
RUN ln -s /usr/lib/jvm/java-8-openjdk-amd64/bin/java /usr/bin/java

# Install JRuby (for testing)
RUN mkdir -p /app/.jruby
ENV JRUBY_HOME /app/.jruby
RUN curl -s --retry 3 -L https://heroku-buildpack-ruby.s3.amazonaws.com/cedar-14/ruby-2.2.2-jruby-9.0.0.0.tgz | tar xz -C /app/.jruby
ENV PATH /app/.jruby/bin:$PATH

ENV CFLAGS "-I/usr/lib/jvm/java-8-openjdk-amd64/include -I/usr/lib/jvm/java-8-openjdk-amd64/include/linux"
ENV LD_LIBRARY_PATH "/usr/lib/jvm/java-8-openjdk-amd64/jre/lib/amd64/server"
