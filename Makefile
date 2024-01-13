
# User for systemd sercice overrides
ACTING_USER = vim-win32
ACTING_GROUP = vim-win32

FETCH_BIN = fetch-vim-win32
SERVICE_BIN = next-build

FETCH_SERVICE = vim-win32-nightly
TIMER_SERVICE = vim-win32-nightly

SYSTEMD_FILES = $(FETCH_SERVICE).service $(TIMER_SERVICE).timer
SYSTEMD_OVERRIDES = $(FETCH_SERVICE).overrides.conf

SRCDIR = .
DESTDIR =
PREFIX = /usr/local
BINDIR = $(PREFIX)/bin
LOGDIR = /var/log
WORKDIR = /var/lib/vim-win32

ifeq ($(PREFIX),/usr)
ETCDIR = /etc
else ifeq ($(PREFIX),/usr/local)
ETCDIR = /etc
else
ETCDIR= $(PREFIX)/etc
endif

ETC_SYSTEMD = $(ETCDIR)/systemd/system
LOG_FILE = vim-win32-build.log

all: bin etc-systemd

# build section

.PHONY: bin
bin: # nothing

.build:
	@mkdir $@

.PHONY: .build/$(FETCH_SERVICE).service
.build/$(FETCH_SERVICE).service: $(SRCDIR)/systemd/vim-win32-nightly.tmpl.service | .build
	sed \
	  -e 's#@@SERVICE_BIN@@#$(BINDIR)/$(SERVICE_BIN)#' \
	  -e 's#@@FETCH_BIN@@#$(BINDIR)/$(FETCH_BIN)#' \
	  -e 's#@@LOG_FILE@@#$(LOGDIR)/$(LOG_FILE)#' \
	  -e 's#@@WORKDIR@@#$(WORKDIR)#' \
	  $< >$@

$(FETCH_SERVICE).service: .build/$(FETCH_SERVICE).service
	@if ! cmp -s "$<" "$@"; then mv -vf "$<" "$@"; fi

.PHONY: .build/$(TIMER_SERVICE).timer
.build/$(TIMER_SERVICE).timer: $(SRCDIR)/systemd/vim-win32-nightly.tmpl.timer | .build
	sed -e 's/@@SERVICE_UNIT@@/$(FETCH_SERVICE)/' $< >$@

$(TIMER_SERVICE).timer: .build/$(TIMER_SERVICE).timer
	@if ! cmp -s "$<" "$@"; then mv -vf "$<" "$@"; fi

.PHONY: .build/$(FETCH_SERVICE).overrides.conf.static
.build/$(FETCH_SERVICE).overrides.conf.static: | .build
	@{ \
	  echo "[Service]"; \
	  echo "User=$(ACTING_USER)"; \
	  echo "Group=$(ACTING_GROUP)"; \
	} >"$@"

$(FETCH_SERVICE).overrides.conf: .build/$(FETCH_SERVICE).overrides.conf.static
	@if ! cmp -s "$<" "$@"; then mv -vf "$<" "$@"; fi

etc-systemd: $(SYSTEMD_FILES)
etc-systemd-overrides: $(SYSTEMD_OVERRIDES)

# system-reload when needed

.PHONY: reload
reload: .reloaded

.reloaded: .no-reload .need-reload
	@if [ "$(ETC_SYSTEMD)" = "/etc/systemd/system" ]; then \
	  if test -r .no-reload; then \
	    echo "systemd units: no change";\
	  else \
	    echo "system daemon-reload";\
	    systemctl daemon-reload; \
	  fi \
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

# install section

define INSTALL_IN_ETC_SYSTEMD
@if ! cmp -s "$1" "$2"; then touch .need-reload; $(RM) .no-reload; fi
install -C -m 0644 $1 $2
endef

.PHONY: install-systemd
install-systemd: etc-systemd
	install -m 0755 -d $(DESTDIR)$(ETC_SYSTEMD)
	$(call INSTALL_IN_ETC_SYSTEMD,$(FETCH_SERVICE).service,$(DESTDIR)$(ETC_SYSTEMD)/$(FETCH_SERVICE).service)
	$(call INSTALL_IN_ETC_SYSTEMD,$(TIMER_SERVICE).timer,$(DESTDIR)$(ETC_SYSTEMD)/$(TIMER_SERVICE).timer)

.PHONY: uninstall-systemd
uninstall-systemd:
	if [ "$(DESTDIR)$(ETC_SYSTEMD)" = "/etc/systemd/system" ]; then \
		if test -r "$(DESTDIR)$(ETC_SYSTEMD)/$(TIMER_SERVICE).timer"; then \
			systemctl disable "$(TIMER_SERVICE).timer"; \
			systemctl stop "$(TIMER_SERVICE).timer"; \
		fi; \
	fi
	$(RM) $(DESTDIR)$(ETC_SYSTEMD)/$(FETCH_SERVICE).service \
		 $(DESTDIR)$(ETC_SYSTEMD)/$(TIMER_SERVICE).timer \
		 $(DESTDIR)$(ETC_SYSTEMD)/$(FETCH_SERVICE).service.d/overrides.conf
	rmdir $(DESTDIR)$(ETC_SYSTEMD)/$(FETCH_SERVICE).service.d
	systemctl daemon-reload

.PHONY: install-bin
install-bin: bin
	install -m 0755 -d $(DESTDIR)$(BINDIR)
	install -m 0755 $(SRCDIR)/scripts/$(FETCH_BIN) $(DESTDIR)$(BINDIR)/$(FETCH_BIN)
	install -m 0755 $(SRCDIR)/scripts/$(SERVICE_BIN) $(DESTDIR)$(BINDIR)/$(SERVICE_BIN)

.PHONY: install-acting-bin
install-acting-bin: bin
	install -o "$(ACTING_USER)" -g "$(ACTING_GROUP)" -m 0755 -d $(DESTDIR)$(BINDIR)
	install -C -o "$(ACTING_USER)" -g "$(ACTING_GROUP)" -m 0755 $(SRCDIR)/scripts/$(FETCH_BIN) $(DESTDIR)$(BINDIR)/$(FETCH_BIN)
	install -C -o "$(ACTING_USER)" -g "$(ACTING_GROUP)" -m 0755 $(SRCDIR)/scripts/$(SERVICE_BIN) $(DESTDIR)$(BINDIR)/$(SERVICE_BIN)

.PHONY: install-acting-systemd
install-acting-systemd: etc-systemd-overrides
	install -m 0755 -d $(DESTDIR)$(ETC_SYSTEMD)/$(FETCH_SERVICE).service.d
	$(call INSTALL_IN_ETC_SYSTEMD,$(FETCH_SERVICE).overrides.conf,$(DESTDIR)$(ETC_SYSTEMD)/$(FETCH_SERVICE).service.d/overrides.conf)

.PHONY: uninstall-acting-systemd
uninstall-acting-systemd:
	$(RM) $(DESTDIR)$(ETC_SYSTEMD)/$(FETCH_SERVICE).service.d/overrides.conf
	rmdir $(DESTDIR)$(ETC_SYSTEMD)/$(FETCH_SERVICE).service.d || true

.PHONY: uninstall-bin
uninstall-bin:
	$(RM) $(DESTDIR)$(BINDIR)/$(FETCH_BIN) $(DESTDIR)$(BINDIR)/$(SERVICE_BIN)

.NOTPARALLEL: install
install: install-bin install-systemd

.PHONY: install-acting
.NOTPARALLEL: install-acting
install-acting: install-acting-bin install-systemd install-acting-systemd reload

.PHONY: uninstall
uninstall: uninstall-systemd uninstall-bin

.PHONY: uninstall-acting
.NOTPARALLEL: uninstall-acting
uninstall-acting: uninstall-acting-systemd uninstall reload

# miscellaneous section

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
