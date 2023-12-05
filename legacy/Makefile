
ETC_SYSTEMD ?= /etc/systemd/system
VIM_WIN32_USER ?= vim-win32
VIM_WIN32_GROUP ?= vim-win32
VIM_WIN32_HOME ?= $(shell getent passwd $(VIM_WIN32_USER) | cut -d: -f6)

SCRIPTS = \
 $(VIM_WIN32_HOME)/vim-win32-run \
 $(VIM_WIN32_HOME)/update-vim-win32-build

.DEFAULT: help
.PHONY: help
help:
	@echo "'make install' to install all files"; \
	echo "'make uninstall' to uninstall all files"; \
	false

.NOTPARALLEL: install
install: install-vim-win32 install-systemd

uninstall: uninstall-systemd uninstall-vim-win32

define INSTALL_IN_ETC_SYSTEMD
install -o root -g root -m 0644 $< $@
touch .need-reload
endef

$(ETC_SYSTEMD)/vim-win32-run.service: vim-win32-run.service
	$(INSTALL_IN_ETC_SYSTEMD)

.PHONY: reload
reload: .reloaded

.reloaded: .no-reload .need-reload
	test -r .no-reload || systemctl daemon-reload
	@touch $@
# this recipe run when systemd install is nop
.SILENT: .need-reload
.need-reload:
	@touch $@
# when .need-reload is absent create .no-reload file
.SILENT: .no-reload
.PHONY: .no-reload
.no-reload:
	@test -r .need-reload || touch $@

.PHONY: install-systemd
.NOTPARALLEL: install-systemd
install-systemd: install-systemd-files reload

.PHONY: install-systemd-files
install-systemd-files: \
 $(ETC_SYSTEMD)/vim-win32-run.service

.PHONY: uninstall-systemd
uninstall-systemd:
	if [ "$(ETC_SYSTEMD)" = "/etc/systemd/system" ]; then \
		if test -r "$(ETC_SYSTEMD)/vim-win32-run.service"; then \
			systemctl disable vim-win32-run; \
			systemctl stop vim-win32-run; \
		fi; \
	fi
	$(RM) $(ETC_SYSTEMD)/vim-win32-run.service
	systemctl daemon-reload

define INSTALL_IN_VIM_WIN32
install -o "$(VIM_WIN32_USER)" -g "$(VIM_WIN32_GROUP)" -m 0755 $< $@
endef

$(VIM_WIN32_HOME)/vim-win32-run: vim-win32-run
	$(INSTALL_IN_VIM_WIN32)

$(VIM_WIN32_HOME)/update-vim-win32-build: update-vim-win32-build
	$(INSTALL_IN_VIM_WIN32)

.PHONY: install-vim-win32
install-vim-win32: $(SCRIPTS)

.PHONY: uninstall-vim-win32
uninstall-vim-win32:
	$(RM) $(SCRITPS)

# vim:noet sw=8 st=8 sts=8
