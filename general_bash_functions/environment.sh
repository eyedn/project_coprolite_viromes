#!/usr/bin/env bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       environment.sh
###############################################################################


# sourcing this file only defines functions; workers activate explicitly.
initialize_conda() {
    export PYTHONDONTWRITEBYTECODE=1 PYTHONNOUSERSITE=1
    unset PYTHONHOME PYTHONPATH
    if ! type module >/dev/null 2>&1; then
        if [[ -r /etc/profile.d/modules.sh ]]; then
            source /etc/profile.d/modules.sh || return
        elif [[ -r /u/local/Modules/default/init/modules.sh ]]; then
            source /u/local/Modules/default/init/modules.sh || return
        else
            echo 'cannot initialize Hoffman2 environment modules' >&2
            return 1
        fi
    fi
    module load miniforge/24.3.0-0 || return
    # initialize explicitly even if an interactive shell provided conda.
    local conda_base
    conda_base=$(conda info --base) || return
    source "$conda_base/etc/profile.d/conda.sh" || return
}

activate_environment() {
    local environment=$1
    initialize_conda || return
    case "$environment" in
        python)
            # the replacement prefix is provisioned before deployment.
            conda activate "${python_env:-$HOME/virome_envs/python}" || return
            ;;
        qc|prokka|phabox|msa)
            if [[ -d $HOME/virome_envs/$environment/conda-meta ]]; then
                conda activate "$HOME/virome_envs/$environment" || return
            else
                conda activate "$HOME/.conda/envs/$environment" || return
            fi
            ;;
        *) conda activate "$environment" || return ;;
    esac
    command -v python3 >/dev/null || {
        echo "Python unavailable in environment: $environment" >&2
        return 1
    }
    if [[ $environment = python ]]; then
        python3 -c 'import sys; assert sys.version_info >= (3, 9)' || return
    fi
}
