#!/bin/sh
# Copyright (c) Contributors to the Apptainer project, established as
#   Apptainer a Series of LF Projects LLC.
#   For website terms of use, trademark policy, privacy policy and other
#   project policies see https://lfprojects.org/policies

# optionally take commit-ish as argument for debugging purposes
head=$1

gitrepo=true
toplevel="$(git rev-parse --show-toplevel 2> /dev/null)"

if test -z "${toplevel}" ; then
	# failed to get toplevel directory, we are not inside a git
	# repo?
	gitrepo=false
	toplevel=$PWD
fi

if test -f "${toplevel}/VERSION" ; then
	cat "${toplevel}/VERSION"
	exit 0
fi

# no VERSION file

if ! ${gitrepo} ; then
	echo "E: Not inside a git repository and no VERSION file found. Abort." 1>&2
	exit 1
fi

# gitdesc extracts the closest version tag, removing the leading "v" and
# returning the rest
gitdesc() {
	git describe --tags --match='v[0-9]*' --always --candidates=1 "$@" 2>/dev/null |
	sed -e 's,^v,,'
}

closest_tag=$(gitdesc --abbrev=0 ${head})
current_commit=$(gitdesc ${head})
if test -n "${head}" ; then
	# cannot pass --dirty when using commit-ish
	dirty_info=${current_commit}
else
	dirty_info=$(gitdesc --dirty)
fi

# First figure out if the current commit matches a tag:
#
# v3.4.1
# v3.4.1-rc.1

if [ "${closest_tag}" = "${current_commit}" ] ; then
	# We are on a tag, leave it alone, maybe including the dirty
	# mark.
	#
	# This works even if we ever use a tag like v3.4.1+pl1 (which we
	# will hopefully never have).
	echo "${dirty_info}"
	exit 0
fi

# We have something which doesn't exactly match a tag:
#
# v3.4.1-315-g21e6d6765
# v3.4.1-rc.1-315-g21e6d6765
#
# Use the -315-g21e6d6765 part as metadata, using + to indicate that
# this is 3.4.1 with 315 additional changes. Keep the g21e6d6765 part to
# have a record of the corresponding git commit hash.
#
# Transform the above into:
#
# v3.4.1+315-g21e6d6765
# v3.4.1-rc.1+315-g21e6d6765

echo "${dirty_info}" | sed -e "s,^\(${closest_tag}\)-,\1+,"
