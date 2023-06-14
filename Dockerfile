FROM python:3.9-slim
# install the notebook package
RUN pip install --no-cache --upgrade pip && \
    pip install --no-cache notebook jupyterlab

# create user with a home directory
ARG NB_USER
ARG NB_UID
ENV USER ${NB_USER}
ENV HOME /home/${NB_USER}

RUN adduser --disabled-password \
    --gecos "Default user" \
    --uid ${NB_UID} \
    ${NB_USER}
WORKDIR ${HOME}
USER ${USER}

# Installing packages with apt.txt
USER root
COPY apt.txt .
RUN apt-get update && \
    apt-get install -y --no-install-recommends $(cat apt.txt) && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Installing python env from environment.yml
USER ${NB_USER}
COPY environment.yml .
RUN conda env update -n base -f environment.yml && \
    conda clean --all -f -y

# Running postBuild commands
USER ${NB_USER}
COPY postBuild .
RUN bash postBuild

# Running slurm setup script as root
USER root
COPY slurm_setup.sh .
RUN bash slurm_setup.sh

# Launching jupyterlab
USER ${NB_USER}
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]
