FROM ubuntu:rolling

ARG version

#install dependencies
RUN apt update && apt install -y git make cmake g++ libfreetype6-dev libjpeg-dev libpng-dev libssl-dev zlib1g-dev libgl1-mesa-glx  libglew-dev freeglut3-dev libxpm-dev

#add user legacyclonk
RUN adduser --disabled-password --gecos "" --home /home/legacyclonk legacyclonk
USER legacyclonk
ENV  USER=legacyclonk HOME=/home/legacyclonk

WORKDIR /home/legacyclonk

#prep folders
RUN mkdir /home/legacyclonk/data
RUN mkdir /home/legacyclonk/defaultdata

#compile LC with USE_CONSOLE flag, also make System.c4g and
RUN git clone --branch v${version} https://github.com/legacyclonk/LegacyClonk
WORKDIR /home/legacyclonk/LegacyClonk
RUN cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DUSE_CONSOLE=ON -DWITH_DEVELOPER_MODE=ON .
RUN make

#get clonk binaries, add them to PATH
RUN mv /home/legacyclonk/LegacyClonk/c4group /home/legacyclonk
RUN mv /home/legacyclonk/LegacyClonk/clonk /home/legacyclonk
ENV PATH=${PATH}:/home/legacyclonk

#make System.c4g and Graphics.c4g
WORKDIR /home/legacyclonk/defaultdata
ENV C4GROUP="/home/legacyclonk/c4group"
RUN /home/legacyclonk/LegacyClonk/tools/make_System.c4g.sh
RUN /home/legacyclonk/LegacyClonk/tools/make_Graphics.c4g.sh

#make clonk content
WORKDIR /home/legacyclonk
RUN git clone https://github.com/legacyclonk/content
WORKDIR /home/legacyclonk/content/
RUN make

#move content to defaultdata folder
WORKDIR /home/legacyclonk/
RUN find /home/legacyclonk/content/packed/ -name "*.c4g" -exec mv {} /home/legacyclonk/defaultdata \;
RUN find /home/legacyclonk/content/packed/ -name "*.c4d" -exec mv {} /home/legacyclonk/defaultdata \;
RUN find /home/legacyclonk/content/packed/ -name "*.c4f" -exec mv {} /home/legacyclonk/defaultdata \;

#create config by letting clonk crash, found no better way yet
RUN touch /home/legacyclonk/defaultdata/config
RUN ./clonk /console /config:"/home/legacyclonk/defaultdata/config" noscen.c4s; exit 0

#setup config
RUN sed -i -- 's:DefinitionPath="":DefinitionPath="/home/legacyclonk/data/":g' /home/legacyclonk/defaultdata/config
RUN sed -i -- 's:UserPath="\$HOME/\.legacyclonk":UserPath="/home/legacyclonk/data/\.legacyclonk":g' /home/legacyclonk/defaultdata/config

#cleanup
RUN rm -rf /home/legacyclonk/LegacyClonk
RUN rm -rf /home/legacyclonk/content

#set workdir
WORKDIR /home/legacyclonk/data/

#setup entrypoint
COPY entrypoint.sh /home/legacyclonk/
ENTRYPOINT /home/legacyclonk/entrypoint.sh $*

EXPOSE 11111/tcp
EXPOSE 11112/tcp
EXPOSE 11113/udp
EXPOSE 11114/tcp