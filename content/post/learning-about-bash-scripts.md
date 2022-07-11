---
title: "Learning About Bash Scripts"
date: 2021-01-20T22:28:26-03:00
Description: ""
Tags: [bash, linux, unix]
Categories: [automation, en-us]
DisableComments: false
---

* * *
## Getting Started :book:
First of all you need to have knowledge and some concepts in Linux, at least the basic level.

### Why should I use it?
If you have ever been a SysAdmin, you will understand me. Sometimes it's necessary to create a workaround for you to have a weekend in peace. Below I'll write some reasons for you to create a Bash Script.

If you:
- want to do something for several times;
- need to monitor a simple action that is running on server;
- need to schedule an action to run from time to time;
- maybe a workaround.

Right! So let's do it.

* * *

### Curious about the first line :question::question::question:
The first line is called [Shebang](https://en.wikipedia.org/wiki/Shebang_(Unix)). In summary, we are going to tell the operating system which interpreter to use when executing the file.

We'll use the **"`/usr/bin/env bash`"** because we don’t worry what operating system we are running the script on.

* * *

## Hands on :raised_hands:
In this post, we'll see about the [RSync](https://linux.die.net/man/1/rsync) script and then, follow me step-by-step:

* * *

**(1) Creating the script and putting it into execution mode:**
```vim
touch rsync_script.sh
chmod +x $_
```

* * *

**(2) Adding the first line and variables like arguments:**
```vim
#!/usr/bin/env bash
SOURCE=$1
DESTINATION=$2
LOG_FILE=/tmp/rsync.log

```

* * *

**(3) What I think important about this script is that you need to create lockfile to prevent overhead. In that case, we need to create two functions to do this:**

```vim
function log {
    echo [$(date "+%d/%m/%Y %H:%M:%S")] - $@
}

function create_lock {
    basename=$(basename $0)
    file_lock="/tmp/$basename.lock"
    pid=$$
    log Starting Script
    if [ -f $file_lock ]; then
    if ps -p $(cat $file_lock) > /dev/null 2>&1; then
        log Lock file found. Exiting...
            exit 0
        else
            log Lock file found but no process running. Removing lock file: $file_lock
            rm -f $file_lock
            log Creating lockfile: $file_lock
            echo $pid > $file_lock
        fi
        else
        log Creating lock file: $file_lock
            echo $pid > $file_lock
        fi
}

function remove_lock {
    log Removing lock file: $file_lock
    rm -f $file_lock 2> /dev/null
}
```

* * *

**(4) Now, we need to create a function for RSYNC:**

```vim
function rsyncExec {
	rsync --log-file="${LOG_FILE}" \
            -av \
            --numeric-ids \
            --progress \
            $SOURCE \
            $DESTINATION
}
```

**However**, what will happen if the source and destination aren't valid?
Therefore, we need create the testing phase. In this case, we can create a test for source and another for destination in just one line for each. For example:

```vim
[ ! -d $SOURCE ] && echo "Not found directory: $SOURCE" && exit 1
[ ! -d $DESTINATION ] && echo "Not found directory: $DESTINATION" && exit 1
```

* * *

**(5) Finally, we need to assemble the script and put each part together:**

**`$ vim rsync_script.sh`**

```vim
#!/usr/bin/env bash
# STEP 1: ----------------------------------------------------------------
SOURCE=$1
DESTINATION=$2
LOG_FILE=/tmp/rsync.log

# STEP 2: TESTS ----------------------------------------------------------
[ ! -d $SOURCE ] && echo "Not found directory: $SOURCE" && exit 1
[ ! -d $DESTINATION ] && echo "Not found directory: $DESTINATION" && exit 1

# STEP 3: ----------------------------------------------------------------
function log {
    echo [$(date "+%d/%m/%Y %H:%M:%S")] - $@
}

function create_lock {
    basename=$(basename $0)
    file_lock="/tmp/$basename.lock"
    pid=$$
    log Starting Script
    if [ -f $file_lock ]; then
    if ps -p $(cat $file_lock) > /dev/null 2>&1; then
        log Lock file found. Exiting...
            exit 0
        else
            log Lock file found but no process running. Removing lock file: $file_lock
            rm -f $file_lock
            log Creating lockfile: $file_lock
            echo $pid > $file_lock
        fi
        else
        log Creating lock file: $file_lock
            echo $pid > $file_lock
        fi
}

function remove_lock {
    log Removing lock file: $file_lock
    rm -f $file_lock 2> /dev/null
}

# STEP 4: ----------------------------------------------------------------
function rsyncExec {
	rsync --log-file="${LOG_FILE}" \
            -av \
            --numeric-ids \
            --progress \
            $SOURCE \
            $DESTINATION
}

# STEP 5: ----------------------------------------------------------------

create_lock;
rsyncExec $SOURCE $DESTINATION;
remove_lock;

```

* * *

#### And now? Let's test!

We need to create a source directory to do our testing:

```vim
mkdir -p class/01/{1,2,3,4}
mkdir -p class/02

touch class/01/{1,2,3,4}/main.yaml
```

Look this tree directory:
```shell
tree class
class
├── 01
│   ├── 1
│   │   └── main.yaml
│   ├── 2
│   │   └── main.yaml
│   ├── 3
│   │   └── main.yaml
│   └── 4
│       └── main.yaml
└── 02
```

#### Now, let's run our script! :eyes:

```vim
$ ./rscript.sh class/01 class/02

[19/01/2021 17:39:45] - Starting Script
[19/01/2021 17:39:45] - Creating lock file: /tmp/rscript.sh.lock
building file list ...
11 files to consider
01/
01/1/
01/1/main.yaml
           0 100%    0.00kB/s    0:00:00 (xfer#1, to-check=8/11)
01/2/
01/2/main.yaml
           0 100%    0.00kB/s    0:00:00 (xfer#2, to-check=6/11)
01/2/1/
01/2/1/main.yaml
           0 100%    0.00kB/s    0:00:00 (xfer#3, to-check=4/11)
01/3/
01/3/main.yaml
           0 100%    0.00kB/s    0:00:00 (xfer#4, to-check=2/11)
01/4/
01/4/main.yaml
           0 100%    0.00kB/s    0:00:00 (xfer#5, to-check=0/11)

sent 446 bytes  received 166 bytes  1224.00 bytes/sec
total size is 0  speedup is 0.00
[19/01/2021 17:39:45] - Removing lock file: /tmp/rscript.sh.lock
```

Current directory:
```vim
tree class
class
├── 01
│   ├── 1
│   │   └── main.yaml
│   ├── 2
│   │   ├── 1
│   │   │   └── main.yaml
│   │   └── main.yaml
│   ├── 3
│   │   └── main.yaml
│   └── 4
│       └── main.yaml
└── 02
    └── 01
        ├── 1
        │   └── main.yaml
        ├── 2
        │   └── main.yaml
        ├── 3
        │   └── main.yaml
        └── 4
            └── main.yaml

12 directories, 9 files
```

* * *

**You can see** more examples and ideas in my repository:

[`https://github.com/wsalles/scripts-shell`](https://github.com/wsalles/scripts-shell)

### Let's rock! :rocket: