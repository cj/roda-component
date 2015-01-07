# GEMSPEC=$(shell ls *.gemspec | head -1)
# VERSION=$(shell ruby -rubygems -e 'puts Gem::Specification.load("$(GEMSPEC)").version')
# PROJECT=$(shell ruby -rubygems -e 'puts Gem::Specification.load("$(GEMSPEC)").name')
# GEM=$(PROJECT)-$(VERSION).gem
#
.PHONY: install package publish test server $(GEM)

define install_bs
	gem list bundler -i || gem install bundler
endef

define gem_paths
	gem list bundler -i || gem install bundler
endef

install:
	$(call install_bs)
	bundle config --local path .bundle
	gem update roda-bin
	bundle

server:
	cd test/dummy && bundle exec thin start -p 8080

test:
	bundle exec pry-test --async

package: $(GEM)

# Always build the gem
$(GEM):
	gem build $(PROJECT).gemspec

publish: $(GEM)
	gem push $(GEM)
	rm $(GEM)
	git tag -a $(VERSION)
	git push
