#!/bin/bash
###############################################################################
#		Aydin Karatas
#		Project Coprolite Viromes
#		general_functions.sh 
###############################################################################


# check the arguments given to the submission script are valid
check_args() {
	# define argument variables
	local valid_args=$1
	local arg=$2

	# check if arg exists in valid_args
	if [[ " ${valid_args[@]} " =~ " ${arg} " ]]; then
		echo "$(timestamp): argument recognized: ${arg}"
	else
		echo "$(timestamp): check_args: '${arg}' is an INVALID argument."
		echo "$(timestamp): Possible inputs are:"
		echo "$(timestamp): ${valid_args[*]}"
		exit 1
	fi
}
