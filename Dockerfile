FROM centos:centos7
MAINTAINER ZhiHaoPlus,proea_00@163.com
# installation 
RUN	yum update  -y && yum upgrade -y &&  \
	yum install -y wget git curl curl-devel gcc zsh tar bzip2 gcc-c++ readline-devel gmp-devel \
	gcc-gfortran cmake zlib zlib-devel mysql mysql-devel libpng libpng12 libpng-devel libtiff libtiff-devel libjpeg \
	libjpeg-devel openssh-clients  boost boost-devel && \
	yum clean all && rm -rf /tmp/* /var/tmp/*
# miniconda3
WORKDIR /tmp
#
RUN wget https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-4.5.4-Linux-x86_64.sh 
RUN	bash ./Miniconda3-4.5.4-Linux-x86_64.sh -b -p /opt/miniconda3
# Setting environment variables
ENV PATH=/opt/miniconda3/bin:$PATH
# Use Tsinghua's source
RUN conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/ && \
    conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r/ && \
    conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/mro/ && \
    conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/ && \
	conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge/ && \
    conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/bioconda/ && \
	conda config --set show_channel_urls yes
# install software
RUN conda install perl -y
RUN conda install seqprep=1.3.2 -y
RUN conda install fastqc=0.11.8 -y
RUN conda install bowtie2=2.3.4 -y
RUN conda install samtools=1.9 -y
# username
RUN adduser -g games nextgen
USER nextgen
WORKDIR /home/nextgen
# copy files and scripts
RUN mkdir -p ./data/fastq ./data/fasta ./data/scripts ./source ./tools
ADD <src> /home/nextgen/tools/
ADD <src> /home/nextgen/tools/
ADD <src> /home/nextgen/
ADD <src> /home/nextgen/
ADD <src> <dest>
ADD <src> <dest>

