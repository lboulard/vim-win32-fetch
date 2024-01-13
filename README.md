## Install system to trigger vim-win32 update and build

Every midnight in Europe/Paris time zone, Vim project is checked for latest
tag. If tag was made at least 9 hours, new build is started if tag is not
yet in vim-win32-build project. Else, a new check is made 9 hours after
last tag date time.

This small project contains systemd files and script to realize this
operation.

### Prerequisites

- Systemd
- User and group `vim-win32` to run service (and required home folder)
- GNU Makefile

Program `vimbuild` will fetch latest tag metadata of project
<https://github.com/vim/vim>.

### Usage

Default `make` will create service and timer systemd files. Use `install` and
`uninstall` to manage project files on host. Use commodity command `make
reload` to run `systemctl daemon-reload`.

Default is too run inside `/var/lib/vim-win32` folder.
Log can be found in `/var/log/vim-win32-fetch.log`.

#### Install files

Run `make install` to install files. Enable nightly build with
`systemctl enable vim-win32-nightly.timer` and then
`systemctl start vim-win32-nightly.timer`

#### Uninstall files

Run `make uninstall` to clear files. Makefile will try to stop and disable
timer first before remove installed files.
You can do it manually with
`systemctl disable vim-win32-nightly.timer` and then
`systemctl stop vim-win32-nightly.timer`.

#### Check outputs

Run `systemctl status vim-win32-nightly.timer` to verify timer state.

Run
`journalctl -n 30 -u vim-win32-nightly.timer -u vim-win32-fetch.service`
to verify timer and service results.

## Install directly in `vim-win32` home folder

Use this command to install and run directly in home folder of `win32-user`
user.

```shell
make install-acting PREFIX=/home/vim-win32 ETCDIR=/etc BINDIR=/home/vim-win32 WORKDIR=\~ LOGDIR=.
```

Installation will try to reload systemd is needed. See "Install Files" section
to enable and start timer. Log will at home folder root. Work folder will be
home folder itself.

Use `ACTING_USER` and `ACTING_GROUP` to change default user for service.

To remove, use

```shell
make uninstall-acting PREFIX=/home/vim-win32 ETCDIR=/etc BINDIR=/home/vim-win32
```
