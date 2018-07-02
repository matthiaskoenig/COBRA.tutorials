#!/bin/bash

# save the cloned directory
tutorialsClonedPath=$(pwd)/../
cd $tutorialsClonedPath
mv linux tutorials
mkdir linux && cd linux

# clone the cobratoolbox
git clone --depth=1 --no-single-branch https://github.com/opencobra/cobratoolbox.git cobratoolbox
cd cobratoolbox

# checkout the branch on cobratoolbox (default: develop)
git checkout ci-tutorials-new

# Remove the submodule entry from .git/config
git submodule deinit -f tutorials

# Remove the submodule directory from the superproject's .git/modules directory
rm -rf .git/modules/tutorials

# Remove the entry in .gitmodules and remove the submodule directory located at path/to/submodule
git rm -f tutorials

# commit the removed submodule
git commit -m "Removed tutorials submodule"

# initialize the submodules
git submodule update --init --depth=1 --remote --no-fetch

# move the cloned tutorials folder to the cobratoolbox directory
cd $tutorialsClonedPath
mv tutorials linux/cobratoolbox/.
cd linux/cobratoolbox

COBRATutorialsPath=$(pwd)

buildTutorialList(){
    nTutorial=0
    for d in $(find $COBRATutorialsPath -maxdepth 7 -type d)
    do
        if [[ "${d}" == *additionalTutorials* ]]; then
            continue  # if not a directory, skip
        fi

        # check for MLX files.
        for tutorial in ${d}/*.mlx
        do
            if ! [[ -f "$tutorial" ]]; then
                break
            fi
            let "nTutorial+=1"
            tutorials[$nTutorial]="$tutorial"
            echo " - ${tutorials[$nTutorial]}"
        done
    done
}

buildTutorialList

declare -a tutorials=("tutorial_optForce")

longest=0
for word in "${tutorials[@]}"
do
    len=${#word}
    if (( len > longest ))
    then
        longest=$len
    fi
done

header=`printf "%-${longest}s    %6s    %6s    %7s\n"  "Name" "passed" "failed" "time(s)"`
report="Tutorial report\n\n"
report+="$header\n"
report+=`printf '=%.0s' $(seq 1 ${#header});`"\n"
failure=0

# Set time format to seconds
TIMEFORMAT=%R

nTutorial=0
nPassed=0
for tutorial in "${tutorials[@]}"
do
    tutorialDir=${tutorial%/*}
    tutorialName=${tutorial##*/}
    tutorialName="${tutorialName%.*}"

    msg="| Starting $tutorialName |"
    chrlen=${#msg}
    underline=`printf '=%.0s' $(seq 1 $chrlen);`
    echo "$underline"
    echo "$msg"
    echo "$underline"

    # Time a process
    SECONDS=0;
    /mnt/prince-data/MATLAB/$MATLAB_VER/bin/./matlab -nodesktop -nosplash -r "restoredefaultpath; addpath([pwd filesep '.artenolis']); runTutorial('$tutorialName'); delete(gcp);"
    CODE=$?
    procTime=$SECONDS

    msg="| Done executing $tutorialName! |"
    chrlen=${#msg}
    underline=`printf '=%.0s' $(seq 1 $chrlen);`
    echo "$underline"
    echo "$msg"
    echo "$underline"
    echo
    echo

    echo "$CODE"

    if [ $CODE -ne 0 ]; then
        report+=`printf "%-${longest}s                x      %7.1f"  "$tutorial" "$procTime"`
    else
        report+=`printf "%-${longest}s     x                 %7.1f"  "$tutorial" "$procTime"`
        let "nPassed+=1"
    fi
    report+="\n"
    let "nTutorial+=1"
done

report+=`printf "\n  Passed:  %d/%d" "$nPassed" "$nTutorial"`
report+="\n\n"
printf "$report"

if [ $nPassed -ne $nTutorial ]; then
    exit 1
else
    exit $CODE
fi