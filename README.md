## Install system to trigger vim-win32 update and build

Every midnight in Europe/Paris time zone, Vim project is checked for latest
tag. If tag was made at least 9 hours, new build is started if tag is not
yet in vim-win32-build project. Else, a new check is made 9 hours after
last tag date time. 

This small project contains systemd files and script to realize this
operation.

### Prerequisites

- Systemd
- User and group `vim-win32` to run service (and requires home folder)
- GNU Makefile
- Python 3 to run `vimbuild`
- `vimbuild` installed at `$HOME/.local/bin/vimbuild`

Program `vimbuild` will fetch latest tag metadata of project
<https://github.com/vim/vim>.

### Usage

Default `make` is to show small help. Use `install` and `uninstall` to manage
project files on host. Use commodity command `make reload` to run `systemctl
daemon-reload`.

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
