#!/bin/sh

set -e

# Generate Dockerfile
generate_docker() {
  docker run --rm kaczmarj/neurodocker:master generate docker \
  --base neurodebian:stretch-non-free \
  --pkg-manager apt \
  --install convert3d ants fsl gcc g++ graphviz tree \
            git-annex-standalone vim emacs-nox nano less ncdu \
            tig git-annex-remote-rclone octave netbase \
  --add-to-entrypoint "source /etc/fsl/fsl.sh" \
  --spm12 version=dev \
  --user=neuro \
  --miniconda \
    conda_install="python=3.6 pytest jupyter jupyterlab jupyter_contrib_nbextensions
                   traits pandas matplotlib scikit-learn scikit-image seaborn nbformat nb_conda" \
    pip_install="https://github.com/nipy/nipype/tarball/master
                 https://github.com/INCF/pybids/tarball/master
                 nilearn datalad[full] nipy duecredit nbval" \
    create_env="neuro" \
    activate=true \
  --run-bash 'source activate neuro && jupyter nbextension enable exercise2/main && jupyter nbextension enable spellchecker/main' \
  --user=root \
  --run 'mkdir /data && chmod 777 /data && chmod a+s /data' \
  --run 'mkdir /output && chmod 777 /output && chmod a+s /output' \
  --user=neuro \
  --run-bash 'source activate neuro
    && cd /data
    && datalad install -r ///workshops/nih-2017/ds000114
    && cd ds000114
    && datalad update -r
    && datalad get -r sub-01/ses-test/anat sub-01/ses-test/func/*fingerfootlips*' \
  --run 'curl -L https://files.osf.io/v1/resources/fvuh8/providers/osfstorage/580705089ad5a101f17944a9 -o /data/ds000114/derivatives/fmriprep/mni_icbm152_nlin_asym_09c.tar.gz
    && tar xf /data/ds000114/derivatives/fmriprep/mni_icbm152_nlin_asym_09c.tar.gz -C /data/ds000114/derivatives/fmriprep/.
    && rm /data/ds000114/derivatives/fmriprep/mni_icbm152_nlin_asym_09c.tar.gz
    && find /data/ds000114/derivatives/fmriprep/mni_icbm152_nlin_asym_09c -type f -not -name ?mm_T1.nii.gz -not -name ?mm_brainmask.nii.gz -not -name ?mm_tpm*.nii.gz -delete' \
  --copy . "/home/neuro/nipype_tutorial" \
  --user=root \
  --run 'chown -R neuro /home/neuro/nipype_tutorial' \
  --run 'rm -rf /opt/conda/pkgs/*' \
  --user=neuro \
  --run 'mkdir -p ~/.jupyter && echo c.NotebookApp.ip = \"0.0.0.0\" > ~/.jupyter/jupyter_notebook_config.py' \
  --workdir /home/neuro/nipype_tutorial \
  --cmd jupyter-notebook
}

generate_docker > Dockerfile


docker run --rm kaczmarj/neurodocker:0.4.0 generate -b neurodebian:stretch-non-free -p apt \
--run-bash "RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -" \
--install dcm2niix convert3d ants graphviz tree git-annex-standalone vim emacs-nox nano less ncdu tig git-annex-remote-rclone build-essential nodejs r-recommended psmisc libapparmor1 sudo dc \
--run-bash "RUN apt-get update && apt-get install -yq xvfb mesa-utils libgl1-mesa-dri && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* " \
--afni version=latest \
--fsl version=5.0.10 \
--freesurfer version=6.0.0 min=true \
--spm version=12 matlab_version=R2017a \
--run-bash " \"curl -sSL  http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.0.0_1.0.2g-1ubuntu11.2_amd64.deb > libssl1.0.0_1.0.2g-1ubuntu11.2_amd64.deb && dpkg -i libssl1.0.0_1.0.2g-1ubuntu11.2_amd64.deb && rm libssl1.0.0_1.0.2g-1ubuntu11.2_amd64.deb\" " \

--run-bash " \"curl -sSL http://download2.rstudio.org/rstudio-server-\$(curl https://s3.amazonaws.com/rstudio-server/current.ver)-amd64.deb >> rstudio-server-amd64.deb && dpkg -i rstudio-server-amd64.deb && rm rstudio-server-amd64.deb\" " \

--run-bash "RUN Rscript -e 'install.packages(c(\"neuRosim\", \"ggplot2\", \"fmri\", \"dplyr\", \"tidyr\", \"Lahman\", \"data.table\", \"readr\"), repos = \"http://cran.case.edu\")' " \
--run-bash "RUN curl -sSL https://dl.dropbox.com/s/lfuppfhuhi1li9t/cifti-data.tgz?dl=0 | tar zx -C / " \
--user=neuro \
--miniconda conda_install="python=3.6 jupyter jupyterlab traits pandas matplotlib scikit-learn seaborn swig reprozip reprounzip altair traitsui apptools configobj vtk jupyter_contrib_nbextensions bokeh scikit-image codecov nitime cython joblib jupyterhub=0.7.2" \
            env_name="neuro3" \
add_to_path=True \
            pip_install="https://github.com/nipy/nibabel/archive/master.zip https://github.com/nipy/nipype/tarball/master nilearn https://github.com/INCF/pybids/archive/master.zip datalad dipy nipy duecredit pymvpa2 mayavi git+https://github.com/jupyterhub/nbserverproxy.git git+https://github.com/jupyterhub/nbrsessionproxy.git
https://github.com/satra/mapalign/archive/master.zip https://github.com/poldracklab/mriqc/tarball/master https://github.com/poldracklab/fmriprep/tarball/master pprocess " \
--run-bash " \"source activate neuro3 && python -m ipykernel install --sys-prefix --name neuro3 --display-name Py3-neuro \" " \
--run-bash " \"source activate neuro3 && pip install --pre --upgrade ipywidgets pythreejs \" " \
--run-bash " \"source activate neuro3 && pip install  --upgrade https://github.com/maartenbreddels/ipyvolume/archive/master.zip && jupyter nbextension install --py --sys-prefix ipyvolume && jupyter nbextension enable --py --sys-prefix ipyvolume \" " \
--run-bash " \"source activate neuro3 && jupyter nbextension enable rubberband/main && jupyter nbextension enable exercise2/main && jupyter nbextension enable spellchecker/main \" " \
--run-bash " \"source activate neuro3 && jupyter serverextension enable --sys-prefix --py nbserverproxy && jupyter serverextension enable --sys-prefix --py nbrsessionproxy && jupyter nbextension install --sys-prefix --py nbrsessionproxy && jupyter nbextension enable --sys-prefix --py nbrsessionproxy \" " \
--run-bash " \" source activate neuro3 && pip install git+https://github.com/data-8/gitautosync && jupyter serverextension enable --py nbgitautosync --sys-prefix \" " \
--miniconda env_name="afni27" \
            conda_install="python=2.7 ipykernel" \
            add_to_path=False \
--run-bash " \"source activate neuro3 && python -m ipykernel install --sys-prefix --name afni27 --display-name Py2-afni \" " \
--user=root \
--run-bash "RUN mkdir /data && chown neuro /data && chmod 777 /data && mkdir /output && chown neuro /output && chmod 777 /output && mkdir /repos && chown neuro /repos && chmod 777 /repos" \
--run-bash "RUN echo 'neuro:neuro' | chpasswd && usermod -aG sudo neuro" \
--user=neuro \
--run-bash " \"source activate neuro3 && datadir='/data' python -c 'from nilearn import datasets; haxby_dataset = datasets.fetch_haxby()' && mv ~/nilearn_data /data \" " \
--run-bash " \"source activate neuro3 && cd /data && datalad install -r ///workshops/nih-2017/ds000114 && datalad get -r -J4 ds000114/sub-0[12]/ses-test/ && datalad get -r ds000114/derivatives/fr*/sub-0[12] && datalad get -r ds000114/derivatives/fm*/sub-0[12]/anat && datalad get -r ds000114/derivatives/fm*/sub-0[12]/ses-test && datalad get -r ds000114/derivatives/f*/fsaverage5 \" " \
--run-bash "RUN curl -sSL https://osf.io/dhzv7/download?version=3 | tar zx -C /data/ds000114/derivatives/fmriprep" \
--workdir /home/neuro \
--run-bash "RUN cd /repos && git clone https://github.com/neuro-data-science/neuroviz.git && git clone https://github.com/neuro-data-science/neuroML.git && git clone https://github.com/ReproNim/reproducible-imaging.git && git clone https://github.com/miykael/nipype_tutorial.git && git clone https://github.com/jmumford/nhwEfficiency.git && git clone https://github.com/jmumford/R-tutorial.git && git clone https://github.com/nih-fmrif/nhw_ipynb.git" \
--run-bash "ENV PATH=\"\${PATH}:/usr/lib/rstudio-server/bin\" " \
--run-bash "ENV LD_LIBRARY_PATH=\"/usr/lib/R/lib:\${LD_LIBRARY_PATH}\" " \
--run-bash " \"source activate neuro3 && pip install niwidgets && conda install -c r -y r-essentials rpy2 \" " \
--no-check-urls > Dockerfile
