##############################################################################
# $Id: Makefile.am,v 1.3 2006/12/28 12:34:25 rockyb Exp $
#  Copyright (C) 2007 Rocky Bernstein
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
##############################################################################

EXT=1
man1_MANS = rdebug.$(EXT)

EXTRA_DIST = $(man1_MANS)  \
        hanoi.rb primes.rb test-tri2.rb tri3.rb triangle.rb \
	ruby-debug.info ruby-debug.html ruby-debug.pdf

info_TEXINFOS = ruby-debug.texi rdebug-emacs.texi

all: $(INFO_DEPS) $(man1_MANS) html pdf

pdf: ruby-debug.pdf rdebug-emacs.pdf

txt: ruby-debug.txt rdebug-emacs.txt

ps: ruby-debug.ps rdebug-emacs.ps

man: $(man1_MANS)

html: ruby-debug.html rdebug-emacs.html

ruby-debug.html: ruby-debug.texi
	texi2html $(srcdir)/ruby-debug.texi || true

rdebug-emacs.html: rdebug-emacs.texi
	texi2html $(srcdir)/rdebug-emacs.texi || true

%.ps.gz: %.ps
	gzip -9c $< > $@

# Our `texinfo.tex' must reside in the current directory, otherwise
# texi2dvi will use the default.
.texi.pdf:
	$(TEXI2PDF) -I $(srcdir) $<

.texi.dvi:
	$(TEXI2DVI) -I $(srcdir) $<

.dvi.ps:
	test -d $(docdir) || mkdir $(docdir)
	$(DVIPS) $< -o $@

all-formats: pdf dvi txt ps html

MOSTLYCLEANFILES = rubydb.tgs rubydb.ps.gz rubydb.pdf rubydb.html rubydb_toc.html rubydb_foot.html rubydb-man.html
