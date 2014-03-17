#!/bin/sh
#
# Welcome to svn-to-git, a simple command-line utility to transform a subversion
# repository to its git counterpart. Fully supports branch/tag transformation.
#
# Excuse the drastic overuse of echo.
#
# Copyright(c) 2014 Isaac Whitfield <iwhitfield@appcelerator.com>
#

base_path="$(pwd)"

capture(){
	message=${2:-"Please enter your choice: "}
	newline=${3:-false}

	read -p "$message" -r
	if test "$newline" == true; then echo ; fi
	eval "$1='$REPLY'"
	if [ $REPLY -ge 0 2>/dev/null ] ; then return $REPLY; fi
}

checkyes(){
	message=${1:-"Are you sure? (y/n) "}
	check=${2:-false}

	read -p "$message" -n 1 -r -s
	if [[ "$check" == true ]]
	then
		if [[ ! $REPLY =~ ^[Yy]$ ]]
		then
			exit 1
		fi
	fi
	if [ $REPLY -ge 0 2>/dev/null ]; then return $REPLY; fi
}

clear && echo "Welcome to svn-to-git, a simple and effective way to translate SVN to Git.\n"

capture svn_url "Please enter your SVN url/path: "
svn_url="${svn_url/\~/$HOME}"
svn_url="$(echo $svn_url | xargs)"

if [[ "${svn_url: -1}" == "/" ]]
then
	svn_url=${svn_url%?}
fi

capture git_path "Please enter your desired Git directory: "
git_path="${git_path/\~/$HOME}"

if [[ "${git_path:0:1}" != "/" ]]
then
	git_path="$base_path/$git_path"
fi

echo
echo "SVN PATH: $svn_url"
echo "GIT PATH: $git_path\n"

svn checkout "$svn_url"
echo
svn_path=${svn_url##*/}
cd "$svn_path"

svn log -q | awk -F '|' '/^r/ {sub("^ ", "", $2); sub(" $", "", $2); print $2" = "$2" <"$2">"}' | sort -u > authors.txt

echo "Please edit the following lines to match the correct Git format."
echo "As an example:\n"
echo "username = username <username>"
echo "    becomes:"
echo "username = Isaac Whitfield <iwhitfield@appcelerator.com>\n"

echo "Please type in the command to start up your favourite shell editor below."
capture edit "Just press enter if you don't know any: " true

editors=( "vi" "vim" "nano" "pico" "emacs" )
if `echo ${editors[@]} | grep -q "$edit"`
then
	if [[ "$edit" != "" ]]
	then
		$edit authors.txt
	else
		nano authors.txt
	fi
else
	nano authors.txt
fi

echo "Please select your SVN layout:\n"
echo "1. Standard layout (branches/tags/trunk)."
echo "2. Non-standard with branches and tags."
echo "3. Non-standard without branches and tags.\n"

validate(){
	capture choice "$1"
	choice=$?
	if [[ "$choice" != "1" && "$choice" != "2" && "$choice" != "3" ]]; then validate "Please enter a valid selection: "; fi
}
validate "Please enter your choice: "
echo

case "$choice" in
1)	svn_clone="git svn clone $svn_url -A authors.txt $git_path --stdlayout --prefix=import/"
	;;
2)	capture branches "Please enter the name of your branches folder: "
	capture tags "Please enter the name of your tags folder: "
	capture trunk "Please enter the name of your trunk folder: "
	echo
	svn_clone="git svn clone $svn_url -A authors.txt $git_path -b $branches -t $tags -T $trunk --prefix=import/"
	;;
3)	capture trunk "Please enter the name of your trunk folder (just hit enter if it's the root): "
	if [[ "$trunk" != "" ]]; then trunk="-T $trunk "; fi
	svn_clone="git svn clone $svn_url -A authors.txt $git_path $trunk --prefix=import/"
	;;
*)	echo "Incorrect code supplied, exiting!"
	exit 1
	;;
esac

$svn_clone
cd $git_path
rm -r "$base_path/$svn_path"
git svn show-ignore > .gitignore 2>/dev/null

folder_arr=( $(find ./ -type d) )
if [[ "${#folder_arr[@]}" == 2 ]]
then
	git mv -k "${folder_arr[1]}/*" ./ && rm -r "${folder_arr[1]}"
fi

echo
commit(){
	capture commit_msg "$1"
	if [[ "$commit_msg" == "" ]]
	then
		commit "Please enter a valid commit message for moving from SVN: "
	else
		echo
	fi
}
commit "Please enter the commit message for moving from SVN: "

git add -A
git commit -m "$commit_msg"

echo
capture git_url "Please enter your remote URL, if you don't have one, type 'none': "
if [[ "$git_url" != "none" ]]; then git remote add origin "$git_url"; fi

for branch in `git branch -r`; do
	if ! echo x"$branch" | grep 'tags' > /dev/null && \
	   ! echo x"$branch" | grep 'trunk' > /dev/null && \
	   ! echo x"$branch" | grep 'git-svn' > /dev/null
	then
		echo
		git checkout -b "${branch##*/}" "refs/remotes/$branch"
		git branch -d -r "$branch"
		rm -rf ".git/svn/refs/remotes/$branch"
	elif echo x"$branch" | grep 'trunk' > /dev/null && \
		 echo x"$branch" | grep 'git-svn' > /dev/null
	then
		git branch -d -r "$branch"
		rm -rf ".git/svn/refs/remotes/$branch"
	fi
done

if [[ -n $(git branch -r | grep "tags/" | sed 's/ tags\///') ]]
then
	echo
	for tag in `git branch -r | grep "tags/" | sed 's/ tags\///'`; do
		echo "Moving tag ${tag##*/} from SVN to Git"
		git tag -a -m "Moving tag ${tag##*/} from SVN to Git" "${tag##*/}" "refs/remotes/$tag"
		rm -rf ".git/svn/refs/remotes/$tag"
	done
fi

notify(){
	echo
	echo "You're done! Here is the state of your Git repo:\n"

	echo "Branches:"
	git branch

	echo "\nTags:"
	for tag in `git tag -l`; do
		echo "  $tag"
	done

	echo ${1:-""}
}

git checkout master 2>/dev/null
if [[ "$git_url" != "none" ]]
then
	echo "\nPushing all branches to new origin\n"
	git push origin --all
	echo "\nPushing all tags to new origin\n"
	git push --tags
	notify
else
	notify "\nYou will need to push your repo to Git when you're ready."
fi