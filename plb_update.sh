#!/bin/bash

#Documentation
usage() {
    cat <<EOF

Planning Biblio update script

./plb_update.sh -b git branch [-d DB name] [-u DB user] [-p DB password] [--dir installation directory] [-h|--help]

Input args:

    -b git branch
        Branch to use from repository https://github.com/planningbiblio/planningbiblio
        Example : 19.04.xx
    -d DB name
        Optional, default = "planningb"
    -u DB user
        Optional, default = ""
    -p DB password
        Optional, default = ""
    --dir installation directory
        Directory where Planning Biblio is installed in
    -h | --help
        Show help
EOF
}

##
# Get input args
##

# No input or help
if [[ -z "$1" ||    "$1" = "-h" || "$1" = "--help" ]]
then
    usage
    exit 255
fi

# Expected args
working_dir=~/planningb_update
planning_dir=~/www/planningbiblio
dbname=planningb
logfile=$working_dir/log-`date +%Y-%m-%d-%H:%M:%S`.txt
> $logfile

while [ $1 ]; do
    case $1 in
        -b )
            shift
            branch=$1
            ;;
        -d )
            shift
            dbname=$1
            ;;
        -u )
            shift
            dbuser="-u $1"
            ;;
        -p )
            shift
            dbpass="--password=$1"
            ;;
        --dir )
            shift
            planning_dir=$1
            ;;

       * )
            echo "Unknown arg $1"
            usage
            exit 255
    esac
    shift
done

# Working directory
if [ ! -d $working_dir ]; then mkdir $working_dir; fi

# DB Dump
mysqldump $dbuser $dbpass $dbname > $working_dir/dump-`date +%Y-%m-%d-%H:%M:%S`.sql

# Install or update composer
if [ -e $working_dir/composer ]; then rm $working_dir/composer >> $logfile; fi
if [ -e $working_dir/composer-setup.php ]; then rm $working_dir/composer-setup.php >> $logfile; fi
curl -sS https://getcomposer.org/installer -o $working_dir/composer-setup.php >> $logfile
php $working_dir/composer-setup.php --install-dir=$working_dir/ --filename=composer >> $logfile

# Change to planning directory
cd $planning_dir

# Git reset, to get setup directory back
git reset --hard >> $logfile

# Git checkout to the new branch
git fetch origin $branch >> $logfile
git checkout $branch >> $logfile

# Update dependencies
php $working_dir/composer update >> $logfile

# Update Data Base
php -f index.php >> $logfile

# Delete setup folder
if [ -d setup ]; then rm -r setup >> $logfile; fi
if [ -d public/setup ]; then rm -r public/setup >> $logfile; fi