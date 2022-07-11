.PHONY: run post

run:
	@hugo server -D --bind=0.0.0.0

post-%:
	@hugo new post/$*