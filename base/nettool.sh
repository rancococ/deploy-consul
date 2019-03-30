#!/usr/bin/env bash

##########################################################################
# network-helper.sh
# --create   : 创建网络
# --remove   : 卸载网络
# --detail   : 查看网络详情
# --list     : 查看网络列表
##########################################################################

set -e

#
# set author info
#
date1=`date "+%Y-%m-%d %H:%M:%S"`
date2=`date "+%Y%m%d%H%M%S"`
author="rancococ@qq.com"

set -o noglob

#
# font and color 
#
bold=$(tput bold)
underline=$(tput sgr 0 1)
reset=$(tput sgr0)

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
white=$(tput setaf 7)

#
# header and logging
#
header() { printf "\n${underline}${bold}${blue}► %s${reset}\n" "$@"; }
header2() { printf "\n${underline}${bold}${blue}♦ %s${reset}\n" "$@"; }
info() { printf "${white}➜ %s${reset}\n" "$@"; }
info2() { printf "${red}➜ %s${reset}\n" "$@"; }
warn() { printf "${yellow}➜ %s${reset}\n" "$@"; }
error() { printf "${red}✖ %s${reset}\n" "$@"; }
success() { printf "${green}✔ %s${reset}\n" "$@"; }
usage() { printf "\n${underline}${bold}${blue}Usage:${reset} ${blue}%s${reset}\n" "$@"; }

trap "error '******* ERROR: Something went wrong.*******'; exit 1" sigterm
trap "error '******* Caught sigint signal. Stopping...*******'; exit 2" sigint

set +o noglob

#
# entry base dir
#
pwd=`pwd`
base_dir="${pwd}"
source="$0"
while [ -h "$source" ]; do
    base_dir="$( cd -P "$( dirname "$source" )" && pwd )"
    source="$(readlink "$source")"
    [[ $source != /* ]] && source="$base_dir/$source"
done
base_dir="$( cd -P "$( dirname "$source" )" && pwd )"
cd ${base_dir}

#
# envirionment
#

# set docker network info
self_name=`basename $0  .sh`

network_driver=bridge
network_subnet=172.16.110.0/24
network_gateway=172.16.110.1
network_name=consul

#
# args flag
#
arg_help=
arg_create=
arg_remove=
arg_detail=
arg_list=
arg_netid=
arg_empty=true

#
# parse parameter
#
# echo $@
# 定义选项， -o 表示短选项 -a 表示支持长选项的简单模式(以 - 开头) -l 表示长选项 
# a 后没有冒号，表示没有参数
# b 后跟一个冒号，表示有一个必要参数
# c 后跟两个冒号，表示有一个可选参数(可选参数必须紧贴选项)
# -n 出错时的信息
# -- 也是一个选项，比如 要创建一个名字为 -f 的目录，会使用 mkdir -- -f ,
#    在这里用做表示最后一个选项(用以判定 while 的结束)
# $@ 从命令行取出参数列表(不能用用 $* 代替，因为 $* 将所有的参数解释成一个字符串
#                         而 $@ 是一个参数数组)
# args=`getopt -o ab:c:: -a -l apple,banana:,cherry:: -n "${source}" -- "$@"`
args=`getopt -o h -a -l help,create,remove:,detail:,list -n "${source}" -- "$@"`
# 判定 getopt 的执行时候有错，错误信息输出到 STDERR
if [ $? != 0 ]; then
    error "Terminating..." >&2
    exit 1
fi
# echo ${args}
# 重新排列参数的顺序
# 使用eval 的目的是为了防止参数中有shell命令，被错误的扩展。
eval set -- "${args}"
# 处理具体的选项
while true
do
    case "$1" in
        -h | --help | -help)
            info "option -h|--help"
            arg_help=true
            arg_empty=false
            shift
            ;;
        --create | -create)
            info "option --create"
            arg_create=true
            arg_empty=false
            shift
            ;;
        --remove | -remove)
            info "option --remove argument : $2"
            arg_remove=true
            arg_empty=false
            arg_netid=$2
            shift 2
            ;;
        --detail | -detail)
            info "option --detail argument : $2"
            arg_detail=true
            arg_empty=false
            arg_netid=$2
            shift 2
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
            error "Internal error!"
            exit 1
            ;;
    esac
done
#显示除选项外的参数(不包含选项的参数都会排到最后)
# arg 是 getopt 内置的变量 , 里面的值，就是处理过之后的 $@(命令行传入的参数)
for arg do
   warn "$arg";
done

# show usage
usage=$"`basename $0` [-h|--help] [--create] [--remove=netid] [--detail=netid] [--list]
       [-h|--help]          : show help info.
       [--create]           : docker network create.
       [--remove=netid]     : docker network rm netid.
       [--detail=netid]     : docker network inspect netid.
       [--list]             : docker network ls.
"

# execute docker network create
fun_execute_network_create() {
    command=$1
    header "execute command:[docker network create --driver ${network_driver} --subnet ${network_subnet} --gateway ${network_gateway} ${network_name}]"
    info "execute command [docker network create --driver ${network_driver} --subnet ${network_subnet} --gateway ${network_gateway} ${network_name}] start..."
    docker network create --driver ${network_driver} --subnet ${network_subnet} --gateway ${network_gateway} ${network_name}
    success "execute command [docker network create --driver ${network_driver} --subnet ${network_subnet} --gateway ${network_gateway} ${network_name}] end..."
    return 0
}

# execute docker network remove
fun_execute_network_remove() {
    header "execute command:[docker network rm ${arg_netid}]"
    info "execute command [docker network rm ${arg_netid}] start..."
    docker network rm ${arg_netid}
    success "execute command [docker network rm ${arg_netid}] end..."
    return 0
}

# execute docker network detail
fun_execute_network_detail() {
    header "execute command:[docker network inspect ${arg_netid}]"
    info "execute command [docker network inspect ${arg_netid}] start..."
    docker network inspect ${arg_netid}
    success "execute command [docker network inspect ${arg_netid}] end..."
    return 0
}

# execute docker network list
fun_execute_network_list() {
    header "execute command:[docker network ls]"
    info "execute command [docker network ls] start..."
    docker network ls
    success "execute command [docker network ls] end..."
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

# create
if [ "x${arg_create}" == "xtrue" ]; then
    fun_execute_network_create;
fi

# remove
if [ "x${arg_remove}" == "xtrue" ]; then
    fun_execute_network_remove;
fi

# detail
if [ "x${arg_detail}" == "xtrue" ]; then
    fun_execute_network_detail;
fi

# list
if [ "x${arg_list}" == "xtrue" ]; then
    fun_execute_network_list;
fi

success "complete."

exit $?
