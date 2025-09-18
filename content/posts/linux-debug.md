---
title: "Linux Debug"
date: 2025-08-30T20:35:21+01:00
draft: true
description: Linux kernel debugging
tags:
  - Linux
math: false
author: "ShellTux"
type: "post"
layout: "post"
cover:
  hidden: false # hide everywhere but not in structured data
  image: "covers/linux-debug.png"
  alt: 
  caption: 
  relative: true
---

Hacking linux kernel

<!--more-->

# Linux Hacking

## Introduction

So a past few days, I was watching this
[video](https://www.youtube.com/watch?v=aoHMiCzqCNw). And it went in depth
about how the shebang works in various operating systems.

### Shebang

If you are not familiar on what the shebang is. It's the first line on a executable script.
And this tells the kernel which interpreter/executable to run.

For example, imagine the following script that prints every argument to the console.

```sh
#!/bin/sh

printf 'arg[0] = %s\n' "$0"
index=1
for arg in "$@"
do
    printf 'arg[%d] = %s\n' "$index" "$arg"
    index=$((index + 1))
done
```

```sh
chmod u+x script.sh # Add execution permissions for owner user
./script.sh # Execute the shell script
```

So the first line on a script file that starts with `#!` is called the shebang.
And the contents of the shebang is `/bin/sh` so that is going to be the interpreter to call that script.

What happens under the hood depends on the kernel implementation.
But on linux `./script.sh` gets replaced with `/bin/sh ./script.sh`.
So the filepath of the executable itself gets appended at the end of the shebang interpreter.

### Python shebang

What this implies is that in the shebang you can put any
interpreter/executable. And as long as that interpreter ignores the shebang as
being source code, it will execute that script.

For example, imagine you have this python script:

```python
print('Hello world!')
```

In order to execute, you would probably call it like this:
```sh
$ python main.py
Hello world!
```

But the shebang allow you to turn this python source code into a executable script:

```python
#!/usr/bin/env python
print('Hello world')
```

`/usr/bin/env` is a executable that exists in most posix compliant OS, that
will find the python executable in the first directory defined by your `PATH`
environment variable.

And by making it executable, you don't need to invoke python on the command line.

```sh
$ chmod u+x ./main.py
$ ./main.py # The kernel will replace this process context with: /usr/bin/env python ./main.py
Hello world!
```

### C program to print argv

And to better visualize what arguments are passed. Let's write a simple c
program that prints every argument in argv (being the list of arguments of the
process).

```c
// printargs.c

#include <stdio.h>

int main(int argc, char **argv)
{
    for (int i = 0; i < argc; ++i) {
        printf("arg[%d] = %s\n", i, argv[i]);
    }

    return 0;
}
```

```shell
$ make printargs # cc -o printargs printargs.c
$ ./printargs
arg[0] = ./printargs
$ ./printargs 1 2 3
arg[0] = ./printargs
arg[1] = 1
arg[2] = 2
arg[3] = 3
$ ./printargs arg{1..10}
arg[0] = ./printargs
arg[1] = arg1
arg[2] = arg2
arg[3] = arg3
arg[4] = arg4
arg[5] = arg5
arg[6] = arg6
arg[7] = arg7
arg[8] = arg8
arg[9] = arg9
arg[10] = arg10
$ ./printargs 'hello world' foo bar
arg[0] = ./printargs
arg[1] = hello world
arg[2] = foo
arg[3] = bar
```

Now let's make a executable shell script that calls printargs:

```sh
#!./printargs
```

```sh
$ chmod u+x ./shebang.sh
$ ./shebang.sh
arg[0] = ./printargs
arg[1] = ./shebang.sh
```

When executing the `./shebang.sh` shell script the kernel read the first line
of the source code and it detected a shebang that starts with `#!`.
And then replaced `./shebang.sh` with `./printargs` and then appended the
filename of the script itself `./shebang.sh`.
`./shebang.sh` = `./printargs ./shebang.sh`.

Now that you understand the concept of the shebang, we will do slight
modifications to the shebang, so to uncover how the implementation of the
shebang works on the linux kernel. Because that is the intent behind this post.
I would like to understand how the shebang works under the hood and modify it
to fit our needs.

Change the `shebang.sh` like this:

```diff
1c1
< #!./printargs
---
> #!./printargs arg1
```

```sh
#!./printargs arg1
```

```shell
$ ./shebang.sh
arg[0] = ./printargs
arg[1] = arg1
arg[2] = ./shebang.sh
```

We added an argument to the shebang, and the output of the script is expected.
`arg1` is the second argument before the appended filepath of the script `./shebang.sh`.

But now let's try and add another argument

```sh
#!./printargs arg1 arg2
```

```sh
$ ./shebang.sh
arg[0] = ./printargs
arg[1] = arg1 arg2
arg[2] = ./shebang.sh
```

If you notice carefully the `arg2` argument of the shebang was not treated as a
different argument when passed to `./printargs`.

We might expect:
```
arg[1] = arg1
arg[2] = arg2
```

But this is not what happens, even tough arguments are space separated, the
implementation in the linux kernel treats everything between the interpreter
and the new line as a single argument, that's why `arg1 arg2` is passed as a
single argument to printargs.
This would be equivalent to:

```sh
$ ./printargs 'arg1 arg2'
arg[0] = ./printargs
arg[1] = arg1 arg2
```

Now on the next chapter, we will hack the linux kernel to understand the
implementation of the shebang and we will modify it so that every argument
space separated to be passed separately to the interpreter.

## Kernel hacking

To make sure, that everyone following the post gets the same version of the
linux kernel. I have prepared a git repo with a version pinned down so you can
reproduce on your own machine.

There is a `flake.nix` with the necessary dependencies and tools to follow this
tutorial, so you can activate the environment with `nix develop`.

### Cloning and compiling linux kernel

```sh
git clone --depth=1 --recursive https://github.com/shelltux/linux-debug
cd linux-debug
make defconfig
make menuconfig
# [ ] - turn off
# [x] - turn on

# [ ] Processor type and features >>> Randomize the address of the kernel image (KASLR) -> This is a security feature, we will disable it so we can debug it with gdb
# [ ] Virtualization -> No need for virtualization
# [ ] Enable loadable module support -> No need for loading modules at runtime
# [ ] Networking support -> No need to reach over the network
# [x] Kernel hacking >>> Compile-time checks and compiler options >>> Debug information >>> Rely on the toolchain's implicit default DWARF version
# [x] Kernel hacking >>> Compile-time checks and compiler options >>> Provide GDB scripts for kernel debugging
make --jobs=$(nproc) # It will take awhile
```

### Compiling my own utilities to replace GNU coreutils

In `./rootfs/src` directory contains my own simple reimplementations of some
GNU coreutils, so I can interact with the system via text/shell. I made this so
I didn't need to pull the source code of coreutils to this repo and it is
necessary to have static linked executables because dynamic linking is not set
up.

Feel free to read the source code, the most important files are:
- `init.c` -> first program to be called
- `shell.c` -> simple shell
- `printargs.c` -> prints arguments in argv

```sh
# This command will compile and prepare rootfs.cpio.gz that contains the root
# filesystem for the linux kernel
make --directory=rootfs --jobs=$(nproc) # make -C rootfs -j4
```

### Running kernel

I prepared a shell script to launch qemu with the necessary flags.

```sh
./startvm.sh
```

#### Getting familiar with the tools

After starting using `startvm.sh` script, you can launch any executable in `/usr/local/bin`:

```sh
# You can use ls to list contents of directory
$ ls -lc /usr/local/bin
# You can use tee to write to a file, and stop writting to the file by closing
# stdin (Ctrl+d). -q just doesn't redirect to stdout so you see duplicate lines.
$ tee -q /tmp/shebang.sh
#!/usr/local/bin/printargs
(ctrl+d)
# use cat to see the content of a file
$ cat /tmp/shebang.sh
#!/usr/local/bin/printargs
# You can use chmod to change permissions the mode needs to be in octal mode
$ chmod 755 /tmp/shebang.sh # rwxr-xr-x
# Execute the script
/tmp/shebang.sh
$ tee -q /tmp/shebang.sh
#!/usr/local/bin/printargs foo bar baz
(ctrl+d)
$ /tmp/shebang.sh
```

Notice that foo bar baz is passed as a single argument.

![linux-debug-tools](/linux-debug/linux-debug-tools.gif)

### Debugging the kernel

Now let's move to debugging the linux kernel. We will do this by using gdb to
open a debugging remote session. qemu is already setup with a gdb server if you
launch the vm by `./startvm.sh`.

The `-s` flag when passed to qemu will open a gdb server session at `1234` port.

I have tracked down where the shebang implementation is by ripgrepping `"#!"`:
```sh
cd linux
rg '"#!"'
```

And I have found `load_script` function inside `linux/fs/binfmt_script.c`, so
will be setting a breakpoint inside this function.

On 2 terminal panes:

1. run linux kernel
```sh
./startvm.sh
```
2. Open gdb session
```gdb
(gdb) break load_script
(gdb) target remote :1234
```

![linux-gdb](/linux-debug/linux-debug-gdb.gif)

Take your time to understand why everything after the interpreter is considered a single argument.

### Modifying the kernel

I have wrote a patch that modifies the shebang implementation to separate arguments by whitespace.

```diff
diff --git i/fs/binfmt_script.c w/fs/binfmt_script.c
index 637daf6e4..ba71b8e35 100644
--- i/fs/binfmt_script.c
+++ w/fs/binfmt_script.c
@@ -30,6 +30,42 @@ static inline const char *next_terminator(const char *first, const char *last)
 			return first;
 	return NULL;
 }
+static inline char *strtok_r(char *text, const char *delimitors,
+			     char **save_this)
+{
+	if (save_this == NULL) {
+		return NULL;
+	}
+
+	if (text != NULL) {
+		/* New text. */
+		for (int i = 0; text[i] != '\0'; ++i) {
+			for (char *d = (char *)delimitors; *d != '\0'; d++) {
+				if (text[i] == *d) {
+					text[i] = '\0';
+					*save_this = &text[i + 1];
+					return text;
+				}
+			}
+		}
+	} else if ((save_this != NULL) && (*save_this != NULL)) {
+		/* Old text. */
+		char *start = *save_this;
+		for (int i = 0; (*save_this)[i] != '\0'; ++i) {
+			for (char *d = (char *)delimitors; *d != '\0'; ++d) {
+				if ((*save_this)[i] == *d) {
+					(*save_this)[i] = '\0';
+					*save_this = &((*save_this)[i + 1]);
+					return start;
+				}
+			}
+		}
+		*save_this = NULL;
+		save_this = NULL;
+		return start;
+	}
+	return NULL;
+}
 
 static int load_script(struct linux_binprm *bprm)
 {
@@ -113,10 +149,40 @@ static int load_script(struct linux_binprm *bprm)
 	*((char *)i_end) = '\0';
 	if (i_arg) {
 		*((char *)i_sep) = '\0';
+
+#define SHEBANG_SEPARATE_ARGS 1
+
+#if SHEBANG_SEPARATE_ARGS
+
+#define MAX_ARGS 64
+
+		char *save_ptr = NULL;
+		char *args[MAX_ARGS] = { 0 };
+		size_t argsSize = 0;
+
+		for (char *arg = strtok_r((char *)i_arg, " ", &save_ptr);
+		     arg != NULL; arg = strtok_r(NULL, " ", &save_ptr)) {
+			args[argsSize++] = arg;
+
+			if (argsSize >= MAX_ARGS)
+				break;
+		}
+
+		/*
+		 * Copy args to argv in reverse order
+		 */
+		for (char **arg = &args[argsSize - 1]; arg >= args; arg--) {
+			retval = copy_string_kernel(*arg, bprm);
+			if (retval < 0)
+				return retval;
+			bprm->argc++;
+		}
+#else
 		retval = copy_string_kernel(i_arg, bprm);
 		if (retval < 0)
 			return retval;
 		bprm->argc++;
+#endif
 	}
 	retval = copy_string_kernel(i_name, bprm);
 	if (retval)
```

Apply the patch

```sh
# Apply the patch
cd linux
git apply < ../binfmt_script.patch
make -j4 # Recompile
```

![post-patch](/linux-debug/linux-post-patch.gif)
