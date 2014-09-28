GEMSPEC=$(shell ls *.gemspec | head -1)
VERSION=$(shell ruby -rubygems -e 'puts Gem::Specification.load("$(GEMSPEC)").version')
PROJECT=$(shell ruby -rubygems -e 'puts Gem::Specification.load("$(GEMSPEC)").name')
GEM=$(PROJECT)-$(VERSION).gem

.PHONY: install package publish test server $(GEM)

define install_bs
	which bs || (wget https://raw.githubusercontent.com/educabilia/bs/master/bin/bs && chmod +x bs && sudo mv bs /usr/local/bin)

	@if [ -s .gs ]; then \
		true; \
	else \
		mkdir .gs; \
		touch .env; \
		echo 'GEM_HOME=$(PWD)/.gs' >> .env; \
		echo 'GEM_PATH=$(PWD)/.gs' >> .env; \
		echo 'PATH=$(PWD)/.gs/bin:$$PATH' >> .env; \
		echo 'RACK_ENV=test' >> .env.test; \
	fi;

	bs gem list dep-cj -i || bs gem install dep-cj
	gem list cutest-cj -i || gem install cutest-cj
endef

install:
	$(call install_bs)
	bs dep install
	bs gem cleanup

test:
	bs env $$(cat .env.test) cutest test/**/*_test.rb

package: $(GEM)

# Always build the gem
$(GEM):
	gem build $(PROJECT).gemspec

publish: $(GEM)
	gem push $(GEM)
	rm $(GEM)
	git tag -a $(VERSION)
	git push
