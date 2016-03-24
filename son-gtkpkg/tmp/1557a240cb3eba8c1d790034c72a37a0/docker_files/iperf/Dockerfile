FROM      ubuntu
MAINTAINER iMinds

RUN apt-get update && apt-get install -y \
	mz \
	iperf


ADD start.sh start.sh
RUN chmod +x start.sh

CMD ./start.sh

#CMD /bin/bash