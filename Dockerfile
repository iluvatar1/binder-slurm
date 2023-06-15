FROM python:3.9-slim
#FROM continuumio/miniconda3:23.3.1-0
FROM jupyter/scipy-notebook:1fa0829d9ff9

USER root
WORKDIR /root

RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc python3-dev sudo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# install the notebook package
RUN pip install --no-cache --upgrade pip && \
    pip install --no-cache notebook jupyterlab

# Installing packages with apt.txt
COPY apt.txt .
RUN apt-get update && \
    apt-get install -y --no-install-recommends $(cat apt.txt) && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Running slurm setup script as root
#RUN echo localhost > /etc/hostname
COPY slurm_setup.sh .
RUN bash slurm_setup.sh

# create user with a home directory
ARG NB_USER
ARG NB_UID
ENV USER ${NB_USER}
ENV HOME /home/${NB_USER}

#RUN adduser --disabled-password \
RUN adduser \
    --gecos "Default user" \
    --uid ${NB_UID} \
    ${NB_USER} || true
RUN echo "${NB_USER}:${NB_USER}" | chpasswd
RUN echo "${NB_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/notebook


# Installing python env from environment.yml
WORKDIR ${HOME}
USER ${USER}

COPY environment.yml .
RUN conda env update -n base -f environment.yml && \
    conda clean --all -f -y

COPY postBuild .
RUN bash postBuild

COPY start_slurm.sh .

# # Launching jupyterlab
# USER ${NB_USER}
#CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]
#RUN jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root &
