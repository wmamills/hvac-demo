FROM debian:12

COPY container-main prj_script.sh /
RUN /container-main container_build
RUN rm /container-main /prj_script.sh

USER user
WORKDIR /home/user/hvac-demo
