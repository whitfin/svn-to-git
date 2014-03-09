svn-to-git
==========

A very simple (but complete) CLI tool to convert a Subversion repository to Git. It's also fairly flexible and allows conversion of any available branches and tags to GitHub format.

It's also extremely simple to setup. All you need to do is just clone the repo, and run `sh svn-to-git.sh`. It's somewhat interactive, so it'll prompt you when anything is required on your part.

Feel free to put it somewhere in your path, it should be able to figure out the pathing from where you're running it from and work as expected.

Assuming ~/bin is in your path:

```
$ curl -o ~/bin/svn-to-git.sh https://raw.github.com/iwhitfield/svn-to-git/master/svn-to-git.sh
$ chmod a+x ~/bin/svn-to-git.sh
```
then just access via
```
$ svn-to-git
```

If there are any issues with the script, or suggested improvements, leave a note in the [issues](https://github.com/iwhitfield/svn-to-git/issues "SVN-To-Git Issues").