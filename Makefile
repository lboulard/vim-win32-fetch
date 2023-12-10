
ETC_SYSTEMD ?= /etc/systemd/system
VIM_WIN32_USER ?= vim-win32
VIM_WIN32_GROUP ?= vim-win32
VIM_WIN32_HOME ?= $(shell getent passwd $(VIM_WIN32_USER) | cut -d: -f6)

FETCH_SERVICE = vim-win32-nightly
TIMER_SERVICE = vim-win32-nightly

FETCH_BIN = $(VIM_WIN32_HOME)/fetch-vim-win32
SERVICE_BIN = $(VIM_WIN32_HOME)/next-build
LOG_FILE = vim-win32-build.log

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
@touch .need-reload; $(RM) .no-reload
endef

.build:
	@mkdir $@

.build/$(FETCH_SERVICE).service: vim-win32-nightly.service | .build
	sed -e 's#@@SERVICE_BIN@@#$(SERVICE_BIN)#' $< >"$@.tmp"; \
	mv -f "$@.tmp" "$@"

$(ETC_SYSTEMD)/$(FETCH_SERVICE).service: .build/$(FETCH_SERVICE).service
	$(INSTALL_IN_ETC_SYSTEMD)

.build/$(TIMER_SERVICE).timer: vim-win32-nightly.timer | .build
	sed -e 's/@@SERVICE_UNIT@@/$(FETCH_SERVICE)/' $< >"$@.tmp"; \
	mv -f "$@.tmp" "$@"

$(ETC_SYSTEMD)/$(TIMER_SERVICE).timer: .build/$(TIMER_SERVICE).timer
	$(INSTALL_IN_ETC_SYSTEMD)

.PHONY: .build/$(FETCH_SERVICE).overrides.conf.static
.build/$(FETCH_SERVICE).overrides.conf.static: | .build
	@{ \
	  echo "[Service]"; \
	  echo "Environment=FETCH_BIN=$(FETCH_BIN)"; \
	  echo "Environment=LOG_FILE=$(LOG_FILE)"; \
        } >"$@"

.build/$(FETCH_SERVICE).overrides.conf: .build/$(FETCH_SERVICE).overrides.conf.static | .build
	@if ! cmp -s "$<" "$@"; then mv -vf "$<" "$@"; fi

$(ETC_SYSTEMD)/$(FETCH_SERVICE).service.d:
	@mkdir "$@"

$(ETC_SYSTEMD)/$(FETCH_SERVICE).service.d/overrides.conf: .build/$(FETCH_SERVICE).overrides.conf | $(ETC_SYSTEMD)/$(FETCH_SERVICE).service.d
	$(INSTALL_IN_ETC_SYSTEMD)

.PHONY: reload
reload: .reloaded

.reloaded: .no-reload .need-reload
	@if test -r .no-reload; then \
	  echo "systemd units: no change";\
	else \
	  echo "system daemon-reload";\
	  systemctl daemon-reload; \
	fi
	@$(RM) ".need-reload"
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
install-systemd: install-systemd-files install-systemd-overrides reload

.PHONY: install-systemd-files
install-systemd-files: \
 $(ETC_SYSTEMD)/$(FETCH_SERVICE).service \
 $(ETC_SYSTEMD)/$(TIMER_SERVICE).timer

.PHONY: install-systemd-overrides
install-systemd-overrides: \
 $(ETC_SYSTEMD)/$(FETCH_SERVICE).service.d/overrides.conf

.PHONY: uninstall-systemd
uninstall-systemd:
	if [ "$(ETC_SYSTEMD)" = "/etc/systemd/system" ]; then \
		if test -r "$(ETC_SYSTEMD)/$(TIMER_SERVICE).timer"; then \
			systemctl disable "$(TIMER_SERVICE).timer"; \
			systemctl stop "$(TIMER_SERVICE).timer"; \
		fi; \
	fi
	$(RM) $(ETC_SYSTEMD)/$(FETCH_SERVICE).service \
		 $(ETC_SYSTEMD)/$(TIMER_SERVICE).timer \
		 $(ETC_SYSTEMD)/$(FETCH_SERVICE).service.d/overrides.conf
	rmdir $(ETC_SYSTEMD)/$(FETCH_SERVICE).service.d
	systemctl daemon-reload

define INSTALL_IN_VIM_WIN32
install -o "$(VIM_WIN32_USER)" -g "$(VIM_WIN32_GROUP)" -m 0755 $< $@
endef

$(FETCH_BIN): fetch-vim-win32
	$(INSTALL_IN_VIM_WIN32)

$(SERVICE_BIN): next-build
	$(INSTALL_IN_VIM_WIN32)

.PHONY: install-vim-win32
install-vim-win32: $(FETCH_BIN) $(SERVICE_BIN)

.PHONY: uninstall-vim-win32
uninstall-vim-win32:
	$(RM) $(FETCH_BIN) $(SERVICE_BIN)

.ONESHELL: status
.PHONY: status
status:
	systemctl status $(TIMER_SERVICE).timer
	systemctl status $(FETCH_SERVICE).service

.ONESHELL: clean
.PHONY: clean
clean:
	$(RM) -r .build
	$(RM) .no-reload .need-reload

# vim:noet sw=8 st=8 sts=8
