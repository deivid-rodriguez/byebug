EXT=1
man1_MANS = byebug.$(EXT)

EXTRA_DIST = $(man1_MANS)  \
        hanoi.rb primes.rb test-tri2.rb tri3.rb triangle.rb \
				byebug.info byebug.html byebug.pdf

info_TEXINFOS = byebug.texi

all: $(man1_MANS) html

man: $(man1_MANS)

html: byebug.html

byebug.html: byebug.texi
	texi2html byebug.texi || true

%.ps.gz: %.ps
	gzip -9c $< > $@
