# Estimated runtime memory usage:
# 	Greek: 		2.55 MB
# 	Bulgarian: 	1.19 MB
# 	Total: 		~3,74 MB
.PHONY: all
all: greek bulgarian

# Bug: https://github.com/vim/vim/issues/299
# Bug was cleaned in vim repo, but entries in FTP server are not updated
# This patches the dictionary with a fix

.PHONY: greek
greek: el.utf-8.spl

el.utf-8.spl : el_GR.dic el_GR.aff
	vim --clean --cmd "mkspell! el el_GR" --cmd q

el_GR.diff:
	curl -Lo el_GR.diff https://github.com/vim/vim/raw/master/runtime/spell/el/el_GR.diff
	vim --clean -c 'e ++enc=iso-8859-7 el_GR.diff' -c '3,47d' -c 'exe "4normal 62\<C-a>"' -c 'exe "5normal 62\<C-a>E62\<C-a>"' -c 'w ++enc=utf-8' -c 'q'

el_GR.aff: el_GR.diff
	curl -Lo el_GR.aff https://github.com/wooorm/dictionaries/raw/main/dictionaries/el/index.aff
	patch < el_GR.diff

el_GR.dic:
	curl -Lo el_GR.dic https://github.com/wooorm/dictionaries/raw/main/dictionaries/el/index.dic

# .PHONY: bulgarian
# bulgarian: bg.utf-8.spl
#
# bg.utf-8.spl : bg_BG.dic bg_BG.aff
# 	vim --clean --cmd "mkspell! bg bg_BG" --cmd q
#
# bg_BG.aff:
# 	curl -Lo bg_BG.aff https://github.com/wooorm/dictionaries/raw/main/dictionaries/bg/index.aff
#
# bg_BG.dic:
# 	curl -Lo bg_BG.dic https://github.com/wooorm/dictionaries/raw/main/dictionaries/bg/index.dic

.PHONY: clean
clean:
	rm *.{aff,dic,diff}
