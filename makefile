# Copyright 2013, Zenoss, Inc
# All rights reserved.
#
# Licensed under a BSD-style license. See COPYING file.

TOP?=$(shell pwd)
SRC_DIR=${TOP}/src
BUILD_DIR=${TOP}/build
PROJECT_DIR=${BUILD_DIR}/perfstore
HBASE_VERSION=0.94.5
TMP?=/tmp
OPENTSDB_BRANCH=master
OPENTSDB_REPO=${TMP}/${USER}-opentsdb
OPENTSDB_TGZ=${BUILD_DIR}/opentsdb-latest.tgz

all: ${PROJECT_DIR}/conf/hbase-site.xml ${OPENTSDB_TGZ}

${PROJECT_DIR}/conf/hbase-site.xml: ${PROJECT_DIR} ${SRC_DIR}/hbase-site.xml.in
	@cd ${BUILD_DIR} && \
	echo -ne "Building default config of hbase..." && \
	grep "__ZENHOME__" ${SRC_DIR}/hbase-site.xml.in  >/dev/null || (echo "__ZENHOME__ not found in ${SRC_DIR}/hbase-site.xml.in" && exit 1) && \
	sed -e "s|__ZENHOME__|${ZENHOME}|g" ${SRC_DIR}/hbase-site.xml.in > ${PROJECT_DIR}/conf/hbase-site.xml || exit 1 && \
	touch $@ && \
	echo "done."

${PROJECT_DIR}: ${TMP}/${USER}-hbase-${HBASE_VERSION}.tar.gz ${BUILD_DIR}/opentsdb/build
	@cd ${BUILD_DIR} && \
	echo -ne "Extracting hbase..." && \
	tar xfz ${TMP}/${USER}-hbase-${HBASE_VERSION}.tar.gz && \
	mkdir -p ${PROJECT_DIR} && \
	cp -Rv hbase-${HBASE_VERSION}/* ${PROJECT_DIR}/ && \
	rm ${PROJECT_DIR}/conf/hbase-site.xml && \
	touch $@ && \
	echo "done."

${BUILD_DIR}/opentsdb/build: ${BUILD_DIR}/opentsdb

${BUILD_DIR}/opentsdb: ${OPENTSDB_TGZ}
	@mkdir -p $@ && \
	cd $@ && tar xfz ${OPENTSDB_TGZ} && \
	mkdir -p ${PROJECT_DIR} && \
	cd ${BUILD_DIR}/opentsdb && \
	./bootstrap && \
	mkdir -p build && \
	cd build && \
	../configure --prefix=${PROJECT_DIR} && \
	make && \
	make install

${OPENTSDB_TGZ}: ${OPENTSDB_REPO}
	echo -n "Updating opentsdb repo..." && \
	cd ${OPENTSDB_REPO} && \
	git pull 1>/dev/null && \
	echo "done." && \
	echo "Exporting opentsdb archive..." && \
	git archive ${OPENTSDB_BRANCH} | gzip > $@ && \
	tar tvfz $@ >/dev/null || (rm $@ && echo "ERROR: git export/archive failed.") && \
	echo "done." && \
	touch $@	

${OPENTSDB_REPO}:
	@cd ${BUILD_DIR} && \
	echo -ne "cloning opentsdb repo..." && \
	git clone git://github.com/OpenTSDB/opentsdb.git $@ >/dev/null && \
	touch $@ && \
	echo "done."

${TMP}/${USER}-hbase-${HBASE_VERSION}.tar.gz:
	@echo -ne "Downloading hbase..." && \
	wget http://www.apache.org/dist/hbase/hbase-${HBASE_VERSION}/hbase-${HBASE_VERSION}.tar.gz -O ${TMP}/${USER}-hbase-${HBASE_VERSION}.tar.gz && \
	tar ztvf $@ >/dev/null || (rm $@ && echo "ERROR: downloaded file did not decompress correctly.") && \
	touch $@ && \
	echo "done."




clean:
	rm -Rf build/* 

