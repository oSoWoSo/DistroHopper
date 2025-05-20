datarootdir := $(PREFIX)/share
datadir := $(datarootdir)
mandir := $(datarootdir)/man
bindir :=  $(PREFIX)/bin

all: ../docs/quickemu.1.md

../docs/quickemu.1.md :
	./build_manuals

clean:
	rm ../docs/*.md
	#rm ../docs/*.1
	rm ./quickemu_conf.lst
	rm ./quickemu.lst
	rm ./quickget.lst
	rm ./README_main.md
	rm ./README.lst
	rm ./*-generated.md



install_docs: all
	install -d $(DESTDIR)$(mandir)/man1
	install -m 644 ../docs/quickget.1 $(DESTDIR)$(mandir)/man1
	install -m 644 ../docs/quickemu.1 $(DESTDIR)$(mandir)/man1
	install -m 644 ../docs/quickemu_conf.1 $(DESTDIR)$(mandir)/man1


install_bins:
	install -d $(DESTDIR)$(bindir)
	install -m 755 ../quickget $(DESTDIR)$(bindir)
	install -m 755 ../quickemu $(DESTDIR)$(bindir)
	install -m 755 ../quickreport $(DESTDIR)$(bindir)
	install -m 755 ../chunckcheck $(DESTDIR)$(bindir)

install: install_bins  install_docs

uninstall::
	rm -f $(DESTDIR)$(mandir)/man1/quickget.1
	rm -f $(DESTDIR)$(mandir)/man1/quickemu.1
	rm -f $(DESTDIR)$(mandir)/man1/quickemu_conf.1
	rm -f $(DESTDIR)$(bindir)/quickget
	rm -f $(DESTDIR)$(bindir)/quickemu
	rm -f $(DESTDIR)$(bindir)/quickreport
	rm -f $(DESTDIR)$(bindir)/macrecovery
	rm -f $(DESTDIR)$(bindir)/chunkcheck


.PHONY: all
