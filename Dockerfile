FROM jupyter/datascience-notebook:8d22c86ed4d7



RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           convert3d \
           ants \
           fsl \
           gcc \
           g++ \
           graphviz \
           tree \
           git-annex-standalone \
           vim \
           emacs-nox \
           nano \
           less \
           ncdu \
           tig \
           git-annex-remote-rclone \
           octave \
           netbase \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN sed -i '$isource /etc/fsl/fsl.sh' $ND_ENTRYPOINT

ENV FORCE_SPMMCR="1" \
    LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/lib/x86_64-linux-gnu:/opt/matlabmcr-2018a/v94/runtime/glnxa64:/opt/matlabmcr-2018a/v94/bin/glnxa64:/opt/matlabmcr-2018a/v94/sys/os/glnxa64:/opt/matlabmcr-2018a/v94/extern/bin/glnxa64" \
    MATLABCMD="/opt/matlabmcr-2018a/v94/toolbox/matlab"
RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           bc \
           libxext6 \
           libxpm-dev \
           libxt6 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && echo "Downloading MATLAB Compiler Runtime ..." \
    && curl -fsSL --retry 5 -o /tmp/mcr.zip https://ssd.mathworks.com/supportfiles/downloads/R2018a/deployment_files/R2018a/installers/glnxa64/MCR_R2018a_glnxa64_installer.zip \
    && unzip -q /tmp/mcr.zip -d /tmp/mcrtmp \
    && /tmp/mcrtmp/install -destinationFolder /opt/matlabmcr-2018a -mode silent -agreeToLicense yes \
    && rm -rf /tmp/* \
    && echo "Downloading standalone SPM ..." \
    && curl -fsSL --retry 5 -o /tmp/spm12.zip http://www.fil.ion.ucl.ac.uk/spm/download/restricted/utopia/dev/spm12_latest_Linux_R2018a.zip \
    && unzip -q /tmp/spm12.zip -d /tmp \
    && mkdir -p /opt/spm12-dev \
    && mv /tmp/spm12/* /opt/spm12-dev/ \
    && chmod -R 777 /opt/spm12-dev \
    && rm -rf /tmp/* \
    && /opt/spm12-dev/run_spm12.sh /opt/matlabmcr-2018a/v94 quit \
    && sed -i '$iexport SPMMCRCMD=\"/opt/spm12-dev/run_spm12.sh /opt/matlabmcr-2018a/v94 script\"' $ND_ENTRYPOINT

RUN useradd --no-user-group --create-home --shell /bin/bash neuro
USER neuro

ENV CONDA_DIR="/opt/miniconda-latest" \
    PATH="/opt/miniconda-latest/bin:$PATH"
RUN export PATH="/opt/miniconda-latest/bin:$PATH" \
    && echo "Downloading Miniconda installer ..." \
    && conda_installer="/tmp/miniconda.sh" \
    && curl -fsSL --retry 5 -o "$conda_installer" https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && bash "$conda_installer" -b -p /opt/miniconda-latest \
    && rm -f "$conda_installer" \
    && conda update -yq -nbase conda \
    && conda config --system --prepend channels conda-forge \
    && conda config --system --set auto_update_conda false \
    && conda config --system --set show_channel_urls true \
    && sync && conda clean -tipsy && sync \
    && conda create -y -q --name neuro \
    && conda install -y -q --name neuro \
           python=3.6 \
           pytest \
           jupyter \
           jupyterlab \
           jupyter_contrib_nbextensions \
           traits \
           pandas \
           matplotlib \
           scikit-learn \
           scikit-image \
           seaborn \
           nbformat \
           nb_conda \
    && sync && conda clean -tipsy && sync \
    && bash -c "source activate neuro \
    &&   pip install  --no-cache-dir \
             https://github.com/nipy/nipype/tarball/master \
             https://github.com/INCF/pybids/tarball/master \
             nilearn \
             datalad[full] \
             nipy \
             duecredit \
             nbval" \
    && rm -rf ~/.cache/pip/* \
    && sync \
    && sed -i '$isource activate neuro' $ND_ENTRYPOINT

RUN bash -c 'source activate neuro && jupyter nbextension enable exercise2/main && jupyter nbextension enable spellchecker/main'

USER root

RUN mkdir /data && chmod 777 /data && chmod a+s /data

RUN mkdir /output && chmod 777 /output && chmod a+s /output

USER neuro

RUN bash -c 'source activate neuro \
        && cd /data \
        && datalad install -r ///workshops/nih-2017/ds000114 \
        && cd ds000114 \
        && datalad update -r \
        && datalad get -r sub-01/ses-test/anat sub-01/ses-test/func/*fingerfootlips*'

RUN curl -L https://files.osf.io/v1/resources/fvuh8/providers/osfstorage/580705089ad5a101f17944a9 -o /data/ds000114/derivatives/fmriprep/mni_icbm152_nlin_asym_09c.tar.gz \
        && tar xf /data/ds000114/derivatives/fmriprep/mni_icbm152_nlin_asym_09c.tar.gz -C /data/ds000114/derivatives/fmriprep/. \
        && rm /data/ds000114/derivatives/fmriprep/mni_icbm152_nlin_asym_09c.tar.gz \
        && find /data/ds000114/derivatives/fmriprep/mni_icbm152_nlin_asym_09c -type f -not -name ?mm_T1.nii.gz -not -name ?mm_brainmask.nii.gz -not -name ?mm_tpm*.nii.gz -delete

COPY [".", "/home/neuro/nipype_tutorial"]

USER root

RUN chown -R neuro /home/neuro/nipype_tutorial

RUN rm -rf /opt/conda/pkgs/*

USER neuro

RUN jupyter labextension install @jupyterlab/hub-extension

RUN pip install nbgitpuller