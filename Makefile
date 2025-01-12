# Basic package information
PKG_NAME=heaptrace
PKG_DESCRIPTION="helps visualize heap operations for pwn and debugging"
PKG_VERSION:=$(shell dpkg-parsechangelog -S Version | sed -rne 's,([^-\+]+)+(\+dfsg)*.*,\1,p'i)
UPSTREAM_PACKAGE:=$(PKG_NAME)_${PKG_VERSION}.orig.tar.gz
PKG_RELEASE=0
PKG_MAINTAINER="Aaron Esau \<contact@aaronesau.com\>"
PKG_ARCH=x86_64
PKG_ARCH_RPM=x86_64

TARGET=$(PKG_NAME)
PREFIX:=/usr
CC:=gcc
#CFLAGS:=-g -Wall
CCFLAGS:=-O3 -fpie
CFLAGS:=-O3 -fpie


.PHONY: default all clean

default: $(TARGET)
all: default

OBJECTS = $(patsubst %.c, %.o, $(wildcard src/*.c))
HEADERS = $(wildcard inc/*.h)

%.o: %.c $(HEADERS)
	$(CC) $(CCFLAGS) -c $< -o $@ -Iinc/

.PRECIOUS: $(TARGET) $(OBJECTS)

$(TARGET): $(OBJECTS)
	$(CC) $(CFLAGS) $(OBJECTS) -Wall $(LIBS) -o $@

clean:
	-rm -f src/*.o
	-rm -f $(TARGET)
	-rm -f *.deb *.rpm
	#-rm -f ../${UPSTREAM_PACKAGE}

# PREFIX is environment variable, but if it is not set, then set default value
ifeq ($(PREFIX),)
	PREFIX := /usr
endif


.PHONY: install
install: $(TARGET)
	mkdir -p $(DESTDIR)$(PREFIX)/bin $(DESTDIR)$(PREFIX)/share/man/man1
	cp $< $(DESTDIR)$(PREFIX)/bin/$(TARGET)
	
	install -m 0644 man/heaptrace.1 $(DESTDIR)$(PREFIX)/share/man/man1/
	gzip -f $(DESTDIR)$(PREFIX)/share/man/man1/heaptrace.1


.PHONY: uninstall
uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/$(TARGET) $(DESTDIR)$(PREFIX)/share/man/man1/heaptrace.1.gz

# These vars probably need no change
PKG_DEB=${PKG_NAME}_${PKG_VERSION}-${PKG_RELEASE}_${PKG_ARCH}.deb
PKG_RPM=${PKG_NAME}-${PKG_VERSION}-${PKG_RELEASE}.${PKG_ARCH_RPM}.rpm
FPM_OPTS=-s dir -n $(PKG_NAME) -v $(PKG_VERSION) --iteration $(PKG_RELEASE) -C $(TMPINSTALLDIR) --maintainer ${PKG_MAINTAINER} --description $(PKG_DESCRIPTION) -a $(PKG_ARCH)
TMPINSTALLDIR=/tmp/$(PKG_NAME)-fpm-install

dpkg: clean
	tar cafv ../${UPSTREAM_PACKAGE} . --exclude debian --exclude .git

# Generate a deb package using fpm
deb:
	rm -rf $(TMPINSTALLDIR)
	rm -f $(PKG_DEB)
	make clean
	make CFLAGS="$(CFLAGS) -static" CCFLAGS="$(CCFLAGS) -static"
	chmod -R g-w *	
	make install DESTDIR=$(TMPINSTALLDIR)
	fpm -t deb -p $(PKG_DEB) $(FPM_OPTS) \
		usr

# Generate a rpm package using fpm
rpm:
	rm -rf $(TMPINSTALLDIR)
	rm -f $(PKG_RPM)
	make clean
	make CFLAGS="$(CFLAGS) -static" CCFLAGS="$(CCFLAGS) -static"
	chmod -R g-w *	
	make install DESTDIR=$(TMPINSTALLDIR)
	fpm -t rpm -p $(PKG_RPM) $(FPM_OPTS) \
		usr

