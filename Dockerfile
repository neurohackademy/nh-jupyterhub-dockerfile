FROM jupyter/datascience-notebook:8d22c86ed4d7

RUN jupyter labextension install @jupyterlab/hub-extension

RUN pip install nbgitpuller