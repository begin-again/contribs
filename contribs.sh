#!/usr/bin/bash

function showHelp() {
    echo "Usage: "
    echo "Required"
    echo "-p | --person, portion of user name found in config core.user"
    echo "-d | --days, number of days to include example: 30"
    echo "Optional"
    echo "-r | --root, folder containing repositories (defaults to MYPROJECTS variable)"
    echo "-n | --projects, optional quote encased list of folder names to include. Default is all"
    echo "-h | --help, show help"
    exit 1
}

# set -x
# parse arguments
help=""
root="$MYPROJECTS"
args=$(($# % 2))
if [ "$args" -ne 0 ]; then show-help; fi;

while [ $# -gt 1 ] && [ -z "$help" ]
do
    key="$1"
    case $key in
         -r|--root)
        root="$2"
        shift
        ;;
        -p|--person)
        person="$2"
        shift
        ;;
        -n|--projects)
        restrict="$2"
        shift
        ;;
        -d|--days)
        since="$2"
        shift
        ;;
        -h|--help)
        help="show"
        shift
        ;;
        *)
        help="show"
        echo "unrecognized option: $2"
        ;;
    esac
    shift
done

if [ -z "$help" ]; then
    if [ -z "$person" ]; then showHelp; fi;
    if [ -z "$since" ]; then showHelp; fi;
    if [ -d "$root" ] ; then
            projectRoot="$root"
    else
        echo "root folder must exist"
        exit 1
    fi
    newProjects=$(echo "$projectRoot" | sed -e 's|^[cC]:|/c|' | sed -e 's|\\|/|g' )
    since="$since days ago"

    # exec 2>/dev/null
    # split the string into an array
    if [ -n "$restrict" ]; then
        projects=($(echo "$restrict" | tr ', ' '\n'))
        for p in "${projects[@]}"
        do
            matchers="$matchers\/$p\/|"
        done
        matchers=${matchers::-1}
        result=$(find "$newProjects" -maxdepth 2 -type d -name .git -print | egrep "$matchers" | xargs -I proj git --no-pager -C proj/.. log --oneline  --since="$since" --format="%an %ae" master | grep -i "$person" | nl | tail -n 1 | awk '{print $1}')
    else
        result=$(find "$newProjects" -maxdepth 2 -type d -name .git -print |  xargs -I proj git --no-pager -C proj/.. log --oneline --since="$since" --format="%an %ae" master | grep -i "$person" | nl | tail -n 1 | awk '{print $1}')
    fi

    if [ -z "$result" ]; then
        echo "No Contributions"
    else
        echo "$result Contributions"
    fi
else
    showHelp
fi
