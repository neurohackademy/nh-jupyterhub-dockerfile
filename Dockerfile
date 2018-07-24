FROM jupyter/datascience-notebook:8d22c86ed4d7

ARG JUPYTERLAB_VERSION=0.31.12
RUN     pip install jupyterlab==$JUPYTERLAB_VERSION \
    &&  jupyter labextension install @jupyterlab/hub-extension
