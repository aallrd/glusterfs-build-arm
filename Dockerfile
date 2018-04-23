FROM aallrd/glusterfs-build-container as builder
ARG GLUSTERFS_VERSION
ENV GLUSTERFS_VERSION ${GLUSTERFS_VERSION:-4.0}
RUN git clone https://github.com/gluster/glusterfs.git \
  && cd glusterfs \
  && git checkout release-${GLUSTERFS_VERSION} \
  && ./autogen.sh \
  && ./configure \
  && make -j4 \
  && make install \
  && cd extras/LinuxRPM \
  && make glusterrpms \
  && mkdir /rpms \
  && mv *.rpm /rpms

FROM golang:latest
ARG GITHUB_TOKEN
ENV GITHUB_TOKEN ${GITHUB_TOKEN:-}
RUN go get -u github.com/tcnksm/ghr
COPY --from=builder /rpms .
RUN tar -czf glusterfs-rpms-$(uname -m).tar.gz ./* \
  && ghr -replace -u aallrd -r glusterfs-build-rpms 4.0-centos-7 .
