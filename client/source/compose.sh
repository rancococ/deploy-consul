#!/usr/bin/env bash

##########################################################################
# compose.sh
# --setup   : setup container
# --start   : start container
# --stop    : stop container
# --down    : down container
# --list    : list container
##########################################################################

# set -x
set -e

# set author info
date1=`date "+%Y-%m-%d %H:%M:%S"`
date2=`date "+%Y%m%d%H%M%S"`
author="yong.ran@cdjdgm.com"

set -o noglob

# font and color 
bold=$(tput bold)
underline=$(tput sgr 0 1)
reset=$(tput sgr0)

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
white=$(tput setaf 7)

# header and logging
header() { printf "\n${underline}${bold}${blue}> %s${reset}\n" "$@"; }
header2() { printf "\n${underline}${bold}${blue}>> %s${reset}\n" "$@"; }
info() { printf "${white}➜ %s${reset}\n" "$@"; }
warn() { printf "${yellow}➜ %s${reset}\n" "$@"; }
error() { printf "${red}✖ %s${reset}\n" "$@"; }
success() { printf "${green}✔ %s${reset}\n" "$@"; }
usage() { printf "\n${underline}${bold}${blue}Usage:${reset} ${blue}%s${reset}\n" "$@"; }

trap "error '******* ERROR: Something went wrong.*******'; exit 1" sigterm
trap "error '******* Caught sigint signal. Stopping...*******'; exit 2" sigint

set +o noglob

# entry base dir
pwd=`pwd`
base_dir="${pwd}"
source="$0"
while [ -h "$source" ]; do
    base_dir="$( cd -P "$( dirname "$source" )" && pwd )"
    source="$(readlink "$source")"
    [[ $source != /* ]] && source="$base_dir/$source"
done
base_dir="$( cd -P "$( dirname "$source" )" && pwd )"
cd "${base_dir}"

# envirionment
if [ -r "${base_dir}/.env" ]; then
    while read line; do
        eval "$line";
    done < "${base_dir}/.env"
fi
self_name=`basename $0 .sh`
parent_name=`basename "${base_dir}"`
project_conf=${base_dir}/${self_name}.yml
project_dir=${base_dir}
if [ -z "${PRODUCT_NAME}" ]; then
    project_name=${parent_name}
else 
    project_name=${PRODUCT_NAME}
fi

# args flag
arg_help=
arg_setup=
arg_start=
arg_stop=
arg_down=
arg_list=
arg_empty=true

# parse parameter
# echo $@
# define options, -o : short options, -a : simple mode for long options (starts with -), -l : long options
# no colon after, indicating no parameter
# followed by a colon to indicate that there is a required parameter
# followed by two colons to indicate that there is an optional parameter (the optional parameter must be next to the option)
# -n information on error
# -- it is also an option. for example, to create a directory named "-f", "mkdir -- -f" will be used
# $@ take the parameter list from the command line
# args=`getopt -o ab:c:: -a -l apple,banana:,cherry:: -n "${source}" -- "$@"`
args=`getopt -o h -a -l help,setup,start,stop,down,list -n "${source}" -- "$@"`
# terminate the execution when there is an error in the execution of getopt
if [ $? != 0 ]; then
    error "terminating..." >&2
    exit 1
fi
# echo ${args}
# reorder parameters(The purpose of using eval is to prevent the shell command in the parameter from being extended by mistake)
eval set -- "${args}"
# handling specific options
while true
do
    case "$1" in
        -h | --help | -help)
            info "option -h|--help"
            arg_help=true
            arg_empty=false
            shift
            ;;
        --setup | -setup)
            info "option --setup"
            arg_setup=true
            arg_empty=false
            shift
            ;;
        --start | -start)
            info "option --start"
            arg_start=true
            arg_empty=false
            shift
            ;;
        --stop | -stop)
            info "option --stop"
            arg_stop=true
            arg_empty=false
            shift
            ;;
        --down | -down)
            info "option --down"
            arg_down=true
            arg_empty=false
            shift
            ;;
        --list | -list)
            info "option --list"
            arg_list=true
            arg_empty=false
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            error "internal error!"
            exit 1
            ;;
    esac
done
# display parameters other than options (parameters without options will be last)
# arg is the built-in variable of getopt. the value in arg is $@ (the parameter passed in from the command line) after processing
for arg do
   warn "$arg";
done

##########################################################################

# show usage
usage=$"`basename $0` [-h|--help] [--setup] [--start] [--stop] [--down] [--list]
       [-h|--help]          : show help info.
       [--setup]            : docker-compose xxx up -d.
       [--start]            : docker-compose xxx start.
       [--stop]             : docker-compose xxx stop.
       [--down]             : docker-compose xxx down.
       [--list]             : docker-compose xxx list.
"

# execute docker-compose command
fun_execute_compose_command() {
    command=$1
    header "execute command:[docker-compose --file ${project_conf} --project-name ${project_name} --project-directory ${project_dir} ${command}]"
    info "execute command [docker-compose --file ${project_conf} --project-name ${project_name} --project-directory ${project_dir} ${command}] start."
    docker-compose --file ${project_conf} --project-name ${project_name} --project-directory ${project_dir} ${command}
    success "execute command [docker-compose --file ${project_conf} --project-name ${project_name} --project-directory ${project_dir} ${command}] end."
    return 0
}


##########################################################################

# argument is empty
if [ "x${arg_empty}" == "xtrue" ]; then
    usage "$usage";
    exit 1
fi

# show usage
if [ "x${arg_help}" == "xtrue" ]; then
    usage "$usage";
    exit 1
fi

# setup
if [ "x${arg_setup}" == "xtrue" ]; then
    fun_execute_compose_command "up -d";
fi

# start
if [ "x${arg_start}" == "xtrue" ]; then
    fun_execute_compose_command "start";
fi

# stop
if [ "x${arg_stop}" == "xtrue" ]; then
    fun_execute_compose_command "stop";
fi

# down
if [ "x${arg_down}" == "xtrue" ]; then
    fun_execute_compose_command "down";
fi

# list
if [ "x${arg_list}" == "xtrue" ]; then
    fun_execute_compose_command "ps";
fi

success "complete."

# exit $?
