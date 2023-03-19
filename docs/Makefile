include pandoc-man.mk

ifeq ($(PREFIX),)
    PREFIX := /usr
endif

datarootdir := $(PREFIX)/share
datadir := $(datarootdir)
mandir := $(datarootdir)/man
bindir :=  $(PREFIX)/bin
ICONS_DIR := config/icons

all: distrohopper.1 quickget.1 quickemu.1 quickemu_conf.1

clean:
	rm *.1

install_docs: all
	install -d $(DESTDIR)$(mandir)/man1
	install -m 644 distrohopper.1 $(DESTDIR)$(mandir)/man1
	install -m 644 quickget.1 $(DESTDIR)$(mandir)/man1
	install -m 644 quickemu.1 $(DESTDIR)$(mandir)/man1
	install -m 644 quickemu_conf.1 $(DESTDIR)$(mandir)/man1

#   install -m 644 quickgui.1 $(DESTDIR)$(mandir)/man1

install_bins:
	install -d $(DESTDIR)$(bindir)
	install -m 755 ../dh $(DESTDIR)$(bindir)
	install -m 755 ../quickget $(DESTDIR)$(bindir)
	install -m 755 ../quickemu $(DESTDIR)$(bindir)
	install -m 755 ../macrecovery $(DESTDIR)$(bindir)

install_icons:
	install -d $(DESTDIR)$(datadir)/icons/dh
	install -m 644 $(ICONS_DIR)/*.svg $(DESTDIR)$(datadir)/icons/dh
	install -m 644 $(ICONS_DIR)/*.png $(DESTDIR)$(datadir)/icons/dh

install: install_bins  install_docs install_icons

uninstall_icons:
	rm -f $(DESTDIR)$(datadir)/icons/dh/*.svg
	rm -f $(DESTDIR)$(datadir)/icons/dh/*.png

uninstall_docs:
	rm -f $(DESTDIR)$(mandir)/man1/distrohopper.1
	rm -f $(DESTDIR)$(mandir)/man1/quickget.1
	rm -f $(DESTDIR)$(mandir)/man1/quickemu.1
	rm -f $(DESTDIR)$(mandir)/man1/quickemu_conf.1

uninstall_bins:
	rm -f $(DESTDIR)$(bindir)/dh
	rm -f $(DESTDIR)$(bindir)/quickget
	rm -f $(DESTDIR)$(bindir)/quickemu
	rm -f $(DESTDIR)$(bindir)/macrecovery

uninstall: uninstall_icons uninstall_docs uninstall_bins


.PHONY: all
